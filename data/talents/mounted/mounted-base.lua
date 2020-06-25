newTalent{
	name = "Loyalty Pool",
	type = {"base/class", 1},
	info = "Allows you to have a Loyalty pool. Loyalty is tied to another party member and allows you to command it.",
	mode = "passive",
	hide = "always",
	callbackOnRest = function(self, t, type)
		--Try to speed up the resting here.
		local perc = 0
		if self.resting.cnt >= 15 then
			perc = math.min(self.resting.cnt, 16)
		end
		self:incLoyalty(self.loyalty_regen * perc)
	end,
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
	name = "Mount", short_name = "OUTRIDER_MOUNT", image = "talents/mount.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	cooldown = 0,
	message = false,
	no_break_stealth = true, -- stealth is broken in attackTarget
	requires_target = true,
	no_unlearn_last = true,
	tactical = { BUFF = 2, DEFEND = 3 },
	range = function(self, t)
		if self:knowTalent(self.T_OUTRIDER_MOUNTED_ACROBATICS) then
			return self:callTalent(self.T_OUTRIDER_MOUNTED_ACROBATICS, "range")
		else return 1 end
	end,
	on_pre_use = function(self, t, silent, fake)
		return preCheckHasMount(self, t, silent, fake) and 
			preCheckIsNotMounted(self, t, silent, fake) and
			preCheckHasMountInRange(self, t, silent, fake, self:getTalentRange(t))
	end,
	action = function(self, t)
		if not self:hasMount() then game.logPlayer(self, "You have no mount!") return nil end
		local tg = nil
		-- local m_list = self:getMountList()
		--TODO: I don't even know what this is about. Let's kill it
		--At least the message log output is half-sane now.
		-- if m_list then
		local m = self:getOutriderPet()
		if m and core.fov.distance(m.x, m.y, self.x, self.y) <= self:getTalentRange(t) then tg = m
		else
			-- target = {type="hit", range=self:getTalentRange(t), talent=t, first_target="friend", default_target=(#m_list==1 and m_list[1])or nil}
			-- _, _, tg = self:getTarget(target)
		end
		-- end
		if not tg then
			return
			-- game.logPlayer(self, "Your mount cannot be mounted right now!") return nil
		elseif not self:mountTarget(tg) then
			if self:canMount(tg) then 
				game.logPlayer(self, "Your mount cannot be mounted right now!") return nil
			else
				if tg:hasEffect(tg.EFF_OUTRIDER_UNBRIDLED_FEROCITY) then
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
	name = "Dismount", short_name = "OUTRIDER_DISMOUNT", image = "talents/dismount.png",
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
		if self:knowTalent(self.T_OUTRIDER_MOUNTED_ACROBATICS) then
			-- t_acr = self:getTalentFromId(self.T_OUTRIDER_MOUNTED_ACROBATICS)
			return self:callTalent(self.T_OUTRIDER_MOUNTED_ACROBATICS, "range")
		else return 1 end
	end,
	on_pre_use = function(self, t, silent, fake)
		return preCheckIsMounted(self, t, silent, fake)
	end,
	action = function(self, t)
		local mount = self:getMount()
		local tg = self:getTalentTarget(t); if self:isTalentCoolingDown(self.T_OUTRIDER_MOUNTED_ACROBATICS) then tg.range=1 end
		local x, y, _ = self:getTarget(tg)
		if not x or not y then return nil end

		local ox, oy = self.x, self.y
		if game.level.map:checkAllEntities(x, y, "block_move") then game.logPlayer(self, "You can't dismount there!") return nil end
		if self:dismount(x, y) then
			if core.fov.distance(ox, oy, x, y) > 1 then
				self:callTalent(self.T_OUTRIDER_MOUNTED_ACROBATICS, "doAttack", ox, oy, x, y)
				self:startTalentCooldown(self.T_OUTRIDER_MOUNTED_ACROBATICS)
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
	name = "Interact With Your Mount", short_name = "OUTRIDER_INTERACT_MOUNT", image = "talents/interact_mount.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	no_energy = true,
	no_npc_use = true,
	no_unlearn_last = true,
	on_pre_use = function(self, t, silent, fake)
		return preCheckHasMountPresent(self, t, silent, fake)
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
	name = "Hunting Horn Buff", short_name = "OUTRIDER_HUNTING_HORN_BUFF", image = "talents/hunting_horn_buff.png",
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

newTalent{
	name = "Hunting Horn Blast", short_name = "OUTRIDER_HUNTING_HORN_BLAST", image = "talents/hunting_horn_buff.png",
	type = {"mounted/mounted-base", 1},
	points = 5,
	cooldown = 22,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false}
	end,
	requires_target = true,
	tactical = { ATTACKAREA = { DISABLE = 1 } },
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		local proj_function = function(px, py, tg, self)
			local target = game.level.map(px, py, engine.Map.ACTOR)
			if target and self:reactionToward(target)<0 then
				local power = t.getPower(self, t)
				if target.type == "animal" then power = t.getPowerVsBeasts(self, t) end
				target:setEffect(target.EFF_INTIMIDATED,
					t.getDur(self, t),
					{power=power})
			end
		end
		self:project(tg, x, y, proj_function, nil)

		game.level.map:particleEmitter(self.x, self.y, self:getTalentRadius(t), "directional_shout", {life=8, size=2, tx=x-self.x, ty=y-self.y, distorion_factor=0.1, radius=self:getTalentRadius(t), nb_circles=8, rm=0.8, rM=1, gm=0.8, gM=1, bm=0.1, bM=0.2, am=0.6, aM=0.8})
		return true
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(t)
		local dur = t.getDur(self, t)
		local power = t.getPower(self, t)
		local power_vs_beasts = t.getPowerVsBeasts(self, t)
		return ([[Trumpet your hunting horn, sowing fear and apprehension among your foes. Causes intimidation in a radius %d cone, reducing enemy physical, spell- and mindpower by %d for %d turns. The hunting horn is specialized for hunting animals, and thus the effect is increased by 75%% (current: %d) against them.]])
		:format(radius, power, dur, power_vs_beasts)
	end,
	getDur = function(self,t) return self:combatTalentScale(t, 4, 6) end,
	getPower = function(self,t) return self:combatTalentScale(t, 6, 20) end,
	getPowerVsBeasts = function(self,t) return t.getPower(self, t)*1.75 end,
}