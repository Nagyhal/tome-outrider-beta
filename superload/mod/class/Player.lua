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
	local can_rest, message = base_restCheck(self)

	if not (self.resting.rest_turns) then
		local mount = self:isMounted() and self:hasMount()
		if mount then
			-- Resting improves regen for our off-screen mount, too!
			-- Had to copy all this from the base routine.
			-- @todo Figure out how to use callbackOnRest to put things
			-- in the middle of resting routine
			local perc = 0
			if self.resting.cnt >= 15 then
				perc = math.min(self.resting.cnt, 16)
			end
			local old_shield = mount.arcane_shield
			mount.arcane_shield = nil
			mount:heal(mount.life_regen * perc)
			mount.arcane_shield = old_shield
			mount:incStamina(mount.stamina_regen * perc)
			mount:incMana(mount.mana_regen * perc)
			mount:incPsi(mount.psi_regen * perc)

			if not self.resting.rest_turns then
				if mount.air_regen < 0 then return false, "mount losing breath!" end
				if mount.life_regen <= 0 then return false, "mount losing health!" end
			end

			if mount.life < mount.max_life and mount.life_regen > 0 and not mount:attr("no_life_regen") then return true end
		end
	end
	return can_rest, message
end

return _M