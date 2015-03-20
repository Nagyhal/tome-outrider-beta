local _M = loadPrevious(...)

function _M:hasEntity(e)
	if e._fake_level_entity then return e._fake_level_entity(self, "has") end
	-- if e.rider and self:hasEntity(e.rider) then return e end
	if e.rider then return e end
	return self.entities[e.uid]
end

return _M