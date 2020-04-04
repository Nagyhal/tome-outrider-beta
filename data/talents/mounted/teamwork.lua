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
	name = "Let 'Em Loose!", short_name = "OUTRIDER_LET_EM_LOOSE", image = "talents/let_em_loose.png",
	type = {"mounted/teamwork", 1},
	require = mnt_wilcun_req1,
	points = 5,
	-- cooldown = function(self, t) return math.max(12, self:combatTalentScale(t, 25, 14)) end,
	cooldown = 15,
	loyalty = 5,
	tactical = { ATTACK = 1, CLOSEIN = 1, DISABLE = { daze = 1 }  },
	range = function(self, t) return math.min(10, self:combatTalentScale(t, 5, 9)) end,
	requires_target = true,
	on_pre_use = function(self, t, silent)
		-- local mount = self:hasMount()
		-- if mount and mount:attr("never_move") then return false end
		-- return true
		return preCheckHasMountPresent(self, t, silent)
	end,
	action = function(self, t)
		local mount = self:hasMount()	
		local tg = {type="bolt", range=self:getTalentRange(t), start_x=mount.x, start_y=mount.y}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if self:reactionToward(target) >= 0 then return nil end
		if core.fov.distance(mount.x, mount.y, x, y) > self:getTalentRange(t) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", mount) end
		local linestep = mount:lineFOV(x, y, block_actor)

		local tx, ty, lx, ly, is_corner_blocked 
		repeat  -- make sure each tile is passable
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = linestep:step()
		until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
		if not tx or core.fov.distance(mount.x, mount.y, tx, ty) < 1 then
			game.logPlayer(self, "Your pet is too close to build up momentum!")
			return
		end
		if not tx or not ty or core.fov.distance(x, y, tx, ty) > 1 then return nil end

		local mounted, px, py = self:isMounted(), self.x, self.y
		if mounted then self:dismountTarget(mount); if self:isMounted() then return nil end end

		local first = true
		local ox, oy = mount.x, mount.y
		mount:move(tx, ty, true)
		if config.settings.tome.smooth_move > 0 then
			mount:resetMoveAnim()
			mount:setMoveAnim(ox, oy, 8, 5)
		end
		self:move(px, py, true)

		if core.fov.distance(mount.x, mount.y, x, y) > 1 then return true end
		if mount:attackTarget(target, nil, t.getDam(self, t), true) and target:canBe("stun") then
			target:setEffect(target.EFF_DAZED, t.getDur(self, t), {})
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
		return ([[Your mount performs a rushing attack on an enemy within %d squares, dealing %d%% damage and dazing it for %d turns. If you are mounted, then using Let 'Em Loose will forcibly dismount you.

			After using Let 'Em Loose, for %d turns your mount will be incensed, gaining a %d%% evasion chance and +%d to saves (scaling with your Willpower) as well as a %d%% bonus to damage (scaling with Cunning.)]]):
			format(range, dam, eff_dur, buff_dur, evade, res_buff, dam_buff)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	getDur = function(self, t) return self:combatTalentScale(t, 2.5, 4.2, .75) end,
	getBuffDur = function(self, t) return self:combatTalentScale(t, 3.5, 5.2, .75) end,
	-- getDefBuff = function(self, t) return self:combatTalentScale(t, 3, 20.5) end,
	getDefBuff = function(self, t) return self:combatTalentIntervalDamage(t, "wil", 5, 30, .65) end,
	-- getDefBuff = function(self, t) return self:combatTalentStatDamage(t, "wil", 1, 35) end,
	-- getDamBuff = function(self, t) return self:combatTalentScale(t, 3, 20.5) end,
	getDamBuff = function(self, t) return self:combatTalentIntervalDamage(t, "cun", 1, 35, .65) end,
	getEvade = function(self, t) return self:combatTalentIntervalDamage(t, "wil", 10, 40, .65) end,
}


newTalent{
	name = "Animal Affinity", short_name = "OUTRIDER_FERAL_AFFINITY", image="talents/feral_affinity.png",
	type = {"mounted/teamwork", 2},
	require = mnt_wilcun_req2,
	mode = "passive",
	points = 5,
	passives = function(self, t, p)
		local mount = self.outrider_pet
		if mount then
			for damtype, val in pairs(mount.resists) do
				self:talentTemporaryValue(p, "resists", {[damtype]=val*t.getResistPct(self, t)})
			end
		end
	end,
	shared_talent = "T_OUTRIDER_FERAL_AFFINITY_MOUNT",
	on_learn = function (self, t)
		local pet = self.outrider_pet
		if not pet then return end
		shareTalentWithPet(self, pet, t)
	end,
	on_unlearn = function(self, t)
		local pet = self.outrider_pet
		if not pet then return end
		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithPet(self, pet, t)
		end
	end,
	info = function(self, t)
		local res = t.getResistPct(self, t)
		local save = t.getSavePct(self, t)
		local max_dist = t.getMaxDist(self, t)
		return ([[You share %d%% of the resistances of your steed, while your steed partakes of some of your own defenses against mental attacks (%d%% of your mindpower, contributing to mental save, and up to %d%% of your confusion & fear resistance).

			Levelling Feral Affinity will increase the distance at which you can share your infusions with your mount; currently %d]]
			):format(res, save, res, max_dist)
	end,
	getSavePct = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getResistPct = function(self, t) return self:combatTalentScale(t, 25, 50) end,
	getMaxDist = function(self, t) return math.round(self:combatTalentScale(t, 2, 4.2, .85)) end,
}

newTalent{
	name = "Animal Affinity (Mount)", short_name = "OUTRIDER_FERAL_AFFINITY_MOUNT", image = "talents/feral_affinity.png",
	type = {"technique/other", 1},
	mode = "passive",
	points = 1,
	passives = function(self, t, p)
		--TODO: These need to be updated frequently
		local owner = self.summoner
		if owner then
			local save_pct = owner:callTalent(owner.T_OUTRIDER_FERAL_AFFINITY, "getSavePct")/100
			local resist_pct = owner:callTalent(owner.T_OUTRIDER_FERAL_AFFINITY, "getResistPct")/100
			local save = owner:combatMindpower()*save_pct
			self:talentTemporaryValue(p, "combat_mentalresist", save)
			local confusion = (owner:attr("confusion_immune") or 0) * resist_pct
			local fear = (owner:attr("fear_immune") or 0) * resist_pct
			local sleep = (owner:attr("sleep_immune") or 0) * resist_pct
			self:talentTemporaryValue(p, "confusion_immune", confusion)
			self:talentTemporaryValue(p, "fear_immune", fear)
			self:talentTemporaryValue(p, "sleep_immune", sleep)
		end
	end,
	info = function(self, t)
		local res = t.getResistPct(self, t)
		local save = t.getSavePct(self, t)
		local max_dist = t.getMaxDist(self, t)
		return ([[You share some of your rider's defenses against mental attacks (%d%% of mindpower, contributing to mental save, and up to %d%% of your confusion, sleep & fear resistance).

			Levelling Feral Affinity will increase the distance at which you can share your infusions with your mount; currently %d]]
			):format(res, save, res, max_dist)
	end,
	getSavePct = function(self, t) return self:combatTalentScale(t, 25, 50) end,
	getResistPct = function(self, t) return self:combatTalentScale(t, 35, 60) end,
	getMaxDist = function(self, t) return math.round(self:combatTalentScale(t, 1, 4.2, .85)) end,
}

newTalent{
	name = "Rearing Assault", short_name = "READING_ASSAULT", image = "talents/rearing_assault.png",
	type = {"mounted/teamwork", 3},
	points = 5,
	random_ego = "defensive",
	cooldown = 6,
	stamina = 6,
	loyalty= 3,
	require = mnt_wilcun_req3,
	requires_target = true,
	tactical = { ATTACK = 2 },
	on_pre_use = function(self, t, silent)
		if self:isMounted() then
			if self:attr("never_move") then return false end
		else
			local mount = self:hasMount()
			if mount and mount:attr("never_move") then return false end
		end
		return preCheckHasMountPresent(self, t, silent)
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
	name = "Flanking", short_name = "OUTRIDER_FLANKING", image = "talents/flanking.png",
	type = {"mounted/teamwork", 4},
	points = 5,
	require = mnt_wilcun_req4,
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