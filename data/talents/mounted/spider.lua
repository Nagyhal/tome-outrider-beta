infoRiderCommand = function() return "\n\nWhen ridden as a mount, this talent is controlled by the rider." end

newTalent{
	name = "Dripping with Venom",
	type = {"spider/stalker-in-the-shadows", 1},
	points = 5,
	stamina = 10,
	mode = "activated",
	require = cuns_req1,
	tactical = { ATTACK = { PHYSICAL = 1, poison = 1}, DISABLE = function(self, t)
			if self:getTalentLevelRaw(t)>=5 then return {cripple=3}
			elseif self:getTalentLevelRaw(t)>=3 then return {cripple=2}
			end
		end},
	-- cooldown = function(self, t) return math.floor(self:combatTalentLimit(t, 7, 10.5, 8)) end,
	requires_target = true,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	cooldown = function(self, t) 
		local val = self:combatTalentScale(t, 10, 8, .75)
		if val<8 then return math.floor(self:combatLimit(val, 6, 7, 6.5, 8, 8)) else return val end
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_DRIPPING_WITH_VENOM2) then self:learnTalent(self.T_DRIPPING_WITH_VENOM2, true) end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 and self:knowTalent(self.T_DRIPPING_WITH_VENOM2) then self:unlearnTalentFull(self.T_DRIPPING_WITH_VENOM2) end
	end,
	doPoison = function(self, t, target)
		local tl = self:getTalentLevelRaw(t)
		--Crippling component
		if tl>=5 then
			target:setEffect(target.EFF_CRIPPLE, 6, {src=self})
		end
		--Choose a poison
		if not target:canBe("poison") then return end
		if tl>=5 then
			target:setEffect(target.EFF_INSIDIOUS_POISON, 6, {power=t.getPoison(self, t)})
		else
			target:setEffect(target.EFF_POISONED, 6, {power=t.getPoison(self, t), src=self})
		end
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		local hit = self:attackTarget(target, nil, t.getDam(self, t), true, true) --we use force_unarmed
		if hit then t.doPoison(self, t, target) end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local poison = t.getPoison(self, t)
		local cooldown = self:getTalentCooldown(t)
		return ([[Inflict a potent bite wound, dealing %d%% damage plus %.1f poison damage per turn over 6 turns, scaling with physical power.

		Also, allies become trained in the sophisticated use and extraction of your poison which can be harvested from your spider fangs. Any mounted or adjacent ally can tip its weapon with the poison, adding to their next weapon attack the same poison damage dealt by this bite. This ability has also a cooldown of %d.

		As you level this talent, the disabling powers of your venom become more potent:

		Level 1: Poison
		Level 3: Poison and cripple
		Level 5: Insidious poison and cripple]]):
		format(dam, poison, cooldown)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1, 1.5) end,
	getPoison = function(self, t) return self:combatTalentPhysicalDamage(t, 15, 40) end,
}

newTalent{
	name = "Dripping with Venom (passive)",
	short_name = "DRIPPING_WITH_VENOM2",
	type = {"spider/stalker-in-the-shadows", 0},
	points = 1,
	hide = "always",
	mode = "passive",
	cooldown = function(self, t) return self:getTalentCooldown(self:getTalentFromId(self.T_DRIPPING_WITH_VENOM)) end,
	callbackOnActBase = function(self, t)
		local allies = {}
		self:project({type="ball", radius=1, selffire=false}, self.x, self.y, function()
			local a = game.level.map(x, y, engine.Map.ACTOR)
			if a and self:reactionToward(a) >= 0 then
				allies[a] = true
			end
		end)
		local done = false
		for ally in pairs(allies) do
			if ally:getInven("MAINHAND") and ally:getInven("MAINHAND")[1] then 
				--do something
				done = true
			end
		end
		if done then self:startTalentCooldown(self.T_DRIPPING_WITH_VENOM2) end
	end,
	info = function(self, t) return "Passive talent taught by Spider with its own cooldown." end,
}

newTalent{
	name = "Scuttle",
	type = {"spider/stalker-in-the-shadows", 2},
	require = cuns_req2,
	points = 5,
	mode = "passive",
	range = 1,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		if not ox or core.fov.distance(ox, oy, x, y)<2 then return end
		local rider = self.rider
		local ab = self.__talent_running or (rider and rider.__talent_running)
		if not ab or ab.is_teleport then return end

		local line = core.fov.line(ox, oy, x, y)
		local acts = {} --don't attack any actor more than once
		local ignore_acts = {}
		local lx, ly = line:step()
		while lx and not (lx==x and ly==y) do --don't run this on the last square
			local coords = util.adjacentCoords(lx, ly)
			--Ignore any actors on our path
		 	local a = game.level.map(lx, ly, engine.Map.ACTOR)
		 	if a then
		 		ignore_acts[a] = true
		 	end
		 	--Add adjacent actors to our list
			for _, coord in ipairs(coords) do
			 	local a = game.level.map(coord[1], coord[2], engine.Map.ACTOR)
		 		if a then acts[a] = true end
		 	end
			lx, ly = line:step()
		end
	 	--Attack actors that were adjacent and not in our path
	 	for act, _ in pairs(acts) do
		 	if act and not ignore_acts[act] and self:reactionToward(act) < 0 then
		 		local hit = self:attackTarget(act, nil, t.getDam(self, t), true)
		 		if hit then 			 		self:logCombat(act, "#Source# tramples #target# with its scuttling legs!")
		 		else 			 		
		 			self:logCombat(act, "#Target# evades the scuttling legs of #source#!")
		 		end
		 	end
		end
	end,
	callbackOnTemporaryEffect = function(self, t, eff_id, e, p)
		 if e.status == "detrimental" and (e.subtype["slow"] or e.subtype["pin"] or e.subtype["stun"]) then
		 	local val = math.round(math.max(p.dur*t.getReduction(self, t), t.getMin(self, t)))
		 	p.dur = math.max(0, p.dur-val)
		 end
	end,
	info = function(self, t)
		local dam = t.getBaseDam(self, t)*100
		local dam2 = dam*1.5
		local reduction = t.getReduction(self, t)*100
		local min = t.getMin(self, t)
		local turns = ("%d turn"..(min>1 and "s" or "")):format(min)
		return ([[Each time you use Rush, Overrun, or any similar movement ability, deal %d%% damage to enemies at the side of your path as you trample them with your many legs. This damage increases with your movement speed; at 200%% move speed the base damage will be %d%%.

			Scuttle also decreases the duration of stuns, slows and pins by %d%% (minimum %s.)]]):
		format(dam, dam2, reduction, turns)
	end,
	getDam = function(self, t)
		local move = 1 / (self:combatMovementSpeed() / self.global_speed)
		local move_factor = self:combatLimit(move, 2, 1, 1, 1.5, 2, .35)
		return t.getBaseDam(self, t) * move_factor
	end,
	getBaseDam = function(self, t) return self:combatTalentScale(t, .4, 1.5) end,
	getMin = function(self, t) return math.floor(self:combatTalentScale(t, 1, 1.5)) end,
	getReduction = function(self, t) return self:combatTalentLimit(t, 1, .1, .25) end
}

newTalent{
	name = "Blinding Spittle",
	type = {"spider/stalker-in-the-shadows", 3},
	require = cuns_req3,
	points = 5,
	stamina = 10,
	no_energy=true,
	cooldown = function(self, t) return math.max(6, self:combatTalentScale(t, 10, 8)) end,
	tactical = { ATTACK = { NATURE = 2}, DISABLE = 1 },
	range = function(self, t) return math.min(10, self:combatTalentScale(t, 5, 10)) end,
	proj_speed = 4,
	target = function(self, t) return {type="bolt", range=self:getTalentRange(t), selffire=false, friendlyfire=false, talent=t, display={particle="bolt_slime"}, name = t.name, speed = t.proj_speed} end,
	requires_target = true,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:projectile(tg, x, y, DamageType.NATURE_BLIND, {dam=self:mindCrit(t.getDam(self, t)), dur=t.getEffDur(self, t), {type="slime"}})
		game:playSoundNear(self, "talents/slime")
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		local eff_dur = t.getEffDur(self, t)
		return ([[Heave a ball of blinding spittle at your target. A successful hit will deal %d nature damage (scaling with Physical Power) while blinding it for %d turns.
		
			Levelling this talent will improve the range and the cooldown.]]):
		format(dam, eff_dur)	
	end,
	getDam = function(self, t) return self:combatTalentPhysicalDamage(t, 20, 150) end,
	getEffDur = function(self, t) return self:combatTalentScale(t, 4, 6) end,
}

newTalent{
	name = "Shadow Walk",
	type = {"spider/stalker-in-the-shadows", 4},
	points = 5,
	cooldown = 15,
	mode = "sustained",
	sustain_stamina = 50,
	require = cuns_req4,
	tactical = { ATTACK = {DARKNESS = 1}, DEFEND = 1, BUFF = 1 },
	activate = function(self, t)
		return {time_to_summon = t.getTime(self, t)
		}
	end,
	deactivate = function(self, t, p)
		if p.shadow and not p.shadow.dead then p.shadow:die() end
		return true
	end,
	createShadow = function(self, t)
		local p = self:isTalentActive(self.T_SHADOW_WALK); if not p then return end --This can happen!
		if (p.shadow and not p.shadow.dead and game.level:hasEntity(p.shadow)) or game.zone.wilderness then return end

		local x, y = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "Not enough space to invoke your shadow!")
			return
		end

		local m = self:cloneFull{
			shader = "shadow_simulacrum",
			no_drops = true,
			faction = self.faction,
			summoner = self, summoner_gain_exp=true,
			ai_target = {actor=nil},
			ai = "summoned", ai_real = "tactical",
			name = "Shadow of "..self.name,
			desc = [[A dark shadowy shape whose form resembles your own.]],
		}

		m:removeAllMOs()
		m.make_escort = nil
		m.on_added_to_level = nil

		m.on_die = function(self)
			local t = self:getTalentFromId(self.T_SHADOW_WALK)
			local p = self:isTalentActive(self.T_SHADOW_WALK); if not p then return end --This can happen!
			p.shadow = nil
			p.time_to_summon = t.getTime(self, t)
		end
		m.energy.value = 0
		m.player = nil
		m.max_life = m.max_life * t.getHealth(self, t)
		m.life = util.bound(m.life, 0, m.max_life)
		m.forceLevelup = function() end
		m.die = nil
		m.on_acquire_target = nil
		m.seen_by = nil
		m.puuid = nil
		m.on_takehit = nil
		m.can_talk = nil
		m.clone_on_hit = nil
		m.exp_worth = 0
		m.no_inventory_access = true
		m.no_levelup_access = true

		m:unlearnTalent(m.T_DRIPPING_WITH_VENOM, m:getTalentLevelRaw(m.T_DRIPPING_WITH_VENOM))
		m:unlearnTalent(m.T_DRIPPING_WITH_VENOM2, m:getTalentLevelRaw(m.T_DRIPPING_WITH_VENOM2))
		m:unlearnTalent(m.T_BLINDING_SPITTLE, m:getTalentLevelRaw(m.T_BLINDING_SPITTLE))
		-- m:forceUseTalent(m.T_SHADOW_WALK, {ignore_energy=true})
		m:unlearnTalent(m.T_SHADOW_WALK, m:getTalentLevelRaw(m.T_SHADOW_WALK))

		m.remove_from_party_on_death = true
		m.resists[DamageType.LIGHT] = -100
		m.resists[DamageType.DARKNESS] = 130
		m.resists.all = -30
		m.inc_damage.all = ((100 + (m.inc_damage.all or 0)) * t.getDam(self, t)) - 100
		m.force_melee_damage_type = DamageType.DARKNESS

		game.zone:addEntity(game.level, m, "actor", x, y)
		game.level.map:particleEmitter(x, y, 1, "shadow")

		if game.party:hasMember(self) then
			game.party:addMember(m, {
				type="shadow",
				title="Shadow of "..self.name,
				temporary_level=1,
				orders = {target=true},
			})
		end
		game:playSoundNear(self, "talents/spell_generic2")
		m:removeSustainsFilter(function(t) if not self:knowTalent(t.id) then
			game.log("DEBUG: should be removing %s", t.id)
			return true end end)
		p.shadow = m

		if m.rider then
			m.rider=nil
			m:removeEffect(m.EFF_RIDDEN, true, true)
		end
		return true
	end,
	tryCreateShadow = function (self, t)
		local p = self:isTalentActive(self.T_SHADOW_WALK); if not p then return end --This can happen!

		if not p.shadow or p.shadow.dead or not game.level:hasEntity(p.shadow) then
			if not t.doCheckInCombat(self, t) then p.time_to_summon = t.getTime(self, t) return end
			if p.time_to_summon > 0 then
				p.time_to_summon = p.time_to_summon - 1
				return
			else
				t.createShadow(self, t)
				return true
			end
		end
	end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(self.T_SHADOW_WALK); if not p then return end --This can happen!
		--Try to create shadow if we don't have one (then quit the function)
		local done = t.tryCreateShadow(self, t)
		--Teleport shadow if it is too far or close
		local shadow = p.shadow; if done or not shadow then return end
		if not t.doCheckInCombat(self, t) then shadow:die() end
		local dist = core.fov.distance(self.x, self.y, shadow.x, shadow.y)
		if dist~=util.bound(dist, 2, 5) or rng.percent(20) then
			shadow:teleportRandom(self.x, self.y, 5, 2)
		end
	end,
	doCheckInCombat = function(self, t)
		local actors_list = {}
		local tg = {type="ball", radius=5, talent=t}
		self:project(tg, self.x, self.y, function(px, py)
			local a = game.level.map(px, py, Map.ACTOR)
			if a and a ~= self and self:reactionToward(a) < 0 then actors_list[#actors_list+1] = a end
		end)
		if #actors_list>=1 then return true end
	end,
	info = function(self, t)
		local health = t.getHealth(self, t)
		local time = t.getTime(self, t)
		local stealth = t.getStealthPower(self, t)
		return ([[You gain the ability to sustain a shadow which teleports around you, dealing darkness damage to enemies. The shadow appears whenever you are in combat (an enemy is visible and within range 5) but will take several (%d) turns to congeal.

			At any time, you can activate the One with Shadows talent to switch places with your shadow, entering stealth with a power of %d scaling with Cunning.]]..infoRiderCommand()):

			format(health, time, stealth)
	end,
	getStealthPower = function(self, t) return self:combatScale(self:getCun(15, true) * self:getTalentLevel(t), 25, 0, 100, 75) end,
	getHealth = function(self, t) return self:combatLimit(self:combatTalentSpellDamage(t, 20, 500), 1, 0.2, 0, 0.584, 384) end, -- Limit to < 100% health of summoner
	getDam = function(self, t) return self:combatLimit(self:combatTalentSpellDamage(t, 10, 500), 1.6, 0.4, 0, 0.761 , 361) end, -- Limit to <160% Nerf?
	getTime = function(self, t) return math.max(3, self:combatTalentScale(t, 5, 4, .35)) end,
}

newTalent{
	name = "Web Ambush",
	type = {"spider/weaver-of-woes", 2},
	require = cuns_req1,
	points = 5,
	cooldown = function(self, t) return self:combatTalentLimit(t, 8, 10, 12) end,
	stamina = 20,
	range = function(self, t) return self:combatTalentLimit(t, 8, 5, 2) end,
	tactical = { DISABLE = {slow = 1, pin = 1}, CLOSEIN = 2 },
	requires_target = true,
	speed = "combat",
	target = function(self, t) return {type="bolt", range=self:getTalentRange(t)} end,
	action = function(self, t)
		local tg = self:getTalentTarget(self, t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		target = game.level.map(x, y, Map.ACTOR)
		if not target then return nil end

		if not self:checkHit(self:combatAttack(), target:combatDefense()) or target:checkEvasion(self) then 
			self:logCombat("#Target# evades the grasping webs of #source#!")
			return true
		end

		local sx, sy = util.findFreeGrid(self.x, self.y, 5, true, {[engine.Map.ACTOR]=true})
		if not sx then return end

		target:move(sx, sy, true)

		if core.fov.distance(self.x, self.y, sx, sy) <= 1 then
			local resist=true
			if rng.percent(t.getSlowChance(self, t)) then
				target:setEffect(target.EFF_SLOW, 5, {apply_power=self:combatPhysicalpower(), src=self})
				resist=false
			end
			if target:canBe("pin") and rng.percent(t.getPinChance(self, t)) then
				target:setEffect(target.EFF_PINNED, 5, {apply_power=self:combatPhysicalpower(), src=self})
				resist=false
			end
			if resist then game.logSeen(target, "%s resists the sticky webs!", target.name:capitalize()) end
		end

		return true
	end,
	info = function(self, t)
		local slow_chance = t.getSlowChance(self, t)
		local pin_chance = t.getPinChance(self, t)
		return ([[Make a ranged attack against a nearby foe, attempting to pull it toward you and encase it in sticky webs.

			Webs have a %d%% chance to slow and a %d%% chance to pin for a duration of 5 turns.]]):
		format(slow_chance, pin_chance)
	end,
	getSlowChance = function(self,t) return self:combatTalentLimit(t, 100, 50, 25) end,
	getPinChance = function(self,t) return self:combatTalentLimit(t, 100, 25, 10) end,
	-- getDur = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6)) end,
}