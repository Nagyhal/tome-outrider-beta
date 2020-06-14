local _M = loadPrevious(...)

base_onBirth = _M.onBirth
function _M:onBirth(birther)
	local ret = base_onBirth(self, birther)

	local engine_ActorAI = require'engine.interface.ActorAI'
	local tome_ActorAI = require'mod.class.interface.ActorAI'
	self.aiCanPass = engine_ActorAI.aiCanPass
	self.moveDirection = tome_ActorAI.moveDirection

	return ret
end

base_restCheck = _M.restCheck
function _M:restCheck()
	if not (self.resting.rest_turns) then
		local mount = self:hasMount()
		if mount then
			if mount.air_regen < 0 then return false, "mount losing breath!" end
			if mount.life_regen <= 0 then return false, "mount losing health!" end
		end
		if self:getLoyalty() < self:getMaxLoyalty() and self.loyalty_regen > 0 then return true end
	end
	return base_restCheck(self)
end

return _M