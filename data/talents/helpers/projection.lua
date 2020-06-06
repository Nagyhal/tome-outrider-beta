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

local function check_dest() end

function projectLineBehind(self, tx, ty, dist)
	dx, dy = self.x - (tx - self.x), self.y - (ty - self.y) -- direction away from target
	-- game.log("#GREY# NPC %s Disengage from (%d, %d) towards (%d, %d) cone_angle=%s", self.name, tx, ty, dx, dy, cone_angle)
	local grids = {}
	self:project(tg2, dx, dy, function(px, py, typ, self)
		local act = game.level.map(px, py, Map.ACTOR)
		if not game.level.map:checkEntity(px, py, Map.TERRAIN, "block_move", self) and (not act or not self:canSee(act)) then
			grids[#grids+1] = {px, py, dist=core.fov.distance(px, py, self.x, self.y) + rng.float(0, 0.1)}
		end
	end)
	table.sort(grids, function(a, b) return a.dist > b.dist end)
	table.print(grids, "\tnpc_grids")
	dx, dy = nil, nil
	for i, grid in ipairs(grids) do
		local chk = check_dest(grid[1], grid[2])
		--print("\tchecking grid", grid[1], grid[2], chk)
		if check_dest(grid[1], grid[2]) then dx, dy = grid[1], grid[2] break end
	end
end

function getFreeGridsFromTarget(self, tg)
	local grids = {}
	self:project(tg2, dx, dy, function(px, py, typ, self)
		local act = game.level.map(px, py, Map.ACTOR)
		if not game.level.map:checkEntity(px, py, Map.TERRAIN, "block_move", self) and (not act or not self:canSee(act)) then
			grids[#grids+1] = {px, py, dist=core.fov.distance(px, py, self.x, self.y) + rng.float(0, 0.1)}
		end
	end)
	table.sort(grids, function(a, b) return a.dist > b.dist end)
	table.print(grids, "\tnpc_grids")
	dx, dy = nil, nil
	for i, grid in ipairs(grids) do
		local chk = check_dest(grid[1], grid[2])
		--print("\tchecking grid", grid[1], grid[2], chk)
		if check_dest(grid[1], grid[2]) then dx, dy = grid[1], grid[2] break end
	end
end