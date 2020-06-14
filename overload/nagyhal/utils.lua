function util.load_lua_dir(dir, do_func)
	for _, file in ipairs(fs.list(dir)) do
		local filepath = dir .. file
		if fs.isdir(filepath) then
			--Recurse through the tree!
			util.load_dir(dir, do_func)
		elseif string.find(filepath, ".lua-$") then
			do_func(filepath) end
	end
end

--- Finds free grids within a given area
-- This will return a random grid. If the coordinates for the region's "epicentre" are given, then it will try to find a square as close to that as possible
-- @param grids the grids in which to search, given as the usual nested tables
-- @param sx the epicenter coordinates
-- @param sy the epicenter coordinates
-- @param block true if we only consider line of sight
-- @param what a table which can have the fields Map.ACTOR, Map.OBJECT, ..., set to true. If so it will only return grids that are free of this kind of entities.
function util.findFreeGridsWithin(grids, sx, sy, block, what)
	if not grids then return nil, nil, {} end
	what = what or {}
	local grids = grids
	local gs = {}
	for x, yy in pairs(grids) do for y, _ in pairs(yy) do
		local ok = true
		if not game.level.map:isBound(x, y) then ok = false end
		for w, _ in pairs(what) do
--			print("findFreeGrid test", x, y, w, ":=>", game.level.map(x, y, w))
			if game.level.map(x, y, w) then ok = false end
		end
		if game.level.map:checkEntity(x, y, game.level.map.TERRAIN, "block_move") then ok = false end
--		print("findFreeGrid", x, y, "from", sx,sy,"=>", ok)
		if ok then
			local dist=1
			if sx and sy then dist = core.fov.distance(sx, sy, x, y) end
			gs[#gs+1] = {x, y, dist, rng.range(1, 1000)}
		end
	end end

	if #gs == 0 then return nil end

	table.sort(gs, function(a, b)
		if a[3] == b[3] then
			return  a[4] < b[4]
		else
			return a[3] < b[3]
		end
	end)

--	print("findFreeGrid using", gs[1][1], gs[1][2])
	return gs[1][1], gs[1][2], gs
end

util.hotkeySwap = function(self, original_tid, new_tid)
	if self.hotkey and self.isHotkeyBound then
		local pos = self:isHotkeyBound("talent", self[original_tid])
		if pos then
			self.hotkey[pos] = {"talent", self[new_tid]}
		end
	end
end