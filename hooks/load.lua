local class = require"engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local ActorInventory = require "engine.interface.ActorInventory"
local ActorResource = require "engine.interface.ActorResource"



class:bindHook("ToME:load", function(self, data)
	ActorTalents:loadDefinition("/data-outrider/talents/mounted/mounted.lua")
	Birther:loadDefinition("/data-outrider/birth/mounted.lua")
	ActorResource:defineResource("Loyalty", "loyalty", ActorTalents.T_LOYALTY_POOL, "loyalty_regen", "Loyalty represents the devotion of your pet.")
	--ActorInventory:defineInventory("MOUNT", "Mount", false, "Your mount.")
    ActorTemporaryEffects:loadDefinition("/data-outrider/timed_effects/timed_effects.lua")
    ActorInventory:defineInventory("MOUNT", "Ridden", true, "Trained characters may ride atop a mount", nil)
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
		self.mount:move(self.x, self.y, true)
		game.level.map(self.x, self.y, engine.Map.ACTOR, self)
		-- game.level:removeEntity(self.mount)
		-- self.mount.x, self.mount.y = self.x, self.y
	end	
	--Dragging code

	if self:hasEffect(self.EFF_DRAGGING) then
		local eff_id = "EFF_DRAGGING"
		if self:hasEffect(self.EFF_FETCH) or self:hasEffect(self.EFF_LIVING_SHIELD) then
			if self:hasEffect(self.EFF_FETCH) then eff_id="EFF_FETCH" end
			if self:hasEffect(self.EFF_LIVING_SHIELD) then eff_id="EFF_LIVING_SHIELD" end
		end
		local drag_eff = self:hasEffect(self.EFF_DRAGGING)
		local eff = self:hasEffect(eff_id)
		local tg_eff = eff.trgt:hasEffect(eff.trgt.EFF_DRAGGED)
		if not tg_eff or tg_eff.src ~= self or drag_eff.trgt.dead or not game.level:hasEntity(eff.trgt) then
			self:removeEffect(self.EFF_DRAGGED)
		end
		local can_move = nil
		if not data.moved then
			--game.level.map:remove(self.x, self.y, Map.ACTOR)
			can_move = drag_eff.target.src:move(data.ox, data.oy, true)
			--game.level.map(self.x, self.y, Map.ACTOR, self)
			if not can_move then 
				game.logPlayer(self, "You cannot drag the target!")
			end
		--Confirm
		elseif core.fov.distance(self.x, self.y, drag_eff.trgt.x, drag_eff.trgt.y) > 1 then 
			--self:removeEffect(self.EFF_DRAGGED)
			data.moved = false
		end
	end
end)	


--class:bindHook{"Actor:actBase:Effects", function(self, data)}
	
	
--[[
class:bindHook("Actor:takeHit", function(self, data)
	if self:hasEffect(self.EFF_DIPLOMATIC_IMMUNITY) then data.value = 0 return true end
end)

class:bindHook("DamageProjector:base", function(self, data)
	if self.hasEffect and self:hasEffect(self.EFF_TOURIST_FURY) then data.dam = data.dam * 5 return true end
end)
--]]
class:bindHook("Actor:postUseTalent", function(self, data)
	local ab = data.t
	local trigger = data.trigger
	if ab.mode == "sustained" then
		if not self:isTalentActive(ab.id) then
			if ab.sustain_loyalty then
				trigger = true; self:incMaxLoyalty(-util.getval(ab.sustain_loyalty, self, ab))
			end
		end
	elseif ab.sustain_loyalty then
		self:incMaxLoyalty(util.getval(ab.sustain_loyalty, self, ab))
	elseif not self:attr("force_talent_ignore_ressources") and not ab.fake_ressource then
		if ab.loyalty and not self:attr("zero_resource_cost") then
			trigger = true; self:incLoyalty(-util.getval(ab.loyalty, self, ab) * (100 + self:combatFatigue()) / 100)
		end
	end
	data.ab, data.trigger = ab, trigger
end)

class:bindHook("Actor:getTalentFullDescription:ressources", function(self, data)
	local d, t = data.str, data.t
	if not config.ignore_ressources then
		if t.loyalty then d:add({"color",0x6f,0xff,0x83}, "Loyalty cost: ", {"color",0xff,0xe4,0xb5}, ""..math.round(util.getval(t.loyalty, self, t) * (100 + self:combatFatigue()) / 100, 0.1), true) 
		end
		if t.sustain_loyalty then d:add({"color",0x6f,0xff,0x83}, "Sustain loyalty cost: ", {"color",0xFF, 0xFF, 0x00}, ""..(util.getval(t.sustain_loyalty, self, t)), true)
		end
	end
	data.d = d
end)

class:bindHook("UISet:Classic:Resources", function(self, data)
	if data.player:knowTalent(data.player.T_LOYALTY_POOL) then
		self:mouseTooltip(self.TOOLTIP_LOYALTY, self:makeTextureBar("#SALMON#Loyalty:", nil, data.player:getLoyalty(), data.player.max_loyalty, data.player.loyalty_regen, data.x, data.h, 255, 255, 255,
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
	if player:knowTalent(player.T_LOYALTY_POOL) and not player._hide_resource_loyalty then
		sshat[1]:toScreenFull(x-6, y+8, sshat[6], sshat[7], sshat[2], sshat[3], 1, 1, 1, a)
		bshat[1]:toScreenFull(x, y, bshat[6], bshat[7], bshat[2], bshat[3], 1, 1, 1, a)
		if loyalty_sha.shad then loyalty_sha:setUniform("a", a) loyalty_sha.shad:use(true) end
		local p = player:getLoyalty() / player.max_loyalty
		shat[1]:toScreenPrecise(x+49, y+10, shat[6] * p, shat[7], 0, p * 1/shat[4], 0, 1/shat[5], loyalty_c[1], loyalty_c[2], loyalty_c[3], a)
		if loyalty_sha.shad then loyalty_sha.shad:use(false) end

		if not self.res.loyalty or self.res.loyalty.vc ~= player.loyalty or self.res.loyalty.vm ~= player.max_loyalty or self.res.loyalty.vr ~= player.loyalty_regen then
			self.res.loyalty = {
				hidable = "Loyalty",
				vc = player.loyalty, vm = player.max_loyalty, vr = player.loyalty_regen,
				cur = {core.display.drawStringBlendedNewSurface(font_sha, ("%d/%d"):format(player.loyalty, player.max_loyalty), 255, 255, 255):glTexture()},
				regen={core.display.drawStringBlendedNewSurface(sfont_sha, ("%+0.2f"):format(player.loyalty_regen), 255, 255, 255):glTexture()},
			}
		end

		local dt = self.res.loyalty.cur
		dt[1]:toScreenFull(2+x+64, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+64, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)
		dt = self.res.loyalty.regen
		dt[1]:toScreenFull(2+x+144, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+144, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)

		local front = fshat_loyalty_dark
		if player.loyalty >= player.max_loyalty then front = fshat_loyalty end
		front[1]:toScreenFull(x, y, front[6], front[7], front[2], front[3], 1, 1, 1, a)
		self:showResourceTooltip(bx+x*scale, by+y*scale, fshat[6], fshat[7], "res:loyalty", self.TOOLTIP_LOYALTY)
		x, y = self:resourceOrientStep(orient, bx, by, scale, x, y, fshat[6], fshat[7])
	elseif game.mouse:getZone("res:loyalty") then 
		game.mouse:unregisterZone("res:loyalty") 
	end
	data.x, data.y = x, y
end)