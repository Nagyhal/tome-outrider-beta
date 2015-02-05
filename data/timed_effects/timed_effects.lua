function checkEffectHasParameter(self, eff, name)
	if not eff[name] then
		local id = eff.effect_id
		self:removeEffect(id, nil, true)
		error("No parameter %s sent to temporary effect %s."):format(name, id)
	end
end

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
	long_desc = function(self, eff) return ("The target is being used as a living shield, reducing defense by %d. The target's manhandler will have a %d%% chance to redirect attacks onto it!"):format(eff.def, eff.pct) end,
	type = "physical",
	subtype = { grapple=true },
	status = "detrimental",
	parameters = { pct = 25, def=5, src},
	on_gain = function(self, err) return "#Target# is being used as a living shield!", "+Living Shield" end,
	on_lose = function(self, err) return "#Target# is no longer a living shield", "-Living Shield" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "combat_def", -eff.def)
		if not eff.src then
			self:removeEffect(self.EFF_LIVING_SHIELD)
			error("No source sent to temporary effect Used as a Living Shield.")
		end
	end,
	deactivate = function(self, eff)
		eff.src:removeEffect(eff.src.EFF_LIVING_SHIELDED)
	 end,
	do_onTakeHit = function(self, eff, dam) end,
	on_timeout = function(self, eff) end,
}

newEffect{
	name = "LIVING_SHIELDED",
	desc = "Living Shield",
	display_desc = function(self, eff) return ("Living Shield: %s"):format(string.bookCapitalize(eff.trgt.name)) end,
	long_desc = function(self, eff) return ("The target grips its victim and enjoys a %d%% chance to displace damage onto it."):format(eff.chance) end,
	type = "physical",
	subtype = { grapple=true },
	status = "beneficial",
	parameters = { chance=25, trgt},
	on_gain = function(self, err) return "#Target# is defended by the living shield!", "+Shielded" end,
	on_lose = function(self, err) return "#Target# no longer has a living shield", "-Shielded" end,
	activate = function(self, eff)
		if not eff.trgt then
			self:removeEffect(self.EFF_LIVING_SHIELDED, nil, true)
			error("No target sent to temporary effect Shield: Living Shield.")
		end
		if not self.dragged_entities then self.dragged_entities = {} end
		local t, e = self.dragged_entities, eff.trgt
		t[e] = t[e] and t[e]+1 or 1
	end,
	deactivate = function(self, eff)
		self.dragged_entities[eff.trgt] = self.dragged_entities[eff.trgt]-1
		if self.dragged_entities[eff.trgt] == 0 then self.dragged_entities[eff.trgt] = nil end
		eff.trgt:removeEffect(eff.trgt.EFF_LIVING_SHIELD)
	end,
	on_timeout = function(self, eff)
		local p = eff.trgt:hasEffect(eff.trgt.EFF_GRAPPLED)
		if not p or p.src ~= self or core.fov.distance(self.x, self.y, eff.trgt.x, eff.trgt.y) > 1 or eff.trgt.dead or not game.level:hasEntity(eff.trgt) then
			self:removeEffect(self.EFF_LIVING_SHIELDED)
		end
	end,
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
		self:addShaderAura("wild_challenger", "awesomeaura", {time_factor=4000, alpha=0.4,  flame_scale=2}, "particles_images/naturewings.png")
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

newEffect{
	name = "UNCANNY_TENACITY", image = "talents/thaloren_wrath.png",
	desc = "Uncanny Tenacity",
	long_desc = function(self, eff) return ("The wolf gains a %d bonus to saves and a %d%% bonus to resist all, so long as it starts its turn next to an enemy at less than %d%% of its max health."):format(eff.saves, eff.res, eff.threshold) end,
	type = "physical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { saves=10, res=5, threshold=25 },
	on_gain = function(self, err) return "#Target#'s tenacity is unleashed!." end,
	on_lose = function(self, err) return "#Target# has become less tenacious." end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "combat_physresist", eff.saves)
		self:effectTemporaryValue(eff, "combat_spellresist", eff.saves)
		self:effectTemporaryValue(eff, "combat_mindresist", eff.saves)
		self:effectTemporaryValue(eff, "resists", {all=eff.power})
	end,
}

newEffect{
	name = "PREDATORY_FLANKING",
	desc = "Predatory Flanking", image = "talents/precise_strikes.png",
	long_desc = function(self, eff) return ("Flanked by the wolf and its allies, the target suffers %d%% increased damage from the source and %d%% from its flanking allies.") end,
	type = "physical",
	subtype = { tactic=true },
	status = "detrimental",
	parameters = {src_pct=15, allies_pct = 5},
	on_gain = function(self, err) return nil, "+Flanked" end,
	on_lose = function(self, err) return nil, "-Flanked" end,
	activate = function(self, eff)
		if not eff.src then
			self:removeEffect(self.EFF_PREDATORY_FLANKING, nil, true)
			error("No source sent to temporary effect Predatory Flanking.")
		end
		if not eff.allies then
			self:removeEffect(self.EFF_MOUNT, nil, true)
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
	name = "FETCH",
	desc = "Fetch!",
	long_desc = function(self, eff) return ("The wolf, each turn, will drag its grappled target towards its master."):format(eff.chance) end,
	type = "physical",
	subtype = { grapple=true },
	status = "beneficial",
	parameters = {target},
	on_gain = function(self, err) return "#Target# will fetch the target!", "+Fetch" end,
	on_lose = function(self, err) return "#Target# finishes fetching the target", "-Fetch" end,
	callbackOnAct= function(self, eff)
		while self:enoughEnergy() do
			if eff.target.dead then return true end

			-- apply periodic timer instead of random chance
			local owner = self.owner
			local cur_dist = core.fov.distance(eff.target.x, eff.target.y, owner.x, owner.y) 
			if not owner or cur_dist <=1 then return end
			if not self:attr("never_move") then
				local targetX, targetY = owner.x, owner.y

				local bestX, bestY
				local bestDistance = cur_dist
				local start = rng.range(0, 8)
				for i = start, start + 8 do
					local dx = (i % 3) - 1
					local dy = math.floor((i % 9) / 3) - 1
					local x, y = self.x+dx, self.y+dy
					if x ~= self.x or y ~= self.y then
						local tx, ty = eff.target.x+dx, eff.target.y+dy
						local distance = core.fov.distance(tx, ty, targetX, targetY)
						local a = game.level.map(x, y, engine.Map.ACTOR)
						local can_drag = (not game.level.map:checkAllEntities(tx, ty, "block_move", self)) or (tx==self.x and ty==self.y)
						if distance < bestDistance
								and game.level.map:isBound(x, y) --TODO: In theory, you could drag enemies off the map. However, because the player isn't ever likely to be n that direction, this may not happen. Still, it could be cleaner.
								and ((not game.level.map:checkAllEntities(x, y, "block_move", self) and not a) or (a and a==eff.target and can_drag)) then
							bestDistance = distance
							bestX = x
							bestY = y
							game.log("DEBUG: Moving with dx %d and dy %d, distance=%d; cur_dist=%d", dx, dy, distance, cur_dist)
						end
					end
				end

				if bestX then
					--TODO: Reset player to Outrider if player is controlling wolf - otherwise this will consume 1,000,000,000 turns
					--TODO: We don't allow the player to use this, but THEN we could.
					game.logPlayer(self, "#F53CBE#You fetch your target toward %s.", owner.name)
					self:move(bestX, bestY, false)
				end
			end
		end
	end,
	activate = function(self, eff)
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
			self:removeEffect(self.EFF_FETCH)
		end
	end,
}

local function removeOtherTwinThreatEffects(self, eff)
	self:callTalent(self.T_TWIN_THREAT, "removeAllEffects", {[eff.effect_id]=true})
end

newEffect{
	name = "TWIN_THREAT_MOUNTED",
	desc = "Twin Threat: Mounted", image = "talents/together_forever.png",
	long_desc = function(self, eff) return ("Beast and master act in concert. The beast stands a %d%% chance to make a free, instananeous attack for each of the rider's physical critical hits."):format(eff.chance) end,
	type = "other",
	decrease = 0, no_remove = true,
	subtype = { tactic=true },
	status = "beneficial",
	parameters = {chance=15},
	activate = function(self, eff)
		removeOtherTwinThreatEffects(self, eff)
	end,
	callbackOnCrit = function(self, eff, type, dam, chance, target)
		if type=="physical" and self:isMounted() and rng.percent(eff.chance) then
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
	name = "TWIN_THREAT_ADJACENT",
	desc = "Twin Threat: Adjacent", image = "talents/together_forever.png",
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
		if mount then mount:setEffect(mount.EFF_TWIN_THREAT_ADJACENT, 2, {heal=eff.heal}) end
	end,
	deactivate = function(self, eff)
		local pet = self:hasMount()
		if pet then pet:removeEffect(pet.EFF_TWIN_THREAT_ADJACENT, true) end
	end,
}

newEffect{
	name = "TWIN_THREAT_MID",
	desc = "Twin Threat: Mid Range", image = "talents/together_forever.png",
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
		if mount then mount:setEffect(mount.EFF_TWIN_THREAT_MID, 2, {move=eff.move, cooldown=eff.cooldown}) end
	end,
	deactivate = function(self, eff)
		local pet = self:hasMount()
		if pet then pet:removeEffect(pet.EFF_TWIN_THREAT_MID, true) end
	end,
}

newEffect{
	name = "TWIN_THREAT_LONG",
	desc = "Twin Threat: Long Range", image = "talents/together_forever.png",
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
			self:learnTalent(self.T_TWIN_THREAT_DASH, true, 1)
			mount:setEffect(mount.EFF_TWIN_THREAT_LONG, 2, {move=eff.move, cooldown=eff.cooldown}) end
	end,
	callbackOnArcheryAttack = function(self, eff, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		local mount = self:hasMount()
		if hitted and core.fov.distance(mount.x, mount.y, target.x, target.y) == 1 then
			self:incLoyalty(eff.regen)
		end
	end,
	deactivate = function(self, eff)
		self:unlearnTalent(self.T_TWIN_THREAT_DASH)
		local pet = self:hasMount()
		if pet then pet:removeEffect(pet.EFF_TWIN_THREAT_LONG, true) end
	end,
}

newEffect{
	name = "BEASTMASTER_MARK",
	desc = "Beastmaster's Mark",
	long_desc = function(self, eff) return ("The beast is filled with a thirst for blood, gaining a %d%% bonus to movement and attack speed, but losing %d%% loyalty each turn it does not move toward or attack %s"):format(eff.target.name) end,
	type = "mental",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { target, speed=1.2, loyalty=5 },
	activate = function(self, eff)
		checkEffectHasParameter(self, eff, "target")
		self:setTarget(eff.target)
		if not self.owner then self:removeEffect(self.EFF_BEASTMASTER_MARK, true) end
		self:effectTemporaryValue(eff, "movement_speed", eff.speed)
		self:effectTemporaryValue(eff, "combat_physspeed", eff.speed)
	end,
	callbackOnAct = function(self, eff)
		if not eff.target or eff.target.dead or game.level.map:hasEntity(eff.target) then
			self:removeEffect(self.EFF_BEASTMASTER_MARK, true)
		end
		self:setTarget(eff.target)
		self.turn_procs.beastmaster_mark_loyalty_loss = true
		game:onTickEnd(function()
			if self.turn_procs.beastmaster_mark_loyalty_loss and self.owner then
				self.owner:incLoyalty(-eff.loyalty)
				self:logCombat(self.owner, "#Source#'s loyalty to #target# decreases as it is held back from its target!")
			end
		end)
	end,
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype, mult, dam)
		if target == eff.target then self.turn_procs.beastmaster_mark_loyalty_loss = false end
	end,
	callbackOnMove = function(self, eff, moved, force, ox, oy, x, y)
		if moved then
			local old_dist = core.fov.distance(ox, oy, target.x, target.y)
			local dist = core.fov.distance(self.x, self.y, target.x, target.y)
			if dist < old_dist then 
				self.turn_procs.beastmaster_mark_loyalty_loss = false
			end
		end
	end,
}
