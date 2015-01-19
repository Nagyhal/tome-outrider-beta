--Effects for basic mount functionality
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
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	parameters = {mount},
	on_timeout = function(self, eff)
		if not eff.mount or eff.mount.dead or not eff.mount:hasEffect(eff.mount.EFF_RIDDEN) then
			self:removeEffect(self.EFF_MOUNT, false, true)
		end
	end,
	activate = function(self, eff)
		if not eff.mount then
			self:removeEffect(self.EFF_MOUNT, nil, true)
			error("No mount sent to temporary effect Mounted.")
		end
	end,
	deactivate = function(self, eff)
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
	decrease = 0, no_remove=true,
	no_stop_enter_worldmap = true, no_stop_resting = true,
	parameters = {rider},
	activate = function(self, eff)
		if not eff.rider then
			self:removeEffect(self.EFF_RIDDEN, nil, true)
			error("No rider sent to temporary effect Ridden.")
		end
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

newEffect{
	name = "LIVING_SHIELD",
	desc = "Used as a Living Shield",
	long_desc = function(self, eff) return ("The target is being used as a living shield! %d%% chance to displace damage onto the target's manhandler."):format(eff.pct) end,
	type = "physical",
	subtype = { grapple=true },
	status = "detrimental",
	parameters = { pct = 25, src},
	on_gain = function(self, err) return "#Target# is being used as a living shield!", "+Living Shield" end,
	on_lose = function(self, err) return "#Target# is no longer a living shield", "-Living Shield" end,
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_MOUNT, nil, true)
			error("No mount sent to temporary effect Mounted.")
		end
	end,
	deactivate = function(self, eff) end,
	do_onTakeHit = function(self, eff, dam) end,
	on_timeout = function(self, eff) end,
}

newEffect{
	name = "LIVING_SHIELDED",
	desc = "Living Shield",
	display_desc = function(self, eff) return ("Living Shield: %s"):format(string.bookCapitalize(eff.trgt.name)) end,
	long_desc = function(self, eff) return ("The target grips its victim and enjoys a %d%% chance to displace damage onto it."):format(eff.pct) end,
	type = "physical",
	subtype = { grapple=true },
	status = "beneficial",
	parameters = { pct = 25, trgt = nil},
	on_gain = function(self, err) return "#Target# is defended by the living shield!", "+Shielded" end,
	on_lose = function(self, err) return "#Target# no longer has a living shield", "-Shielded" end,
	activate = function(self, eff)
		if not eff.trgt then
			self:removeEffect(self.EFF_LIVING_SHIELDED, nil, true)
			error("No target sent to temporary effect Shield: Living Shield.")
		end
	end,
	deactivate = function(self, eff) end,
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
		self:effectTemporaryValue(eff, "never_move", 1)
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
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_DRAGGED, nil, true)
			error("No source sent to temporary effect Dragged.")
		end
	end,
	deactivate = function(self, eff) end,
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
		if eff.dur <= 0 then
			local p = eff.trgt:hasEffect(eff.trgt.EFF_DRAGGED)
			if p then eff.tgrt:removeEffect(eff.trgt.EFF_DRAGGED) end
		end
	end,
	do_onTakeHit = function(self, eff, dam) end,
	on_timeout = function(self, eff)
		local p = eff.trgt:hasEffect(eff.trgt.EFF_DRAGGED)
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
		return ("The target's charge emboldens it, granting %d%% movement speed, %d accuracy, %d%% critical chance and %d defense until the next attack."):format(eff.move, eff.atk, eff.crit, eff.def) end,
	type = "physical",
	subtype = { charge=true, tactic=true, speed=true },
	status = "beneficial",
	parameters = { ct=1, move=5, atk=3, crit=3, def=3, sunder=0},
	charges = function(self, eff) return eff.ct end,
	--TODO: As you can use this with archers, the terminology "charge" isn't really appropriate
	on_gain = function(self, eff) return "#Target# prepares a deadly charge!", "+Strike at the Heart" end,
	on_lose = function(self, eff) return "#Target# ends the charge.", "-Strike at the Heart" end,
	activate = function(self, eff, p)
		eff.targets={}
		self:effectTemporaryValue(eff, "movement_speed", eff.move/100)
		self:effectTemporaryValue(eff, "combat_def", eff.def)
		self:effectTemporaryValue(eff, "combat_atk", eff.atk)
		self:effectTemporaryValue(eff, "combat_physcrit", eff.crit)
		-- p = self:getEffectFromId(self.EFF_STRIKE_AT_THE_HEART)
		p.doStoreBonuses(self, eff)
	end,
	updateValues = function(self, eff)
		for i = 1, #eff.__tmpvals do
			self:removeTemporaryValue(eff.__tmpvals[i][1], eff.__tmpvals[i][2])
		end
		self:effectTemporaryValue(eff, "movement_speed", eff.move/100)
		self:effectTemporaryValue(eff, "combat_def", eff.def)
		self:effectTemporaryValue(eff, "combat_atk", eff.atk)
		self:effectTemporaryValue(eff, "combat_physcrit", eff.crit)
	end,
	doStoreBonuses = function(self, eff)
		local p = self:hasEffect(self.EFF_SPRING_ATTACK)
		if p then
			eff.move = math.max(0, eff.move - p.move)
			eff.def = math.max(0, eff.def - p.def)
			eff.store={def=math.min(p.def, eff.def), move=math.min(p.move, eff.move)}
		end
		p = self:getEffectFromId(self.EFF_STRIKE_AT_THE_HEART)
		p.updateValues(self, eff)
	end,
	doUnstoreBonuses = function(self, eff)
		if eff.store then
			eff.move = eff.move + eff.store.move
			eff.def = eff.def + eff.store.def
			eff.store=nil
			local p = self:getEffectFromId(self.EFF_STRIKE_AT_THE_HEART)
			p.updateValues(self, eff)
		end
	end,
	on_merge = function(self, old_eff, new_eff, p)
		new_eff.targets=old_eff.targets
		self:removeEffect(self.EFF_STRIKE_AT_THE_HEART, true, true)
		-- local p = self:getEffectFromId(self.EFF_STRIKE_AT_THE_HEART)
		p.activate(self, new_eff, p)
		return new_eff
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam)
		if target then eff.targets[target] = hitted and true or false end
		game:onTickEnd(function() 
			local p = self:getEffectFromId(self.EFF_STRIKE_AT_THE_HEART)
			if eff.store then p.doUnstoreBonuses(self, eff) end
			if eff.sunder>0 then
				for a, hitted in pairs(eff.targets) do
					if hitted then
						target:setEffect(target.EFF_SUNDER_ARMOUR, 3, {power=eff.sunder, apply_power=self:combatPhysicalpower()})
					end
				end
			end
			self:removeEffect(self.EFF_STRIKE_AT_THE_HEART)
		end)
	end,
	callbackOnArcheryAttack = function(self, eff, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		if target then eff.targets[target] = true end
		game:onTickEnd(function() self:removeEffect(self.EFF_STRIKE_AT_THE_HEART) end)
	end,
	deactivate = function(self, eff, p)
		local ct = eff.ct
		if self:knowTalent(self.T_SPRING_ATTACK) and #table.keys(eff.targets)>0 then
			local t = self:getTalentFromId(self.T_SPRING_ATTACK)
			--Can't do callEffect in deactivate function
			-- local p = self:getEffectFromId(self.EFF_STRIKE_AT_THE_HEART)
			p.doUnstoreBonuses(self, eff)
			self:setEffect(self.EFF_SPRING_ATTACK, t.getDur(self,t), {
				move = eff.move*ct,
				def = eff.def*ct,
				min_pct = t.getMinPct(self, t),
				max_pct = t.getMaxPct(self, t)
				})
		end
		--TODO: Decide how to pass a target
	end,
}

newEffect{
	name = "SPRING_ATTACK",
	desc = "Spring Attack",
	long_desc = function(self, eff) return ("The target's onslaught has ended, but it retains a bonus of %d%% to movement speed and %d to defense. Also, the target gains a bonus to ranged damage against any marked targets for the duration. This bonus is dependent on distance: starting from %d%% at 2 tiles, increasing to %d%% at 5 tiles."):format(eff.move, eff.def, eff.min_pct, eff.max_pct) end,
	type = "physical",
	subtype = { tactic=true, speed=true },
	status = "beneficial",
	parameters = { move=10, def=6, min_pct=5, max_pct=15},
	on_gain = function(self, eff) return "#Target# enters into a spring attack!", "+Spring Attack" end,
	on_lose = function(self, eff) return "#Target#'s spring attack has ended.", "-Spring Attack" end,
	--callbackonDealDamage is not useful so we handle the damage increment in load.lua's DamageProjector:base hook
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "movement_speed", eff.move/100)
		self:effectTemporaryValue(eff, "combat_def", eff.def)
	end,
	deactivate = function(self, eff)
		if self:hasEffect(self.EFF_STRIKE_AT_THE_HEART) then
			self:callEffect(self.EFF_STRIKE_AT_THE_HEART, "doUnstoreBonuses")
		end
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

newEffect{
	name = "UNBRIDLED_FEROCITY", image = "talents/willful_combat.png",
	desc = "Unbridled Ferocity",
	long_desc = function(self, eff) return ("The target is unleashed, gaining a %d bonus to physical power; however, the target cannot be mounted while in this state. Furthermore, when taking damage, the target will not lose Loyalty but will regain it."):format(eff.power) end,
	type = "mental",
	subtype = { focus=true },
	status = "beneficial",
	parameters = { power=8 },
	on_gain = function(self, err) return "#Target#'s ferocity is unleashed!" end,
	on_lose = function(self, err) return "#Target#' becomes less ferocious." end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "combat_dam", eff.power)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "WILD_CHALLENGE", image = "talents/challenge_the_wilds.png",
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
	on_gain = function(self, err) return "#Target#'s wild challenge begins!" end,
	on_lose = function(self, err) return "#Target#' has ended the wild challenge" end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "WILD_CHALLENGER", image = "talents/challenge_the_wilds.png",
	desc = "Wild Challenger",
	long_desc = function(self, eff) return ("Beat down to 50%% life points to establish dominance over your mount!"):format(eff.ct) end,
	type = "other",
	subtype = { focus=true },
	decrease = 0, no_remove = true,
	status = "beneficial",
	parameters = {},
	callbackOnTakeDamage = function(self, eff, src, x, y, type, dam, tmp, no_martyr)
		if (self.life-dam) < self.max_life*.5 then
			game:onTickEnd(function()
				local src = eff.src
				src:callTalent(src.T_CHALLENGE_THE_WILDS, "doBefriendMount", self)
			end)
			self:removeEffect(self.EFF_WILD_CHALLENGER, nil, true)
		end
	end,
	on_gain = function(self, err) return "#Target# rises to the challenge!" end,
	on_lose = function(self, err) return "#Target#' has been subdued!" end,
	activate = function(self, eff)
		assert(eff.src, "No source sent to Wild Challenger.")
		self:addShaderAura("wild_challenger", "awesomeaura", {time_factor=4000, alpha=0.6,  flame_scale=2}, "particles_images/naturewings.png")
	end,
	deactivate = function(self, eff)
		self:removeShaderAura("wild_challenger")
	end,
}

newEffect{
	name = "PINNED_TO_THE_WALL", image = "effects/pinned.png",
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
			self:removeEffect(self.EFF_PINNED_TO_THE_WALL, nil, true)
			error("No terrain tile sent to temporary effect Pinned to the Wall.")
		end
		if not eff.ox or not eff.oy then
			self:removeEffect(self.EFF_PINNED_TO_THE_WALL, nil, true)
			error("Original position not sent to temporary effect Pinned to the Wall.")
		end
		eff.tmpid = self:addTemporaryValue("never_move", 1)
	end,
	callbackOnActBase = function(self, eff)
		local ter = game.level.map(eff.tile.x, eff.tile.y, engine.Map.TERRAIN)
		if not ter or not ter.does_block_move or self.x~=eff.ox or self.y~=eff.oy then
			self:removeEffect(self.EFF_PINNED_TO_THE_WALL, nil, true)
		end	
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("never_move", eff.tmpid)
	end,
}