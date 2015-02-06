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
	name = "Rearing Assualt",
	type = {"mounted/teamwork", 1},
	points = 5,
	random_ego = "defensive",
	cooldown = 10,
	stamina = 15,
	require = mnt_wil_req1,
	requires_target = true,
	tactical = { ATTACK = 2 },
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	action = function(self, t)
		local mount = self:hasMount()	
		local mover = self:isMounted() and self or mount
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end

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
			if mover==self then
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
		return ([[Your mount rears up and attacks your target for %d%% damage, while moving into its space; your mount and your foe will exchange places. If you are mounted you follow up with a crushing strike or a focused shot with a %d increased critical modifier. You may also call upon your mount to use this while dismounted; this does not cost stamina.]]):
			format(dam, crit)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, .9, 1.7) end,
	getCrit = function(self, t) return self:combatTalentScale(t, 6, 25) end,
}

newTalent{
	short_name = "LET_EM_LOOSE",
	name = "Let 'Em Loose",
	type = {"mounted/teamwork", 2},
	require = mnt_wil_req2,
	points = 5,
	cooldown = function(self, t) return self:combatTalentLimit(t, 12, 25, 18) end,
	loyalty = 5,
	tactical = { ATTACK = 1, CLOSEIN = 1, DISABLE = { daze = 1 }  },
	range = function(self, t) return math.min(10, self:combatTalentScale(t, 5, 9)) end,
	requires_target = true,
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	action = function(self, t)
		local mount = self:hasMount()	
		local tg = {type="hit", range=self:getTalentRange(t), start_x=mount.x, start_y=mount.y}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
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
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam = t.getDam(self, t)*100
		local dur = t.getDur(self, t)
		return ([[Your mount performs a rushing attack on an enemy within %d squares, dealing %d%% damage and dazing it for %d turns. If you are mounted, then using Let 'Em Loose will forcibly dismount you.]]):
			format(range, dam, dur)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 4) end,

}