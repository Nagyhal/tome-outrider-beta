newTalent{
	name = "Loyalty Pool",
	type = {"base/class", 1},
	info = "Allows you to have a Loyalty pool. Loyalty is tied to another party member and allows you to command it.",
	mode = "passive",
	hide = "always",
	no_unlearn_last = true,
}

--newEntity{
--	define_as = "BASE_MOUNT",
--	slot = "MOUNT",
--	type = "mount",
--	display = "&", color=colors.SLATE,
--	encumber = 0,
--	desc = [[A mount]],
--}

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
			-- t_acr = self:getTalentFromId(self.T_MOUNTED_ACROBATICS)
			return 3 --t_acr.getMountRange()
		else return 1 end
	end,
	on_pre_use = function(self, t)
		if self:isMounted() or not self:getMountList() then
			return false
		else return true
		end
	end,
	action = function(self, t)
		local m_list = self:getMountList()
		local tg = nil
		-- if #m_list == 1 then
		-- 	tg = m_list[1]
		-- elseif #m_list > 1 then
		if m_list then
			--make this automatic if only 1 mount and adjacent
			target = {type="hit", range=self:getTalentRange(t), talent=t, first_target="friend", default_target=(#m_list==1 and m_list[1])or nil}
			_, _, tg = self:getTarget(target)
		end
		if not tg then game.logPlayer(self, "You have no mount!") return false end
		if not self:mountTarget(tg) then
			if tg:canMount(self) then 
				game.logPlayer(self, "Your mount cannot be mounted right now!")
			else
				game.logPlayer(self, "That is not your mount!")
				return false 
			end
		return true end
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
		if self:dismountTarget(m) then return true end
	end,
	info = function(self, t)
		return ([[Get down from your mount to a square within range %d]]):
		format (self:getTalentRange(t))
	end,
}