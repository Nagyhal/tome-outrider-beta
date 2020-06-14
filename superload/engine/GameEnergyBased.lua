local _M = loadPrevious(...)

-- local base_tickLevel = _M.tickLevel

-- function _M:tickLevel(level)
-- 	base_tickLevel(self, level)

-- 	local i, e = 1, nil
-- 	local arr = level.e_array

-- 	for i = i, #arr do
-- 		e = arr[i].mount or nil
-- 		if e and e.act and e.energy then
-- 			if e.actBase and e.energyBase then
-- 				if e.energyBase < self.energy_to_act then
-- 					e.energyBase = e.energyBase + self.energy_per_tick
-- 				end
-- 				if e.energyBase >= self.energy_to_act then
-- 					e:mountActBase(self)
-- 				end
-- 			end

-- --			print("<ENERGY", e.name, e.uid, "::", e.energy.value, self.paused, "::", e.player)
-- 			if e.energy.value < self.energy_to_act then
-- 				e.energy.value = (e.energy.value or 0) + self.energy_per_tick * (e.energy.mod or 1) * (e.global_speed or 1)
-- 			end
-- 			if e.energy.value >= self.energy_to_act then
-- 				e.energy.used = false
-- 				e:mountAct(self)
-- 			end
-- --			print(">ENERGY", e.name, e.uid, "::", e.energy.value, self.paused, "::", e.player)
-- 		end
-- 	end
-- end

function _M:tickLevel(level)
	local i, e = 1, nil
	local arr = level.e_array

	if level.last_iteration then
		i = nil

		for ii = 1, #arr do if arr[ii] == level.last_iteration.e then i = ii + 1 break end end

		if not i then i = level.last_iteration.i + 1 end

		if i > #arr then i = 1 end
		level.last_iteration = nil
--		print("=====LEVEL", level.level, level.sublevel_id, "resuming tick loop at ", i, arr[i].name)
	end

	for i = i, #arr do
		e = arr[i]
		if e and e.act and e.energy then
			for _, e in pairs(e.mount and {e, e.mount} or {e}) do
				if e.actBase and e.energyBase then
					if e.energyBase < self.energy_to_act then
						e.energyBase = e.energyBase + self.energy_per_tick
					end
					if e.energyBase >= self.energy_to_act then
						if e.rider and e.mountActBase then e:mountActBase(self) else e:actBase(self) end
					end
				end

	--			print("<ENERGY", e.name, e.uid, "::", e.energy.value, self.paused, "::", e.player)
				if e.energy.value < self.energy_to_act then
					e.energy.value = (e.energy.value or 0) + self.energy_per_tick * (e.energy.mod or 1) * (e.global_speed or 1)
				end
				if e.energy.value >= self.energy_to_act then
					e.energy.used = false
					if e.rider and e.mountAct then e:mountAct(self) else e:act(self) end
				end
	--			print(">ENERGY", e.name, e.uid, "::", e.energy.value, self.paused, "::", e.player)
			end
		end

		if self.can_pause and self.paused then
			level.last_iteration = {i=i, e=e}
--				print("====LEVEL", level.level, level.sublevel_id, "pausing tick loop at ", i, e.name)
			break
		end
	end
end

return _M