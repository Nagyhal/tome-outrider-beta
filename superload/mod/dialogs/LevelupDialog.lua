local _M = loadPrevious(...)

local base_generateList = _M.generateList

function _M:generateList()
	base_generateList(self)

	for _, group in ipairs{self.ctree, self.gtree} do
		for i, node in ipairs(group) do
			local tt = engine.interface.ActorTalents:getTalentTypeFrom(node.type)
			if tt.sort then tt.sort(self, node) end
		end
	end
end

return _M