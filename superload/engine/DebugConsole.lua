local _M = loadPrevious(...)

local commands = {
	"me = game.player",
	"pet = game.player.outrider_pet",
	"target; for i, a in ipairs(me.fov.actors_dist) do if me:reactionToward(target)<0 then target = a break end end"
}

local base_display = _M.display
function _M:display()
	for _, line in ipairs(commands) do
		--Essentially, use the standard console code from pressing Enter
		table.insert(_M.commands, line)
		_M.com_sel = #_M.commands + 1
		table.insert(_M.history, line)

		local f, err = loadstring(line)
		if err then
			table.insert(_M.history, err)
		else
			local res = {pcall(f)}
			for i, v in ipairs(res) do
				if i > 1 then
					table.insert(_M.history, "    "..(i-1).." :=: "..tostring(v))
					-- Handle printing a table
					if type(v) == "table" then
						local array = {}
						for k, vv in table.orderedPairs(v) do
							array[#array+1] = tostring(k).." :=: "..tostring(vv)
						end
						self:historyColumns(array, 8)
					end
				end
			end
		end
		_M.line = ""
		_M.line_pos = 0
		_M.offset = 0
		self.changed = true
	end
	return base_display()
end

--I can't make this work at all, not one simple superload. I wonder why?
local base_scrollUp = _M.scrollUp
function _M:scrollUp(i)
	game.log 'test'
	return base_scrollUp(i)
end