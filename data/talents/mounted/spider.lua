infoRiderCommand = function() return "\n\nWhen ridden as a mount, this talent is controlled by the rider." end

newTalent{
	name = "Dripping with Venom",  short_name = "OUTRIDER_DRIPPING_WITH_VENOM", image = "talents/dripping_with_venom.png",
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
		if not self:knowTalent(self.T_OUTRIDER_DRIPPING_WITH_VENOM2) then self:learnTalent(self.T_OUTRIDER_DRIPPING_WITH_VENOM2, true) end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 and self:knowTalent(self.T_OUTRIDER_DRIPPING_WITH_VENOM2) then self:unlearnTalentFull(self.T_OUTRIDER_DRIPPING_WITH_VENOM2) end
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
	name = "Dripping with Venom (passive)", short_name = "DRIPPING_WITH_VENOM2", image = "talents/dripping_with_venom.png",
	type = {"spider/stalker-in-the-shadows", 0},
	points = 1,
	hide = "always",
	mode = "passive",
	cooldown = function(self, t) return self:getTalentCooldown(self:getTalentFromId(self.T_OUTRIDER_DRIPPING_WITH_VENOM)) end,
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
		if done then self:startTalentCooldown(self.T_OUTRIDER_DRIPPING_WITH_VENOM2) end
	end,
	info = function(self, t) return "Passive talent taught by Spider with its own cooldown." end,
}

newTalent{
	name = "Scuttle", short_name = "OUTRIDER_SCUTTLE", image = "talents/scuttle.png",
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
		return ([[Each time you use Rush, Run Them Down, or any similar movement ability, deal %d%% damage to enemies at the side of your path as you trample them with your many legs. This damage increases with your movement speed; at 200%% move speed the base damage will be %d%%.

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
	name = "Blinding Spittle", short_name = "OUTRIDER_BLINDING_SPITTLE", image = "talents/blinding_spittle.png",
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
	name = "Shadow Walk", short_name = "OUTRIDER_SHADOW_WALK", image = "talents/shadow_walk.png",
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
 	on_learn = function(self, t)
		if not self:knowTalent(self.T_OUTRIDER_ONE_WITH_SHADOWS) then
			self:learnTalent(self.T_OUTRIDER_ONE_WITH_SHADOWS, true, 1)
 		end
	end,
 	on_unlearn = function(self, t)
		if not self:knowTalent(self.T_OUTRIDER_SHADOW_WALK) then
			self:unlearnTalent(self.T_OUTRIDER_ONE_WITH_SHADOWS)
 		end
 	end,
	createShadow = function(self, t)
		local p = self:isTalentActive(self.T_OUTRIDER_SHADOW_WALK); if not p then return end --This can happen!
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
			local t = self:getTalentFromId(self.T_OUTRIDER_SHADOW_WALK)
			local p = self:isTalentActive(self.T_OUTRIDER_SHADOW_WALK); if not p then return end --This can happen!
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

		m:unlearnTalent(m.T_OUTRIDER_DRIPPING_WITH_VENOM, m:getTalentLevelRaw(m.T_OUTRIDER_DRIPPING_WITH_VENOM))
		m:unlearnTalent(m.T_OUTRIDER_DRIPPING_WITH_VENOM2, m:getTalentLevelRaw(m.T_OUTRIDER_DRIPPING_WITH_VENOM2))
		m:unlearnTalent(m.T_OUTRIDER_BLINDING_SPITTLE, m:getTalentLevelRaw(m.T_OUTRIDER_BLINDING_SPITTLE))
		-- m:forceUseTalent(m.T_OUTRIDER_SHADOW_WALK, {ignore_energy=true})
		m:unlearnTalent(m.T_OUTRIDER_SHADOW_WALK, m:getTalentLevelRaw(m.T_OUTRIDER_SHADOW_WALK))

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
			return true end end)
		p.shadow = m

		if m.rider then
			m.rider=nil
			m:removeEffect(m.EFF_OUTRIDER_RIDDEN, true, true)
		end
		return true
	end,
	tryCreateShadow = function (self, t)
		local p = self:isTalentActive(self.T_OUTRIDER_SHADOW_WALK); if not p then return end --This can happen!

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
		local p = self:isTalentActive(self.T_OUTRIDER_SHADOW_WALK); if not p then return end --This can happen!
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
	name = "One with Shadows", short_name = "OUTRIDER_ONE_WITH_SHADOWS", image = "talents/one_with_shadows.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	cooldown = 15,
	tactical = { ESCAPE = 2 },
	stamina= 30,
	is_teleport = true,
	on_pre_use = function(self, t)
		local eff = self:isTalentActive(self.T_OUTRIDER_SHADOW_WALK)
		if not eff then
			if not silent then 
				game.logPlayer(self, "You must have Shadow Walk active!")
			end
			return false 
		end
		if not eff.shadow or not game.level:hasEntity(eff.shadow) then
			if not silent then 
				game.logPlayer(self, "Your shadow is not currently active!")
			end
			return false 
		end
		return true
	end,
	action = function(self, t)
		local eff = self:isTalentActive(self.T_OUTRIDER_SHADOW_WALK)
		local x, y = eff.shadow.x, eff.shadow.y
		eff.shadow:die()

		game.level.map:particleEmitter(self.x, self.y, 1, "teleport")
		self:teleportRandom(x, y, 0)
		game.level.map:particleEmitter(x, y, 1, "teleport")

		game:playSoundNear(self, "talents/teleport")
		return true
	end,
	info = function(self, t)
		local radius = t.getRadius(self, t)
		local range = t.getRange(self, t)
		return ([[Teleports you randomly within a small range of up to %d grids.
		At level 4, it allows you to specify which creature to teleport.
		At level 5, it allows you to choose the target area (radius %d). If the target area is not in line of sight, there is a chance the spell will fizzle.
		The range will increase with your Spellpower.]]):format(range, radius)
	end,
}


newTalent{
	name = "Web Ambush", short_name = "OUTRIDER_WEB_AMBUSH", image = "talents/web_ambush.png",
	type = {"spider/weaver-of-woes", 1},
	require = cuns_req1,
	points = 5,
	cooldown = function(self, t) return self:combatTalentLimit(t, 8, 10, 12) end,
	stamina = 20,
	range = function(self, t) return self:combatTalentLimit(t, 8, 2, 5) end,
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
	getSlowChance = function(self,t) return self:combatTalentLimit(t, 100, 25, 50) end,
	getPinChance = function(self,t) return self:combatTalentLimit(t, 100, 10, 25) end,
	-- getDur = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6)) end,
}

newTalent{
	name = "Vestigial Magicks", short_name = "OUTRIDER_VESTIGIAL_MAGICKS", image = "talents/vestigial_magicks.png",
	type = {"spider/weaver-of-woes", 2},
	points = 5,
	mode = "passive",
	radius = function(self, t) return self:combatTalentLimit(t, 5, 1, 3) end,
	passives = function(self, t, p)
		local Stats = require "engine.interface.ActorStats"
		self:talentTemporaryValue(p, "inc_stats",  {[Stats.STAT_STR]=t.getMag(self, t)})
		self:talentTemporaryValue(p, "combat_spellresist", t.getSave(self, t))
		self:talentTemporaryValue(p, "resists", {
			blight=t.getRes(self, t),
			arcane=t.getRes(self, t)
			})
	end,
	doDamage = function(self, t, target)
		DamageType:get(DamageType.ARCANE).projector(self, target.x, target.y, DamageType.ARCANE, t.getDam(self, t))
	end,
	info = function(self, t)
		local mag = t.getMag(self, t)
		local save = t.getSave(self, t)
		local res = t.getRes(self, t)
		local dam = t.getDam(self, t)
		local radius = self:getTalentRadius(t)
		return ([[Increase your Magic by %d, spell save by %d, and arcane, temporal, blight and darkness resistance by %d%%.

			Using runes will grant a single-turn aura that deals %d arcane and darkness damage to attackers within a %d radius, scaling with your spellpower as well as with your owner's spellpower.]]):
		format(mag, save, res, dam, radius)
	end,
	getMag = function(self, t) return self:combatTalentScale(t, 3, 15) end,
	getSave = function(self, t) return self:combatTalentScale(t, 5, 25) end,
	getRes = function(self, t) return self:combatTalentScale(t, 5, 25) end,
	getDam = function(self, t) 
		local spell_factor = self:combatSpellpower()
		local owner = self.owner
		if owner then spell_factor = spell_factor + owner:combatSpellpower() end
		return self:combatTalentSpellDamage(t, 30, 120, spell_factor/2) --The last argument overrides our spellpower.
	end,
}

newTalent{
	name = "Cobweb", short_name = "OUTRIDER_COBWEB", image = "talents/cobweb.png",
	type = {"spider/weaver-of-woes",3},
	require = spells_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 30,
	tactical = { DISABLE = {slow=2, pin=1} },
	target = function(self, t)
		return {type="ball", range=0, radius=self:getTalentRadius(t)}
	end,
	radius = function(self, t) return self:combatTalentScale(t, 2, 3) end,
	action = function(self, t)
		local eff = game.level.map:addEffect(self,
			self.x, self.y, t.getDuration(self, t),
			DamageType.COBWEB, {slow_power=t.getSlowPower(self, t), chance=t.getPinChance(self, t)},
			self:getTalentRadius(t),
			5, nil,
			{type="ice_vapour"},
			nil, self:spellFriendlyFire()
		)
		local x, y = util.findFreeGridsWithin(eff.grids, nil, nil, true, engine.Map.ACTOR)
		if self:canMove(x, y) then self:move(x, y, true) end
		game:playSoundNear(self, "talents/cloud")
		return true
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(self, t)
		local slow_power =  t.getSlowPower(self, t)
		local chance = t.getPinChance(self, t)
		return ([[Weave a great web that spans a radius %d area around you.

			Enemies entering the web will be slowed by %d%%. Furthermore, any enemy attacking you from within the web suffers a %d%% chance to pinned.

			Completing your web will move you to a random square within the radius.]]):
		format(radius, slow_power, chance)
	end,
	getSlowPower = function(self, t) return self:combatTalentIntervalDamage(t, "cun", 30, 75) end,
	getPinChance = function(self, t) return self:combatTalentIntervalDamage(t, "cun", 30, 50) end,
}

newTalent{
	name = "Numbing Ichor", short_name = "OUTRIDER_NUMBING_ICHOR", image = "talents/numbing_ichor.png",
	type = {"spider/weaver-of-woes", 4},
	points = 5,
	mode = "passive",
	require = cuns_req4,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		if not target:effectsFilter({subtype="pin"}) then return end
		if hitted and target:canBe("poison") then
			target:setEffect(target.EFF_NUMBING_POISON, t.getDur(self, t), {power=t.getPoison(self, t), reducte=t.getReduction(self, t), apply_power=self:combatPhysicalpower()})
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getPoison(self, t)
		local dur = t.getDur(self, t)
		local reduction = t.getReduction(self, t)
		return ([[Any time the spider attacks a pinned target, it infuses it with a numbing serum that prepares it for digestion.

			Victims will suffer %d nature damage per turn for %d turns and a %d%% reduction in global damage output.]]):
		format(dam, dur, reduction)
	end,
	getReduction= function(self, t) return self:combatTalentLimit(t, 25, 10, 20) end,
	getDur= function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getPoison = function(self, t) return self:combatTalentPhysicalDamage(t, 15, 40) end,
}
