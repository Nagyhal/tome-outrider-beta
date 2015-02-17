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
	name = "Charge",
	type = {"mounted/shock-tactics", 1},
	message = "@Source@ charges!",
	require = techs_strdex_req1,
	points = 5,
	random_ego = "attack",
	stamina = function(self, t) return 20 end,
	loyalty = function(self, t) return 10 end,
	cooldown = function(self, t) return math.ceil(self:combatTalentLimit(t, 0, 36, 20)) end, --Limit to >0
	tactical = { ATTACK = { weapon = 1, stun = 1 }, CLOSEIN = 3 },
	requires_target = true,
	is_melee = true,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	range = function(self, t) return math.floor(self:combatTalentScale(t, 6, 10)) end,
	on_pre_use = function(self, t)
		if self:attr("never_move") then return false
		else return preCheckIsMounted(self, t, silent) end
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local linestep = self:lineFOV(x, y, block_actor)

		local tx, ty, lx, ly, is_corner_blocked
		repeat  -- make sure each tile is passable
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = linestep:step()
		until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
		if not tx or core.fov.distance(self.x, self.y, tx, ty) < 1 then
			game.logPlayer(self, "You are too close to build up momentum!")
			return
		end
		if not tx or not ty or core.fov.distance(x, y, tx, ty) > 1 then return nil end

		local ox, oy = self.x, self.y
		self:move(tx, ty, true)
		--Required for knockback function
		local recursive = function(target)
			if self:checkHit(self:combatPhysicalpower(), target:combatPhysicalResist(), 0, 95) and target:canBe("knockback") then 
				return true
			else
				game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
			end
		end
		--Get permissible knockback directions
		local poss_coords = {}
		for _, coord in ipairs(util.adjacentCoorsds(target.x, target.y)) do
			local cx, cy = coord[1], coord[2]
			if not game.level.map:checkEntity(cx, cy, engine.Map.TERRAIN, "block_move", target) then
				poss_coords[#poss_coords+1] = coord
			end
		end
		-- Attack ?
		if self:attackTarget(target, nil, 1.2, true) and target:canBe("stun") then
			--First, the stun component
			local tg = {type="ball", x, y, radius=dam.radius, friendlyfire=dam.friendlyfire}
			local stun_dur = t.getStunDur(self, t)
			self:project(tg, self.x, self.y, function(px, py, tg, self)
				local a = game.level.map(px, py, Map.ACTOR)
				if self:reactionToward(a) < 0 and a:canBe("stun") then
					a:setEffect(a.EFF_STUNNED, stun_dur, {apply_power=self:combatPhysicalpower(), src=self}) 
				end
			end)
			--Next, the knockback component
			local coord = rng.table(poss_coords)
			if coord and target:canBe("knockback") then
				if coord.x==self.x and coord.y==self.y then
					self:move(target.x, target.y, true)
					target:move(tx, ty, true)
				else
					local otx, oty = target.x, target.y
					target:knockback(self.x, self.y, 1, recursive)
					if target.x ~= otx and target.y ~= oty then
						self:move(otx, oty, true)
					end
				end
			end
		end

		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(ox, oy, 8, 5)
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local stun_dur = t.getStunDur(self, t)
		local radius = self:getTalentRadius(t)
		return ([[Mounted, you perform a devastating charge against an enemy within range, striking it for %d%% damage. A successful hit will stun it and any other enemies near you for %d turns. You will also attempt to move into the target's square, pushing it back one square in a random direction.]]):
		format(dam, stun_dur, radius)
	end,
	getStunDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.15, 1.3) end,
}
