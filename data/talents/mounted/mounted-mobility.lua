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
local Chat = require "engine.Chat"

newTalent{
	name = "Overrun",
	type = {"mounted/mounted-mobility", 1},
	require = mount_str_req1,
	no_energy = "fake",
	points = 5,
	random_ego = "attack" ,
	loyalty = 15,
	cooldown = 15,
	requires_target = true,
	target = function(self, t) return {type="beam", range=self:getTalentRange(t), friendlyfire=false} end,
	range = function(self, t) return math.floor(self:getTalentLevel(t) + 2) end,
	getDamageMultiplier = function(self, t) return self:combatTalentScale(t, 1.5, 2.25) end,
	getMaxAttackCount = function(self, t) return 10 end,	
	tactical = { ATTACK = { weapon = 2 }, CLOSEIN = 3 },	
	action = function(self, t)
		-- if not self:IsMounted() then game.logPlayer(self, "You cannot use Overrun without riding a mount!") return nil end
		-- local tg = self.getTalentTarget(t)
		-- local x, y = self:getTarget(tg)
		-- if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then game.logSeen(self, "You can't move there.") return nil	end
		-- if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		-- local _ _, x, y = self:canProject(tg, x, y)
		-- self.mount:project(tg, x, y, DamageType.TEMPORALSTUN, dam)
		if not self:isMounted() then game.logPlayer(self, "You cannot use Overrun without riding a mount!") return nil end
		local tg = {type="beam", range=self:getTalentRange(t), nolock=true, talent =t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty then return nil end
		if core.fov.distance(self.x, self.y, tx, ty) > self:getTalentRange(t) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", target) end
		local lineFunction = core.fov.line(self.x, self.y, tx, ty, block_actor)
		local nextX, nextY, is_corner_blocked = lineFunction:step()
		local currentX, currentY = self.x, self.y

		local attackCount = 0
		local maxAttackCount = t.getMaxAttackCount(self, t)

		while nextX and nextY and not is_corner_blocked do
			-- local blockingTarget = game.level.map(nextX, nextY, Map.ACTOR)
			-- if blockingTarget and self:reactionToward(blockingTarget) < 0 then  --slaughter.lua code, may be useful for later status effect additions
				-- -- attempt a knockback
				-- local level = self:getTalentLevelRaw(t)
				-- local maxSize = 2
				-- if level >= 5 then
					-- maxSize = 4
				-- elseif level >= 3 then
					-- maxSize = 3
				-- end
				-- local blocked = true
				-- if blockingTarget.size_category <= maxSize then
					-- if blockingTarget:checkHit(self:combatPhysicalpower(), blockingTarget:combatPhysicalResist(), 0, 95, 15) and blockingTarget:canBe("knockback") then
						-- blockingTarget:crossTierEffect(blockingTarget.EFF_OFFBALANCE, self:combatPhysicalpower())
						-- -- determine where to move the target (any adjacent square that isn't next to the attacker)
						-- local start = rng.range(0, 8)
						-- for i = start, start + 8 do
							-- local x = nextX + (i % 3) - 1
							-- local y = nextY + math.floor((i % 9) / 3) - 1
							-- if core.fov.distance(currentY, currentX, x, y) > 1
									-- and game.level.map:isBound(x, y)
									-- and not game.level.map:checkAllEntities(x, y, "block_move", self) then
								-- blockingTarget:move(x, y, true)
								-- game.logSeen(self, "%s knocks back %s!", self.name:capitalize(), blockingTarget.name)
								-- blocked = false
								-- break
							-- end
						-- end
					-- end
				-- end
			
				-- if blocked then
					-- game.logSeen(self, "%s blocks %s!", blockingTarget.name:capitalize(), self.name)
				-- end
			-- end

			-- check that we can move
			-- if not game.level.map:isBound(nextX, nextY) or game.level.map:checkAllEntities(nextX, nextY, "block_move", self) then break end

			-- allow the move
			currentX, currentY = nextX, nextY
			nextX, nextY, is_corner_blocked = lineFunction:step()

			mount_target = game.level.map(currentX, currentY, Map.ACTOR)
			if mount_target then self.mount:attackTarget(mount_target, nil, t.getDamageMultiplier(self, t), true) end
			-- attack adjacent targets
			-- for i = 0, 8 do
				-- local x = currentX + (i % 3) - 1
				-- local y = currentY + math.floor((i % 9) / 3) - 1
				-- local target = game.level.map(x, y, Map.ACTOR)
				-- if target and self:reactionToward(target) < 0 and attackCount < maxAttackCount then
					-- local damageMultiplier = t.getDamageMultiplier(self, t)
					-- self:attackTarget(target, nil, damageMultiplier, true)
					-- attackCount = attackCount + 1

					-- game.level.map:particleEmitter(x, y, 1, "blood", {})
					-- game:playSoundNear(self, "actions/melee")s
				-- end
			-- end
		end

		self:move(currentX, currentY, true)

		return true
	end,
	info = function(self, t)
		return ([[Riding your mount, you charge to a vacant point up to %d squares away, trampling over enemies brutally as you do so, your mount dealing %d%% damage to all who those who dare obstruct you.]]):format(self:getTalentRange(t), t.getDamageMultiplier(self, t)*100) end,
}

-- Goad/ 25 LOY, cooldown 16
-- For 3+2*TL turns, your mount's movement speed is increased by 50 +TL*10 %. You may be riding or adjacent to your mount to achieve this effect.
newTalent{
	name = "Goad",
	type = {"mounted/mounted-mobility", 2},
	points = 5,
	random_ego = "utility",
	cooldown = function (self, t) return math.floor(20-2*self:getTalentLevel(t)) end,
	loyalty = 25,
	no_energy = true,
	require = mnt_str_req2,
	getGoadSpeed = function (self, t) return self:combatTalentScale(t, 0.2, 0.65, 0.85) end,
	tactical = { BUFF = 2, CLOSEIN = 2, ESCAPE = 2 },
	action = function(self, t)
		--TODO: Create hasMount method
		if not self:isMounted() then game.logPlayer(self, "You cannot use Goad without a mount!") return nil end
		local mount = self:getMount()
		if not self:isMounted() and math.floor(core.fov.distance(self.x, self.y, mount.x, mount.y)) > 1 then game.logPlayer(self, "You cannot Goad your mount from here.") return nil end
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
	-- getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	getPinDuration = function(self, t) return math.floor(3 + 0.5*self:getTalentLevel(t)) end, 
	range = function(self, t) return math.floor(2.5 + 0.7*self:getTalentLevel(t)) end,
	requires_target = true,
	action = function(self, t)
		local a = self:isMounted() and self or (self:hasMount() and self:getOutriderPet())

		local tg = {type="hit", range=self:getTalentRange(t), start_x=a.x, start_y=a.y}

		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		if core.fov.distance(a.x, a.y, x, y) > self:getTalentRange(t) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkAllEntities(bx, by, "block_move", a) end
		local l = a:lineFOV(x, y, block_actor)
		local lx, ly, is_corner_blocked = l:step()
		local tx, ty, _ = a.x, a.y
		local ox, oy = tx, ty
		while lx and ly do
			if is_corner_blocked or block_actor(_, lx, ly) then break end
			ox, oy = tx, ty
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = l:step()
		end
		-- Find space
		-- if block_actor(_, ox, oy) and (tx~=a.x and ty~=a.y) then return nil end
		if block_actor(_, tx, ty) then
			local fx, fy = util.findFreeGrid(lx, ly, 1, true, {[Map.ACTOR]=true})
			if not fx then
				return
			end
			a:move(fx, fy, true)
		else a:move(tx, ty, true) end
		local target = game.level.map(lx, ly, Map.ACTOR)
		if target then
			if core.fov.distance(a.x, a.y, tx, ty) > 1 then return true end
			self.has_mount:attackTarget(target, nil, t.getDamage(self, t), true)
			target:setEffect(target.EFF_PINNED, t.getPinDuration(self, t), {apply_power=self.has_mount:combatPhysicalpower(),  apply_save="combatPhysicalResist"})
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
	stamina = 30,
	getRange = function (self, t) return math.floor(3 + self:getTalentLevel(t)/2) end,
	range = function (self, t) return t.getRange(self, t) end,
	cooldown = function (self, t) return 13-self:getTalentLevelRaw(t) end,
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 0.8, 1.6)  end,
	tactical = { ESCAPE = 2, },
	action = function(self, t)
		if not self:HasMount() then
			game.logPlayer(self, "You cannot use mounted acrobatics without a mount.")
			return
		end
		local mount = self:getMount()
		if not self:IsMounted() then
			if math.floor(core.fov.distance(self.x, self.y, mount.x, mount.y)) > self:getRange(t) then
				game.logPlayer(self, "You are too far away from your mount.")
				return
			end
			--mount the character
		else  --do a Ghoulish Leap  (heh)
			local tg = {type="hit", range=self:getTalentRange(t)}
			local x, y, target = self:getTarget(tg)
			if not x or not y then return nil end
			if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end

			local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
			local l = self:lineFOV(x, y, block_actor)
			local lx, ly, is_corner_blocked = l:step()
			local tx, ty, _ = lx, ly
			while lx and ly do
				if is_corner_blocked or block_actor(_, lx, ly) then break end
				tx, ty = lx, ly
				lx, ly, is_corner_blocked = l:step()
			end

			-- Find space
			if block_actor(_, tx, ty) then return nil end
			local fx, fy = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
			if not fx then
				return
			end
			self:Dismount()  -- unsure
			self:move(fx, fy, true)
			return true
		end
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam = t.getDamage(self, t)*100
		return ([[When you dismount, you may leap a great distance, jumping an extra %d squares away. All enemies you pass through during this manoeuvre suffer a %d%% damage attack, if you are wielding a melee weapon; if you wield a ranged weapon, then you shoot one enemy nearest to you (but not adjacent) when you land for %d%% damage. In addition, you may mount from an extra %d squares away.]]
		):format(range, dam, dam, range)
	end,
}