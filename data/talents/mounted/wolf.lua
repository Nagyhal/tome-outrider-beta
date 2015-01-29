newTalent{
	name = "Sly Senses",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_dex_req1,
	mode = "passive",
	getStatBoost = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getDefense = function(self, t) return self:getTalentLevelRaw(t) *5 end,
	getSaves = function(self, t) return self:getTalentLevelRaw(t) * 3 end,
	getPerception = function(self, t) return self:combatTalentScale(t, 5, 20) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "inc_stats",  {[self.STAT_DEX] = t.getStatBoost(self, t)})
		self:talentTemporaryValue(p, "inc_stats",  {[self.STAT_CUN] = t.getStatBoost(self, t)})
		self:talentTemporaryValue(p, "combat_def", t.getDefense(self, t))
		self:talentTemporaryValue(p, "combat_physresist", t.getSaves(self, t))
		self:talentTemporaryValue(p, "combat_spellresist", t.getSaves(self, t))
		self:onStatChange(self.STAT_DEX,  t.getStatBoost(self, t))
		self:onStatChange(self.STAT_CUN,  t.getStatBoost(self, t))
	end,
	shared_talent = "T_SLY_SENSES_SHARED",
	on_learn = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	on_unlearn = function(self, t, p)
		unshareTalentWithOwner(self, t)
	end,
	info = function(self, t)
		local stat = t.getStatBoost(self, t)
		local def = t.getDefense(self, t)
		local saves = t.getSaves(self, t)
		local perception = t.getPerception(self, t)
		return ([[The wolf gains a %d bonus to Dexterity and Cunning, a %d bonus to defense and a %d bonus to physical and spell saves.

			A wolf levelled in Sly Senses serves as an aid to perception for its owner, granting a bonus of %d to checks to see through stealth and invisibility.]]):
			format(stat, def, saves, perception)
	end,
}

newTalent{
	name = "Sly Senses",
	short_name = "SLY_SENSES_SHARED",
	type = {"mounted/mounted-base", 1},
	points = 1,
	mode = "passive",
	base_talent = "T_SLY_SENSES",
	passives = function(self, t, p)
		local mount = self:hasMount()
		local t2 = self:getTalentFromId(t.base_talent)
		self:talentTemporaryValue(p, "see_invisible",  t2.getPerception(mount, t2))
		self:talentTemporaryValue(p, "see_stealth",  t2.getPerception(mount, t2))
	end,
	info = function(self, t)
		local mount = self:hasMount()
		local t2 = self:getTalentFromId(t.base_talent)
		local perception = t2.getPerception(mount, t2)
		return ([[The perceptory abilities of your wolf grant you a %d bonus to checks to see through stealth and invisibility.]]):
		format(perception)
	end,
}

newTalent{
	name = "Go for the Throat",
	type = {"wolf/tenacity", 2},
	require = mnt_dex_req2,
	points = 5,
	cooldown = 8,
	--stamina = 12,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3, CUT = 1} },
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 0.9, 1.4) end,
	range = function (self, t) return 2 + math.floor(self:getTalentLevel(t) / 3) end,
	shared_talent = "T_GO_FOR_THE_THROAT_COMMAND",
	on_learn = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	on_unlearn = function(self, t, p)
		unshareTalentWithOwen(self, t)
	end,
	on_pre_use = function(self, t, silent)
		local tg = {type="ball", radius=self:getTalentRange(t), 0}
		local tgs = {}
		local tg_vulnerable = false
		self:project(tg, self.x, self.y,
			function(px, py, tg, self)
				local target = game.level.map(px, py, Map.ACTOR)
				if target and self:reactionToward(target)<0 then 
					tgs[#tgs+1] = target
				end
			end)
		for _, target in pairs(tgs) do
			for eff_id, _ in pairs(target.tmp) do
				local e = target.tempeffect_def[eff_id]
				if e.type == "stun" or "pin" then
					tg_vulnerable = true
				end
			end
		end
		if not tg_vulnerable then 
			if not silent then 
				game.logPlayer(self, "There must be a stunned or pinned enemy within talent range!")
			end
			return false 
		end
		return true
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		--TODO: Maybe use something more mount-centric than self.rider:isMounted()
		return t.doAttack(self, t, self, target)
	end,
	--Modular action function so can be invoked by either mount or rider
	doAttack = function(self, t, mover, target)
		local x, y = target.x, target.y
		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", mover) end
		local l = mover:lineFOV(x, y, block_actor)
		if not is_corner_blocked and not game.level.map:checkAllEntities(lx, ly, "block_move", mover) then
			local tx, ty = x, y
			lx, ly, is_corner_blocked = l:step()
			while lx and ly do
				if is_corner_blocked or game.level.map:checkAllEntities(lx, ly, "block_move", mover) then break end
				tx, ty = lx, ly
				lx, ly, is_corner_blocked = l:step()
			end

			local ox, oy = self.x, self.y
			mover:move(tx, ty)
			if config.settings.tome.smooth_move > 0 then
				self:resetMoveAnim()
				self:setMoveAnim(ox, oy, 8, 5)
			end
		end
		--rush end
		local bonus_multipler = nil
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local speed, hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		if hit then 
			if target:canBe("cut") then target:setEffect(target.EFF_CUT, 5, {power=t.getDamage(self, t)*12, src=self}) end
		end
		return true
	end,
	info = function(self, t)
		return ([[The wolf dashes forward to make a ferocious crippling blow against a stunned or pinned enemy for %d%% damage; if this hits, it also causes bleeding for 60%% of this damage over 5 turns.

			This talent may also be controlled by the wolf's owner.]]):
		format(100 * t.getDamage(self, t))
	end
}

newTalent{
	name = "Command: Go for the Throat",
	short_name = "GO_FOR_THE_THROAT_COMMAND",
	type = {"mounted/mounted-base", 1},
	points = 1,
	cooldown = 8,
	stamina = 12,
	requires_target = true,
	base_talent = "T_GO_FOR_THE_THROAT",
	tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3, CUT = 1} },
	-- tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3, CUT = 1} }, --TODO: Decide on how summon controls are handled tactically
	getDamage = function (self, t) return self.outrider_pet:callTalent(self.outrider_pet.T_GO_FOR_THE_THROAT, "getDamage") end,
	range = function (self, t) return self.outrider_pet:callTalent(self.outrider_pet.T_GO_FOR_THE_THROAT, "range") end,
	targetTry = function(self, t)
		return {type="ball", radius=self:getTalentRange(t), 0}
	end,
	on_pre_use = function(self, t)
		local mount = self.outrider_pet
		return mount and mount:callTalent(mount.T_GO_FOR_THE_THROAT, "on_pre_use") or false
	end,
	action = function(self, t)
		local mount = self.outrider_pet
		local t2 = mount:getTalentFromId(mount.T_GO_FOR_THE_THROAT)

		local tg = {type="hit", start_x=mount.x, start_y=mount.y, range=self:getTalentRange(t2)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t2) then return nil end

		local mover
		if self:isMounted() then mover = self else mover = mount end
		return mount:callTalent(mount.T_GO_FOR_THE_THROAT, "doAttack", mover, target)
	end,
	info = function(self, t)
		if not self.outrider_pet then return [[Without a wolf, you cannot use Command: Go For The Throat.]]
		else return ([[The wolf dashes forward to make a ferocious crippling blow against a stunned, pinned or disabled enemy for %d%% damage; if this hits, it also causes bleeding for 60%% of this damage over 5 turns.]]):
			format(100 * t.getDamage(self, t))
		end
	end
}

newTalent{
	name = "Uncanny Tenacity",
	type = {"wolf/tenacity", 3},
	points = 5,
	require = mnt_dex_req3,
	mode = "passive",
	getThreshold = function (self, t) return math.round(self:combatTalentScale(t, 25, 40), 5) end,
	getSaves = function (self, t) return math.round(self:combatTalentScale(t, 5, 20), 1) end,
	getRes = function (self, t) return self:combatTalentScale(t, 8, 20) end,
	callbackOnAct = function(self, t)
		local okay = false
		local tg = {type="ball", radius=self:getTalentRange(t), talent=t}
		local actors_list = {}
		self:project(tg, self.x, self.y, function(px, py)
			local a = game.level.map(px, py, Map.ACTOR)
			if a and self:reactionToward(a) < 0 and a.life < a.max_life*t.getThreshold(self, t)/100 then
				okay = true
			end
		end)
		if okay then self:setEffect(self.EFF_UNCANNY_TENACITY, 2, {saves=t.getSaves(self, t), res=t.getRes(self, t)})
		elseif self:hasEffect(self.EFF_UNCANNY_TENACITY) then
			--It might be more logical to have the effect try to unset itself when activated, rather than do it from within the talent.
			--This way is tidier, though.
			self:removeEffect(self.EFF_UNCANNY_TENACITY)
		end
		local act = rng.table(actors_list)
	end,
	info = function(self, t)
		local threshold =  t.getThreshold(self, t)
		local saves = t.getSaves(self, t)
		local res = t.getRes(self, t)
		return ([[The wolf will stop at nothing to hound and harry its prey; when it starts its turn adjacent to an enemy at less than %d%% health, the wolf gains a %d bonus to saves and a %d%% bonus to resist all (including stuns, pins, knockback, confusion and fear.)]]):
		format(threshold, saves, res)
	end,
}

newTalent{
	name = "Fetch!",
	short_name = "FETCH",
	type = {"wolf/tenacity", 4},
	points = 5,
	require = mnt_dex_req4,
	--stamina = 50,
	cooldown = 30,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 } },
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, .6, 1.2) end,
	getReduction = function (self, t) return 3 + math.floor(self:getTalentLevel(t) *1.8) end,
	getFetchDistance = function (self, t) return math.floor(self:getTalentLevel(t) + 1) end,
	getDuration = function(self, t) return 3 + math.floor(self:getTalentLevel(t) / 2) end,
	on_pre_use= function(self, t) return false end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local grappled = false
		if target:isGrappled(self) then
			grappled = true
		else
			self:breakGrapples()
		end
		if self:grappleSizeCheck(target) then
			return true
		end
		local hit = self:startGrapple(target)
		local duration = t.getDuration(self, t)
		if hit then
			self:setEffect(target.FETCH, t.getDuration(self, t), t.getDamage(self, t))
		return true
		end
	end,
	info = function(self, t)
		return ([[The wolf attempts to grab an enemy, ravaging it within its jaws for %d damage each turn and reducing its attack and defense by %d. If it succeeds, it will bring it to you within range %d while you are dismounted.

			The wolf will only use this ability at the command of its owner.

			#GOLD##BOLD#Currently disabled while dragging is reimplemented.]]):
		format(t.getDamage(self, t)*100, t.getReduction(self, t), t.getFetchDistance(self, t))
	end,
}

newTalent{
	name = "Loyal to the Pack",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req1,
	mode = "passive",
	getStatBoost = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getRegen = function(self, t) return math.round(self:combatTalentScale(t, .5, 3.5, .35), .5)  end,
	getSaves = function(self, t) return self:getTalentLevelRaw(t) * 3 end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "inc_stats",  {[self.STAT_WIL] = t.getStatBoost(self, t)})
		self:talentTemporaryValue(p, "inc_stats",  {[self.STAT_CUN] = t.getStatBoost(self, t)})
		self:onStatChange(self.STAT_WIL,  t.getStatBoost(self, t))
		self:onStatChange(self.STAT_CUN,  t.getStatBoost(self, t))
		self:talentTemporaryValue(p, "combat_mentalresist", t.getSaves(self, t))
	end,
	shared_talent = "T_LOYAL_TO_THE_PACK_SHARED",
	on_learn = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	on_unlearn = function(self, t, p)
		unshareTalentWithOwner(self, t)
	end,
	info = function(self, t)
		local stat = t.getStatBoost(self, t)
		local save = t.getSaves(self, t)
		local regen = t.getRegen(self, t)
		return ([[The wolf gains a %d bonus to Willpower and Cunning, a %d bonus to mental saves and grants its owner a %.1f bonus to Loyalty regen.]]):
		format(stat, save, regen)
	end,
}

newTalent{
	name = "Loyal to the Pack",
	short_name = "LOYAL_TO_THE_PACK_SHARED",
	type = {"mounted/mounted-base", 1},
	points = 1,
	mode = "passive",
	base_talent = "T_LOYAL_TO_THE_PACK",
	passives = function(self, t, p)
		local mount = self:hasMount()
		local t2 = self:getTalentFromId(t.base_talent)
		self:talentTemporaryValue(p, "loyalty_regen",  t2.getRegen(mount, t2))
	end,
	info = function(self, t)
		local mount = self:hasMount()
		local t2 = self:getTalentFromId(t.base_talent)
		local regen = t2.getRegen(mount, t2)
		return ([[Your wolf's loyalty to you regenerates more quickly: %d additional loyalty per turn.]])
		:format(regen)
	end,
}

newTalent{
	name = "Together, Forever",
	short_name = "TOGETHER_FOREVER",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req2,
	mode = "passive",
	cooldown = 8,
	range = function(self, t) return 5 + self:getTalentLevelRaw(t) end,
	getHealMod = function(self, t) return math.round(self:combatTalentScale(t, 5, 20), 5) end,
	getDam = function(self, t) return self:combatTalentScale(1, 1.2, 1.75) end,
	getRegen = function(self, t) return 1 + self:getTalentLevel(t) end,
	getThreshold = function(self,t) return 10 + self:getTalentLevel(t) * 2.5 end,
	callbackOnAct = function(self, t)
		if self:isTalentCoolingDown(t.id) then return end
		local owner = self.owner
		if not (owner and (owner.life / owner.max_life <= t.getThreshold(self, t)/100) and (core.fov.distance(self.x, self.y, owner.x, owner.y)>1)) then return end
		local tg = {type="ball", start_x=owner.x, start_y=owner.y, radius=1, talent=t}
		local foes_list = {}
		self:project(tg, owner.x, owner.y, function(px, py)
			local a = game.level.map(px, py, Map.ACTOR)
			if a and self:reactionToward(a) < 0 and self:hasLOS(a) then foes_list[#foes_list+1] = a end
		end)
		local other_grids = {}
		self:project(tg, owner.x, owner.y, function(px, py)
			if not game.level.map:checkAllEntities(px, py, "block_move", self) and self:hasLOS(px, py) then other_grids[#other_grids+1]={x=px, y=py} end
		end)
		local target = rng.table(foes_list)
		local grid = rng.table(other_grids)
		if target then
			--Rush the target if we find one
			local linestep = self:lineFOV(target.x, target.y, block_actor)
			local tx, ty, lx, ly, is_corner_blocked 
			repeat  -- make sure each tile is passable
				tx, ty = lx, ly
				lx, ly, is_corner_blocked = linestep:step()
			until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
			if not tx or not ty then return end
			if core.fov.distance(self.x, self.y, tx, ty) == 1 then
				if self:attackTarget(target, nil, t.getDam(self, t), true) and target:canBe("stun") then
				target:setEffect(target.EFF_DAZED, 3, {})
				end
			end
		elseif grid then
			--Run directly toward a free square adjacent to the owner.
			local line = self:lineFOV(grid.x, grid.y, block_actor)
			local tx, ty, lx, ly, is_corner_blocked 
			repeat  -- make sure each tile is passable
				tx, ty = lx, ly
				lx, ly, is_corner_blocked = line:step()
			until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
			if not tx or not ty then return end
			self:move(tx, ty)
		else return
		end
		self:logCombat(target, "#Source# uses Together, Forever!")
		--Expend energy and start the cooldown, provided we pass the many fail checks.
		-- if not game.player==self then self:useEnergy(game.energy_to_act) end
		self:startTalentCooldown(t.id)
	end,
	info = function(self, t) 
		local heal_mod = t.getHealMod(self, t)
		local regen = t.getRegen(self, t)
		local threshold = t.getThreshold(self, t)
		local dam = t.getDam(self, t)*100
		local range = self:getTalentRange(t)
		local cooldown = self:getTalentCooldown(t)
		return ([[The wolf gains a +%d%% healing modifier bonus and each heal or inscription usage restores its loyalty to you by an additional %d points. Also, when your health is below %d%% of its total, if your wolf is not adjacent to you, it will activate Together, Forever to come rushing to your side, attacking fo %d%% damage (maximum range %d). This ability has a cooldown of %d.]]):
		format(heal_mod, regen, threshold, dam, range, cooldown)
	end
}

newTalent{
	name = "Predatory Flanking",
	type = {"wolf/pack-hunter", 2},
	points = 5,
	require = mnt_cun_req3,
	mode = "passive",
	getPct = function(self, t) return 15 + (self:getTalentLevel(t) + self:getTalentLevelRaw(t))/2 * 10 end,
	getSecondaryPct = function(self, t)
		--shift property of combatTalentScale doesn't really work
		local shifted_tl = self:getTalentLevel(t)-1
		--0 at TL1 ; 5 at TL2 ; 12 at TL5
		local val = shifted_tl>=1 and self:combatScale(shifted_tl, 5, 1,  12, 4, .5) or 0
		return math.round(val, .5)
	end,
	--Might want to do this as often as possible
	doCheck = function(self, t)
		local tgts = {}
		for _, c in pairs(util.adjacentCoords(self.x, self.y)) do
			local target = game.level.map(c[1], c[2], Map.ACTOR)
			if target and self:reactionToward(target) < 0 then tgts[#tgts+1] = target end
		end
		for _, target in ipairs(tgts) do
			local allies = {}
			for _, c in pairs(util.adjacentCoords(target.x, target.y)) do
				local target2 = game.level.map(c[1], c[2], Map.ACTOR)
				if target2 and self:reactionToward(target2) >= 0 and core.fov.distance(self.x, self.y, target2.x, target2.y)>1 then allies[#allies+1] = target2 end
				if #allies>=1 then
					target:setEffect(target.EFF_PREDATORY_FLANKING, 2, {src=self, allies=allies, src_pct=t.getPct(self, t), allies_pct=t.getSecondaryPct(self, t)})
				end --We run the check to see if we are no longer flanking from within the enemy's temp effect.
			end
		end
	end,
	callbackOnActBase = function(self, t)
		t.doCheck(self, t)
	end,
	info = function(self, t)
		local pct = t.getPct(self, t)
		local secondary = t.getSecondaryPct(self, t)
		return ([[If you and one of your allies both stand adjacent to the same enemy, but not adjacent to one another, then damage against that foe is increased by %d%%, and your flanking ally's damage by %.1f%%.]])
			:format(pct, secondary)
		end,
}

newTalent{
	name = "Howl to the Moon",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req4,
	cooldown = 50,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 }, BUFF = 1, DEFEND = 2},
	getDur = function(self, t) return self:combatTalentScale(t, 7, 12) end,
	getRareChance = function(self, t) return 12 + self:getTalentLevel(t) * 8 end,
	getConvertChance = function(self, t) return 12 + self:getTalentLevel(t) * 8 end,
	getMin = function(self, t) return math.floor(0.5 + self:getTalentLevel(t) / 2) end,
	getMax = function(self, t) return math.floor(1.5 + self:getTalentLevel(t) / 1.5) end,
	getMindpower = function(self, t) return self:getTalentLevelRaw(t)*3 end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_mindpower", t.getMindpower(self, t))
	end,
	on_learn = function(self, t)
		self.seen_wolves = {}
	end,
	callbackOnActBase = function(self, t)
		if not game.party.members[self] then return end
		local grids = core.fov.circle_grids(self.x, self.y, self.sight, true)		
			for x, ys in pairs(grids) do for y, _ in pairs(ys) do
				local a = game.level.map(x, y, engine.Map.ACTOR)
				if a and a.subtype=="canine" and game.engine.Faction:factionReaction(self.faction, a.faction)<0 and not self.seen_wolves[a.iud] and self:hasLOS(a.x, a.y) then
					if rng.percent(t.getConvertChance(self, t)) then
						a.faction = self.faction
						a.summoner=self.rider or self
						a.summon_time=20
						game.party:addMember(a, {
							control="no",
							type="summon",
							title="Wolf Ally",
							orders = {target=true},
						})
						a:setTarget()
						a.remove_from_party_on_death=true
						a.summoner_gain_exp=true
						a.ai = "party_member"
						a.ai_state.ally_compassion=10
						a.ai_state.tactic_leash=10
						-- a.ai_state.ai_move="move_astar"
						a.ai_tactic = resolvers.tactic"melee"
						a.ai_tactic.escape = 0
					end
					self.seen_wolves[a.uid] = true
				end
			end
		end
	end,
	action = function(self, t)
		local coords = {}
		local block = function(_, lx, ly) return game.level.map:checkAllEntities(lx, ly, "block_move") end
		self:project({type="ball", radius=10, block_radius=block, talent=t}, self.x, self.y, function(px, py)
			local a = game.level.map(px, py, engine.Map.ACTOR)
			local terrain = game.level.map(px, py, engine.Map.TERRAIN)
			if not a and not terrain.does_block_move then coords[#coords+1] = {px, py, core.fov.distance(self.x, self.y, px, py), rng.float(0,1)} end
		end)
		local f = function(a, b)
			if a[3]~=b[3] then return a[3] > b[3] else return a[4] < b[4] end
		end
		table.sort(coords, f)

		--TODO: Make this not crash if not enough room.
		--Stolen from teleportRandom
		local poss, dist, min_dist = {}, 8, 4
		local x, y = self.x, self.y
		for i = x - dist, x + dist do
			for j = y - dist, y + dist do
				if game.level.map:isBound(i, j) and
				   core.fov.distance(x, y, i, j) <= dist and
				   core.fov.distance(x, y, i, j) >= min_dist and
				   self:canMove(i, j) and
				   not game.level.map.attrs(i, j, "no_teleport") and
				   self:hasLOS(i, j) then
				poss[#poss+1] = {i,j}
				end
			end
		end
		if #poss == 0 then return false end
		for i=1, rng.range(t.getMin(self, t), t.getMax(self, t)) do	
			local filter = {
				base_list="mod.class.NPC:data/general/npcs/canine.lua",
			}
			local coord = rng.tableRemove(poss)
			local e = game.zone:makeEntity(game.level, "actor", filter, true)
			-- e.summoner = self
			e.summon_time = t.getDur(self, t)
			e.faction = self.faction
			setupSummon(self, e, coord[1], coord[2])
		end
		return true
	end,
	info = function(self, t)
		local min = t.getMin(self, t)
		local max = t.getMax(self, t)
		local dur = t.getDur(self, t)
		local rare_chance = t.getRareChance(self, t)
		local convert_chance = t.getConvertChance(self, t)
		local mindpower = t.getMindpower(self, t)
		return ([[The wolf summons between %d and %d of its allies, with a %d%% chance for a legendary wolf to be present. Also, as you level this talent, wolves you encounter have a %d%% chance to be friendly if they fail a mental save against the wolf's mindpower.

			Learning Howl to the Moon will increase your wolf's mindpower by %d.]]):
		format(min, max, dur, rare_chance, convert_chance, mindpower)
	end,
}