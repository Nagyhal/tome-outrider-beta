newTalent{
	name = "Loyalty Pool",
	type = {"base/class", 1},
	info = "Allows you to have a Loyalty pool. Loyalty is tied to another party member and allows you to command it.",
	mode = "passive",
	hide = "always",
	no_unlearn_last = true,
	-- callbackOnRest = function (self, t, type)
	-- 	if type=="check" then
 -- 			local mount = self:hasMount()
	-- 		if mount then
	-- 			if mount.air_regen < 0 then
	-- 				game.log(self.resting.past:capitalize().." for %d turns (stop reason: mount losing breath!).", self.resting.cnt, msg)
	-- 				return false
	-- 			end
	-- 				-- false, "mount losing breath!" end
	-- 			if mount.life_regen <= 0 then return false, "mount losing health!" end
	--  			if mount.life < mount.max_life and mount.life_regen>0 then return true end
	--  			local effs = mount:effectsFilter({status="detrimental"})
	--  			if #effs > 0 then return true end
	--  		end
 -- 			if self.loyalty < self.max_loyalty and self.loyalty_regen > 0 and not self:attr("no_loyalty_regen") then return true end
	-- 	end
	-- end,
}

newTalent{
	name = "Mount",
	type = {"mounted/mounted-base", 1},
	points = 1,
	message = false,
	no_break_stealth = true, -- stealth is broken in attackTarget
	requires_target = true,
	tactical = { BUFF = 2, DEFEND = 3 },
	no_unlearn_last = true,
	range = function(self, t)
		if self:knowTalent(self.T_MOUNTED_ACROBATICS) then
			return self:callTalent(self.T_MOUNTED_ACROBATICS, "range")
		else return 1 end
	end,
	on_pre_use = function(self, t)
		if self:isMounted() or not self:hasMount() then
			return false
		else return true
		end
	end,
	action = function(self, t)
		if not self:hasMount() then game.logPlayer(self, "You have no mount!") return nil end
		local m_list = self:getMountList()
		local tg = nil
		--TODO: I don't even know what this is about. Let's kill it
		--At least the message log output is half-sane now.
		if m_list then
			if #m_list == 1 then
				local m = m_list[1]
				if core.fov.distance(m.x, m.y, self.x, self.y) <= self:getTalentRange(t) then tg = m end
			else
				target = {type="hit", range=self:getTalentRange(t), talent=t, first_target="friend", default_target=(#m_list==1 and m_list[1])or nil}
				_, _, tg = self:getTarget(target)
			end
		end
		if not tg then
			return
			-- game.logPlayer(self, "Your mount cannot be mounted right now!") return nil
		elseif not self:mountTarget(tg) then
			if self:canMount(tg) then 
				game.logPlayer(self, "Your mount cannot be mounted right now!") return nil
			else
				if tg:hasEffect(tg.EFF_UNBRIDLED_FEROCITY) then
					game.logPlayer(self, "Your mount's ferocity prevents you from riding it!")
				else	
					game.logPlayer(self, "That cannot be mounted!") return nil 
				end
			end
		end
		return true
	end,
	info=function(self, t)
		return ([[Climb atop your mount.]])
	end,
}

newTalent{
	name = "Dismount",
	type = {"mounted/mounted-base", 1},
	points = 1,
	no_break_stealth = true, -- stealth is broken in attackTarget
	tactical = { CLOSEIN = 1, ESCAPE = 1 },
	target = function(self, t) 
		local display_default_target = function(self, d) return end
		local first_target
		local range = self:getTalentRange(t)
		if range == 1 then first_target=util.findFreeGrid(self.x, self.y, 1) end
		return {type="hit", range=range, first_target=first_target}
	end,
	no_unlearn_last = true,
	range = function(self, t)
		if self:knowTalent(self.T_MOUNTED_ACROBATICS) then
			-- t_acr = self:getTalentFromId(self.T_MOUNTED_ACROBATICS)
			return self:callTalent(self.T_MOUNTED_ACROBATICS, "range")
		else return 1 end
	end,
	on_pre_use = function(self, t, silent)
		return preCheckIsMounted(self, t, silent)
	end,
	action = function(self, t)
		local mount = self:getMount()
		local tg = self:getTalentTarget(t)
		if self:isTalentCoolingDown(self.T_MOUNTED_ACROBATICS) then tg.range=1 end
		local x, y, _ = self:getTarget(tg)
		if not x or not y then return nil end
		local ox, oy = self.x, self.y
		if game.level.map:checkAllEntities(x, y, "block_move") then game.logPlayer(self, "You can't dismount there!") return nil end
		if self:dismountTarget(mount, x, y) then
			if core.fov.distance(ox, oy, x, y) > 1 then
				self:callTalent(self.T_MOUNTED_ACROBATICS, "doAttack", ox, oy, x, y)
				self:startTalentCooldown(self.T_MOUNTED_ACROBATICS)
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[Get down from your mount to a square within range %d]]):
		format(self:getTalentRange(t))
	end,
}

newTalent{
	name = "Interact With Your Mount", short_name = "INTERACT_MOUNT",
	type = {"mounted/mounted-base", 1},
	points = 1,
	no_energy = true,
	no_npc_use = true,
	no_unlearn_last = true,
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	action = function(self, t)
		local Chat = require "engine.Chat"
		local mount = self:hasMount()
		local chat = Chat.new("outrider+interact-mount", mount, self, {mount=mount, player=self})
		chat:invoke()
		return true
	end,
	info = function(self, t)
		return ([[Interact with your mount to level its talents or change its name. You can also do that whenever you have direct control over your mount.]]):
			format()
	end,
}

newTalent{
	name = "Hunting Horn Buff",
	type = {"mounted/mounted-base", 1},
	points = 1,
	hide = "always",
	mode = "passive",
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_dam", 5)
		self:talentTemporaryValue(p, "combat_atk", 5)
	end,
	info = function(self, t)
		return ([[+5 physical power and +5 attack]]):
			format()
	end,
}