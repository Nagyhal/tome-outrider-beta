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

-- newTalent{
-- 	name = "Barbarous Archery",
-- 	short_name = "OUTRIDER_MOUNTED_ARCHERY_MASTERY", image="talents/mounted_archery_mastery.png",
-- 	type = {"mounted/skirmish-tactics", 1},
-- 	points = 5,
-- 	require = { stat = { dex=function(level) return 12 + level * 6 end }, },
-- 	mode = "passive",
-- 	getDamage = function(self, t) return 30 end,
-- 	getPercentInc = function(self, t) return math.sqrt(self:getTalentLevel(t) / 5) / 1.5 end,
-- 	ammo_mastery_reload = function(self, t)
-- 		return math.floor(self:combatTalentScale(t, 0, 2.7, "log"))
-- 	end,
-- 	passives = function(self, t, p)
-- 		self:talentTemporaryValue(p, 'ammo_mastery_reload', t.ammo_mastery_reload(self, t))
-- 	end,
-- 	info = function(self, t)
-- 		local damage = t.getDamage(self, t)
-- 		local inc = t.getPercentInc(self, t)
-- 		local reloads = t.ammo_mastery_reload(self, t)
-- 		return ([[You are a master of brutal ranged harrying techniques, both mounted and on foot, increasing your weapon damage by %d%% and physical power by 30 when using bows.
-- 		Your reload rate is also increased by %d.]]):format(inc * 100, reloads)
-- 	end,
-- }

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
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon() then if not silent then game.logPlayer(self, "You require a bow or sling for this talent.") end return false end return true end,
	action = function(self, t)
		local targets = self:archeryAcquireTargets(nil, {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, nil, {mult=self:combatTalentWeaponDamage(t, 1.1, 2.2)})
		local target = targets[1]
		if not target then return true end
		if target:canBe("cut") then target:setEffect(mount.EFF_BLEED,  t.getDur(self, t), {power=t.getBleed(self, t)}) end
		local mount = self:hasMount()
		if not mount then return true end
		mount:setEffect(mount.EFF_OUTRIDER_BEASTMASTER_MARK,  t.getDur(self, t), {target=target})
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local bleed = t.getBleed(self, t)
		local dur = t.getDur(self, t)
		local speed = t.getSpeed(self, t)*100
		local loyalty = t.getLoyalty(self, t)
		-- local range = t.getRushRange(self, t)
		return ([[You let off a jagged missile that fills your steed with a savage thirst for blood, enraging it. You shoot your enemy for %d%% damage, bleeding it for %d damage and marking it with the Beastmaster's Mark for %d turns. While this is in effect, your steed concentrates solely upon this foe, moving and attacking %d%% faster, but if you hold it back it will lose %.1f Loyalty per turn that you do this.]]):
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

newTalent{
	name = "Spring Attack", short_name = "OUTRIDER_SPRING_ATTACK", image = "talents/spring_attack.png",
	type = {"mounted/skirmish-tactics", 2},
	mode = "passive",
	require = techs_dex_req3,
 	points = 5,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local min_pct = t.getMinPct(self, t)
		local max_pct = t.getMaxPct(self, t)
		return ([[After charging, for %d turns, the defense and movement speed components of your Strike at the Heart bonuses will persist.

			Also, you gain a bonus to ranged damage against the foe struck for the duration. This bonus is dependent on the distance you gain after that attack: %d%% at 2 tiles, increasing to %d%% at 5 or more.

			Only distance gained from the moment of your attack will count.]]):
		format(dur, min_pct, max_pct)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
	getMinPct = function(self, t) return self:combatTalentScale(t, 10, 22.5) end,
	getMaxPct = function(self, t) return self:combatTalentScale(t, 20, 35) end,
}

newTalent{
	name = "Loose in the Saddle", short_name = "LOOSE_IN_THE_SADDLE", image = "talents/loose_in_the_saddle.png",
	type = {"mounted/skirmish-tactics", 3},
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

--4: Cacophonous Downpour
--How should it work? Fire arrows against everyone, then over 2 turns repeat
newTalent{
	name = "Cacophonous Downpour", short_name = "OUTRIDER_CACOPHONOUS_DOWNPOUR", image = "talents/cacophonous_downpour.png",
	type = {"mounted/skirmish-tactics", 4},
	no_energy = "fake",
	points = 5,
	random_ego = "attack",
	cooldown = 8,
	stamina = 16,
	require = techs_dex_req4,
	range = archery_range,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 2, 3.7)) end,
	tactical = { ATTACKAREA = { weapon = 2 }, DISABLE = { confusion = 1, silence = 1 }},
	requires_target = true,
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), display=self:archeryDefaultProjectileVisual(weapon, ammo)}
	end,
	on_pre_use = function(self, t, silent) return archerPreUse(self, t, silent) end,
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
		return ([[Taking specially notched arrows from your quiver, you let loose a rain of horridly screeching missiles upon your foes. Your arrows deal %d%% ranged weapon damage in a radius of %d, but any target standing within the cacophony also has a chance to be confused (%d power).

			At talent level 3 there is also a %d%% chance to inflict silence, as the screeching becomes loud enough to drown out the chants of spellcasters.]])
		:format(dam, rad, confuse_power, silence_chance)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 0.87, 1.42) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 5) end,
	getConfusePower = function(self, t) return self:combatTalentLimit(t, 60, 27, 52) end,
	getSilenceChance = function(self, t) return math.max(50, self:combatTalentLimit(t, 90, 19, 54)) end,
}