newTalent{
	name = "Sly Senses",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_dex_req1,
	mode = "passive",
	getStatBoost = function(self, t) return self:getTalentLevelRaw(t) * 4 end,
	getDefense = function(self, t) return self:getTalentLevelRaw(t) *5 end,
	getSaves = function(self, t) return self:getTalentLevelRaw(t) * 7 end,
	getPerception = function(self, t)
		local val1 = self:combatTalentIntervalDamage(t, "dex", 5, 50)
		local val2 = self:combatTalentIntervalDamage(t, "cun", 5, 50)
		return (val1+val2)/2
	end,
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
		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithOwner(self, t)
		end
	end,
	info = function(self, t)
		local stat = t.getStatBoost(self, t)
		local def = t.getDefense(self, t)
		local saves = t.getSaves(self, t)
		local perception = t.getPerception(self, t)
		return ([[The wolf gains a %d bonus to Dexterity and Cunning, a %d bonus to defense and a %d bonus to physical and spell saves.

			A wolf levelled in Sly Senses serves as an aid to perception for its owner, granting a bonus of %d to checks to see through stealth and invisibility, scaling with talent level, Dexterity and Cunning.]]):
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
	name = "Uncanny Tenacity",
	type = {"wolf/tenacity", 2},
	points = 5,
	require = mnt_dex_req2,
	mode = "passive",
	cooldown = function(self, t) return self:combatTalentLimit(t, 8, 20, 10) end,
	callbackOnActBase = function(self, t)
		if self:isTalentCoolingDown(t.id) then return end
		if self.life <= self.max_life*.15 then
			self:callTalent(t.id, "setEffect")
		end
		self:startTalentCooldown(t.id)
	end,
	setEffect = function(self, t)
		self:setEffect(self.EFF_UNCANNY_TENACITY, t.getDur(self, t), {res=t.getRes(self, t), buff=t.getBuff(self, t)})
	end,
	info = function(self, t)
		local res = t.getRes(self, t)
		local immediate_res = t.getImmediateRes(self, t)
		local dur = t.getDur(self, t)
		local buff = t.getBuff(self, t)
		local cooldown = self:getTalentCooldown(t)
		return ([[The wolf will stop at nothing to hound and harry its prey; Whenever the wolf is hit for over 15%% of its health in a single attack or reaches 15%% of its life total, it will reduce all incoming damage by %d%% for %d turns (and the triggering attack by %d%%), while increasing attack and physical power by %d. While in this state, the wolf will also remove 2 turns from a random detrimental effect each turn.

			This effect has a cooldown of %d.]]):
		format(res, dur, immediate_res, buff, cooldown)
	end,
	getRes = function (self, t) return math.round(self:combatTalentScale(t, 10, 20)) end,
	getImmediateRes = function (self, t) return math.round(t.getRes(self, t)*2.5) end,
	getDur = function (self, t) return math.round(self:combatTalentScale(t, 3, 6)) end,
	getBuff = function (self, t) return math.round(self:combatTalentScale(t, 5, 15)) end,
}

newTalent{
	name = "Go for the Throat",
	type = {"wolf/tenacity", 3},
	require = mnt_dex_req3,
	points = 5,
	cooldown = 8,
	stamina = 12,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3 } },
	-- getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 0.7, 1.2) end,
	getDamage = function (self, t) return self:combatTalentScale(t, 0.7, 1.2) end,
	getDamInc = function (self, t) return self:combatTalentScale(t, .15, .25, .85) end,
	range = function (self, t) return self:combatTalentScale(t, 2, 4) end,
	shared_talent = "T_GO_FOR_THE_THROAT_COMMAND",
	on_learn = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	on_unlearn = function(self, t, p)
		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithOwner(self, t)
		end
	end,
	on_pre_use = function(self, t)
		-- if self:hasEffect(self.EFF_RIDDEN) then return false end
		if self.owner and not self.player then return false end
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		if self:attr("never_move") then tg.range=1 end
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		--TODO: Maybe use something more mount-centric than self.rider:isMounted()
		local ret = t.doAttack(self, t, self, target)
		local owner = self.owner
		if ret and owner then owner:startTalentCooldown(owner.T_GO_FOR_THE_THROAT_COMMAND) end
		return ret
	end,
	--Modular action function so can be invoked by either mount or rider
	doAttack = function(self, t, mover, target)
		local x, y = target.x, target.y
		-- local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", mover) end
		-- local l = mover:lineFOV(x, y, block_actor)
		local l = mover:lineFOV(x, y)
		local tx, ty = self.x, self.y
		local lx, ly, is_corner_blocked
		if not is_corner_blocked and not game.level.map:checkAllEntities(lx, ly, "block_move", mover) then
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
		if core.fov.distance(self.x, self.y, x, y) > 1 then return end
		local dam, dam_inc = t.getDamage(self, t), t.getDamInc(self, t)
		dam = dam + dam_inc * #target:effectsFilter({ subtype = { pin=true, stun=true }, status = "detrimental" })
		for i = 1, 3 do
			local speed, hit = self:attackTarget(target, nil, dam, strue)
		end
		return true
	end,
	info = function(self, t)
		local dam_pct = 100 * t.getDamage(self, t)
		local dam_inc = 100 * t.getDamInc(self, t)
		return ([[The wolf dashes forward, ravaging a single enemy with three attacks that hit for %d%% damage. For each stun or pin affect inflicting it, the damage is increased by a further %d%%

			This talent is a command and must be controlled by the wolf's owner.]]):
		format(dam_pct, dam_inc)
	end
}

newTalent{
	name = "Command: Go for the Throat",
	short_name = "GO_FOR_THE_THROAT_COMMAND", image = "talents/go_for_the_throat.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	cooldown = 8,
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
		return mount and true or false
	end,
	action = function(self, t)
		local mount = self.outrider_pet
		local t2 = mount:getTalentFromId(mount.T_GO_FOR_THE_THROAT)

		local tg = {type="hit", start_x=mount.x, start_y=mount.y, range=mount:getTalentRange(t2)}
		if self:attr("never_move") then tg.range=1 end
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(mount.x, mount.y, x, y) > mount:getTalentRange(t2) then return nil end

		local mover
		if self:isMounted() then mover = self else mover = mount end
		local ret = mount:callTalent(mount.T_GO_FOR_THE_THROAT, "doAttack", mover, target)
		if ret then mount:startTalentCooldown(mount.T_GO_FOR_THE_THROAT) end
		return ret
	end,
	info = function(self, t)
		if not self.outrider_pet then return [[Without a wolf, you cannot use Command: Go For The Throat.]]
		else return ([[The wolf dashes forward to make a ferocious crippling blow against a stunned, pinned or disabled enemy for %d%% damage; if this hits, it also causes bleeding for 60%% of this damage over 5 turns.]]):
			format(100 * t.getDamage(self, t))
		end
	end
}

newTalent{
	name = "Fetch!",
	short_name = "FETCH",
	type = {"wolf/tenacity", 4},
	points = 5,
	require = mnt_dex_req4,
	cooldown = 30,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 } },
	range = function(self, t) return self:combatTalentScale(t, 2, 4) end,
	getDam = function (self, t) return self:combatTalentPhysicalDamage(t, 15, 35) end,
	getBonusPct = function (self, t) return self:combatTalentScale(t, 130, 170) end,
	getReduction = function (self, t) return self:combatTalentScale(t, 5, 12) end,
	getDur = function(self, t) return self:combatTalentScale(t, 4, 7) end,
	on_pre_use= function(self, t, silent)
		return false
	end,
	shared_talent = "T_FETCH_COMMAND",
	on_learn = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	on_unlearn = function(self, t, p)
  		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithOwner(self, t)
		end
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		if self:attr("never_move") then tg.range=1 end
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		--TODO: Maybe use something more mount-centric than self.rider:isMounted()
		local ret = t.doAttack(self, t, target)
		local owner = self.owner
		if ret and owner then owner:startTalentCooldown(t.shared_talent) end
		return ret
	end,
	--Modular action function so can be invoked by either mount or rider
	doAttack = function(self, t, target)
		local x, y = target.x, target.y
		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local linestep = self:lineFOV(x, y, block_actor)
		
		local tx, ty, lx, ly, is_corner_blocked 
		repeat  -- make sure each tile is passable
			tx, ty = lx or self.x, ly or self.y
			lx, ly, is_corner_blocked = linestep:step()
		until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
		if not tx or core.fov.distance(x, y, tx, ty) > 1 then return nil end

		local ox, oy = self.x, self.y
		self:move(tx, ty, true)
		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(ox, oy, 8, 5)
		end

		if core.fov.distance(self.x, self.y, x, y) ~= 1 then return true end
		local hit = self:startGrapple(target)
		local duration = t.getDur(self, t)
		local eff = target:hasEffect(target.EFF_GRAPPLED)
		if eff then
			eff.power = t.getDam(self, t)
			eff.dur = t.getDur(self, t)
			self:setEffect(self.EFF_FETCH, t.getDur(self, t), {target=target})
			local owner = self.owner
			if owner then
				target:setEffect(target.EFF_FETCH_VULNERABLE, t.getDur(self, t), {pct=t.getBonusPct(self, t), src=owner})
			end
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		local dur = t.getDur(self, t)
		local reduction = t.getReduction(self, t)
		local bonus_pct = t.getBonusPct(self, t)
		return ([[The wolf attempts to grab an enemy of up to 1 size category larger than itself, ravaging it within its jaws for %d damage, and reducing its attack and defense by %d. If it succeeds, it will drag its target to its owner over a period of %d turns, granting a %d%% increase in damage when the owner first attacks it within melee range.

			The wolf will only use this ability at the command of its owner, and only then when not mounted.]]):
		format(dam, reduction, dur, bonus_pct)
	end,
}

newTalent{
	name = "Command: Fetch!",
	short_name = "FETCH_COMMAND", image = "talents/fetch.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	cooldown = 30,
	requires_target = true,
	base_talent = "T_FETCH",
	tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3, CUT = 1} },
	-- tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3, CUT = 1} }, --TODO: Decide on how summon controls are handled tactically
	getDamage = function (self, t) return self.outrider_pet:callTalent(self.outrider_pet.T_FETCH, "getDamage") end,
	range = function (self, t) return self.outrider_pet:callTalent(self.outrider_pet.T_FETCH, "range") end,
	on_pre_use = function(self, t)
		local pet = self.outrider_pet
		return pet and not pet:isTalentCoolingDown(pet.T_FETCH) or false
	end,
	action = function(self, t)
		local pet = self.outrider_pet
		local t2 = pet:getTalentFromId(pet.T_FETCH)

		local tg = {type="hit", start_x=pet.x, start_y=pet.y, range=pet:getTalentRange(t2)}
		if self:attr("never_move") then tg.range=1 end
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(pet.x, pet.y, x, y) > pet:getTalentRange(t2) then return nil end

		local ret = pet:callTalent(pet.T_FETCH, "doAttack", target)
		if ret then pet:startTalentCooldown(pet.T_FETCH) end
		return ret
	end,
	info = function(self, t)
		local pet = self.outrider_pet
		if not pet then return [[Without a wolf, you cannot use Command: Fetch!]]
		else
			local t2=self:getTalentFromId(pet.T_FETCH)
			local dam = t2.getDam(pet, t2)
			local dur = t2.getDur(pet, t2)
			local reduction = t2.getReduction(pet, t2)*100
			local bonus_pct = t2.getBonusPct(pet, t2)
			return ([[The wolf attempts to grab an enemy of up to 1 size category larger than itself, ravaging it within its jaws for %d damage, and reducing its attack and defense by %d. If it succeeds, it will drag its target to its owner over a period of %d turns, granting a %d%% increase in damage when the owner first attacks it within melee range.

			The wolf will only use this ability at the command of its owner, and only then when not mounted.]]):
			format(dam, reduction, dur, bonus_pct)
		end
	end
}

newTalent{
	name = "Loyal to the Pack",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req1,
	mode = "passive",
	getStatBoost = function(self, t) return self:getTalentLevelRaw(t) * 4 end,
	getRegen = function(self, t) return self:getTalentLevelRaw(t)*.2  end,
	getSaves = function(self, t) return self:getTalentLevelRaw(t) * 7 end,
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
		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithOwner(self, t)
		end
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
	type = {"wolf/pack-hunter", 2},
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
		return ([[The wolf gains a +%d%% healing modifier bonus and each heal or inscription usage restores its loyalty to you by an additional %d points. Also, when your health is below %d%% of its total, if your wolf is not adjacent to you, it will activate Together, Forever to come rushing to your side, attacking any one nearby enemy for %d%% damage (maximum range %d). This ability has a cooldown of %d.]]):
		format(heal_mod, regen, threshold, dam, range, cooldown)
	end
}

newTalent{
	name = "Predatory Flanking",
	type = {"wolf/pack-hunter", 3},
	points = 5,
	require = mnt_cun_req3,
	mode = "passive",
	getPct = function(self, t) return 15 + (self:getTalentLevel(t) + self:getTalentLevelRaw(t))/2 * 10 end,
	getSecondaryPct = function(self, t)
		return math.round(self:combatTalentScale(t, 5, 15), .5)
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
	callbackOnMove = function(self, t, ...)
		t.doCheck(self, t)
	end,
	info = function(self, t)
		local pct = t.getPct(self, t)
		local secondary = t.getSecondaryPct(self, t)
		return ([[If you and one of your allies both stand adjacent to the same enemy (but not adjacent to one another), then your damage against that foe is increased by %d%%, and your flanking ally's damage by %.1f%%.]])
			:format(pct, secondary)
		end,
}

newTalent{
	name = "Howl to the Moon",
	type = {"wolf/pack-hunter", 4},
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