-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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
	name = "Let 'Em Have It!", short_name = "OUTRIDER_LET_EM_LOOSE", image = "talents/let_em_loose.png",
	type = {"mounted/teamwork", 1},
	require = mnt_wilcun_req1,
	points = 5,
	-- cooldown = function(self, t) return math.max(12, self:combatTalentScale(t, 25, 14)) end,
	cooldown = 15,
	loyalty = 5,
	tactical = { ATTACK = 1, CLOSEIN = 1, DISABLE = { stun = 1 }  },
	range = function(self, t) return math.min(10, self:combatTalentScale(t, 5, 9)) end,
	requires_target = true,
	on_pre_use = function(self, t, silent, fake)
		-- local mount = self:hasMount()
		-- if mount and mount:attr("never_move") then return false end
		-- return true
		return preCheckHasMountPresent(self, t, silent, fake)
	end,
	target = function(self, t)
		local mount = self:hasMount()
		return {
			type="bolt", range=self:getTalentRange(t),
			friendlyfire=false, friendlyblock=false,
			start_x=mount.x or self.x,
			start_y=mount.y or self.y
		}
	end,
	action = function(self, t)
		local mount = self:hasMount()	
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if self:reactionToward(target) >= 0 then return nil end

		if core.fov.distance(mount.x, mount.y, x, y) > self:getTalentRange(t) then return nil end

		local done = rushTargetTo(mount, x, y, {min_range=0, dismount=true, go_through_friends=true})
		if not done then return end

		if core.fov.distance(mount.x, mount.y, x, y) > 1 then return true end
		if mount:attackTarget(target, nil, t.getDam(self, t), true) and target:canBe("stun") then
			target:setEffect(target.EFF_STUNNED, t.getDur(self, t), {})
		end
		mount:setEffect(mount.EFF_OUTRIDER_SET_LOOSE, t.getBuffDur(self, t), {dam=t.getDamBuff(self, t), def=t.getDefBuff(self, t), evade=t.getEvade(self, t)})
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam = t.getDam(self, t)*100
		local eff_dur = t.getDur(self, t)
		local buff_dur = t.getBuffDur(self, t)
		local dam_buff = t.getDamBuff(self, t)
		local res_buff = t.getDefBuff(self, t)
		local evade = t.getEvade(self, t)
		return ([[Your mount performs a rushing attack on an enemy within %d squares, dealing %d%% damage and stunning it for %d turns. If you are mounted, then using Let 'Em Have It will forcibly dismount you.

			After using Let 'Em Have It, for %d turns your mount will be incensed, gaining a %d%% evasion chance and +%d to saves (scaling with your Willpower) as well as a %d%% bonus to damage (scaling with Cunning.)]]):
			format(range, dam, eff_dur, buff_dur, evade, res_buff, dam_buff)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	getDur = function(self, t) return self:combatTalentScale(t, 2.5, 4.2, .75) end,
	getBuffDur = function(self, t) return self:combatTalentScale(t, 3.5, 5.2, .75) end,
	getDefBuff = function(self, t) return self:combatTalentIntervalDamage(t, "wil", 5, 30, .65) end,
	getDamBuff = function(self, t) return self:combatTalentIntervalDamage(t, "cun", 1, 35, .65) end,
	getEvade = function(self, t) return self:combatTalentIntervalDamage(t, "wil", 10, 40, .65) end,
}

newTalent{
	name = "Predatory Flanking", short_name = "OUTRIDER_FLANKING", image = "talents/flanking.png",
	type = {"mounted/teamwork", 2},
	points = 5,
	require = mnt_wilcun_req2,
	mode = "passive",
	doCheck = function(self, t)
		local tgts = {}
		for _, c in pairs(util.adjacentCoords(self.x, self.y)) do
			local target = game.level.map(c[1], c[2], Map.ACTOR)
			if target and self:reactionToward(target) < 0 then tgts[#tgts+1] = target end
		end
		for _, target in ipairs(tgts) do
			local allies = {}
			for _, c in pairs(util.adjacentCoords(target.x, target.y)) do
				local target2 = game.level.map(c[1], c[2], Map.ACTOR)
				if target2 and self:reactionToward(target2) >= 0 and core.fov.distance(self.x, self.y, target2.x, target2.y)>1 then allies[#allies+1] = target2 end
				if #allies>=1 then
					target:setEffect(target.EFF_OUTRIDER_FLANKED, 2, {src=self, allies=allies, crit=t.getCritChance(self, t), crit_dam=t.getCritPower(self, t)})
				end --We run the check to see if we are no longer flanking from within the enemy's temp effect.
			end
		end
	end,
	callbackOnActBase = function(self, t)
		t.doCheck(self, t)
	end,
	callbackOnMove = function(self, t, ...)
		t.doCheck(self, t)
	end,
	info = function(self, t)
		local def = t.getDef(self, t)
		local crit = t.getCritChance(self, t)
		local crit_dam = t.getCritPower(self, t)
		return ([[If you and one of your allies both stand adjacent to the same enemy (but not adjacent to one another), then you both gain a bonus of %d%% to critical strike chance and %d%% to critical damage against that enemy. It will also suffer a %d penalty to defense.]]):
			format(crit, crit_dam, def)
	end,
	getDef = function(self, t) return self:combatTalentScale(t, 5, 12) end,
	getCritChance = function(self, t) return self:combatTalentScale(t, 5, 15) end,
	getCritPower = function(self, t) return self:combatTalentScale(t, 15, 35) end,
}

newTalent{
	name = "Rearing Assault", short_name = "READING_ASSAULT", image = "talents/rearing_assault.png",
	type = {"mounted/teamwork", 3},
	hide="always", --DEBUG: Hiding untested talents 
	points = 5,
	random_ego = "defensive",
	cooldown = 6,
	stamina = 6,
	loyalty= 3,
	require = mnt_wilcun_req3,
	requires_target = true,
	tactical = { ATTACK = 2 },
	on_pre_use = function(self, t, silent, fake)
		if self:isMounted() then
			if self:attr("never_move") then return false end
		else
			local mount = self:hasMount()
			if mount and mount:attr("never_move") then return false end
		end
		return preCheckHasMountPresent(self, t, silent, fake)
	end,
	target = function(self, t)
		local pet = self.outrider_pet
		local ret = {type="hit", range=self:getTalentRange(t), friendlyfire=false, selffire=false}
		if not self:isMounted() then
			ret = table.merge(ret, {start_x=pet.x, start_y=pet.y, default_target=pet, immediate_keys=false})
		end
		return ret
	end,
	action = function(self, t)
		local mount = self:hasMount()
		local mover = self:isMounted() and self or mount
		local tg = self:getTalentTarget(t)
		local x, y, target
		if mover==self then
			x, y, target = self:getTarget(tg)
		else
			game.target.target.x = mount.x
			game.target.target.y = mount.y
			x, y, target = autoPetTarget(self, mount)
			if not target then x, y, target = game:targetGetForPlayer(tg) end
		end
		if not x or not y or not target then return nil end
		if core.fov.distance(mount.x, mount.y, x, y) > 1 then return nil end

		local tx, ty, sx, sy = target.x, target.y, mount.x, mount.y
		local hitted = mount:attackTarget(target, nil, 0, true)
		if hitted and not mount.dead and tx == target.x and ty == target.y then
			if not mover:canMove(tx,ty,true) or not target:canMove(sx,sy,true) then
				mount:logCombat(target, "Terrain prevents #Source# from switching places with #Target#.")
				return true
			end
			mover:move(tx, ty, true)
			if not target.dead then
				target:move(sx, sy, true)
			end
			if core.fov.distance(self.x, self.y, target.x, target.y)==1 then
				local buff = t.getCrit(self, t)
				self.combat_physcrit = self.combat_physcrit+buff
				if self:hasArcheryWeapon() then
					tg = self:archeryAcquireTargets(tg, {x=target.x, y=target.y})
					self:archeryShoot(tg, t, nil, {})
				else
					self:attackTarget(target, nil, 1, true)
				end
				self.combat_physcrit = self.combat_physcrit-buff
			end
		end
		mover:resetMoveAnim()
		mover:setMoveAnim(sx, sy, 8, 5, 8, 3)
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local crit = t.getCrit(self, t)
		return ([[Your mount rears up and attacks your target for %d%% damage, while moving into its space; your mount and your foe will exchange places. If you are mounted, or adjacent to the target when the movement completes, then you follow up with a crushing strike or a focused shot with a %d%% increased critical modifier. You may also call upon your mount to use this while dismounted; this does not cost stamina.]]):
			format(dam, crit)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.8) end,
	getCrit = function(self, t) return self:combatTalentScale(t, 6, 25) end,
}

newTalent{
	name = "Strike at the Heart", short_name = "T_OUTRIDER_SMASH_DEFENSES", image = "talents/feral_affinity.png",
	type = {"mounted/teamwork", 4},
	hide="always", --DEBUG: Hiding untested talents 
	require = mnt_wilcun_req4,
	points = 5,
	cooldown = 10,
	stamina = 20,
	loyalty = 5,
	tactical = { ATTACK = {weapon = 2}, DISABLE = 3 },
	requires_target = true,
	range = function(self, t)
		if self:hasArcheryWeapon() then return util.getval(archery_range, self, t)
		else return 1 end
	end,
	is_melee = function(self, t) return not self:hasArcheryWeapon() end,
	target = function(self, t)
		if self:hasArcheryWeapon() then 
			local weapon, ammo = self:hasArcheryWeapon()
			return {
				type="bolt",
				range=self:getTalentRange(t),
				display=self:archeryDefaultProjectileVisual(weapon, ammo),
				talent = t
			}
		else return {type="hit", range=self:getTalentRange(t), talent=t}
		end
	end,
	speed = function(self, t) return self:hasArcheryWeapon() and "archery" or "weapon" end,
	on_pre_use = function(self, t, silent, fake) if self:attr("disarmed") then if not silent then game.logPlayer(self, "You require a weapon to use this talent.") end return false end return true end,
	archery_onhit = function(self, t, target, x, y)
		t.doSmash(self, t, target)
	end,
	doSmash = function(self, t, target)
			target:setEffect(target.EFF_OUTRIDER_SMASH_DEFENSES, t.getDuration(self, t), {apply_power=self:combatPhysicalpower(t)})
	end,
	--This is shamelessly copied from the Chronomancy "Breach" talent.
	action = function(self, t)
		local target
		local tg = self:getTalentTarget(t)
		--Player attacks.
		if self:hasArcheryWeapon() then
			local targets = self:archeryAcquireTargets(tg, {one_shot=true, no_energy = true})
			if not targets then return nil end

			target=targets[1]
			self:archeryShoot(targets, t, {type="bolt"}, {mult=t.getDamage(self, t)})
		else
			local tg = {type="hit", range=self:getTalentRange(t), talent=t}
			local _, x, y = self:canProject(tg, self:getTarget(tg))
			target = game.level.map(x, y, game.level.map.ACTOR)
			if not target then return nil end
			
			local hit = self:attackTarget(target, nil, t.getDam(self, t), true)

			if hit then
				t.doSmash(self, t, target)
			end
		end

		--Pet attacks!
		local mount = self:getOutriderPet()
		if not mount then return true end

		if doOutriderCharge(self, t, mount, t.getPetRange(self, t), target.x, target.y, false) then
			if core.fov.distance(mount.x, mount.y, target.x, target.y) > 1 then return true end
			--Not sure how to work out the second part of this ability
			if mount:attackTarget(target, nil, t.getDam(self, t), true) then
				-- target:setEffect(target.EFF_FOO, t.getDur(self, t), {})
			end
		end
		return true
	end,
	-- pet_target = function(self, t) return end
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local dur = t.getDur(self, t)
		local pet_range = t.getPetRange(self,t)
		local phys_pen= t.getPhysPen(self,t)
		return ([[Make a cruelly aimed attack against one target for %d%% damage. If it hits, its defenses are wrecked for %d turns, decreasing physical resistance by %d%%. It will lose one beneficial effect which is chosen at random.

		Your pet immediately closes in for the takedown - from a range of %d, it will move in to strike, for %d%% damage. On a hit, it completely breaches the target's armour, increasing its own physical penetration by %d%% for the duration.]]):
		format(dam, dur, phys_pen, pet_range, dam, phys_pen)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.7) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 7) end,
	getPetRange = function(self, t) return self:combatTalentScale(t, 3, 4.5) end,
	getPhysPen = function(self, t) return self:combatTalentLimit(t, 37.5, 15, 25) end,
}