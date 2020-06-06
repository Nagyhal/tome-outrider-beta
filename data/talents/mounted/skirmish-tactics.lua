-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2020 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

newTalent{
	name = "Beastmaster's Mark", short_name = "OUTRIDER_BEASTMASTERS_MARK", image = "talents/beastmasters_mark.png",
	type = {"mounted/skirmish-tactics", 1},
	points = 5,
	cooldown = 10,
	stamina = 15,
	require = techs_dex_req1,
	range = archery_range,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 } },
	on_pre_use = function(self, t, silent, fake) return preCheckArcheryInAnySlot(self, t, silent, fake) end,
	on_learn = function(self ,t)
		-- if not self:knowTalent(self.T_OUTRIDER_MOUNTED_ARCHERY_MASTERY) then
		-- 	self:learnTalent(self.T_OUTRIDER_MOUNTED_ARCHERY_MASTERY, true) 
		-- end
		if not self.__show_special_talents[self.T_OUTRIDER_MOUNTED_ARCHERY_MASTERY] then
			table.set(self, "__show_special_talents", "T_OUTRIDER_MOUNTED_ARCHERY_MASTERY", true)
		end
	end,
	archery_onhit = function(self, t, target, x, y)
		local mount = self:hasMount()
		if target:canBe("cut") then target:setEffect(target.EFF_CUT, t.getDur(self, t), {power=t.getBleed(self, t)}) end
		if not mount then return true end
		mount:setEffect(mount.EFF_OUTRIDER_BEASTMASTER_MARK,  t.getDur(self, t), {target=target})
	end,
	action = function(self, t)
		local targets = getArcheryTargetsWithSwap(self)
		if not targets then return nil end
		self:archeryShoot(targets, t, nil, {mult=t.getDam(self, t)})
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local bleed = t.getBleed(self, t)
		local dur = t.getDur(self, t)
		local speed = t.getSpeed(self, t)*100
		local loyalty = t.getLoyalty(self, t)
		-- local range = t.getRushRange(self, t)
		return ([[You let off a jagged missile that fills your steed with a savage thirst for blood, enraging it. You shoot your enemy for %d%% damage, bleeding it for %d damage and marking it with the Beastmaster's Mark for %d turns. While this is in effect, your steed concentrates solely upon this foe, moving and attacking %d%% faster, but if you hold it back it will lose %.1f Loyalty per turn that you do this.

			Investing in the Skirmish Tactics tree also teaches you the Mounted Combat Mastery skill.]]):
		format(dam, bleed, dur, speed, loyalty, range)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	getBleed = function(self, t) return self:combatTalentPhysicalDamage(t, 10, 16)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 5, 9) end,
	getLoyalty = function(self, t) return self:combatTalentLimit(t, 1, 5, 3) end,
	getSpeed = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	-- getRushRange = function(self, t) return math.min(10, self:combatTalentScale(t, 3, 8)) end,
}


--4: Cacophonous Downpour
--How should it work? Fire arrows against everyone, then over 2 turns repeat
newTalent{
	name = "Cacophonous Downpour", short_name = "OUTRIDER_CACOPHONOUS_DOWNPOUR", image = "talents/cacophonous_downpour.png",
	type = {"mounted/skirmish-tactics", 2},
	no_energy = "fake",
	points = 5,
	random_ego = "attack",
	cooldown = 8,
	stamina = 16,
	require = techs_dex_req2,
	range = archery_range,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 2, 3.7)) end,
	tactical = { ATTACKAREA = { weapon = 2 }, DISABLE = { confusion = 1, silence = 1 }},
	requires_target = true,
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), display=self:archeryDefaultProjectileVisual(weapon, ammo)}
	end,
	on_pre_use = function(self, t, silent, fake) return archerPreUse(self, t, silent, fake) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		-- local _ _, x, y = self:canProject(tg, x, y)
		local targets = self:archeryAcquireTargets(tg)
		if not targets then return nil end

		local dam = t.getDam(self,t)
		local radius = self:getTalentRadius(t)

		self:archeryShoot(targets, t, {type = "hit", selffire=false}, {mult=dam})

		local dur = t.getDur(self, t)
		local power = t.getConfusePower(self, t)
		local phys_power = self:combatPhysicalpower()

		for _, target in ipairs(targets) do
			target:setEffect(target.EFF_CONFUSED, dur, {{power=power}, apply_power=phys_power})

			if self:getTalentLevel(t) >= 3 and rng.percent(t.getSilenceChance(self, t)) then
				target:setEffect(target.EFF_SILENCED, dur, {apply_power=phys_power})
			end
		end

		game.level.map:particleEmitter(x, y, radius, "volley", {radius=radius})
	end,
	info = function(self, t)
		local rad = self:getTalentRadius(t)
		local dam = t.getDam(self,t)*100
		local confuse_power = t.getConfusePower(self, t)
		local silence_chance = t.getSilenceChance(self, t)
		local dur = t.getDur(self, t)
		return ([[Taking specially notched arrows from your quiver, you let loose a rain of horridly screeching missiles upon your foes. Your arrows rain down for 3 turns upon targets in radius of %d, striking 3 per turn. Each target stands a chance to be confused by the cacophony (%d power, duration).

			At talent level 3 there is also a %d%% chance to inflict silence, as the screeching becomes loud enough to drown out the chants of spellcasters.]])
		:format(dam, rad, confuse_power, dur, silence_chance)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 0.87, 1.42) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 5) end,
	getConfusePower = function(self, t) return self:combatTalentLimit(t, 60, 27, 52) end,
	getSilenceChance = function(self, t) return math.max(50, self:combatTalentLimit(t, 90, 19, 54)) end,
}

newTalent{
	name = "Loose in the Saddle", short_name = "LOOSE_IN_THE_SADDLE", image = "talents/loose_in_the_saddle.png",
	type = {"mounted/skirmish-tactics", 3},
	hide="always", --DEBUG: Hiding untested talents 
	points = 5,
	mode = "sustained",
	sustain_stamina = 50,
	no_energy = true,
	cooldown = function(self, t) return self:combatTalentLimit(t, 8, 20, 12) end,
	require = techs_dex_req3,
	activate = function(self, t)
		local mount = self:hasMount()
		local ret = {
			reduction=t.getReduction(self, t)/100,
		}
		if mount then
			mount:setEffect(mount.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED, 2, ret)
			ret.mount = mount
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if ret.mount then
			ret.mount:removeEffect(ret.mount.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED, true, true)
		end
		return true
	end,
	callbackOnTakeDamage = function(self, t, src, x, y, type, dam, state)
		if not self:isMounted() then return end
		local p = self:isTalentActive(t.id)
		if dam>self.max_life*.15 then
			dam = dam - dam*p.reduction
			self:setEffect(self.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE, 2, {speed=t.getSpeed(self, t)/100})
			self:forceUseTalent(self.T_OUTRIDER_LOOSE_IN_THE_SADDLE, {ignore_energy=true})
		end
		return {dam=dam}
	end,
	info = function(self, t)
		local reduction = t.getReduction(self, t)
		local speed = t.getSpeed(self, t)
		return ([[While mounted, if you or your mount are hit for over 15%% of your max health (but not enough to kill you), then you take only %d%% of that damage, this sustain deactivates, and you gain a movement speed increase of %d%% for one turn and may mount or dismount freely - but if you do anything other than mount, dismount or move, then this bonus ends.]]):
		format(reduction, speed)
	end,
	getReduction = function(self, t) return self:combatTalentLimit(t, 80, 35, 60) end,
	getSpeed = function(self, t) return self:combatTalentScale(t, 400, 650) end,
}

newTalent{
	name = "Spring Attack", short_name = "OUTRIDER_SPRING_ATTACK", image = "talents/spring_attack.png",
	type = {"mounted/skirmish-tactics", 4},
	hide="always", --DEBUG: Hiding untested talents
	require = techs_dex_req4,
	no_energy = true,
	points = 5,
	cooldown = 10,
	stamina = 10,
	range = archery_range,
	on_pre_use = function(self, t, silent, fake) return preCheckArcheryInAnySlot(self, t, silent, fake) end,
	requires_target = true,
	tactical = { ATTACK = { weapon = 1 }, DISABLE = { pin = 2 } },
	archery_onhit = function(self, t, target, x, y)
		self:setEffect(self.EFF_OUTRIDER_SPRING_ATTACK, t.getDur(self, t), {target=target})
		target:setEffect(target.EFF_OUTRIDER_SPRING_ATTACK_TARGET, t.getDur(self, t), {src=self})
	end,
	action = function(self, t)
		local targets = getArcheryTargetsWithSwap(self)
		if not targets then return nil end

		self:archeryShoot(targets, t, nil, {mult=t.getDam(self, t)})

		return true
	end,
 	points = 5,
	info = function(self, t)
		local dam_pct = t.getDam(self, t)*100
		local dur = t.getDur(self, t)
		local min_pct = t.getMinPct(self, t)
		local max_pct = t.getMaxPct(self, t)
		return ([[Weaving in and out of your enemies' battle lines, you take advantage of the confusion wrought in the fray. Dart in with a quick attack for %d%% damage, targeting your foe with your Spring Attack for %d turns. You gain a bonus to ranged damage against the foe for the duration. This bonus is dependent on the distance you gain after that attack: %d%% at 2 tiles, increasing to %d%% at 5 or more.

			Only distance gained from the moment of your attack will count.]]):
		format(dam_pct, dur, min_pct, max_pct)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 0.6, 1.1) end,
	getDur = function(self, t) return self:combatTalentScale(t, 4, 7) end,
	getMinPct = function(self, t) return self:combatTalentScale(t, 10, 22.5) end,
	getMaxPct = function(self, t) return self:combatTalentScale(t, 20, 35) end,
}