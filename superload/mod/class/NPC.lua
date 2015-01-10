local _M = loadPrevious(...)

--Quick hack until I can fix FOV for multi-occupant squares
function _M:doFOV()
	-- If the actor has no special vision we can use the default cache
	local rider=self.rider
	if rider then
		self.fov = rider.fov
		self.fov_last_x = self.x
		self.fov_last_y = self.y
		self.fov_last_turn = game.turn
		self.fov_last_change = game.turn
		self.fov_computed = true
	else
		if not self.special_vision then
			self:computeFOV(self.sight or 10, "block_sight", nil, nil, nil, true)
		else
			self:computeFOV(self.sight or 10, "block_sight")
		end
	end
end

return _M