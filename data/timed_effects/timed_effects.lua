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
status = "beneficial",
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

newEffect{
	name = "STRIKE_AT_THE_HEART",
	desc = "Strike at the Heart",
	long_desc = function(self, eff)
		local ct = eff.ct
		return ("The target's charge emboldens it, granting %d%% movement speed, %d accuracy, %d%% critical chance and %d defense until the next attack."):format(eff.move*ct, eff.atk*ct, eff.crit*ct, eff.def*ct) end,
	type = "physical",
	subtype = { charge=true, tactic=true, speed=true },
	status = "beneficial",
	parameters = { targets={}, ct=1, move=5, atk=3, crit=3, def=3},
	--TODO: As you can use this with archers, the terminology "charge" isn't really appropriate
	on_gain = function(self, eff) return "#Target# prepares a deadly charge!", "+Strike at the Heart" end,
	on_lose = function(self, eff) return "#Target# ends the charge.", "-Strike at the Heart" end,
	activate = function(self, eff)
		local ct = eff.ct
		eff.move_id = self:addTemporaryValue("movement_speed", eff.move/100*ct)
		eff.atk_id = self:addTemporaryValue("combat_atk", eff.atk*ct)
		eff.crit_id = self:addTemporaryValue("combat_physcrit", eff.crit*ct)
		eff.def_id = self:addTemporaryValue("combat_def", eff.def*ct)
	end,
	on_merge = function(self, old_eff, new_eff)
		new_eff.ct = math.min(old_eff.ct+1, 3)
		self:removeTemporaryValue("movement_speed", old_eff.move_id)
		self:removeTemporaryValue("combat_atk", old_eff.atk_id)
		self:removeTemporaryValue("combat_physcrit", old_eff.crit_id)
		self:removeTemporaryValue("combat_def", old_eff.def_id)
		local ct = new_eff.ct
		new_eff.move_id = self:addTemporaryValue("movement_speed", new_eff.move/100*ct)
		new_eff.atk_id = self:addTemporaryValue("combat_atk", new_eff.atk*ct)
		new_eff.crit_id = self:addTemporaryValue("combat_physcrit", new_eff.crit*ct)
		new_eff.def_id = self:addTemporaryValue("combat_def", new_eff.def*ct)
		return new_eff
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam)
		if target then eff.targets[target] = true end
		game:onTickEnd(function() self:removeEffect(self.EFF_STRIKE_AT_THE_HEART) end)
	end,
	callbackOnArcheryAttack = function(self, eff, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		if target then eff.targets[target] = true end
		game:onTickEnd(function() self:removeEffect(self.EFF_STRIKE_AT_THE_HEART) end)
	end,
	deactivate = function(self, eff)
		if self:knowTalent(self.T_SPRING_ATTACK) then
			local t = self:getTalentFromId(self.T_SPRING_ATTACK)
			self:setEffect(self.EFF_SPRING_ATTACK, t.getDur(self,t), {
				move = eff.move,
				def = eff.def,
				min_pct = t.getMinPct(self, t),
				max_pct = t.getMaxPct(self, t)
				})
		end
		self:removeTemporaryValue("movement_speed", eff.move_id)
		self:removeTemporaryValue("combat_atk", eff.atk_id)
		self:removeTemporaryValue("combat_physcrit", eff.crit_id)
		self:removeTemporaryValue("combat_def", eff.def_id)
		--TODO: Decide how to pass a target
	end,
}

newEffect{
name = "SPRING_ATTACK",
desc = "Spring Attack",
long_desc = function(self, eff) return ("The target's charge has ended, but it retains a bonus of %d%% movement speed and %d to defense. Also, the target gain a bonus to ranged damage against any marked targets for the duration. This bonus is dependent on distance: starting from %d%% at 2 tiles, increasing to %d%% at 5"):format(eff.move, eff.def, eff.min_pct, eff.max_pct) end,
type = "physical",
subtype = { tactic=true, speed=true },
status = "beneficial",
parameters = { move=10, def=6, min_pct=5, max_pct=15},
--TODO: As you can use this with archers, the terminology "charge" isn't really appropriate
on_gain = function(self, eff) return "#Target# enters into a spring attack!", "+Spring Attack" end,
on_lose = function(self, eff) return "#Target# ends the spring attack.", "-Spring Attack" end,
--callbackonDealDamage is not useful so we handle the damage increment in load.lua's DamageProjector:base hook
activate = function(self, eff)
	self:effectTemporaryValue(eff, "movement_speed", eff.move)
	self:effectTemporaryValue(eff, "combat_def", eff.def)
end,
}

newEffect{
	name = "HOWLING_ARROWS",
	desc = "Howling Arrows",
	long_desc = function(self, eff) return ("The target has a %d%% chance to confuse (power %d) with each archery attack."):format(eff.chance, eff.power) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { power=35, chance=25 },
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		self:callTalent(self.T_WAILING_WEAPON, "doTryConfuse", target)
	end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "SHRIEKING_STRIKES",
	desc = "Shrieking Strikes",
	long_desc = function(self, eff) return ("The target has a %d%% chance to confuse (power %d) with each melee attack."):format(eff.chance, eff.power) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { power=35, chance=25 },
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		self:callTalent(self.T_WAILING_WEAPON, "doTryConfuse", target)
	end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}
