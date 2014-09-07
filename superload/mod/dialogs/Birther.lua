local _M = loadPrevious(...)

--require "engine.class"

--local base_makeDefault = _M.makeDefault
--- Make a default character when using cheat mode, for easier testing
function _M:makeDefault()
	self:setDescriptor("sex", "Female")
	self:setDescriptor("world", "Maj'Eyal")
	self:setDescriptor("difficulty", "Normal")
	self:setDescriptor("permadeath", "Roguelike")
	self:setDescriptor("race", "Human")
	self:setDescriptor("subrace", "Cornac")
	self:setDescriptor("class", "Mounted")
	self:setDescriptor("subclass", "Outrider")
	module_extra_info.no_birth_popup = true
	self:atEnd("created")
end

return _M