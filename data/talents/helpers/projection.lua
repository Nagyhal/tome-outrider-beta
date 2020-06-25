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

local Talents = require("engine.interface.ActorTalents")
setfenv(1, Talents.main_env)

--- Check if the user of a given talent is behind a given target
-- The pattern we need to see is this, on a straight line:
-- (px, py) ---> self ---> target
-- @param self   The user
-- @param target The user's target
-- @param px     Target square x
-- @param py     Target square y
-- @return check Does the line from (px, py) pass through "self"?
function checkUserIsBehindTarget(self, target, px, py)
	local block_check = function(_, bx, by)
		return game.level.map:checkEntity(bx, by, engine.Map.TERRAIN, "block_move", self)
	end

	linestep = self:lineFOV(px, py, block_check, nil, target.x, target.y)

	local check = false
	local lx, ly, is_corner_blocked
	repeat
		lx, ly, is_corner_blocked = linestep:step()
		if self.x == lx and self.y == ly then check = true break end
	until is_corner_blocked or not lx or not ly or game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, "block_move", self)
	return check
end

--- Set up a complicated target table that uses checkUserIsBehindTarget
function getTargetForProjectLineBehind(self, target, t, dist)
	local tg2 = {type="beam", source_actor=self, selffire=false, range=dist, talent=t, no_start_scan=true, no_move_tooltip=true}

	tg2.display_line_step = function(game_target, d) 
		local t_range = core.fov.distance(
			game_target.target_type.start_x,
			game_target.target_type.start_y,
			d.lx,
			d.ly)
		if t_range >= 1 and t_range <= tg2.range and not d.block and checkUserIsBehindTarget(self, target, d.lx, d.ly) then
			d.s = game_target.sb
		else
			d.s = game_target.sr
		end
		d.display_highlight(d.s, d.lx, d.ly)
	end

	return tg2
end

--- Project a line dist squares behind self from target
-- What we want to see is something like:
-- target ---> self ---(dist)---> tx, ty
-- @param t       talent
-- @param dist    Maximum distance
-- @return tx, ty Furthest grids possible for targeter
function projectLineBehind(self, target, t, dist)
	local grids = {}

	local tg2 = getTargetForProjectLineBehind(self, target, t, dist)

	-- Project a line and get the initial coordinates we want to try
	local try_x, try_y = lx, ly

	local l = target:lineFOV(self.x, self.y)
	local lx, ly, is_corner_blocked = l:step(true)
	l:set_corner_block()
	local pass_self = false

	while lx and ly and not is_corner_blocked and core.fov.distance(self.x, self.y, lx, ly) <= dist do
		local actor = game.level.map(lx, ly, engine.Map.ACTOR)
		if actor == self then
			pass_self = true
		elseif pass_self and game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, "block_move") then
			break
		end
		try_x, try_y = lx, ly
		lx, ly = l:step(true)
	end

	if not try_x then return end

	-- Now project to our tested coords
	self:project(tg2, try_x, try_y, function(px, py, typ, self)
		local act = game.level.map(px, py, engine.Map.ACTOR)
		if not game.level.map:checkEntity(px, py, engine.Map.TERRAIN, "block_move", self) and (not act or not self:canSee(act)) then
			grids[#grids+1] = {px, py, dist=core.fov.distance(px, py, self.x, self.y) + rng.float(0, 0.1)}
		end
	end)

	for _, grid in ipairs(grids) do
	end

	table.sort(grids, function(a, b) return a.dist > b.dist end)
	table.print(grids, "\tnpc_grids")

	tx, ty = nil, nil
	for i, grid in ipairs(grids) do
		if checkUserIsBehindTarget(self, target, grid[1], grid[2]) then
			tx, ty = grid[1], grid[2]
			break
		end
	end
	return tx, ty
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