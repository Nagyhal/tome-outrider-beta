function checkEffectHasParameter(self, eff, name)
	if not eff[name] then
		local id = eff.effect_id
		self:removeEffect(id, nil, true)
		error("No parameter %s sent to temporary effect %s."):format(name, id)
	end
end

local Particles = require "engine.Particles"

load("/data-outrider/timed_effects/disobedience.lua")

--Effects for basic mount functionality
newEffect{
	name = "OUTRIDER_MOUNT", image="talents/mount.png",
	desc = "Mounted",
	long_desc = function(self, eff)
		if eff.mount.type == "animal" then
			return ("The target rides atop a bestial steed - sharing damage and gaining the mount's movement speed.")
		else return "The target rides atop a mount - sharing damage and gaining the mount's movement speed"
		end
	end,
	type = "other",
	subtype = { miscellaneous=true },
	status = "beneficial",
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	parameters = {mount},
	checkMount = function(self, eff)
		if not eff.mount or eff.mount.dead or not eff.mount:hasEffect(eff.mount.EFF_OUTRIDER_RIDDEN) then
			self:removeEffect(self.EFF_OUTRIDER_MOUNT, false, true)
		end
	end,
	on_timeout = function(self, eff, ed) ed.checkMount(self, eff) end,
	callbackOnActBase = function(self, eff)
		local ed = self:getEffectFromId(eff.effect_id)
		ed.checkMount(self, eff)

		eff.mount:runAI("pet_behaviour")
		while eff.mount:enoughEnergy() do
			eff.mount:doAI()
		end
	end,
	activate = function(self, eff, ed)
		if not eff.mount then
			self:removeEffect(self.EFF_OUTRIDER_MOUNT, nil, true)
			error("No mount sent to temporary effect Mounted.")
		end
		-- DEBUG: Test!
		-- ed.generateMountedMOs(self, eff)
		self:updateModdableTile()
		game.level.map:updateMap(self.x, self.y)
	end,
	deactivate = function(self, eff)
		self.mount = nil
		self:updateModdableTile()
		game.level.map:updateMap(self.x, self.y)
	end,
}

newEffect{
	name = "OUTRIDER_RIDDEN", image="talents/mount.png",
	desc = "Ridden",
	long_desc = function(self, eff)
		return ("The target is being ridden, sharing damage with its controller")
	end,
	type = "other",
	subtype = { miscellaneous=true },
	status = "beneficial",
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	parameters = {rider},
	activate = function(self, eff)
		if not eff.rider then
			self:removeEffect(self.EFF_OUTRIDER_RIDDEN, nil, true)
			error("No rider sent to temporary effect Ridden.")
		end
		self:effectTemporaryValue(eff, "never_move", 1)
	end,
	deactivate = function(self, eff)
		if self.dead then
			eff.rider:removeEffect(self.EFF_OUTRIDER_MOUNT, false, true)
		end
		self.rider = nil
		return
	end,
}

newEffect{
name = "OUTRIDER_REGAIN_POISE", image = "talents/brazen_lunge.png",
desc = "Regaining Poise",
long_desc = function(self, eff) return ("The target gathers poise after an all-out attack. Each turn the target avoids taking damage, the target may recover %d stamina per turn."):format(eff.regen) end,
type = "physical",
subtype = { tactic=true, morale=true },
status = "beneficial",
parameters = { regen=6, toggleDamageTaken=false, first_turn=true},
on_gain = function(self, eff) return "#Target# tries to regain stamina!", "+Regain Poise" end,
on_lose = function(self, eff) return "#Target# stops recovering stamina.", "-Regain Poise" end,
activate = function(self, eff)
	eff.toggleDamageTaken = false
end,
deactivate = function(self, eff, ed)
	--Note to self:
	--This is a weird one, because I can't use actor:callEffect here.

	--If I use callEffect, that function doesn't get any effect table, so it doesn't ever try to call an effect
	--that doesn't seem to exist.

	--That is because deactivate() is called AFTER the effect is removed from self.tmp, which callEffect checks.
	--However, the effect parameters are still passed to deactivate, even though
	--the effect no longer exists as an element of the actor object table.

	--If bugs appear, you'd be wise to check here!
	ed.on_timeout(self, eff)
end,
do_onTakeHit = function(self, eff, dam)
	--Give the player one turn to escape
	if eff.first_turn == true then return end
	if dam > 1 and not eff.toggleDamageTaken then
		eff.toggleDamageTaken = true
		-- Give the player some feeback
		game.logSeen(self, ("#Self# recovers no stamina under the onslaught!"):gsub("#Self#", self.name:capitalize()))
		if game.flyers and not silent and self.x and self.y and game.level.map.seens(self.x, self.y) then
			local fly = "No Recovery!"
			local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
			if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
		end
	end
end,
on_timeout = function(self, eff)
	--This gives player one turn to escape & makes timing nicer
	if eff.first_turn == true then eff.first_turn = false return end

	if not eff.toggleDamageTaken then
		self:incStamina(eff.regen)
		game.logSeen(self, ("#Self# recovers stamina as the enemies are kept at bay!"):gsub("#Self#", self.name:capitalize()))
		if game.flyers and not silent and self.x and self.y and game.level.map.seens(self.x, self.y) then
			local fly = "Recovery!"
			local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
			if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
		end
		
	end
	eff.toggleDamageTaken = false
end,
}

newEffect{
	name = "OUTRIDER_TAUNT", image = "talents/brazen_lunge.png",
	desc = "Taunted",
	long_desc = function(self, eff) return ("Target is taunted and will target %s."):
		format(eff.src and eff.src.name:capitalize() or "the source")
	end,
	type = "mental",
	subtype = { tactic=true, morale=true },
	status = "detrimental",
	parameters = { src=nil },
	on_gain = function(self, eff) return "#Target#' is taunted!", "+Taunted" end,
	on_lose = function(self, eff) return "#Target#' is no longer taunted!", "-Taunted" end,
	on_timeout = function(self, eff)
		self:callEffect(self.EFF_OUTRIDER_TAUNT, "doTaunt")
	end,
	doTaunt = function(self, eff)
		local src = eff.src 
		if not scr or src.dead then
			self:removeEffect(eff.EFF_OUTRIDER_TAUNT)
			return
		end  
		--Copied from the golem taunt, but constantly refreshes
		if self:reactionToward(src) < 0 then
			self:setTarget(src)
		src:logCombat(self, "#Source# provokes #Target# to attack it.")
		end
	end,
	callbackOnAct = function(self, eff)
		self:callEffect(self.EFF_OUTRIDER_TAUNT, "doTaunt")
	end,
	activate = function(self, eff)
		if not eff.src then	error("No source sent to temporary effect EFF_OUTRIDER_TAUNT.") end
		self:callEffect(self.EFF_OUTRIDER_TAUNT, "doTaunt")
	end,
}

-- @todo Make some reaaally beautiful paired effects functionality
local function checkPairedEffect(target, effect_id, src, must_be_adjacent)
	local p = target:hasEffect(target[effect_id])

	if not p or (p.src and p.src ~= src) or target.dead or not game.level:hasEntity(target) then
		return false
	else
		local reference = p.src or p.target or p.trgt
		local moved_away = must_be_adjacent and core.fov.distance(reference.x, reference.y, target.x, target.y) > 1
		if must_be_adjacent and moved_away then
			return false
		end
	end
	return true
end

newEffect{
	name = "OUTRIDER_LIVING_SHIELD", image="talents/living_shield.png",
	desc = "Used as a Living Shield",
	long_desc = function(self, eff) return ("The target is being used as a living shield, reducing defense by %d. The target's manhandler will have a %d%% chance to redirect attacks onto it!"):format(eff.def, eff.pct) end,
	type = "physical",
	subtype = { grapple=true },
	status = "detrimental",
	parameters = { pct = 25, def=5, src},
	on_gain = function(self, eff) return "#Target# is being used as a living shield!", "+Living Shield" end,
	on_lose = function(self, eff) return "#Target# is no longer a living shield", "-Living Shield" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "combat_def", -eff.def)
		if not eff.src then
			self:removeEffect(self.EFF_OUTRIDER_LIVING_SHIELD)
			error("No source sent to temporary effect Used as a Living Shield.")
		end
	end,
	deactivate = function(self, eff)
		eff.src:removeEffect(eff.src.EFF_GRAPPLING)
		eff.src:removeEffect(eff.src.EFF_OUTRIDER_LIVING_SHIELDED)
	 end,
	callbackOnDie = function(self, eff)
		eff.src:removeEffect(eff.src.EFF_GRAPPLING)
		eff.src:removeEffect(eff.src.EFF_OUTRIDER_LIVING_SHIELDED)
	end,
	on_timeout = function(self, eff)
		if not checkPairedEffect(eff.src, "EFF_GRAPPLING", nil, true)
			or not checkPairedEffect(eff.src, "EFF_OUTRIDER_LIVING_SHIELDED", nil, true) then
			self:removeEffect(eff.effect_id)
		end
	end,
}

newEffect{
	name = "OUTRIDER_LIVING_SHIELDED", image="talents/living_shield.png",
	desc = "Living Shield",
	display_desc = function(self, eff) return ("Living Shield: %s"):format(string.bookCapitalize(eff.target.name)) end,
	long_desc = function(self, eff) return ("The target grips its victim and enjoys a %d%% chance to displace damage onto it."):format(eff.chance) end,
	type = "physical",
	subtype = { grapple=true },
	status = "beneficial",
	parameters = { chance=25 },
	on_gain = function(self, err) return "#Target# is defended by the living shield!", "+Shielded" end,
	on_lose = function(self, err) return "#Target# no longer has a living shield", "-Shielded" end,
	activate = function(self, eff)
		if not eff.target then
			self:removeEffect(self.EFF_OUTRIDER_LIVING_SHIELDED, nil, true)
			error("No target sent to temporary effect Shield: Living Shield.")
		end
		if not self.dragged_entities then self.dragged_entities = {} end
		local t, e = self.dragged_entities, eff.target
		t[e] = t[e] and t[e]+1 or 1
		if eff.shield then
			-- @todo: make the util function work
			if self.hotkey and self.isHotkeyBound then
				local pos = self:isHotkeyBound("talent", self.T_OUTRIDER_LIVING_SHIELD)
				if pos then
					self.hotkey[pos] = {"talent", self.T_OUTRIDER_LIVING_SHIELD_BLOCK}
				end
			end

			util.hotkeySwapOnLearn(
				self, "T_OUTRIDER_LIVING_SHIELD", "T_OUTRIDER_LIVING_SHIELD_BLOCK",
				function()
					self:learnTalent(self.T_OUTRIDER_LIVING_SHIELD_BLOCK, true, 1, {no_unlearn=true})
				end
			)
		end
	end,
	deactivate = function(self, eff)
		self.dragged_entities[eff.target] = self.dragged_entities[eff.target]-1
		if self.dragged_entities[eff.target] == 0 then self.dragged_entities[eff.target] = nil end
		eff.target:removeEffect(eff.target.EFF_OUTRIDER_LIVING_SHIELD)
		if self:knowTalent(self.T_OUTRIDER_LIVING_SHIELD_BLOCK) then
			util.hotkeySwap(self, "T_OUTRIDER_LIVING_SHIELD_BLOCK", "T_OUTRIDER_LIVING_SHIELD")
			self:unlearnTalent(self.T_OUTRIDER_LIVING_SHIELD_BLOCK)
		end
	end,
	on_timeout = function(self, eff)
		if not checkPairedEffect(eff.target, "EFF_GRAPPLED", self, true)
			or not checkPairedEffect(eff.target, "EFF_OUTRIDER_LIVING_SHIELD", self, true) then
			self:removeEffect(eff.effect_id)
		end
	end,
}

newEffect{
	name = "OUTRIDER_IMPALED", image = "talents/impalement.png",
	desc = "Impaled",
	long_desc = function(self, eff) return ("The target is skewered against an obstacle, floor tile, or living thing, and is pinned and bled for %d per turn. Teleporting will break this pin."):format(eff.bleed) end,
	type = "physical",
	subtype = { pin=true },
	status = "detrimental",
	parameters = { bleed = 0},
	on_gain = function(self, err) return "#Target# is skewered and cannot move!", "+Impaled" end,
	on_lose = function(self, err) return "#Target# escapes the impalement.", "-Impaled" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "never_move", 1)
	end,
	do_onTakeHit = function(self, eff, dam) end,
	on_timeout = function(self, eff) end,
}


--- Simply returns the distance to the nearest enemy
local function getDistToNearestEnemy(self)
	-- We're going to update the user's FOV cache
	-- If we move instantly, the new FOV is usually calculated /after/
	-- the movement, which we don't want.
	self:computeFOV()

	local i = 1 
	for i, act in ipairs(self.fov.actors_dist) do
		if act and not act.dead and self.fov.actors[act] then
			-- Break out the loop when we have our nearest enemy
			if self:reactionToward(act) < 0 then
				return math.sqrt(self.fov.actors[act].sqdist)
			end
		end
	end
end

newEffect{
	name = "OUTRIDER_SPRING_ATTACK", image = "talents/spring_attack.png",
	desc = "Spring Attack",
	long_desc = function(self, eff) return ([[The user gains a point of spring attack for each move, so long as an enemy has not moved adjacent by the beginning of the next turn. Attacks will reduce the counter by one.

		This current bonuses are: %d%% crit chance, %d stamina on shot; after %d points, shots become dual-target.]]):
		format(eff.current_crit or 77, eff.current_stamina or 77, eff.threshold)
	end,
	type = "physical",
	subtype = {
		tactic = true
	},
	parameters = {	
		ct = 1, ct_to_add = 0,
		min_pct = 5, max_pct = 10, min_stamina = 0.25, max_stamina = 1,
		current_crit = 5, current_stamina = 0.25,
		threshold = 10
	},
	charges = function(self, eff) return eff.ct end,
	status = "beneficial",
	getCurrentCrit = function(self, eff)
		local mod = util.bound(eff.ct, 0, 10) / 10
		return util.lerp(eff.min_pct, eff.max_pct, mod)
	end,
	getCurrentStamina = function(self, eff)
		local mod = util.bound(getDistToNearestEnemy(self) or 6, 1, 6) -1 / 5
		if mod > 0 then
			return util.lerp(eff.min_stamina, eff.max_stamina, mod)
		else return 0 end
	end,
	on_gain = function(self, eff) return "#Target# enters into a spring attack!", "+Spring Attack" end,
	on_lose = function(self, eff) return "#Target#'s spring attack has ended.", "-Spring Attack" end,
	callbackOnMove = function(self, eff, moved, force, ox, oy, x, y)
		-- Wait until next turn to check if we earned our points
		local move_dist = core.fov.distance(ox, oy, x, y)
		eff.ct_to_add = eff.ct_to_add + move_dist
		-- EXCEPT when we're about to act again (no energy used) straight away
		-- The game doesn't do callbackOnAct in that situation, so we we'll...
		-- else
		if not self.energy.used then
			self:callEffect(eff.effect_id, "callbackOnAct")
		end
		self:callEffect(eff.effect_id, "updateValues")
	end,
	callbackOnActBase = function(self, eff)
		self:callEffect(eff.effect_id, "updateValues")
		local stamina = eff.current_stamina
		if stamina > 0 then 
			self:incStamina(stamina)
			game.logPlayer(self, "#GREEN#%s gains %.1f stamina from Spring Attack!#NORMAL#", self.name:capitalize(), eff.current_stamina)
		end
	end,
	callbackOnAct = function(self, eff)
		local dist = getDistToNearestEnemy(self) or 10
		if dist > 1 then
			eff.ct = eff.ct + eff.ct_to_add
		end
		eff.ct_to_add = 0
	end,
	useSavedPoints = function(self, eff)
	end,
	--callbackonCrit is not useful so we handle that in 
	updateValues = function(self, eff)
		local ed = self:getEffectFromId(eff.effect_id)
		eff.current_crit = ed.getCurrentCrit(self, eff) or 99
		eff.current_stamina = ed.getCurrentStamina(self, eff) or 99
	end,
	activate = function(self, eff, ed)
		ed.updateValues(self, eff)
	end,
	deactivate = function(self, eff, ed)
	end,
}

newEffect{
	name = "OUTRIDER_HOWLING_ARROWS", image="talents/wailing_weapon.png",
	desc = "Howling Arrows",
	long_desc = function(self, eff) return ("The target has a %d%% chance to confuse (power %d) with each archery attack."):format(eff.chance, eff.power) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { power=35, chance=25 },
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		self:callTalent(self.T_OUTRIDER_WAILING_WEAPON, "doTryConfuse", target)
	end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_SHRIEKING_STRIKES", image="talents/wailing_weapon.png",
	desc = "Shrieking Strikes",
	long_desc = function(self, eff) return ("The target has a %d%% chance to confuse (power %d) with each melee attack."):format(eff.chance, eff.power) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { power=35, chance=25 },
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		self:callTalent(self.T_OUTRIDER_WAILING_WEAPON, "doTryConfuse", target)
	end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_UNBRIDLED_FEROCITY", image = "talents/unbridled_ferocity.png",
	desc = "Unbridled Ferocity",
	long_desc = function(self, eff) return ("The target is unleashed, gaining a %d bonus to physical power; however, the target cannot be mounted while in this state. Furthermore, when taking damage, the target will not lose Loyalty but will regain it."):format(eff.power) end,
	type = "mental",
	subtype = { focus=true },
	status = "beneficial",
	parameters = { power=8, atk = 4, move=50 },
	on_gain = function(self, err) return "#Target#'s ferocity is unleashed!" end,
	on_lose = function(self, err) return "#Target#' becomes less ferocious." end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "combat_dam", eff.power)
		self:effectTemporaryValue(eff, "combat_atk", eff.atk)
		self:effectTemporaryValue(eff, "movement_speed", eff.move)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_WILD_CHALLENGE", image = "talents/challenge_the_wilds.png",
	desc = "Wild Hunt",
	long_desc = function(self, eff) return ("Slay %d more creatures to find your bestial challenger!"):format(eff.ct) end,
	type = "other",
	subtype = { focus=true },
	decrease = 0, no_remove = true,
	status = "beneficial",
	charges = function(self, eff) return eff.ct>0 and eff.ct or "" end,
	parameters = { ct=15 },
	callbackOnKill = function(self, eff, tgt, death_note)
		if tgt.exp_worth and tgt.exp_worth > 0 then eff.ct=math.max(0, eff.ct-1) end
	end,
	callbackOnWear = function(self, eff)
		local ed = self:getEffectFromId(self.EFF_OUTRIDER_WILD_CHALLENGE)
		ed.checkChanges(self, eff, ed)
	end,
	callbackOnTakeoff = function(self, eff)
		local ed = self:getEffectFromId(self.EFF_OUTRIDER_WILD_CHALLENGE)
		ed.checkChanges(self, eff, ed)
	end,
	checkChanges= function(self, eff, ed)
		local new_val = self.challenge_the_wilds_boost or 0
		if eff.buff~=new_val then
			eff.buff = new_val
			ed.updateValues(self, eff)
		end
	end,
	updateValues = function(self, eff)
		if eff.buff_id then
			self:removeTemporaryValue(eff, "combat_atk", eff.buff_id)
			self:removeTemporaryValue(eff, "combat_dam", eff.buff_id)
			eff.atk_id, eff.dam_id = nil, nil
		end
		if eff.buff and eff.buff>0 then
			eff.atk_id = self:addTemporaryValue("combat_atk", eff.buff)
			eff.dam_id = self:addTemporaryValue("combat_dam", eff.buff)
		end			
	end,
	on_gain = function(self, err) return "#Target#'s wild challenge begins!" end,
	on_lose = function(self, err) return "#Target#' has ended the wild challenge" end,
	activate = function(self, eff)
		eff.buff = self.challenge_the_wilds_boost or 0
		eff.atk_id = self:addTemporaryValue("combat_atk", eff.buff)
		eff.dam_id = self:addTemporaryValue("combat_dam", eff.buff)
	end,
	deactivate = function(self, eff)
		if eff.buff_id then self:removeTemporaryValue("combat_atk", eff.buff_id) end
		if eff.buff_id then self:removeTemporaryValue("combat_dam", eff.buff_id) end
	end,
}

newEffect{
	name = "OUTRIDER_WILD_CHALLENGER", image = "talents/challenge_the_wilds.png",
	desc = "Wild Challenger",
	long_desc = function(self, eff) return ("Beat down to 50%% life points to establish dominance over your mount!"):format(eff.ct) end,
	type = "other",
	subtype = { focus=true },
	decrease = 0, no_remove = true,
	status = "beneficial",
	parameters = {first=true},
	callbackOnTakeDamage = function(self, eff, src, x, y, type, dam, tmp, no_martyr)
		if not eff.first then return end
		if (self.life-dam) < self.max_life*.5 then
			game:onTickEnd(function()
				local src = eff.src
				src:callTalent(src.T_OUTRIDER_CHALLENGE_THE_WILDS, "doBefriendMount", self)
				eff.first = false
				self:removeEffect(self.EFF_OUTRIDER_WILD_CHALLENGER, nil, true)
			end)
		end
	end,
	on_gain = function(self, err) return "#Target# rises to the challenge!" end,
	on_lose = function(self, err) return "#Target#' has been subdued!" end,
	activate = function(self, eff)
		assert(eff.src, "No source sent to Wild Challenger.")
		self:addShaderAura("wild_challenger", "awesomeaura", {time_factor=4000, alpha=0.4,  flame_scale=2}, "particles_images/naturewings.png")
	end,
	deactivate = function(self, eff)
		self:removeShaderAura("wild_challenger")
	end,
}

newEffect{
	name = "OUTRIDER_PINNED_TO_THE_WALL", image = "talents/impalement.png",
	desc = "Pinned to the wall",
	long_desc = function(self, eff) return "The target is pinned to the wall or some other suitable piece of terrain, unable to move. If the terrain is detroyed, the target will be able to move agian." end,
	type = "physical",
	subtype = { pin=true },
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#Target# is pinned to the wall.", "+Pinned" end,
	on_lose = function(self, err) return "#Target# is no longer pinned.", "-Pinned" end,
	activate = function(self, eff)
		if not eff.tile or not eff.tile.x then
			self:removeEffect(self.EFF_OUTRIDER_PINNED_TO_THE_WALL, nil, true)
			error("No terrain tile sent to temporary effect Pinned to the Wall.")
		end
		if not eff.ox or not eff.oy then
			self:removeEffect(self.EFF_OUTRIDER_PINNED_TO_THE_WALL, nil, true)
			error("Original position not sent to temporary effect Pinned to the Wall.")
		end
		eff.tmpid = self:addTemporaryValue("never_move", 1)
	end,
	callbackOnActBase = function(self, eff)
		local ter = game.level.map(eff.tile.x, eff.tile.y, engine.Map.TERRAIN)
		if not ter or not ter.does_block_move or self.x~=eff.ox or self.y~=eff.oy then
			self:removeEffect(self.EFF_OUTRIDER_PINNED_TO_THE_WALL, nil, true)
		end	
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("never_move", eff.tmpid)
	end,
}

newEffect{
	name = "OUTRIDER_UNCANNY_TENACITY", image = "talents/uncannity_tenacity.png",
	desc = "Uncanny Tenacity",
	long_desc = function(self, eff) return ("The wolf gains %d%% to resist all and a %d bonus to attack and physical power. Each turn, its tenacity allows it to overcome 2 turns of a random detrimental effect."):format(eff.res, eff.buff) end,
	type = "physical",
	subtype = { tactic=true, morale=true },
	status = "beneficial",
	parameters = { buff=5, res=5, threshold=25 },
	on_gain = function(self, err) return "#Target#'s tenacity is unleashed!." end,
	on_lose = function(self, err) return "#Target# has become less tenacious." end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "resists", {all=eff.res})
		self:effectTemporaryValue(eff, "combat_atk", eff.buff)
		self:effectTemporaryValue(eff, "combat_dam", eff.buff)
	end,
	callbackOnActBase = function(self, t)
		local filter = {status="detrimental"}
		local list = self:effectsFilter(filter, 1)
		local eff_id = list[1]
		--TODO: is this okay?
		if eff_id then self.tmp[eff_id].dur = self.tmp[eff_id].dur-2 end
	end,
}

newEffect{
	name = "OUTRIDER_FLANKED", image = "talents/flanking.png",
	desc = "Flanked",
	long_desc = function(self, eff) return ("Flanked by the outrider and its allies, the target suffers a defense decrease of %d, a %d%% increase to critical damage and all attackers gain a crit chance bonus of %d%% against it."):format(eff.def, eff.crit_dam, eff.crit) end,
	type = "physical",
	subtype = { tactic=true },
	status = "detrimental",
	parameters = {def=5, crit=7, crit_dam = 10},
	on_gain = function(self, err) return nil, "+Flanked" end,
	on_lose = function(self, err) return nil, "-Flanked" end,
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_OUTRIDER_PREDATORY_FLANKING, nil, true)
			error("No source sent to temporary effect Flanking.")
		end
		if not eff.allies then
			self:removeEffect(self.EFF_OUTRIDER_MOUNT, nil, true)
			error("No allies list sent to temporary effect Flanking.")
		end
		self:effectTemporaryValue(eff, "combat_crit_vulnerable", eff.crit)
		self:effectTemporaryValue(eff, "combat_def", -eff.def)
	end,
	callbackOnActBase = function(self, eff)
		local src = eff.src
		if core.fov.distance(self.x, self.y, src.x, src.y) ~= 1 then self:removeEffect(eff.effect_id) end
		local count = 0 
		for _, ally in ipairs(eff.allies) do
			--Checks to see if adjacent ally is not also adjacent to use,
			if core.fov.distance(self.x, self.y, ally.x, ally.y) == 1 and core.fov.distance(src.x, src.y, ally.x, ally.y) > 1 then
				count = count+1
			end
		end
		if count < 1 then self:removeEffect(eff.effect_id) end
	end,
}


newEffect{
	name = "OUTRIDER_PREDATORY_FLANKING", image = "talents/predatory_flanking.png",
	desc = "Predatory Flanking",
	long_desc = function(self, eff) return ("Flanked by the wolf and its allies, the target suffers %d%% increased damage from the source and %d%% from its flanking allies."):format(eff.src_pct, eff.allies_pct) end,
	type = "physical",
	subtype = { tactic=true },
	status = "detrimental",
	parameters = {src_pct=15, allies_pct = 5},
	on_gain = function(self, err) return nil, "+Flanked" end,
	on_lose = function(self, err) return nil, "-Flanked" end,
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_OUTRIDER_PREDATORY_FLANKING, nil, true)
			error("No source sent to temporary effect Predatory Flanking.")
		end
		if not eff.allies then
			self:removeEffect(self.EFF_OUTRIDER_MOUNT, nil, true)
			error("No allies list sent to temporary effect Predatory Flanking.")
		end
	end,
	callbackOnActBase = function(self, eff)
		local src = eff.src
		if core.fov.distance(self.x, self.y, src.x, src.y) ~= 1 then self:removeEffect(eff.effect_id) end
		local count = 0 
		for _, ally in ipairs(eff.allies) do
			--Checks to see if adjacent ally is not also adjacent to wolf,
			if core.fov.distance(self.x, self.y, ally.x, ally.y) == 1 and core.fov.distance(src.x, src.y, ally.x, ally.y) > 1 then
				count = count+1
			end
		end
		if count < 1 then self:removeEffect(eff.effect_id) end
	end,
}

newEffect{
	name = "OUTRIDER_FETCH", image="talents/fetch.png",
	desc = "Fetch!",
	long_desc = function(self, eff) return ("The wolf, each turn, will drag its grappled target towards its master."):format(eff.chance) end,
	type = "physical",
	subtype = { grapple=true },
	status = "beneficial",
	parameters = {target},
	on_gain = function(self, err) return "#Target# will fetch the target!", "+Fetch" end,
	on_lose = function(self, err) return "#Target# finishes fetching the target", "-Fetch" end,
	callbackOnAct= function(self, eff)
		local stuck = false
		while self:enoughEnergy() and not stuck do
			if eff.target.dead then return true end

			-- apply periodic timer instead of random chance
			local owner, target = self.owner, eff.target
			local cur_dist = core.fov.distance(target.x, target.y, owner.x, owner.y) 
			if not owner or cur_dist <=1 then return end
			self.never_move = self.never_move-1 -- Yeah, I'm a massive hack, so shoot me
			if not self:attr("never_move") then
				local dest_x, dest_y = owner.x, owner.y

				local bestX, bestY
				local bestDistance = cur_dist
				local start = rng.range(0, 8)
				for i = start, start + 8 do
					local dx = (i % 3) - 1
					local dy = math.floor((i % 9) / 3) - 1
					local sx, sy = self.x+dx, self.y+dy
					if sx ~= self.x or sy ~= self.y then
						local tx, ty = target.x+dx, target.y+dy
						-- local distance = core.fov.distance(tx, ty, dest_x, dest_y)
						local distance = math.sqrt(math.abs(dest_x-tx)^2+math.abs(dest_y-ty)^2)
						local can_drag = target:canMove(tx, ty) or (tx==self.x and ty==self.y)
						local can_move = self:canMove(sx, sy) or (sx==target.x and sy==target.y)
						if distance < bestDistance and can_move and can_drag then
							bestDistance = distance
							bestX = sx
							bestY = sy
						end
					end
				end

				if bestX then
					--TODO: Reset player to Outrider if player is controlling wolf - otherwise this will consume 1,000,000,000 turns
					--TODO: We don't allow the player (as wolf) to use this, but THEN we could.
					self:logCombat(owner, "#Source# fetches its target toward #target#")
					local oldx, oldy = self.x, self.y
					self:move(bestX, bestY, false)
					-- print("DEBUG (fetch): Trying to move to "..bestX.." "..bestY)
					if (self.x == oldx) and (self.y == oldy) then stuck = true end
					-- if stuck then print("DEBUG (fetch): Dig not drag.") else print("DEBUG (fetch): Successfully dragged target.") end
				else stuck=true
				end
			self.never_move = self.never_move+1
			else stuck=true
			end
		end
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "never_move", 1)
		checkEffectHasParameter(self, eff, "target")
		if not self.dragged_entities then self.dragged_entities = {} end
		local t, e = self.dragged_entities, eff.target
		t[e] = t[e] and t[e]+1 or 1
	end,
	deactivate = function(self, eff)
		self.dragged_entities[eff.target] = self.dragged_entities[eff.target]-1
		if self.dragged_entities[eff.target] == 0 then self.dragged_entities[eff.target] = nil end
	end,
	on_timeout = function(self, eff)
		local p = eff.target:hasEffect(eff.target.EFF_GRAPPLED)
		if not p or p.src ~= self or core.fov.distance(self.x, self.y, eff.target.x, eff.target.y) > 1 or eff.target.dead or not game.level:hasEntity(eff.target) then
			self:removeEffect(self.EFF_OUTRIDER_FETCH)
		end
	end,
}

local function removeOtherTwinThreatEffects(self, eff)
	self:callTalent(self.T_OUTRIDER_TWIN_THREAT, "removeAllEffects", {[eff.effect_id]=true})
end

newEffect{
	name = "OUTRIDER_TWIN_THREAT_MOUNTED", image = "talents/twin_threat.png",
	desc = "Twin Threat: Mounted",
	long_desc = function(self, eff) return ("Beast and master act in concert. The beast stands a %d%% chance to make a free, instananeous attack for each of the rider's physical critical hits."):format(eff.chance) end,
	type = "other",
	decrease = 0, no_remove = true,
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {chance=15},
	activate = function(self, eff)
		removeOtherTwinThreatEffects(self, eff)
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam)
		if not hitted then return end
		if self:isMounted() and rng.percent(eff.chance) then
			game:onTickEnd(function()
				--If not done on tick end, the free hit impacts before the physical crit actually impacts. This can result in wasted attacks, as well as other weirdness.
				local mount = self:hasMount()
				local tgts={}
				local grids = core.fov.circle_grids(mount.x, mount.y, 1, true)
				for x, ys in pairs(grids) do for y, _ in pairs(ys) do
					local a = game.level.map(x, y, engine.Map.ACTOR)
					if a and self:reactionToward(a) < 0 then
						tgts[#tgts+1] = a
					end
				end end
				local target = rng.table(tgts); if not target then return end
				mount:logCombat(self, "#Source#'s gets a free attack from #target#'s Twin Threat!")
				mount:attackTarget(target, nil, 1, true)
			end)
		end
	end,
}

newEffect{
	name = "OUTRIDER_TWIN_THREAT_ADJACENT", image = "talents/twin_threat.png",
	desc = "Twin Threat: Adjacent",
	long_desc = function(self, eff) return ("Beast and master act in concert, each gaining a %d%% increase to healing modifer and a %d bonus to stamina and loyalty regen."):format(eff.heal, eff.regen) end,
	type = "other",
	decrease = 0, no_remove = true,
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {heal=15, regen = 1},
	activate = function(self, eff)
		removeOtherTwinThreatEffects(self, eff)
		self:effectTemporaryValue(eff, "healing_factor", eff.heal)
		self:effectTemporaryValue(eff, "stamina_regen", eff.regen)
		if not self.rider then self:effectTemporaryValue(eff, "loyalty_regen", eff.regen) end
		local mount = self:hasMount()
		if mount then mount:setEffect(mount.EFF_OUTRIDER_TWIN_THREAT_ADJACENT, 2, {heal=eff.heal}) end
	end,
	deactivate = function(self, eff)
		local pet = self:hasMount()
		if pet then pet:removeEffect(pet.EFF_OUTRIDER_TWIN_THREAT_ADJACENT, true) end
	end,
}

newEffect{
	name = "OUTRIDER_TWIN_THREAT_MID", image = "talents/twin_threat.png",
	desc = "Twin Threat: Mid Range",
	long_desc = function(self, eff) return ("Beast and master act in concert, each gaining a %d%% increase in movement speed and a %d%% cooldown reduction to all Techniques talents."):format(eff.move, eff.cooldown) end,
	type = "other",
	decrease = 0, no_remove = true,
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {move=15, cooldown=5},
	activate = function(self, eff)
		removeOtherTwinThreatEffects(self, eff)
		self:effectTemporaryValue(eff, "movement_speed", eff.move/100)
		for tid, _ in pairs(self.talents) do
			local tt = self:getTalentFromId(tid)
			if tt.type[1]:find("^technique/") then
				local cd = self:getTalentCooldown(tt)
				if cd then self:effectTemporaryValue(eff, "talent_cd_reduction", {[tid] = math.max(1, cd*eff.cooldown/100)}) end
			end
		end
		local mount = self:hasMount()
		if mount then mount:setEffect(mount.EFF_OUTRIDER_TWIN_THREAT_MID, 2, {move=eff.move, cooldown=eff.cooldown}) end
	end,
	deactivate = function(self, eff)
		local pet = self:hasMount()
		if pet then pet:removeEffect(pet.EFF_OUTRIDER_TWIN_THREAT_MID, true) end
	end,
}

newEffect{
	name = "OUTRIDER_TWIN_THREAT_LONG", image = "talents/twin_threat.png",
	desc = "Twin Threat: Long Range",
	long_desc = function(self, eff) return ("Beast and master act in concert. Successful attacks against targets adjacent to the beast will increase its Loyalty to the owner by %d. Also, when the beast reaches %d%% of its life total, the owner receives the ability to hasten to its aid in a heroic dash."):format(eff.regen, eff.life_total) end,
	type = "other",
	decrease = 0, no_remove = true,
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {regen = 1, life_total=10},
	activate = function(self, eff)
		removeOtherTwinThreatEffects(self, eff)	
		local mount = self:hasMount()
		if mount then 
			self:learnTalent(self.T_OUTRIDER_TWIN_THREAT_DASH, true, 1)
			mount:setEffect(mount.EFF_OUTRIDER_TWIN_THREAT_LONG, 2, {move=eff.move, cooldown=eff.cooldown}) end
	end,
	callbackOnArcheryAttack = function(self, eff, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		local mount = self:hasMount()
		if hitted and core.fov.distance(mount.x, mount.y, target.x, target.y) == 1 then
			self:incLoyalty(eff.regen)
		end
	end,
	deactivate = function(self, eff)
		self:unlearnTalent(self.T_OUTRIDER_TWIN_THREAT_DASH)
		local pet = self:hasMount()
		if pet then pet:removeEffect(pet.EFF_OUTRIDER_TWIN_THREAT_LONG, true) end
	end,
}

newEffect{
	name = "OUTRIDER_BEASTMASTER_MARK",  image="talents/beastmasters_mark.png",
	desc = "Beastrider's Mark",
	long_desc = function(self, eff) return ("The beast is filled with a thirst for blood, gaining a %d%% bonus to movement and attack speed, but losing %d%% loyalty each turn it does not move toward or attack %s"):format(eff.target.name) end,
	type = "mental",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { target, speed=1.2, loyalty=5, dissatisfaction=0 },
	activate = function(self, eff)
		checkEffectHasParameter(self, eff, "target")
		self:setTarget(eff.target)
		if not self.owner then self:removeEffect(self.EFF_OUTRIDER_BEASTMASTER_MARK, true) end
		self:effectTemporaryValue(eff, "movement_speed", eff.speed)
		self:effectTemporaryValue(eff, "combat_physspeed", eff.speed)
	end,
	callbackOnAct = function(self, eff)
		if not eff.target or eff.target.dead or not game.level:hasEntity(eff.target) then
			self:removeEffect(self.EFF_OUTRIDER_BEASTMASTER_MARK, true)
		end
		self:setTarget(eff.target)

		eff.old_x, eff.old_y = self.x, self.y
		local target, ox, oy = eff.target, eff.old_x, eff.old_y

		--Are we not getting any closer to the enemy? If so, start to get miffed!
		local cur_dist = core.fov.distance(self.x, self.y, target.x, target.y)
		local o_dist = core.fov.distance(ox, oy, target.x, target.y)

		if cur_dist>1 and (cur_dist >= o_dist or (self.x==ox and self.y==oy)) then
			--This will prompt the AI to bark!
			eff.dissatisfaction = eff.dissatisfaction + 1
		else
			eff.dissatisfaction = 0
		end
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam)
		if target == eff.target then self.turn_procs.beastmaster_mark_loyalty_loss = false end
	end,
	callbackOnMove = function(self, eff, moved, force, ox, oy, x, y)
		if moved then
			local target = eff.target
			local old_dist = core.fov.distance(ox, oy, target.x, target.y)
			local dist = core.fov.distance(self.x, self.y, target.x, target.y)
			if dist < old_dist then 
				self.turn_procs.beastmaster_mark_loyalty_loss = false
			end
		end
	end,
}

newEffect{
	name = "OUTRIDER_VESTIGIAL_MAGICKS", image="talents/vestigial_magicks.png",
	desc = "Vestigial Magicks",
	long_desc = function(self, eff) return ("The spider's residual magic energies have been awoken. Attackers will suffer %d arcane damage."):format(eff.power) end,
	type = "spell",
	subtype = { arcane=true },
	status = "beneficial",
	parameters = { power=20 },
	on_gain = function(self, err) return "The vestigial magicks of #Target# have awoken!", "+Vestigial Magicks" end,
	on_lose = function(self, err) return "#Target#'s vestigial magic energies have subsided", "-Vestigial Magicks" end,
	activate = function(self, eff)
	end,
	callbackOnMeleeHit = function(self, eff, src, dam)
		self:callTalent(self.T_OUTRIDER_VESTIGIAL_MAGICKS, "doDamage", src)
	end,
	callbackOnMeleeMiss = function(self, eff, src, dam)
		self:callTalent(self.T_OUTRIDER_VESTIGIAL_MAGICKS, "doDamage", src)
	end,
}

newEffect{
	name = "OUTRIDER_CATCH", image="talents/catch.png",
	desc = "Catch: Readied!",
	long_desc = function(self, eff) return "The target, having recently slain an adjacent enemy with a critical hit, is ready to hurl its severed remnants back at its foes." end,
	type = "spell",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {},
	on_gain = function(self, err) return "#Target# is ready to use Catch!", "+Catch! (readied)" end,
	on_lose = function(self, err) return "#Target# is no longer ready to use Catch!", "+Catch! (readied)" end,
	activate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_AERIAL_SUPREMACY", image="talents/aerial_supremacy.png",
	desc = "Aerial Supremacy",
	long_desc = function(self, eff) return ("The drake gains a bonus of %d to attack, defense, and physical save."):format(eff.buff) end,
	type = "physical",
	subtype = { charge=true, tactic=true },
	status = "beneficial",
	parameters = { buff=7},
	on_gain = function(self, eff) return "#Target# soars aloft!!", "+Aerial Supremacy" end,
	on_lose = function(self, eff) return "#Target# returns to the ground.", "-Aerial Supremacy" end,
	activate = function(self, eff, p)
		self:effectTemporaryValue(eff, "combat_atk", eff.buff)
		self:effectTemporaryValue(eff, "combat_def", eff.buff)
		self:effectTemporaryValue(eff, "combat_physresist", eff.buff)
	end
}

newEffect{
	name = "OUTRIDER_LOOSE_IN_THE_SADDLE", image="talents/loose_in_the_saddle.png",
	desc = "Loose in the Saddle",
	long_desc = function(self, eff) return ("The rider moves with an additional %d%% movement speed, but any action other than moving, mounting or dismounting will break the effect."):format(eff.speed*100) end,
	type = "physical",
	subtype = { speed=true, tactic=true },
	status = "beneficial",
	parameters = { speed=4},
	on_gain = function(self, eff) return "#Target# shows 'em how to ride loose in the saddle!!", "+Loose In The Saddle" end,
	on_lose = function(self, eff) return "#Target# moves normally", "-Loose In The Saddle" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "movement_speed", eff.speed)
	end,
	callbackOnTalentPost = function(self, t, ab, ret, silent)
		if ab.id == "T_OUTRIDER_DISMOUNT" or ab.id == "T_OUTRIDER_MOUNT" then return end
		if self:hasEffect(self.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE) then
			self:removeEffect(self.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE)
		end
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		if self:hasEffect(self.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE) then
			self:removeEffect(self.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE)
		end
	end,
}

newEffect{
	name = "OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED", image="talents/loose_in_the_saddle.png",
	desc = "Loose in the Saddle",
	long_desc = function(self, eff) return ("The rider moves with an additional %d%% movement speed, but any action other than moving, mounting or dismounting will break the effect."):format(eff.speed) end,
	type = "other",
	no_remove = true,
	decrease = 0,
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { reduction=.35},
	activate = function(self, eff)
	end,
	callbackOnTakeDamage = function(self, eff, src, x, y, type, dam, state)
		local rider = self.rider; if not rider then return end
		local p = rider:isTalentActive(rider.T_OUTRIDER_LOOSE_IN_THE_SADDLE); if not p then return end
		if dam>self.max_life*.15 then
			local t2 = rider:getTalentFromId(rider.T_OUTRIDER_LOOSE_IN_THE_SADDLE)
			dam = dam - dam*p.reduction
			rider:setEffect(rider.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE, 2, {speed=t2.getSpeed(self, t)/100})
			rider:forceUseTalent(rider.T_OUTRIDER_LOOSE_IN_THE_SADDLE, {ignore_energy=true})
		end
		return {dam=dam}
	end,
}

newEffect{
	name = "OUTRIDER_SHOCK_ATTACK", image = "talents/shock_and_awe.png",
	desc = "Shock Attack",
	long_desc = function(self, eff) return ("The rider will knock back 1 square any enemy it targets with a melee attack."):format() end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {speed=0, parry_chance=0},
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "movement_speed", eff.speed)
		self:effectTemporaryValue(eff, "combat_physspeed", eff.speed)
		self:learnTalent(self.T_OUTRIDER_SHOCK_ATTACK_CHARGE, true, 1)
		self.talents_cd[self.T_OUTRIDER_SHOCK_ATTACK_CHARGE] = nil
	end,
	deactivate = function(self, eff)
		self:unlearnTalent(self.T_OUTRIDER_SHOCK_ATTACK_CHARGE)
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam)
		if not self:isMounted() then return end
		if hitted then
			game:onTickEnd(function()
				local ox, oy = target.x, target.y
				target:knockback(self.x, self.y, 1)
				if target.x==ox and target.y==oy then return end
				if self:canMove(ox, oy) then self:move(ox, oy, true) end
			end)
		end
	end,
}

newEffect{
	name = "OUTRIDER_BOND_BEYOND_BLOOD",
	desc = "Bond Beyond Blood", image = "talents/bond_beyond_blood.png",
	long_desc = function(self, eff) return ("Reduces damage received by %d%% while controlling the mount."):format(eff.res, eff.incdur) end,
	type = "other",
	subtype = { focus=true },
	status = "beneficial",
	parameters = { res=10, loyalty_discount=10 },
	activate = function(self, eff)
		local pet = self.outrider_pet
		eff.pet = pet
		if not pet then self:removeEffect(self.EFF_OUTRIDER_BOND_BEYOND_BLOOD) end
		if pet and game.party:hasMember(self) and game.party:hasMember(pet) then
			eff.old_control = game.party.members[pet].control 
			game.party.members[pet].control ="full"
		end
	end,
	deactivate = function(self, eff)
		local pet = eff.pet
		if pet and game.party:hasMember(pet) then
			game.party.members[pet].control=eff.old_control
			if pet.player then
				game.party:setPlayer(self)
			end
		end
	end,
	callbackOnKill = function(self, eff, target, death_note)
		--TODO: Add this callback to the mount, too.
		--The mount will have a whole host of other effects come the redesign, so it's fine to do this later.
		self:logCombat(target, "#Source# extends its Bond Beyond Blood!")
		eff.dur = eff.dur+1
	end,
	callbackOnTakeDamage = function(self, eff, src, x, y, type, dam, state)
		if game.party:hasMember(self) and eff.pet.player then
			dam = dam - dam*eff.res/100
			return {dam=dam}
		end
	end,
}

newEffect{
	name = "OUTRIDER_FETCH_VULNERABLE", image = "talents/backlash.png",
	desc = "Vulnerable (Fetch)",
	long_desc = function(self, eff) return ("When the wolf's owner next strikes this target with a weapon attack, it gains a %d%% bonus to damage."):format(eff.pct) end,
	type = "physical",
	subtype = { focus=true, trgt},
	status = "detrimental",
	parameters = { pct=110, src },
	on_gain = function(self, eff) return ("#Target#'s is vulnerable to %s's next strike"):format(eff.src.name), "+Vulnerable" end,
	-- on_lose = function(self, eff) return ("#Target#' completes the strike") end,
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_OUTRIDER_FETCH_VULNERABLE, nil, true)
			error("No source sent to temporary effect Vulnerable (Fetch).")
		end
	end,
	callbackOnTakeDamage = function(self, eff, src, x, y, type, dam, state)
		if eff.src == src and core.fov.distance(self.x, self.y, src.x, src.y) == 1 then
			dam = dam * eff.pct/100
			if not self.turn_procs.handled_fetch_vulnerable then
				game:onTickEnd(function()
					self:removeEffect(self.EFF_OUTRIDER_FETCH_VULNERABLE)
				end)
				self.turn_procs.handled_fetch_vulnerable= true
			end
		end
		return {dam=dam}
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_PROVOKED", --image = "talents/backlash.png",
	desc = "Provoked",
	long_desc = function(self, eff) return ("Damage is increased by %d%%, but all damage resistances are decreased by %d%%"):format(eff.boost, eff.red) end,
	type = "mental",
	subtype = { tactic=true, morale=true },
	status = "detrimental",
	parameters = { buff=20, dam=25, red=10 },
	on_gain = function(self, eff) return "#Target#' is provoked!", "+Provoked" end,
	on_lose = function(self, eff) return "#Target#' is no longer provoked!", "-Provoked" end,
	on_timeout = function(self, eff)
		self:setTarget(eff.src)
	end,
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_OUTRIDER_PROVOKED)
			error("No source sent to temporary effect Provoked.")
		end
		self:setTarget(eff.src)
		self:effectTemporaryValue(eff, "inc_damage", {all=eff.buff})
		self:effectTemporaryValue(eff, "resists", {all=-eff.dam})
		self:effectTemporaryValue(eff, "combat_armor", -eff.red)
		self:effectTemporaryValue(eff, "combat_def", -eff.red)
	end,
}

newEffect{
	name = "OUTRIDER_SET_LOOSE", image = "talents/let_em_loose.png",
	desc = "Set Loose",
	long_desc = function(self, eff) return ("The beast has been emboldened by the charge, gaining a damage bonus of %d%% and a bonus of %d to defense and all saves."):format(eff.dam, eff.def) end,
	type = "physical",
	subtype = { tactic=true, morale=true },
	status = "beneficial",
	parameters = { dam=10, evade=10, def=8 },
	on_gain = function(self, eff) return "#Target#' is set loose!", "+Set Loose" end,
	on_lose = function(self, eff) return "#Target#' is no longer set loose!", "-Set Loose" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "inc_damage", {all=eff.dam})
		self:effectTemporaryValue(eff, "evasion", eff.evade)
		-- self:effectTemporaryValue(eff, "combat_def", eff.def)
		self:effectTemporaryValue(eff, "combat_physresist", eff.def)
		self:effectTemporaryValue(eff, "combat_spellresist", eff.def)
		self:effectTemporaryValue(eff, "combat_mentalresist", eff.def)
	end,
}

newEffect{
	name = "OUTRIDER_SILENT_KILLER", --image = "effects/madness_stunned.png",
	desc = "Silent Killer",
	long_desc = function(self, eff) return ("The spider is stealthed (power %d) and benefits from a passive crit bonus while stealthed of %d%%"):format() end,
	type = "physical",
	subtype = { morale=true }, --TODO: Better, extant subtypes
	status = "beneficial",
	parameters = {stealth=10, crit=0},
	on_gain = function(self, err) return "#Target# stalks the shadows!", "+Silent Killer" end,
	on_lose = function(self, err) return "#Target# exits the shadows.", "-Silent Killer" end,
	activate = function(self, eff)
		if not self.break_with_stealth then self.break_with_stealth = {} end
		table.insert(self.break_with_stealth, eff.effect_id)

		self:effectTemporaryValue(eff, "stealth", eff.stealth)
		self:effectTemporaryValue(eff, "lite", -1000)
		self:effectTemporaryValue(eff, "infravision", 1)

		self:resetCanSeeCacheOf()
		if self.updateMainShader then self:updateMainShader() end
	end,
	deactivate = function(self, eff)
		table.removeFromList(self.break_with_stealth, eff.effect_id)

		self:resetCanSeeCacheOf()
		if self.updateMainShader then self:updateMainShader() end
	end,
}

newEffect{
	name = "OUTRIDER_GIBLETS", image = "talents/giblets.png",
	desc = "Gory Trophy",
	display_desc = function(self, eff) 
		if eff.giblets_name then
			return "Gory Trophy: "..eff.giblets_name:capitalize()
		else
			return "Gory Trophy"
		end
	end,
	long_desc = function(self, eff) return ("You've got %s %s! That's absolutely disgusting. But oh, what to do with it?"):format(eff.indefinite_article_form, eff.giblets_name) end,
	-- old_desc = function(self, eff) return ("The Outrider retains a %s in inventory, a cruel trophy of %s's vivisection"):format(eff.giblets_name, eff.src) end,
	type = "other",
	cancel_on_level_change = true,
	subtype = { miscellaneous = true },
	status = "beneficial",
	parameters = { src=nil, giblets_name="hunk of gore", indefinite_article_form="a", did_kill=false },
	-- on_gain = function(self, err) return "#Target# indulges in a very strange collecting hobby.", "+Giblets" end,
	-- on_lose = function(self, err) return "#Target# contemplates a more wholesome hobby, like embroidery.", "-Giblets" end,
	activate = function(self, eff)
		if not eff.src then self:removeEffect(eff.effect_id) return end

		-- @todo Create the giblets icons
		local bits = did_kill and {
			{"%s heart", "a", "talents/giblets.png"},
			{"%s intestines", "some", "talents/giblets.png"},
			{"%s lungs", "some", "talents/giblets.png"},
			{"%s torso", "half a", "talents/giblets.png"},
		} or {
			{"%s ear", "a", "talents/giblets.png"},
			{"%s finger", "a", "talents/giblets.png"},
			{"chunk of %s gore", "a", "talents/giblets.png"},
			{"scrap of %s flesh", "a", "talents/giblets.png"},
			{"%s giblets", "some", "talents/giblets.png"},
		}

		local desc = rng.table(bits)

		--This is some powerful procedural generation going on here!
		local name = eff.src.name
		if eff.src.unique then name = name.."'s" end
		
		eff.giblets_name = (desc[1]):format(eff.src.name)
		--Do we have a giblet or some giblets?
		eff.indefinite_article_form = desc[2]
		eff.image_variant = desc[3]

		util.hotkeySwapOnLearn(
			self, "T_OUTRIDER_GORY_SPECTACLE", "T_OUTRIDER_GIBLETS",
			function()
				self:learnTalent(self.T_OUTRIDER_GIBLETS, true, 1, {no_unlearn=true})
			end
		)
	end,
	deactivate = function(self, eff)
		util.hotkeySwap(self, "T_OUTRIDER_GIBLETS", "T_OUTRIDER_GORY_SPECTACLE")
		self:unlearnTalent(self.T_OUTRIDER_GIBLETS, 1, nil, {no_unlearn=true})
	end,
}

newEffect{
	name = "OUTRIDER_ALL_OUT_ATTACK", image = "talents/feigned_retreat.png",
	desc = "All-Out Attack!",
	long_desc = function(self, eff) return ("After an all-out retreat, %s deals %d%% additional damage!"):format(self.name, eff.dam_pct) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { dam=1.1, dam_pct=10 },
	on_gain = function(self, err) return "#Target# suddenly returns to the attack." end,
	on_lose = function(self, err) return "#Target#'s bonus damage ends." end,
	activate = function(self, eff)
		eff.dam_pct = (eff.dam-1) * 100
		self:effectTemporaryValue(eff, "inc_damage", {all=eff.dam_pct})
	end,

	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_FEIGNED_RETREAT", image="talents/feigned_retreat.png",
	desc = "Feigned Retreat",
	long_desc = function(self, eff)
		local his_her = string.his_her(self)
		return ("The fighter has executed a feigned retreat against %s and deals %d%% damage in %s first %d attacks after re-initiating combat. If the target is not slain by the user, it will instead take %d more enemy kills to recharge Feigned Retreat."):
		format(eff.target_name, eff.dam*100, his_her, eff.attacks_no, eff.ct)
	end,
	parameters = {target, target_name="the victim", dam=1.1, attacks_no=1, ct=30},
	charges = function(self, eff) return eff.ct end,
	type = "other",
	subtype = { miscellaneous=true },
	status = "beneficial",
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	callbackOnKill = function(self, eff, victim, death_note)
		--@todo: Make this more verbose in the game log?
		if victim == eff.target then
			self:removeEffect(eff.effect_id, false, true)
		else
			eff.ct = eff.ct-1
			if eff.ct <= 0 then self:removeEffect(eff.effect_id, false, true) end
		end
	end,
	-----------------------------------------------------------
	--Main effect functionality.
	--TODO: I need to re-work this to trigger /before/ the hit damage is calculated!
	doOnAttack = function(self, eff, target)
		if not eff.attack_done and target == eff.target then
			if not target:hasEffect(target.EFF_OUTRIDER_FEIGNED_RETREAT_TARGET) then return end
			self:setEffect(self.EFF_OUTRIDER_ALL_OUT_ATTACK, eff.attacks_no+1, {attacks_no=eff.attacks_no, dam=eff.dam})
			target:removeEffect(target.EFF_OUTRIDER_FEIGNED_RETREAT_TARGET)
		end
		eff.attack_done = true
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam, hd)
		if not eff.attack_done then self:callEffect(self.EFF_OUTRIDER_FEIGNED_RETREAT, "doOnAttack", target) end
	end,
	callbackOnArcheryAttack = function(self, eff, target, hitted, crit, weapon, ammo, damtype, mult, dam, talent)
		if not eff.attack_done then self:callEffect(self.EFF_OUTRIDER_FEIGNED_RETREAT, "doOnAttack", target) end
	end,
	-----------------------------------------------------------
	activate = function(self, eff)
		assert(eff.target, "No target sent to effect EFF_OUTRIDER_FEIGNED_RETREAT.")
		eff.target_name = eff.target.name --In case it dies, disappears or horribly mutates
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_FEIGNED_RETREAT_TARGET", image="talents/feigned_retreat.png",
	desc = "Feigned Reteat (Target)",
	long_desc = function(self, eff)
		local his_her = string.his_her(eff.src)
		local attacks = eff.src_attacks_no > 1 and "attacks" or "attack"
		return ("%d has used Feigned Retreat on the target and "..his_her.." next %s "..attacks.." will deal %d%% damage. Only killing %d or leaving the level will remove this mark." ):
		format(eff.src, eff.src_attacks_no, eff.scr_dam, eff.src)
	end,
	parameters = {src, src_dam=1.1},
	type = "other",
	subtype = { miscellaneous=true },
	status = "detrimental",
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	callbackOnChangeLevel = function(self, eff)
		self:removeEffect(self[eff.eff_id], false, true)
	end,
	callbackOnActBase = function(self, eff)
		local src = eff.src
		if not src or src.dead or not game.level:hasEntity(src) then
			self:removeEffect(self.EFF_OUTRIDER_FEIGNED_RETREAT_TARGET, false, true)
		end
	end,
	activate = function(self, eff)
		assert(eff.src, "No source sent to effect EFF_OUTRIDER_FEIGNED_RETREAT.")
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_SPRING_ATTACK_TARGET", image="talents/spring_attack.png",
	desc = "Feigned Reteat (Target)",
	long_desc = function(self, eff)
		local his_her = string.his_her(eff.src)
		local attacks = eff.src_attacks_no > 1 and "attacks" or "attack"
		return ("%d has used Spring Attack on the target and "..his_her.." attacks will deal an extra %d%% damage. Only killing %d or leaving the level will remove this effect." ):
		format(eff.src, eff.scr_dam, eff.src)
	end,
	parameters = {src, src_dam=1.1},
	type = "other",
	subtype = { miscellaneous=true },
	status = "detrimental",
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	callbackOnChangeLevel = function(self, eff)
		self:removeEffect(self[eff.eff_id], false, true)
	end,
	callbackOnActBase = function(self, eff)
		local src = eff.src
		local src_eff = src and src:hasEffect(src.EFF_OUTRIDER_SPRING_ATTACK) 
		if not src or src.dead or not game.level:hasEntity(src) or not (src_eff and src_eff.target==self) then
			self:removeEffect(self.EFF_OUTRIDER_SPRING_ATTACK_TARGET, false, true)
			return
		end
	end,
	activate = function(self, eff)
		-- self:effectParticles(eff, type = "spring_attack", args = {})
		-- eff.particle = self:addParticles(Particles.new("spring_attack", 1, {
		-- 	base_size = 0.5,
		-- }))
		assert(eff.src, "No source sent to effect EFF_OUTRIDER_FEIGNED_RETREAT.")
		eff.particle = self:addParticles(Particles.new("circle", 1, {base_rot=1, oversize=1, a=200, appear=12, speed=0, img="spring_attack", radius=0}))
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "OUTRIDER_LIVING_SHIELD_BLOCKING", image = "talents/block.png",
	desc = "Blocking (with Living Shield",
	long_desc = function(self, eff) return ("Negates the next attack of damage over %d, redirecting it to your target and swapping places with it."):format(eff.min_incoming) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { min_incoming=50, pct=50 },
	on_gain = function(self, eff) return nil, nil end,
	on_lose = function(self, eff) return nil, nil end,
	callbackOnTakeDamage = function(self, eff, src, x, y, type, dam, state)
		if dam>eff.min_incoming then
			local target = eff.target
			self:project({type="hit"}, target.x, target.y, type, dam*eff.power/100)
			-- Do the swap, trying my best to do it as safely as I can
			self.x, self.y, target.x, target.y = target.x, target.y, self.x, self.y
			self:move(self.x, self.y, true)
			target:move(target.x, target.y, true)
		end
		return {dam=dam*(1-eff.power/100)}
	end,
	activate = function(self, eff)
		self:effectParticles(eff, {type="block"})
	end,
	deactivate = function(self, eff)
	end,
}