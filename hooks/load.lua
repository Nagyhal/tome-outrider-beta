local class = require"engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local ActorInventory = require "engine.interface.ActorInventory"
local ActorResource = require "engine.interface.ActorResource"
local ActorAI = require "engine.interface.ActorAI"
local DamageType = require "engine.DamageType"
local Chat = require "engine.Chat"
local Colors = require "engine.colors"

class:bindHook("ToME:load", function(self, data)
	dofile "nagyhal/utils.lua"

	ActorTalents:loadDefinition("/data-outrider/talents/outrider.lua")
	Birther:loadDefinition("/data-outrider/birth/mounted.lua")
	ActorResource:defineResource(
		"Loyalty", "loyalty", ActorTalents.T_LOYALTY_POOL, "loyalty_regen",
		"Loyalty represents the devotion of your pet.", 
		nil, nil, {
			color = "#f88072#",
			wait_on_rest = true,
			cost_factor = function(self, t, check) 
				return not self:isMounted() and 1 or (100 + self:combatFatigue()*2) / 100
			end,
			--@todo Describe how disobedience will work in the final iteration
			-- status_text = function(act)
			-- end,
		})
	--ActorInventory:defineInventory("MOUNT", "Mount", false, "Your mount.")
	ActorTemporaryEffects:loadDefinition("/data-outrider/timed_effects/timed_effects.lua")
	-- ActorTemporaryEffects:loadDefinition("/data-outrider/timed_effects/disobedience.lua")
	ActorInventory:defineInventory("MOUNT", "Ridden", true, "Trained characters may ride atop a mount", nil)
	DamageType:loadDefinition("data-outrider/damage_types.lua")
	ActorAI:loadDefinition("/data-outrider/ai/")
	defineColor("OUTRIDER_GREEN", 0x00, 0xD9, 0x00)

	--Here's a very pretty and beautiful hack to make weapon swapping work on bump attack.
	local t = ActorTalents.talents_def.T_ATTACK
	local main_env = ActorTalents.main_env
	old_action = t.action
	t.action = function(self, t)
		main_env.swapToMelee(self)
		return old_action(self, t)
	end

	-- Here comes the hackiest of hacks!
	-- I want the Giblets talent to have a variable talent icon; if you gib lungs, show a
	-- pair of lungs, an eye - show a gory eye - and so on. But there's no way to assign
	-- a function to the image value, it must remain a static string describing the talent
	-- icon's location

	-- The less hacky way would be to define several talents and assign each of them its
	-- own icon, foolproof for sure.

	-- I'll probably change this implementation later - for example, it doesn't work nicely
	-- if the player has the Giblets effect but inspects the talent on an enemy.
	-- But I'm so happy with my hack that, for the minute, I'll leave it at that.
	local gibs_de = ActorTalents.talents_def.T_OUTRIDER_GIBLETS.display_entity
	local new_metatable = table.clone(getmetatable(gibs_de))
	gibs_de.__oldindex = getmetatable(gibs_de).__index
	gibs_de.old_image = image
	gibs_de.image = nil

	new_metatable.__index = function(table, key)
		if key=="image" then
			local eff = game.player:hasEffect(game.player.EFF_OUTRIDER_GIBLETS)
			if eff.image_variant then return eff.image_variant
			else return table.old_image
			end
		else return table.__oldindex[key]
		end
	end
	setmetatable(gibs_de, new_metatable)
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

	-- Predatory Flanking:
	-- We want to check this on every move, both Outider and Wolf, so let's do it from one place
	local pet = self.outrider_pet
	if pet and pet:knowTalent(pet.T_OUTRIDER_WOLF_FLANKING) or self:knowTalent(self.T_OUTRIDER_FLANKING) then
		self:callTalent(pet.T_OUTRIDER_FLANKING, "doCheck")
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

	-- @todo Delete this and incorporate it into the main flank effect
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

	if target then
		local eff = a:hasEffect(a.EFF_OUTRIDER_FLANKED)
		if eff then
			if eff.src==self then
				data.dam = data.dam + (data.dam/100)
				ret=true
			elseif table.reverse(eff.allies)[self] then
				data.dam = data.dam + (data.dam/100)
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
	--Regen Loyalty on inscription usage if applicable
	local owner = self.owner
	if owner and owner.loyalty and string.find(ab.type[1],  "inscriptions") then
		local name = string.sub(ab.id, 3)
		local inscription_data = self.__inscription_data_fake or self.inscriptions_data[name]
		if inscription_data.heal then
			--@todo: Decide whether this goes in
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
	if rider and data.value / self.max_life > 0.1 then
		--Maybe do a getDismountChance() so Loyalty can be factored in?
		-- local pct = self:combatScale(data.value, 10, self.max_life*1, 50, self.max_life*.25)
		if rng.percent(25) then rider:forceDismount() end
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
	-----------------------------------------------------------------------
	-- Display the rider high on the mount
	-----------------------------------------------------------------------
	local mount, add = self:getMount(), data.add; if not mount then return end
	-- When we find the mount, remember its index in add_mos
	local mount_index
	local do_unbridled_ferocity = mount and
		mount:hasEffect(mount.EFF_OUTRIDER_UNBRIDLED_FEROCITY) or self:hasEffect(self.EFF_OUTRIDER_UNBRIDLED_FEROCITY)

	if mount then 
		for i, mo in ipairs(add) do
			if not mo.mount then
				mo.display_y = do_unbridled_ferocity and -.65 or -.45
			end

			if mo.mount then 
				mount_index = i
				if do_unbridled_ferocity then
					mo.display_w, mo.display_h = 1.4, 1.4
					mo.display_x, mo.display_y = -0.2, -0.3
				end
			end

			if string.find(mo.image, "quiver") and mount_index then
				-- Put the quiver behind the the mount
				-- We remembered the index so it can go exactly 1 layer behind.
				add[i] = nil
				table.insert(add, mount_index, mo)
			end 
		end
	end
	-----------------------------------------------------------------------
	-- Handle the Unbridled Ferocity shader display (warning: hack!)
	-----------------------------------------------------------------------
	if do_unbridled_ferocity then
		for _, mo in ipairs(add) do
			if mo.shader and mo.shader=="awesomeaura" then
				-- @todo Use some kind of globally-visible constants for these numbers
				-- ... or even calculate them live -- will matter when we have different
				-- sized-mounts
				mo.display_w, mo.display_h = 1.4, 2.4
				mo.display_x, mo.display_y = -0.2, -1.3
				if mount then mo.image = mount.image end
			end
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

--- Create a highly specific target type for Gory Spectacle
-- When targeting a certain actor, referenced by 'feed_to', becomes a simple
-- one-square hit. Otherwise, remains a ball.
class:bindHook("Target:realDisplay", function(self, d)
	if self.target_type.type=="foodball" then
		local eater = self.target_type.feed_to
		if eater and eater.x==self.target.x and eater.y==self.target.y then
		-- 	--If we're throwing to our pet, don't calculate the ball radius
			self.target_type.old_radius = self.target_type.old_radius or self.target_type.radius
			self.target_type.radius = 0
			self.target_type.ball = 0
			return nil
		end

		if self.target_type.old_radius then
			self.target_type.radius = self.target_type.old_radius
			self.target_type.old_radius = nil
		end
		self.target_type.ball = self.target_type.radius or 1

		core.fov.calc_circle(
			d.stop_radius_x,
			d.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.ball,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					d.display_highlight(self.syg, px, py)
				else
					d.display_highlight(self.sg, px, py)
				end
			end,
			nil
		)
	end
end)
