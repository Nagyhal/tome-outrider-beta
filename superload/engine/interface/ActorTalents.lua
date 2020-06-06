local _M = loadPrevious(...)

local base_callTalent = _M.callTalent
function _M:callTalent(tid, name, ...)
	-- game.log("DEBUG: trying to call talent tid: "..(tid or "nil").." and function name: "..(name or "nil"))
	return base_callTalent(self, tid, name, ...)
end
