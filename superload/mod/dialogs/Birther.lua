local _M = loadPrevious(...)

--require "engine.class"

--- Make a default character when using cheat mode, for easier testing
local base_makeDefault = _M.makeDefault
function _M:makeDefault()
	--I think this only works under cheat mode anyway, but we'll check in case of changes
	if config.settings.cheat then
		self:setDescriptor("sex", "Female")
		self:setDescriptor("world", "Maj'Eyal")
		self:setDescriptor("difficulty", "Normal")
		self:setDescriptor("permadeath", "Roguelike")
		self:setDescriptor("race", "Human")
		self:setDescriptor("subrace", "Cornac")
		self:setDescriptor("class", "Mounted")
		self:setDescriptor("subclass", "Outrider")
		-- module_extra_info.no_birth_popup = true
		self:atEnd("created")
	else
		return base_makeDefault()
	end
end

return _M