local _M = loadPrevious(...)

function _M:hasEntity(e)
	if e._fake_level_entity then return e._fake_level_entity(self, "has") end
	-- if e.rider and self:hasEntity(e.rider) then return e end
	if e.rider then return e end
	return self.entities[e.uid]
end

base_removeEntity = _M.removeEntity
function _M:removeEntity(e)
	if not e._fake_level_entity and e.rider then
		return true
	end
	return base_removeEntity(self, e)
end

base_addEntity = _M.addEntity
function _M:addEntity(e)
	if not e._fake_level_entity and e.rider then
		return true
	end
	return base_addEntity(self, e)
end


return _M