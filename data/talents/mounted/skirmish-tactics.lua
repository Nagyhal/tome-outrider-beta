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
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		local pet = self:getOutriderPet()
		if not pet or not target or not hitted or self:isMounted() then return end

		if core.fov.distance(pet.x, pet.y, target.x, target.y) == 1 then
			if rng.percent(t.getAttackChance(self, t)) then
				game.logSeen(
					self, 
					"#MOCCASIN##{bold}#%s sets up a free strike for %s!#{normal}##LAST#", 
					self.name:capitalize(), 
					pet.name)
				pet:attackTarget(target, nil, t.getAttackDam(self, t), true)
			end
		end
	end,
	passives = function(self, t, p)
		-- @todo : Figure out where I can neatly put the reload in this new class design
		-- self:talentTemporaryValue(p, 'ammo_mastery_reload', t.getReload(self, t))
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
	short_name = "OUTRIDER_MOUNTED_ARCHERY", image="talents/beast_archery.png",
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
				ignore_energy=true, ignore_cd=true, force_target=tgt, ignore_ressources=true, silent=true, speed=0.5
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
	callbackOnAct = function(self, t, p)
		t.checkTarget(self, t, p)
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

newTalent{
	name = "Spring Attack", short_name = "OUTRIDER_SPRING_ATTACK", image = "talents/spring_attack.png",
	type = {"mounted/skirmish-tactics", 2},
	require = techs_dex_req2,
	mode = "sustained",
	sustain_stamina = 40,
	points = 5,
	cooldown = 15,
	tactical = { BUFF = 2 },
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype, mult, dam, hd)
		local p = self:isTalentActive(t.id)

		if core.fov.distance(self.x, self.y, target.x, target.y) <= 1 then
			p.attacked_foes[target] = true
		end
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		if not moved or (ox==self.x and oy==self.y) then return end

		local p = self:isTalentActive(t.id)

		-- Doesn't work for forced movement; we must actively set up the Spring Attack!
		if force then p.attacked_foes={}; return end
		local adjacent_foes = getAdjacentActors(self, {only_enemies=true})

		if #table.keys(p.attacked_foes)>=1 and #adjacent_foes==0 then
			self:setEffect(self.EFF_OUTRIDER_SPRING_ATTACK, t.getDur(self, t), {
				min_pct = t.getMinPct(self, t),
				max_pct = t.getMaxPct(self, t),
				threshold = t.getThreshold(self, t),
				min_stamina = t.getMinStamina(self, t),
				max_stamina = t.getMaxStamina(self, t),
				target=target
			})
		end
		p.attacked_foes={}
	end,
	activate = function(self, t)
		return {attacked_foes = {}}
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local min_pct = t.getMinPct(self, t)
		local max_pct = t.getMaxPct(self, t)
		local threshold = t.getThreshold(self, t)
		local min_stamina = t.getMinStamina(self, t)
		local max_stamina = t.getMaxStamina(self, t)
		return ([[Weaving in and out of your enemies' battle lines, you take advantage of the confusion wrought in the fray. Whenever you move away from a foe you have attacked in melee, gain the Spring Attack effect for %d turns. Each tile of movement, so long as you don't start your new turn next to an enemy, increases the power of the effect by 1; each attack reduces it by 1.

			Attacks increase their crit chance from %d%% (1 point of Spring Attack) up to %d%% (at 10 points of Spring Attack). At %d points of Spring Attack or above, all your shots will be dual-target. Also, each turn you will regain Stamina depending on your distance from the nearest enemy: %.1f at 2 squares up to %.1f at 5 squares.

			Rushing in for the kill, you can make a final melee strike which removes your Spring Attack effect and has double your Spring Attack crit bonus.]]):
		format(dur, min_pct, max_pct, threshold, min_stamina, max_stamina)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 4, 7) end,
	getMinPct = function(self, t) return t.getMaxPct(self, t)/2 end,
	getMaxPct = function(self, t) return self:combatTalentScale(t, 8, 25.5) end,
	getThreshold = function(self, t) 
		local base = 11 - math.floor(self:getTalentLevel(t))
		return math.max(5, base)
	end,
	getMinStamina = function(self, t) return t.getMaxStamina(self, t)/2 end,
	getMaxStamina = function(self, t) return self:combatTalentScale(t, .5, 2.5) end,
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
	checkMount = function(self, t)
		-- I can't see why the mount would lose its paired effect, but my experience with
		-- ToME has taught me that it *will*
		local mount = self:getOutriderPet()

		if not mount:hasEffect(mount.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED) then
			mount:setEffect(mount.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED, 2, ret)
		end
	end,
	callbackOnActBase = function(self, t)
		t.checkMount(self, t)
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
	on_pre_use = function(self, t, silent, fake) return archerPreUse(self, t, silent, weapon_type) end,
	action = function(self, t)
		--We need to grab the target here first
		--archeryAcquireTargets, very confusingly, doesn't actually return a list of targets
		local tg = self:getTalentTarget(t)
		local targets = getArcheryTargetsWithSwap(self, tg)
		if not targets then return nil end

		local dam = t.getDam(self,t)
		local radius = self:getTalentRadius(t)

		self:archeryShoot(targets, t, {type = "hit", selffire=false}, {mult=dam})

		local dur = t.getDur(self, t)
		local power = t.getConfusePower(self, t)
		local phys_power = self:combatPhysicalpower()

		for _, target in ipairs(targets) do
			local a = game.level.map(target.x, target.y, engine.Map.ACTOR)
			a:setEffect(a.EFF_CONFUSED, dur, {{power=power}, apply_power=phys_power})

			if self:getTalentLevel(t) >= 3 and rng.percent(t.getSilenceChance(self, t)) then
				a:setEffect(a.EFF_SILENCED, dur, {apply_power=phys_power})
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
		return ([[Taking specially notched arrows from your quiver, you let loose a rain of horridly screeching missiles upon your foes. Your arrows rain down for 3 turns upon targets in a radius of %d, striking 3 per turn. Each target stands a chance to be confused by the cacophony (%d power, duration).

			At talent level 3 there is also a %d%% chance to inflict silence, as the screeching becomes loud enough to drown out the chants of spellcasters.]])
		:format(dam, rad, confuse_power, dur, silence_chance)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 0.87, 1.42) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 5) end,
	getConfusePower = function(self, t) return self:combatTalentLimit(t, 60, 27, 52) end,
	getSilenceChance = function(self, t) return math.max(50, self:combatTalentLimit(t, 90, 19, 54)) end,
}