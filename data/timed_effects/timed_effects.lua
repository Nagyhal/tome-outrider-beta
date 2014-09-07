--Mounted effects and important mounted stuff


-- local Stats = require "engine.interface.ActorStats"
-- local Particles = require "engine.Particles"
-- local Shader = require "engine.Shader"
-- local Entity = require "engine.Entity"
-- local Chat = require "engine.Chat"
-- local Map = require "engine.Map"
-- local Level = require "engine.Level"


newEffect{
name = "MOUNT",
desc = "Mounted",
long_desc = function(self, eff)
	if eff.mount.type == "animal" then
		return ("The target rides atop a bestial steed - sharing damage and gaining the mount's movement speed")
	else return "The target rides atop a mount - sharing damage and gaining the mount's movement speed"
	end
end,
type = "other",
subtype = { miscellaneous=true },
status = "beneficial",
decrease = 0,
no_stop_enter_worldmap = true, no_stop_resting = true,
parameters = {mount},
on_timeout = function(self, eff)
	if not eff.mount or eff.mount.dead or not eff.mount:hasEffect(eff.mount.EFF_RIDDEN) then
		self:removeEffect(self.EFF_MOUNT, false, true)
	end
end,
-- callbackOnActBase = function(self,)
-- end,
-- callbackOnMeleeHit = function(self, eff, cb, src)
-- 	game.logPlayer(game.player, "callbackOnMeleeHit functioning for effect")
-- 	return true
-- end,
activate = function(self, eff)
end,
deactivate = function(self, eff)
	-- self.mount = nil
end,
}

newEffect{
name = "RIDDEN",
desc = "Ridden",
long_desc = function(self, eff)
	return ("The target is being ridden, sharing damage with its controller")
end,
type = "other",
subtype = { miscellaneous=true },
status = "beneficial",
decrease = 0,
no_stop_enter_worldmap = true, no_stop_resting = true,
parameters = {rider},
activate = function(self, eff)
	eff.tmpid = self:addTemporaryValue("never_move", 1)
end,
deactivate = function(self, eff)
	self:removeTemporaryValue("never_move", eff.tmpid)
	if self.dead then
		eff.rider:removeEffect(self.EFF_MOUNT, false, true)
	end
	return
end,
}

--Combat effects

newEffect{
name = "REGAIN_POISE",
desc = "Regaining Poise",
long_desc = function(self, eff) return ("The target gathers poise after an all-out attack, suffering a movement speed penalty of %d%% and enduring the disarmed state. However, when the target avoids taking damage, the target may recover %d stamina per turn."):format(eff.slow, eff.regen) end,
type = "physical",
subtype = { disarm=true },
status = "detrimental",
parameters = { regen=6, slow=50, cause="all-out attack", toggleDamageTaken=false },
on_gain = function(self, eff) return ("#Target# must recover from the %s!"):format(eff.cause), "+Regain Poise" end,
on_lose = function(self, eff) return "#Target# has regained full poise.", "-Regain Poise" end,
activate = function(self, eff)
	eff.tmpid = self:addTemporaryValue("disarmed", 1)
	eff.speedid = self:addTemporaryValue("movement_speed", -eff.slow/100)
	eff.toggleDamageTaken = false
end,
deactivate = function(self, eff)
	self:removeTemporaryValue("movement_speed", eff.speedid)
	self:removeTemporaryValue("disarmed", eff.tmpid)
end,
do_onTakeHit = function(self, eff, dam)
	if dam > 1 
		then eff.toggleDamageTaken = true
	 -- Give the player some feeback
		game.logSeen(self, ("#Self# gains no recovery under the onslaught!"):gsub("#Self#", self.name:capitalize()))
		if game.flyers and not silent and self.x and self.y and game.level.map.seens(self.x, self.y) then
			local fly = "No Recovery!"
			local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
			if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
		end
	end
end,
on_timeout = function(self, eff)
	if eff.toggleDamageTaken == false then
		self:incStamina(eff.regen)
		game.logSeen(self, ("#Self# recovers poise as the enemies are kept at bay!"):gsub("#Self#", self.name:capitalize()))
		if game.flyers and not silent and self.x and self.y and game.level.map.seens(self.x, self.y) then
			local fly = "Recovery!"
			local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
			if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
		end
		
	end
	-- else -- Give the player some feeback
		-- game.logSeen(self, ("#Target# gains no recovery under the onslaught!"):gsub("#Target#", self.name:capitalize()))
		-- if game.flyers and not silent and self.x and self.y and game.level.map.seens(self.x, self.y) then
			-- local fly = "No Recovery!"
			-- local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
			-- if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
		-- end
	-- end
	
	eff.toggleDamageTaken = false
end,
}


newEffect{
name = "LIVING_SHIELD",
desc = "Living Shield",
long_desc = function(self, eff) return ("The target is being used as a living shield! %d%% chance to displace damage onto the target's manhandler."):format(eff.pct) end,
type = "physical",
subtype = { grapple=true },
status = "detrimental",
parameters = { pct = 25, src = nil},
on_gain = function(self, err) return "#Target# is being used as a living shield!", "+Living Shield" end,
on_lose = function(self, err) return "#Target# is no longer a living shield", "-Living Shield" end,
activate = function(self, eff)end,
deactivate = function(self, eff)end,
do_onTakeHit = function(self, eff, dam) end,
on_timeout = function(self, eff) end,
}

newEffect{
name = "LIVING_SHIELDED",
desc = "Shield: Living Shield",
long_desc = function(self, eff) return ("The target grips its victim and enjoys a %d%% chance to displace damage onto it."):format(eff.pct) end,
type = "physical",
subtype = { grapple=true },
status = "beneficial",
parameters = { pct = 25, trgt = nil},
on_gain = function(self, err) return "#Target# is defended by the living shield!", "+Shielded" end,
on_lose = function(self, err) return "#Target# no longer has a living shield", "-Shielded" end,
activate = function(self, eff)end,
deactivate = function(self, eff)end,
do_onTakeHit = function(self, eff, dam) end,
on_timeout = function(self, eff) end,
}

newEffect{
name = "IMPALED",
desc = "Impaled",
long_desc = function(self, eff) return ("The target is skewered against an obstacle, floor tile, or living thing, and is pinned and bled for %d per turn. Teleporting will break this pin."):format(eff.bleed) end,
type = "physical",
subtype = { pin=true },
status = "detrimental",
parameters = { bleed = 0},
on_gain = function(self, err) return "#Target# is skewered and cannot move!", "+Impaled" end,
on_lose = function(self, err) return "#Target# escapes the impalement.", "-Impaled" end,
activate = function(self, eff)
	eff.tmpid = self:addTemporaryValue("never_move", 1)
end,
deactivate = function(self, eff)
	self:removeTemporaryValue("never_move", eff.tmpid)
end,
do_onTakeHit = function(self, eff, dam) end,
on_timeout = function(self, eff) end,
}

newEffect{
name = "DRAGGED",
desc = "Dragged",
long_desc = function(self, eff) return ("The target is engaged in a mobile grapple, and may be moved by its assaulter.") end,
type = "physical",
subtype = { grapple=true, src=nil },
status = "detrimental",
parameters = {},
on_gain = function(self, err) return "#Target# is being dragged!", "+Dragged" end,
on_lose = function(self, err) return "#Target# is no longer dragged", "Dragged" end,
activate = function(self, eff)end,
deactivate = function(self, eff)end,
do_onTakeHit = function(self, eff, dam) end,
on_timeout = function(self, eff) 
	if core.fov.distance(self.x, self.y, eff.src.x, eff.src.y) > 1 or eff.src.dead or not game.level:hasEntity(eff.src) then
		self:removeEffect(self.EFF_DRAGGED)
	end
end,
}

newEffect{
name = "DRAGGING",
desc = "Dragging",
long_desc = function(self, eff) return ("The target is engaged in a mobile grapple, leading its helpless defender whereever it wills.") end,
type = "physical",
subtype = { grapple=true },
status = "detrimental",
parameters = {trgt=nil},
on_gain = function(self, err) return "#Target# drags its victim!", "+Dragged" end,
on_lose = function(self, err) return "#Target# can no longer drag its victim", "Dragged" end,
activate = function(self, eff)end,
deactivate = function(self, eff)
	if eff.dur <= 0 then eff.on_timeout(self, eff) end
end,
do_onTakeHit = function(self, eff, dam) end,
on_timeout = function(self, eff)
	local p = eff.trgt:hasEffect(eff.trgt.EFF_DRAGGING)
	if not p or p.src ~= self or core.fov.distance(self.x, self.y, eff.trgt.x, eff.trgt.y) > 1 or eff.trgt.dead or not game.level:hasEntity(eff.trgt) then
		self:removeEffect(self.EFF_DRAGGING)
	end
end,
}