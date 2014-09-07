local _M = loadPrevious(...)

local base_bumpInto = _M.bumpInto

local Map = require "engine.Map"

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
-- 		game.logPlayer(game.player, "DEBUG: bump hijinx, reactio is..."..self:reactionToward(tg, no_relfection))
-- 		base_bumpInto(self, target, x, y)
-- 		self.reaction_actor[tg] = self.reaction_actor[tg.name] - 200
-- 		return
-- 	end
-- 	base_bumpInto(self, target, x, y)
-- end


return _M