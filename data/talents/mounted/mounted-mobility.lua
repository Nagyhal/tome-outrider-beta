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
	name = "Overrun",
	type = {"mounted/mounted-mobility", 1},
	require = mnt_str_req1,
	points = 5,
	loyalty = 15,
	cooldown = 15,
	requires_target = true,
	target = function(self, t) return {type="beam", range=self:getTalentRange(t), friendlyfire=false} end,
	range = function(self, t) return math.floor(self:getTalentLevel(t) + 2) end,
	getDamageMultiplier = function(self, t) return self:combatTalentScale(t, 1.5, 2.25) end,
	getMaxAttackCount = function(self, t) return 10 end,	
	tactical = { ATTACK = { weapon = 2 }, CLOSEIN = 3 },
	on_pre_use = function(self, t, silent)
		return preCheckIsMounted(self, t, silent)
	end,
	action = function(self, t)
		local tg = {type="beam", range=self:getTalentRange(t), nolock=true, talent =t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty or game.level.map(tx, ty, engine.Map.ACTOR) then return nil end
		if core.fov.distance(self.x, self.y, tx, ty) > self:getTalentRange(t) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", target) end
		local lineFunction = core.fov.line(self.x, self.y, tx, ty, block_actor)
		local nextX, nextY, is_corner_blocked = lineFunction:step()
		local currentX, currentY = self.x, self.y

		local attackCount = 0
		local maxAttackCount = t.getMaxAttackCount(self, t)

		while nextX and nextY and not is_corner_blocked do
			currentX, currentY = nextX, nextY
			nextX, nextY, is_corner_blocked = lineFunction:step()

			mount_target = game.level.map(currentX, currentY, Map.ACTOR)
			if mount_target then self.mount:attackTarget(mount_target, nil, t.getDamageMultiplier(self, t), true)
			end
		end

		self:move(currentX, currentY, true)

		return true
	end,
	info = function(self, t)
		return ([[Riding your mount, you charge to a vacant point up to %d squares away, trampling over enemies brutally as you do so, your mount dealing %d%% damage to all who those who dare obstruct you.]]):format(self:getTalentRange(t), t.getDamageMultiplier(self, t)*100) end,
}

newTalent{
	name = "Goad",
	type = {"mounted/mounted-mobility", 2},
	points = 5,
	cooldown = function (self, t) return math.floor(20-2*self:getTalentLevel(t)) end,
	loyalty = 25,
	no_energy = true,
	require = mnt_str_req2,
	getGoadSpeed = function (self, t) return self:combatTalentScale(t, 0.2, 0.65, 0.85) end,
	tactical = { BUFF = 2, CLOSEIN = 2, ESCAPE = 2 },
	on_pre_use = function(self, t, silent)
		local ret = preCheckHasMountInRange(self, t, silent, 1)
		return ret
	end,
	action = function(self, t)
		self.mount:setEffect(self.EFF_SPEED, 5, {power=t.getGoadSpeed(self, t)})
		return true
	end,
	info = function(self, t)
		return ([[For 5 turns, your mount's global speed is increased by %d%%. You may be riding or adjacent to your mount to activate this effect]]):format(t.getGoadSpeed(self, t)*100)
	end,
}

newTalent{
	name = "Savage Bound",
	type = {"mounted/mounted-mobility", 3},
	require = mnt_str_req3,
	points = 5,
	cooldown = 8,
	loyalty = 15,
	tactical = { CLOSEIN = 3, DISABLE = { pin = 2 }  },
	direct_hit = true,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.9, 1.4) end,
	getDamageMultiplier = function(self, t) return self:combatTalentScale(t, 1.25, 1.75) end,
	getPinDuration = function(self, t) return math.floor(3 + 0.5*self:getTalentLevel(t)) end, 
	range = function(self, t) return math.floor(2.5 + 0.7*self:getTalentLevel(t)) end,
	requires_target = true,
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	action = function(self, t)
		--TODO: Make rider also follow when the mount is moved
		local mount = self:hasMount()	
		local mover = self:isMounted() and self or mount
		local tg = {type="hit", range=self:getTalentRange(t), start_x=mount.x, start_y=mount.y, friendlyfire=false, selffire=false}
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end

		local ox, oy = self.x, self.y
		if target then
			local fx, fy = util.findFreeGrid(x, y, 1, true, {[engine.Map.ACTOR]=true})
			if not fx then
				return nil
			end
			mover:move(fx, fy, true)
		else 
			local feat = game.level.map(x, y, engine.Map.TERRAIN); if feat and feat:check(block_move) then return nil end
			mover:move(x, y, true)
		end
		self:resetMoveAnim()
		self:setMoveAnim(ox, oy, 8, 5, 8, 3)
		if target then
			if core.fov.distance(mount.x, mount.y, x, y) > 1 then return true end
			local hit = mount:attackTarget(target, nil, t.getDamage(self, t), true)
			if hit and target:canBe("pin")then
				target:setEffect(target.EFF_PINNED, t.getPinDuration(self, t), {apply_power=mount:combatPhysicalpower(),  apply_save="combatPhysicalResist"})
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[Your mount bounds into the air, landing up to %d squares away. If an enemy is in this square, your mount pounces upon it, dealing %d%% damage while landing in the square in front of it and pinning it for %d turns.]]):format(self:getTalentRange(t), t.getDamageMultiplier(self,t)*100, t.getPinDuration(self, t))
	end,
}

newTalent{
	name = "Mounted Acrobatics",
	type = {"mounted/mounted-mobility", 4},
	require = mnt_str_req4,
	points = 5,
	mode = "passive",
	range = function (self, t) return math.floor(3 + self:getTalentLevel(t)/2) end,
	cooldown = function (self, t) return 13-self:getTalentLevelRaw(t) end,
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 0.8, 1.6)  end,
	doAttack = function(self, t, ox, oy, x, y)
		local main = self:getInven"MAINHAND"; if main then main=main[1] else return end
		if main.archery then
			if not self:hasArcheryWeapon() then return end -- This checks for ammo & disarming among other things.
			local range = archery_range(self, t)
			--Get actors in a ball around user; we only want targets we can shoot at, hence the block function.
			local actors_list = {}
			local block = function(_, lx, ly) return game.level.map:checkAllEntities(lx, ly, "block_move") end
			local tg = {type="ball", block_radius=block, radius=range, talent=t}
			self:project(tg, x, y, function(px, py)
				local a = game.level.map(px, py, Map.ACTOR)
				if a and  a ~= self and self:reactionToward(a) < 0 then actors_list[a] = true end
			end)

			local actors = table.keys(actors_list)
			for i = 1, 2 do
				local a = rng.tableRemove(actors); if not a then break end
				local tg = {friendlyfire=false, friendlyblock=false, no_energy=true}
				tg = self:archeryAcquireTargets(tg, {x=a.x, y=a.y})
				self:archeryShoot(tg, t, nil, {mult=t.getDamage(self, t)})
			end
		elseif main.combat then
			if not self:hasWeaponType() then return end -- This only  checks for disarming, really
			local tg = {type="beam", start_x=ox, start_y=oy, talent=t}
			local actors_list = {}
			self:project(tg, x, y, function(px, py)
				local a = game.level.map(px, py, Map.ACTOR)
				if a and a ~= self and self:reactionToward(a) < 0 then actors_list[#actors_list+1] = a end
			end)
			for _ , a in ipairs(actors_list) do
				self:attackTarget(a, nil, t.getDamage(self, t), true)
			end
		end
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam = t.getDamage(self, t)*100
		return ([[When you mount or dismount, you may leap a great distance, jumping an extra %d squares away. All enemies you pass through during this manoeuvre suffer a %d%% damage attack, if you are wielding a melee weapon; if you wield a ranged weapon, then when you land you shoot up to two enemies within range for %d%% damage.]]
		):format(range, dam, dam, range)
	end,
}