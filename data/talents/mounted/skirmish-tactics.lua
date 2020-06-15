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

local archerPreUse = Talents.main_env.archerPreUse
local use_stamina = Talents.main_env.use_stamina
local archery_range = Talents.main_env.archery_range


newTalent{
	name = "Beast Archery", 
	short_name = "OUTRIDER_MOUNTED_ARCHERY_MASTERY", image="talents/beast_archery.png",
	type = {"mounted/skirmish-tactics", 1},
	points = 5,
	require = techs_dex_req1,
	mode = "passive",
	on_learn = function(self, t)
		if not self:knowTalent(self.T_OUTRIDER_MOUNTED_ARCHERY) then self:learnTalent(self.T_OUTRIDER_MOUNTED_ARCHERY, true) end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 and self:knowTalent(self.T_OUTRIDER_MOUNTED_ARCHERY) then self:unlearnTalentFull(self.T_OUTRIDER_MOUNTED_ARCHERY) end
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'ammo_mastery_reload', t.getReload(self, t))
	end,
	getChance = function(self,t) 
		local chance = 15
		return chance
	end,
	info = function(self, t)
		local inc = t.getInc(self, t)
		local reload = t.getReload(self,t)

		local attack_chance = t.getAttackChance(self,t)
		local attack_dam_pct = t.getAttackDam(self, t)*100

		local stamina = t.getStamina(self,t)

		--You are a master of brutal ranged harrying techniques, both mounted and on foot, increasing your weapon damage by %d%% and physical power by 30 when using bows.

		return ([[Whether you were a child of the wild steppes, or you came of age beneath the starry skies of the great Northern wastes, you were born to rain fury with your bow from atop your bestial steed. 

			Increases physical power by 30 when using bows or slings, and also increase your ranged damage while riding by %d%%.

			In addition, learn the Beast Archery mounted combat manoeuvre (current stamina per shot: %.1f). Also, when dismounted, shots will have a %d%% chance to let your beast make an extra attack against your target (80%% damage).]]):

			-- You learn the Beast Archery combat manoeuvre : When riding, you can sustain to loose arrows upon your target as you move. Each turn, if you move or rest with a bow equipped, you stand tall and let soar an arrow at your hapless target, just as if you had used the Shoot talent. This costs %.1f stamina per shot and will deactivate if you move out of range, dismount or use another weapon to attack.]]):
		format(inc*100, stamina, attack_chance)
	end,
	getInc = function(self, t) return self:combatTalentScale(t, .085, .21) end,
	getReload = function(self, t)
		return math.floor(self:combatTalentScale(t, 0, 2.7, "log"))
	end,
	getAttackChance = function(self, t)
		local tl = self:getTalentLevel(t)
		if tl <= 6.5 then
			return self:combatTalentScale(t, 8.5, 21, .45)
		else
			return self:combatLimit(tl, 35, 25, 6.5, 28, 10)
		end
	end,
	getAttackDam = function(self, t) return self:combatTalentScale(t, 0.62, 0.88) end,
	getStamina = function(self, t) return self:combatTalentLimit(t, 2.25, 10.9, 4.1) end,
}

newTalent{
	name = "Beast Archery",
	short_name = "OUTRIDER_MOUNTED_ARCHERY", image="talents/mounted_archery.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	mode = "sustained",
	deactivate_on = {no_combat=true, rest=true},
	tactical = { BUFF = 1 },
	cooldown = 5,
	no_energy = true,
	remove_on_zero = true,
	requires_target = true,
	target = function(self, t)
		local tg = self:getTalentTarget(self:getTalentFromId(self.T_SHOOT))
		tg.friendlyfire=false
		tg.selffire=false
		tg.friendlyblock=false
	end,
	on_pre_use = function(self, t, silent, fake) 
		return preCheckIsMounted(self, t, silent, fake) and preCheckArcheryInAnySlot(self, t, silent, fake)
	end,
	----Helper functions---------------------------------------
	doShot = function(self, t)
		local tgt = self:isTalentActive(t.id)["target"]

		local did_shot
		if self:hasArcheryWeapon() then
			did_shot = self:forceUseTalent(self.T_SHOOT, {
				ignore_energy=true, ignore_cd=true, force_target=tgt, ignore_ressources=true, silent=true
			})
		end
		if did_shot and not use_stamina(self, t.getStamina(self, t)) then
			local spend = math.min(t.getStamina(self, t), self:getStamina())
			self:incStamina(-spend) --Never free!
			t.forceDisactivate(self, t)
			return
		end

		local p = self:isTalentActive(t.id); p.dont_shoot = nil
	end,
	checkTarget = function(self, t)
		local target = table.get(self:isTalentActive(t.id), "target")
		if not target or target.dead or not game.level:hasEntity(target) then
			t.forceDisactivate(self, t)
		elseif not self:canProject(self:getTalentTarget(t), target.x, target.y) then
			t.forceDisactivate(self, t)
		else return true end
	end,
	checkCanShoot = function(self, t)
		if not self:hasArcheryWeapon() then 
			t.forceDisactivate(self, t)
			return nil
		end
		if not table.get(self:isTalentActive(t.id), "dont_shoot") then return true end
	end,
	dontShootThisTurn = function(self, t)
		local p = self:isTalentActive(t.id); p["dont_shoot"] = true
	end,
	forceDisactivate = function(self, t)
		--This is a function, because it might need to be expanded
		--upon at some point.
		self:forceUseTalent(t.id, {ignore_energy=true})
	end,
	----Callbacks----------------------------------------------
	-----------------------------------------------------------
	--We shoot once per turn on ActBase.
	--If we attack, though - don't shoot.
	--If we use any talent, except for an instant talent, then
	--  we don't shoot.
	--If we dismount, then we can't use Mounted Archery any more.
	--Likewise, if we remove our archery weapon, we can't use
	--  Mounted Archery any more.
	callbackOnActBase = function(self, t)
		if t.checkTarget(self, t) and t.checkCanShoot(self, t) then
			t.doShot(self, t)
		end
	end,
	callbackOnCombatAttack = function(self, t, weapon, ammo)
		t.dontShootThisTurn(self, t)
	end,
	callbackOnPostTalent = function(self, t, ab, ret, silent)
		if not ab.no_energy then t.dontShootThisTurn(self, t) end
	end,
	callbackOnQuickSwitchWeapons = function(self, t)
		if not self:hasArcheryWeapon() then
			t.forceDisactivate(self, t)
		end
	end,
	callbackOnDismount = function(self, t) t.forceDisactivate(self, t) end,
	-----------------------------------------------------------
	activate = function(self, t)
		local done_swap = swapToArchery(self)
		if not self:hasArcheryWeapon() then
			game.logPlayer(self, "You can't swap to your ranged weapon to use this talent!")
			return nil
		end

		local tg = {type = "bolt", range = archery_range(self),	talent = t}
		local x, y, target = self:getTarget(tg)
		if not target then
			if done_swap then self:quickSwitchWeapons(true, nil, true) end
			return nil
		end

		local mount = self:getMount()
		game.logSeen(self, "%s looses arrows at %s from atop %s!", self.name:capitalize(), target.name, mount.name)
		return {target=target, ct=5}
	end,
	deactivate = function(self, t, p) 
		return true
	end,
	info = function(self, t)
		return ([[]]):
		format(t.getStamina(self, t))
	end,
	getStamina = function(self, t)
		return self:callTalent(self.T_OUTRIDER_MOUNTED_ARCHERY_MASTERY, "getStamina")
	end,
	info = function(self, t)
		local stamina = t.getStamina(self,t)
		-- local damage = t.getDamage(self, t)
		-- local dur = t.getDur(self,t)
		-- local cooldown = t.getCooldown(self,t)

		--You are a master of brutal ranged harrying techniques, both mounted and on foot, increasing your weapon damage by %d%% and physical power by 30 when using bows.
		return ([[When riding, you can sustain to loose arrows at your target as you move. Each turn, if you move or rest with a bow equipped, you stand tall and let soar an arrow at your hapless target, just as if you had used the Shoot talent. This costs %.1f stamina per shot and will deactivate if you move out of range, dismount or use another weapon to attack.]]):
		format(stamina)
	end,
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