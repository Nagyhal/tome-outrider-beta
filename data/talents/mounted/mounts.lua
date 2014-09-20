newTalent{
	name = "Loyalty Pool",
	type = {"base/class", 1},
	info = "Allows you to have a Loyalty pool. Loyalty is tied to another party member and allows you to command it.",
	mode = "passive",
	hide = "always",
	no_unlearn_last = true,
}


newTalent{
	name = "Mount",
	type = {"mounted/mounted-base", 1},
	no_energy = "fake",
	points = 1,
	message = false,
	no_break_stealth = true, -- stealth is broken in attackTarget
	requires_target = true,
	tactical = { BUFF = 2, DEFEND = 3 },
	no_unlearn_last = true,
	range = function(self, t)
		if self:knowTalent(self.T_MOUNTED_ACROBATICS) then
			local range = self:callTalent(self.T_MOUNTED_ACROBATICS, "getMountRange")
			return range
		else return 1 end
	end,
	on_pre_use = function(self, t)
		if self:isMounted() or not self:getMountList() then
			return false
		else return true
		end
	end,
	action = function(self, t)
		if not self:hasMount() then game.logPlayer(self, "You have no mount!") return nil end
		local m_list = self:getMountList()
		local tg = nil
		if m_list then
			if #m_list == 1 then
				local m = m_list[1]
				if  core.fov.distance(m.x, m.y, self.x, self.y) <= self:getTalentRange(t) then tg = m end
			else
				target = {type="hit", range=self:getTalentRange(t), talent=t, first_target="friend", default_target=(#m_list==1 and m_list[1])or nil}
				_, _, tg = self:getTarget(target)
			end
		end
		if not tg then 
			game.logPlayer(self, "Your mount cannot be mounted right now!") return nil
		elseif not self:mountTarget(tg) then
			if self:canMount(tg) then 
				game.logPlayer(self, "Your mount cannot be mounted right now!") return nil
			else
				game.logPlayer(self, "That cannot be mounted!") return nil 
			end
		else return true
		end
	end,
	info = function(self, t)
		return ([[Climb atop your mount]])
	end,
}

newTalent{
	name = "Dismount",
	type = {"mounted/mounted-base", 1},
	no_energy = "fake",
	points = 1,
	message = false,
	no_break_stealth = true, -- stealth is broken in attackTarget
	requires_target = true,
	tactical = { CLOSEIN = 1, ESCAPE = 1 },
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	no_unlearn_last = true,
	range = function(self, t)
		if self:knowTalent(self.T_MOUNTED_ACROBATICS) then
			-- t_acr = self:getTalentFromId(self.T_MOUNTED_ACROBATICS)
			return 3 --t_acr.getMountRange()
		else return 1 end
	end,
	on_pre_use = function(self, t)
		if not self:isMounted() then
			return false
		else return true
		end
	end,
	action = function(self, t)
		m = self:getMount()
		local tg = self:getTalentTarget(t)
		local x, y, _ = self:getTarget(tg)
		if game.level.map:checkAllEntities(x, y, "block_move") then game.logPlayer(self, "You can't dismount there!") return nil end
		if self:dismountTarget(m, x, y) then return true end
	end,
	info = function(self, t)
		return ([[Get down from your mount to a square within range %d]]):
		format (self:getTalentRange(t))
	end,
}