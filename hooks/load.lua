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
	ActorTalents:loadDefinition("/data-outrider/talents/mounted/mounted.lua")
	Birther:loadDefinition("/data-outrider/birth/mounted.lua")
	ActorResource:defineResource("Loyalty", "loyalty", ActorTalents.T_LOYALTY_POOL, "loyalty_regen", "Loyalty represents the devotion of your pet.")
	--ActorInventory:defineInventory("MOUNT", "Mount", false, "Your mount.")
	ActorTemporaryEffects:loadDefinition("/data-outrider/timed_effects/timed_effects.lua")
	ActorInventory:defineInventory("MOUNT", "Ridden", true, "Trained characters may ride atop a mount", nil)
	DamageType:loadDefinition("data-outrider/damage_types.lua")
	ActorAI:loadDefinition("/data-outrider/ai/")
end)

class:bindHook("Actor:takeHit", function(self, data)
	--1.1.6 will be able to do this in a callback
	if self:hasEffect(self.EFF_REGAIN_POISE) then
		local eff = self:hasEffect(self.EFF_REGAIN_POISE)
		if data.value > 1 then self.tempeffect_def[self.EFF_REGAIN_POISE].do_onTakeHit(self, eff, data.value) end
	end

	--another way to do this would be superloading on_project
	--probably more fun to do it this way as the full effect and full combat log assertions will be transferred to the new target.
	if self:hasEffect(self.EFF_LIVING_SHIELDED) and data.src ~= self.tmp[self.EFF_LIVING_SHIELDED].trgt then 
		if rng.percent(self.tmp["EFF_LIVING_SHIELDED"].pct) then
			game.logSeen(self, "The living shield takes the damage!")
			self.tmp["EFF_LIVING_SHIELDED"].trgt:onTakeHit(data.value, data.src)
			
			--data.value = data.value / 2
			data.value = 0
			-- data.trgt
		end
	end
	return true
end)
	
--	self:triggerHook{"Actor:move", moved=moved, force=force, ox=ox, oy=oy}

class:bindHook("Actor:move", function(self, data)
	if self.mount then
		if not game.level.map(data.x, data.y, engine.Map.ACTOR) then
			self.mount:move(self.x, self.y, true)
			game.level.map(self.x, self.y, engine.Map.ACTOR, self)
		end
		-- game.level:removeEntity(self.mount)
		-- self.mount.x, self.mount.y = self.x, self.y
	end	
end)	

class:bindHook("DamageProjector:base", function(self, data)
	local ret = false
	local eff = self:hasEffect(self.EFF_SPRING_ATTACK) 
	if eff then
		local dist = core.fov.distance(self.x, self.y, data.x, data.y)
		if dist >= 2 then
			dist = util.bound(dist, 2, 5)
			local pct = 100 + self:combatScale(dist, eff.min_pct, 2, eff.max_pct, 5)
			data.dam = data.dam * pct/100
			ret = true
		end
	end

	local a = game.level.map(data.x, data.y, engine.Map.ACTOR)
	if a then
		local eff = a:hasEffect(a.EFF_PREDATORY_FLANKING)
		if eff then
			if eff.src==self then
				data.dam = data.dam * eff.src_pct/100
				ret=true
			elseif table.reverse(eff.allies)[self] then
				data.dam = data.dam * eff.allies_pct/100
				ret=true
			end
		end
	end
	return ret
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
			owner:incLoyalty(5)
		end
	end
	data.ab, data.trigger = ab, trigger
end)

class:bindHook("Actor:getTalentFullDescription:ressources", function(self, data)
	local d, t = data.str, data.t
	if not config.ignore_ressources then
		local fatigue_factor = (t.requires_mounted or self:isMounted()) and self:combatFatigue() or 0
		if t.loyalty then d:add({"color",0x6f,0xff,0x83}, "Loyalty cost: ", {"color",0xff,0xe4,0xb5}, ""..math.round(util.getval(t.loyalty, self, t) * (100 + fatigue_factor) / 100, 0.1), true) 
		end
		if t.sustain_loyalty then d:add({"color",0x6f,0xff,0x83}, "Sustain loyalty cost: ", {"color",0xFF, 0xFF, 0x00}, ""..(util.getval(t.sustain_loyalty, self, t)), true)
		end
	end
	data.d = d
end)

class:bindHook("UISet:Classic:Resources", function(self, data)
	local src = data.player.show_owner_loyalty_pool and data.player.summoner or data.player
	if src:knowTalent(data.player.T_LOYALTY_POOL) then
		self:mouseTooltip(self.TOOLTIP_LOYALTY, self:makeTextureBar("#SALMON#Loyalty:", nil, src:getLoyalty(), src.max_loyalty, src.loyalty_regen, data.x, data.h, 255, 255, 255,
	 		{r=0xff / 3, g=0xcc / 3, b=0x80 / 3},
	 		{r=0xff / 6, g=0xcc / 6, b=0x80 / 6})) 
		data.h = data.h + self.font_h
	end
	return data
end)

local Shader = require "engine.Shader"

local loyalty_c = {colors.SALMON.r/255, colors.SALMON.g/255, colors.SALMON.b/255}
local loyalty_sha = Shader.new("resources", {require_shader=4, delay_load=true, color=loyalty_c, speed=2000, distort={0.4,0.4}})

local fshat_loyalty = {core.display.loadImage("/data/gfx/ui/resources/front_psi.png"):glTexture()}
local fshat_loyalty_dark = {core.display.loadImage("/data/gfx/ui/resources/front_psi_dark.png"):glTexture()}

local sshat = {core.display.loadImage("/data/gfx/ui/resources/shadow.png"):glTexture()}
local bshat = {core.display.loadImage("/data/gfx/ui/resources/back.png"):glTexture()}
local shat = {core.display.loadImage("/data/gfx/ui/resources/fill.png"):glTexture()}
local fshat = {core.display.loadImage("/data/gfx/ui/resources/front.png"):glTexture()}


local font_sha = core.display.newFont("/data/font/DroidSans.ttf", 14, true)
font_sha:setStyle("bold")
local sfont_sha = core.display.newFont("/data/font/DroidSans.ttf", 12, true)
sfont_sha:setStyle("bold")

class:bindHook("UISet:Minimalist:Resources", function(self, data)
	local player = data.player
	local a = data.a
	local x, y, bx, by = data.x, data.y, data.bx, data.by
	local orient, scale = data.orient, data.scale
	local src = player.show_owner_loyalty_pool and player.summoner or player
	if src:knowTalent(src.T_LOYALTY_POOL) and src.outrider_pet and not src._hide_resource_loyalty then
		sshat[1]:toScreenFull(x-6, y+8, sshat[6], sshat[7], sshat[2], sshat[3], 1, 1, 1, a)
		bshat[1]:toScreenFull(x, y, bshat[6], bshat[7], bshat[2], bshat[3], 1, 1, 1, a)
		if loyalty_sha.shad then loyalty_sha:setUniform("a", a) loyalty_sha.shad:use(true) end
		local p = src:getLoyalty() / src.max_loyalty
		shat[1]:toScreenPrecise(x+49, y+10, shat[6] * p, shat[7], 0, p * 1/shat[4], 0, 1/shat[5], loyalty_c[1], loyalty_c[2], loyalty_c[3], a)
		if loyalty_sha.shad then loyalty_sha.shad:use(false) end

		if not self.res.loyalty or self.res.loyalty.vc ~= src.loyalty or self.res.loyalty.vm ~= src.max_loyalty or self.res.loyalty.vr ~= src.loyalty_regen then
			self.res.loyalty = {
				hidable = "Loyalty",
				vc = src.loyalty, vm = src.max_loyalty, vr = src.loyalty_regen,
				cur = {core.display.drawStringBlendedNewSurface(font_sha, ("%d/%d"):format(src.loyalty, src.max_loyalty), 255, 255, 255):glTexture()},
				regen={core.display.drawStringBlendedNewSurface(sfont_sha, ("%+0.2f"):format(src.loyalty_regen), 255, 255, 255):glTexture()},
			}
		end

		local dt = self.res.loyalty.cur
		dt[1]:toScreenFull(2+x+64, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+64, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)
		dt = self.res.loyalty.regen
		dt[1]:toScreenFull(2+x+144, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+144, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)

		TOOLTIP_LOYALTY =  [[#GOLD#Magic#LAST#
		Loyalty represents the devotion of an ally to you - devotion that can be lost should you disabuse it.
		In the case of a mount, at less than 50% Loyalty there is a chance it will struggle to obey orders when under threat. At less than 25% Loyalty, you will have to treat it with great care to keep it under your control.
		]]
		local front = fshat_loyalty_dark
		if src.loyalty >= src.max_loyalty then front = fshat_loyalty end
		front[1]:toScreenFull(x, y, front[6], front[7], front[2], front[3], 1, 1, 1, a)
		self:showResourceTooltip(bx+x*scale, by+y*scale, fshat[6], fshat[7], "res:loyalty", TOOLTIP_LOYALTY)
		x, y = self:resourceOrientStep(orient, bx, by, scale, x, y, fshat[6], fshat[7])
	elseif game.mouse:getZone("res:loyalty") then 
		game.mouse:unregisterZone("res:loyalty") 
	end
	data.x, data.y = x, y
end)