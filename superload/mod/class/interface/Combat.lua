local _M = loadPrevious(...)

local Map = require "engine.Map"

local base_bumpInto = _M.bumpInto
local base_combatMovementSpeed = _M.combatMovementSpeed
local base_hasTwoHandedWeapon = _M.hasTwoHandedWeapon

function _M:bumpInto(target, x, y)
	if self:hasEffect(self.EFF_LIVING_SHIELDED) and target==self.tmp[self.EFF_LIVING_SHIELDED].trgt then
		local dx, dy = util.dirToCoord(util.getDir(target.x, target.y, self.x, self.y))
		game.logPlayer(game.player, "move enemy from "..x..", "..y.." to "..x+dx..", "..y+dy)
		local blocks = game.level.map:checkAllEntitiesLayersNoStop(x+dx, y+dy, "block_move", target)
			for kind, v in pairs(blocks) do if kind[1] and v then return end end
		local blocks = game.level.map:checkAllEntitiesLayersNoStop(x, y, "block_move", self)
			for kind, v in pairs(blocks) do if kind[1] ~= Map.ACTOR and v then return end end
		target:move(x+dx, y+dy, true)
		self:move(x, y, true)
		self:useEnergy(game.energy_to_act * self:combatMovementSpeed(x, y))
		self.did_energy = true
		return
	end
	base_bumpInto(self, target, x, y)
end

-- function _M:bumpInto(target, x, y)
-- 	if self:hasEffect(self.EFF_LIVING_SHIELDED) and target==self.tmp[self.EFF_LIVING_SHIELDED].trgt then
-- 		local tg = self.tmp[self.EFF_LIVING_SHIELDED].trgt
-- 		if not self.reaction_actor then self.reaction_actor = {} end
-- 		if not self.reaction_actor[tg] then self.reaction_actor[tg.name] = 0 end
-- 		self.reaction_actor[tg] = self.reaction_actor[tg.name] + 200
-- 		base_bumpInto(self, target, x, y)
-- 		self.reaction_actor[tg] = self.reaction_actor[tg.name] - 200
-- 		return
-- 	end
-- 	base_bumpInto(self, target, x, y)
-- end

function _M:combatMovementSpeed(x, y)
	local mount = self.mount
	if mount then return base_combatMovementSpeed(mount, x, y) / mount.global_speed
	else return base_combatMovementSpeed(self, x, y)
	end
end

function _M:hasTwoHandedWeapon()
	if self:knowTalent(self.T_ORCHESTRATOR_OF_DISMAY) then
		local weaponry = self:getInven("MAINHAND") or {}
		return weaponry[1]
	end
	return base_hasTwoHandedWeapon(self)
end

return _M