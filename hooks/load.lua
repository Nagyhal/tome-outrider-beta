local class = require"engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local ActorInventory = require "engine.interface.ActorInventory"
local ActorResource = require "engine.interface.ActorResource"
local ActorAI = require "engine.interface.ActorAI"
local DamageType = require "engine.DamageType"
local Chat = require "engine.Chat"

class:bindHook("ToME:load", function(self, data)
	dofile "nagyhal/utils.lua"

	ActorTalents:loadDefinition("/data-outrider/talents/outrider.lua")
	Birther:loadDefinition("/data-outrider/birth/mounted.lua")
	ActorResource:defineResource("Loyalty", "loyalty", ActorTalents.T_LOYALTY_POOL, "loyalty_regen", "Loyalty represents the devotion of your pet.", nil, nil, {
		color = "#f88072#",
		wait_on_rest = true,
	})
	--ActorInventory:defineInventory("MOUNT", "Mount", false, "Your mount.")
	ActorTemporaryEffects:loadDefinition("/data-outrider/timed_effects/timed_effects.lua")
	-- ActorTemporaryEffects:loadDefinition("/data-outrider/timed_effects/disobedience.lua")
	ActorInventory:defineInventory("MOUNT", "Ridden", true, "Trained characters may ride atop a mount", nil)
	DamageType:loadDefinition("data-outrider/damage_types.lua")
	ActorAI:loadDefinition("/data-outrider/ai/")
end)

class:bindHook("Entity:loadList", function(self, data)
	if data.file == "/data/general/objects/objects.lua" then
		self:loadList("/data-outrider/general/objects/hunting_horn.lua", data.no_default, data.res, data.mod, data.loaded)
	end
end)

class:bindHook("Actor:move", function(self, data)
	if self.mount then
		if not game.level.map(data.x, data.y, engine.Map.ACTOR) then
			self.mount:move(self.x, self.y, true)
			game.level.map(self.x, self.y, engine.Map.ACTOR, self)
		end
		-- game.level:removeEntity(self.mount)
		-- self.mount.x, self.mount.y = self.x, self.y
	end
	--This is the laziest way to code over (a hook that calls a callback, seriously?)
	--The reason I'm doing it this way is a) time and b) I am a more... shall we say
	--a more /architectural/.solution planned.
	--TODO: implement this solution
	local pet = self.outrider_pet
	if pet and pet:knowTalent(pet.T_OUTRIDER_PREDATORY_FLANKING) then
		pet:callTalent(pet.T_OUTRIDER_PREDATORY_FLANKING, "callbackOnMove")
	end
	local owner = self.owner
	if owner and owner:knowTalent(owner.T_OUTRIDER_FLANKING) then
		owner:callTalent(owner.T_OUTRIDER_FLANKING, "callbackOnMove")
	end
end)

class:bindHook("DamageProjector:base", function(self, data)
	local ret = nil
	--Does the source actually exist? (a useful check!)
	if not self.x then return ret end
	--Does the damage come from an actor?
	local a = game.level.map(self.x, self.y, engine.Map.ACTOR)
	if not a or a~=self then return ret end

	local target = game.level.map(data.x, data.y, engine.Map.ACTOR)

	local a = game.level.map(data.x, data.y, engine.Map.ACTOR)
	if self:knowTalent(self.T_OUTRIDER_TRAIT_OPPORTUNISTIC) then
		if a.life <= a.max_life*.25 then
			local p = self:getTalentFromId(self.T_OUTRIDER_TRAIT_OPPORTUNISTIC)
			local pct = p.getPct(self, t)
			data.dam = data.dam * pct/100
		end
	end

	if target then
		local eff = a:hasEffect(a.EFF_OUTRIDER_PREDATORY_FLANKING)
		if eff then
			if eff.src==self then
				data.dam = data.dam + (data.dam * eff.src_pct/100)
				ret=true
			elseif table.reverse(eff.allies)[self] then
				data.dam = data.dam + (data.dam * eff.allies_pct/100)
				ret=true
			end
		end
	end
	return ret
end)

class:bindHook("Actor:actBase:Effects", function(self, data)
	if self.life>=self.max_life*.95 and self.outrider_bloodied then
		--The 95% threshold is a kind of catch-all for any weird effects that prevent life reaching maximum
		self.outrider_bloodied = nil
	end
end)

class:bindHook("DamageProjector:final", function(self, data)
	--Does the source actually exist? (a useful check!)
	if not self.x then return nil end
	--Does the damage come from an actor?
	local a = game.level.map(self.x, self.y, engine.Map.ACTOR)
	if not a or a~=self then return nil end

	local target = game.level.map(data.x, data.y, engine.Map.ACTOR)

	if target and self.turn_procs and self.turn_procs.leviathan then
		local tt = self.turn_procs.leviathan
		if not tt.done then
			tt.stun_this_turn = rng.percent(tt.chance)
			tt.done = true
			tt.acts = {} --Only run once per turn per actor
		end
		if tt.stun_this_turn and not tt.acts[self] and self:canBe("stun") then
			local user = self
			if self:isMounted() then user = self.mount end
			user:logCombat(target, "#Source# stuns #target# with its leviathan prowess!")
			a:setEffect(a.EFF_STUNNED, tt.dur, {
				apply_power=user:combatPhysicalpower(),
				src=user
				}
			)
			tt.acts[self] = true
		end
	end

	if target then
		if target:knowTalent(target.T_OUTRIDER_UNCANNY_TENACITY) then
			if data.dam > self.max_life*.15 then
				if not target:isTalentCoolingDown(target.T_OUTRIDER_UNCANNY_TENACITY) then
					local res_pct= target:callTalent(target.T_OUTRIDER_UNCANNY_TENACITY, "getImmediateRes")
					local true_res =  data.dam*res_pct
					data.dam = data.dam - true_res
					game.logSeen(target, "#CRIMSON#%s overcomes %d of the damage!", target.name:capitalize(), true_res)
					target:callTalent(target.T_OUTRIDER_UNCANNY_TENACITY, "setEffect")
					target:startTalentCooldown(target.T_OUTRIDER_UNCANNY_TENACITY)
				end
			end
		end
	end

	return data
end)
class:bindHook("Actor:postUseTalent", function(self, data)
	local ab = data.t
	local trigger = data.trigger
	if ab.mode == "sustained" then
		if not self:isTalentActive(ab.id) then
			if ab.sustain_loyalty then
				trigger = true; self:incMaxLoyalty(-util.getval(ab.sustain_loyalty, self, ab))
			end
		elseif ab.sustain_loyalty then
			self:incMaxLoyalty(util.getval(ab.sustain_loyalty, self, ab))
		end
	elseif not self:attr("force_talent_ignore_ressources") and not ab.fake_ressource then
		if ab.loyalty and not self:attr("zero_resource_cost") then
			local fatigue_factor = self:isMounted() and self:combatFatigue()*2 or 0
			trigger = true; self:incLoyalty(-util.getval(ab.loyalty, self, ab) * (100 + fatigue_factor) / 100)
		end
	end
	--Regen Loyalty on inscription usage if applicable
	local owner = self.owner
	if owner and owner.loyalty and string.find(ab.type[1],  "inscriptions") then
		local name = string.sub(ab.id, 3)
		local inscription_data = self.__inscription_data_fake or self.inscriptions_data[name]
		if inscription_data.heal then
			--TODO: Decide whether this goes in
			-- owner:incLoyalty(5)
		end
	end
	data.ab, data.trigger = ab, trigger
end)

class:bindHook("Actor:getTalentFullDescription:ressources", function(self, data)
	local d, t = data.str, data.t
	if not config.ignore_ressources then
		local fatigue_factor = (t.requires_mounted or self:isMounted()) and self:combatFatigue() or 0
		-- if t.loyalty then d:add({"color",0x6f,0xff,0x83}, "Loyalty cost: ", {"color",0xff,0xe4,0xb5}, ""..math.round(util.getval(t.loyalty, self, t) * (100 + fatigue_factor) / 100, 0.1), true)
		-- end
		-- if t.sustain_loyalty then d:add({"color",0x6f,0xff,0x83}, "Sustain loyalty cost: ", {"color",0xFF, 0xFF, 0x00}, ""..(util.getval(t.sustain_loyalty, self, t)), true)
		-- end
	end
	data.d = d
end)

class:bindHook("Actor:takeHit", function(self, data)
	--Pet's owners lose loyalty when pet takes a hit.
	local owner = self.owner
	if owner and owner.loyalty then
		local coeff = self.loyalty_loss_coeff or 1
		local pct = data.value / self.max_life * 100
		local loyalty_loss = pct / 6
		-- game.log(("DEBUG: %s losing %.1f loyalty on hit."):format(owner.name:capitalize(), loyalty_loss))
		if self:hasEffect(self.EFF_OUTRIDER_UNBRIDLED_FEROCITY) then
			--Increase rather than decrease
			owner:incLoyalty(loyalty_loss)
		else
			owner:incLoyalty(-loyalty_loss * coeff)
		end
	end
	--Chance to dismount on hit.
	local eff = self:hasEffect(self.EFF_OUTRIDER_RIDDEN) or self:hasEffect(self.EFF_OUTRIDER_MOUNT)
	rider = (eff and eff.rider) or ((eff and eff.mount) and self)
	if rider and data.value / self.max_life > .1 then
		--Maybe do a getDismountChance() so Loyalty can be factored in?
		local pct = self:combatScale(data.value, 10, self.max_life*1, 50, self.max_life*.25)
		if rng.percent(25) then rider:dismount() end
	end
end)

-- class:bindHook("UISet:Classic:Resources", function(self, data)
-- 	local src = data.player.show_owner_loyalty_pool and data.player.summoner or data.player
-- 	if src:knowTalent(data.player.T_LOYALTY_POOL) then
-- 		self:mouseTooltip(self.TOOLTIP_LOYALTY, self:makeTextureBar("#SALMON#Loyalty:", nil, src:getLoyalty(), src.max_loyalty, src.loyalty_regen, data.x, data.h, 255, 255, 255,
-- 	 		{r=0xff / 3, g=0xcc / 3, b=0x80 / 3},
-- 	 		{r=0xff / 6, g=0xcc / 6, b=0x80 / 6}))
-- 		data.h = data.h + self.font_h
-- 	end
-- 	return data
-- end)

local function handleStrikeAtTheHeart(self, data)
	if self:hasEffect(self.EFF_OUTRIDER_STRIKE_AT_THE_HEART) then
		self:callTalent(self.T_OUTRIDER_STRIKE_AT_THE_HEART, "handleStrike", data.target, data.hitted)
	end
end

class:bindHook("Combat:attackTargetWith", function(self, data)
	handleStrikeAtTheHeart(self, data)
	return data
end)

class:bindHook("Combat:attackTarget", function(self, data)
	local target = data.target
	--TODO: Make this also functional for attackTargetWith!
	if self:isTalentActive(self.T_OUTRIDER_DIVE_BOMB) or self:isTalentActive("T_OUTRIDER_COMMAND_DIVE_BOMB") then
		if not self:attr("never_move") then self:flyOver(target.x, target.y, 5) end
		data.hit = false
		data.stop = true
	end
	if target:isTalentActive(target.T_OUTRIDER_DIVE_BOMB) or self:isTalentActive("T_OUTRIDER_COMMAND_DIVE_BOMB") then
		data.hit = false
		data.stop = true
	end

	handleStrikeAtTheHeart(self, data)
	return data
end)

class:bindHook("Actor:updateModdableTile:middle", function(self, data)
	local mount, add = self:getMount(), data.add
	if mount then
		-- local sort_table = function()
		add[#add+1] = {image = mount.image, mount=true}
	end
end)

class:bindHook("Actor:updateModdableTile:front", function(self, data)
	local mount, add = self:getMount(), data.add; if not mount then return end
	local mount_index

	for i, mo in ipairs(add) do
		if not mo.mount then mo.display_y = -.45 end

		if mo.mount then mount_index = i end
		if string.find(mo.image, "quiver") and mount_index then
			--Put it behind the mount
			add[i] = nil
			table.insert(add, mount_index, mo)
		end 
	end
end)

class:bindHook("Combat:archeryTargetKind", function(self, data)
	if self:knowTalent(self.T_OUTRIDER_CHALLENGE_THE_WILDS) then
        data.tg.friendlyfire=false
        data.tg.friendlyblock=false
    end
end)

class:bindHook("Combat:getDammod:subs", function(self, data)
	local owner = self.owner
	if owner and owner:knowTalent(owner.T_OUTRIDER_CHALLENGE_THE_WILDS) then
		local dammod = data.dammod
		dammod['cun'] = (dammod['cun'] or 0) + 0.6
	end
end)

class:bindHook("Combat:archeryTargetKind", function(self, data)
	local eff = self:hasEffect(self.EFF_OUTRIDER_SPRING_ATTACK)
	if eff and eff.ct >= eff.threshold then
		local params, tg = data.params, data.tg
		params.limit_shots = (params.limit_shots or 0) + 1
		tg.type, tg.radius = "ball", 1
	end
end)
