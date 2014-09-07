--Wolf talents
newTalent{
	name = "Sly Senses",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_dex_req1,
	mode = "passive",
	getDexterity = function(self, t) return self:getTalentLevelRaw(t) * t.getDexterityInc(self, t) end,
	getDefense = function(self, t) return self:getTalentLevelRaw(t) * t.getDefenseInc(self, t) end,
	getSaves = function(self, t) return self:getTalentLevelRaw(t) * t.getSavesInc(self, t) end,
	--If I want to tweak this I only want to change 1 of the following functions - extensibility, essentially.
	getDexterityInc = function(self, t) return 2 end,
	getDefenseInc = function(self, t) return 3 end,
	getSavesInc = function(self, t) return 3 end, 
	on_learn = function(self, t)
		-- local dex = 2
		-- local def = 3
		-- local saves = 3
		self.inc_stats[self.STAT_DEX] = self.inc_stats[self.STAT_DEX] + t.getDexterityInc(self, t)
		self:onStatChange(self.STAT_DEX,  t.getDexterityInc(self, t))
		self.combat_def = self.combat_def + t.getDefenseInc(self, t)
		self.combat_physresist = self.combat_physresist + t.getSavesInc(self, t)
		self.combat_spellresist = self.combat_spellresist + t.getSavesInc(self, t)
	end,
	on_unlearn = function(self, t)
		self.inc_stats[self.STAT_DEX] = self.inc_stats[self.STAT_DEX] - t.getDexterityInc(self, t)
		self:onStatChange(self.STAT_DEX, -t.getDexterityInc(self, t))
		self.combat_def = self.combat_def - t.getDefenseInc(self, t)
		self.combat_physresist = self.combat_physresist - t.getSavesInc(self, t)
		self.combat_spellresist = self.combat_spellresist - t.getSavesInc(self, t)
	end,
	info = function(self, t)
		return ([[The wolf gains a %d bonus to Dexterity, a %d bonus to defense and a %d bonus to physical and spell saves.]]):
		format(t.getDexterity(self, t),
		t.getDefense(self, t),
		t.getSaves(self, t)
		)
	end,
}

newTalent{
	name = "Go for the Throat",
	type = {"wolf/tenacity", 1},
	require = mnt_dex_req1,
	points = 5,
	cooldown = 8,
	--stamina = 12,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 , CLOSEIN = 3, CUT = 1} },
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 0.9, 1.4) end,
	range = function (self, t) return 2 + math.floor(self:getTalentLevel(t) / 3) end,
	targetTry = function(self, t)
		return {type="ball", radius=self:getTalentRange(t), 0}
	end,
	on_pre_use = function(self, t)
		local tgs = {}
		local tg_vulnerable = false
		self:project(t.targetTry(self, t), self.x, self.y,
		function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and (target.faction ~= self.faction) then 
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
				--game.logPlayer(self, "There must be a stunned or pinned enemy within talent range!")
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
		--rush routine
		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local l = self:lineFOV(x, y, block_actor)
		--no test for closeness
		-- if is_corner_blocked or game.level.map:checkAllEntities(lx, ly, "block_move", self) then
			-- game.logPlayer(self, "You are too close to build up momentum!")
			-- return
		-- end
		if not is_corner_blocked and not game.level.map:checkAllEntities(lx, ly, "block_move", self) then
			local tx, ty = x, y
			lx, ly, is_corner_blocked = l:step()
			while lx and ly do
				if is_corner_blocked or game.level.map:checkAllEntities(lx, ly, "block_move", self) then break end
				tx, ty = lx, ly
				lx, ly, is_corner_blocked = l:step()
			end

			local ox, oy = self.x, self.y
			self:move(tx, ty)
			if config.settings.tome.smooth_move > 0 then
				self:resetMoveAnim()
				self:setMoveAnim(ox, oy, 8, 5)
			end
		end
		--rush end
		local bonus_multipler = nil
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local freecrit = false
		if target:attr("stunned") or target:attr("confused") then
			freecrit = true
			self.combat_physcrit = self.combat_physcrit + 1000
		end
		local speed, hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		if hit and freecrit then 
			if target:canBe("cut") then target:setEffect(target.EFF_CUT, 5, {power=t.getDamage(self, t)*12, src=self}) end
		end
		if freecrit then	
			self.combat_physcrit = self.combat_physcrit - 1000
		end
		return true
	end,
	info = function(self, t)
		return ([[The wolf makes a ferocious crippling blow for %d%% damage; if the wolf attacks a stunned, pinned or disabled enemy with Go For the Throat, it is a sure critical strike which also causes bleeding for 60%% of this damage over 5 turns.]]):format(100 * t.getDamage(self, t))
	end
}

newTalent{
	name = "Uncanny Tenacity",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_dex_req1,
	mode = "passive",
	getThreshold = function (self, t) return ( 13 + self:getTalentLevelRaw(t) * 12 ) end,
	getSave = function (self, t) return math.floor( 3 * self:getTalentLevel(t)) end,
	--getReduction = function (self, t) return math.floor(10 * self:getTalentLevel(t)) end,
	
	info = function(self, t)
		return ([[The wolf will stop at nothing to hound and harry its prey; if it is inflicted with status effects by an enemy it targets at less than %d%% health, the wolf gains a %d bonus to the relevant save.]]):
		format(t.getThreshold(self, t), t.getSave(self, t))
	end,
}

newTalent{
	name = "Fetch!",
	short_name = "FETCH",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_dex_req1,
	--stamina = 50,
	cooldown = 30,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 } },
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, .6, 1.2) end,
	getReduction = function (self, t) return 3 + math.floor(self:getTalentLevel(t) *1.8) end,
	getFetchDistance = function (self, t) return math.floor(self:getTalentLevel(t) + 1) end,
	getDuration = function(self, t) return 3 + math.floor(self:getTalentLevel(t) / 2) end,
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
		return ([[The wolf attempts to grab an enemy, ravaging it within its jaws for %d damage each turn and reducing its attack and defense by %d. If it succeeds, it will bring it to you within range %d while you are dismounted.]]):
		format(t.getDamage(self, t)*100, t.getReduction(self, t), t.getFetchDistance(self, t))
	end,
}

--Tenacity talents

newTalent{
	name = "Loyal to the Pack",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req1,
	mode = "passive",
	getCunning = function(self, t) return self:getTalentLevelRaw(t) * t.getCunningInc(self, t) end,
	getRegen = function(self, t) return self:getTalentLevelRaw(t) * t.getRegenInc(self, t) end,
	getSaves = function(self, t) return self:getTalentLevelRaw(t) * t.getSavesInc(self, t) end,
	--If I want to tweak this I only want to change 1 of the following functions - extensibility, essentially.
	getCunningInc = function(self, t) return 2 end,
	getRegenInc = function(self, t) return 3 end,
	getSavesInc = function(self, t) return 3 end, 
	on_learn = function(self, t)
		-- local dex = 2
		-- local def = 3
		-- local saves = 3
		self.inc_stats[self.STAT_CUN] = self.inc_stats[self.STAT_CUN] + t.getCunningInc(self, t)
		self:onStatChange(self.STAT_CUN,  t.getCunningInc(self, t))
		--self.combat_def = self.combat_def + t.getRegenInc(self, t)
		self.combat_mentalresist = self.combat_mentalresist + t.getSavesInc(self, t)
	end,
	on_unlearn = function(self, t)
		self.inc_stats[self.STAT_CUN] = self.inc_stats[self.STAT_CUN] - t.getCunningInc(self, t)
		self:onStatChange(self.STAT_CUN, -t.getCunningInc(self, t))
		--self.combat_def = self.combat_def - t.getRegenInc(self, t)
		self.combat_mentalresist = self.combat_mentalresist - t.getSavesInc(self, t)
	end,
	info = function(self, t)
		return ([[The wolf gains a %d bonus to Cunning, a %d bonus to mental saves and a %d bonus to Loyalty regen.]]):
		format(t.getCunning(self, t),
		t.getRegen(self, t),
		t.getSaves(self, t)
		)
	end,
}

newTalent{
	name = "Together, Forever",
	short_name = "TOGETHER_FOREVER",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req1,
	mode = "passive",
	getHealingMod = function(self, t) return 15 + self:getTalentLevel(t) * 10 end,
	getLoyaltyRegen = function(self, t) return 1 + self:getTalentLevel(t) end,
	getHealthThreshold = function(self,t) return 10 + self:getTalentLevel(t) * 2.5 end,
	getRushRange = function(self, t) return 5 + self:getTalentLevelRaw(t) end,
	info = function(self, t) return ([[The wolf gains a +%d%% healing modifier bonus and each heal or inscription usage restores its loyalty to you by %d points. Also, when your health is below %d%% of its total, if your wolf is not adjacent to you, it will activate Steady Companion to come rushing to your side, dealing heavy damage at a maximum range of %d]]):
		format(t.getHealingMod(self, t),
		t.getLoyaltyRegen(self, t),
		t.getHealthThreshold(self, t),
		t.getRushRange(self, t)
		)
	end
}


newTalent{
	name = "Predatory Flanking",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req1,
	mode = "passive",
	getPct = function(self, t) return 15 + (self:getTalentLevel(t) + self:getTalentLevelRaw(t))/2 * 10 end,
	info = function(self, t)
		return ([[If you and one of your allies both stand adjacent to the same enemy, but not adjacent to one another, then your damage is increased by %d%%]]):format(t.getPct(self, t))end,
}

newTalent{
	name = "Howl to the Moon",
	type = {"wolf/pack-hunter", 1},
	points = 5,
	require = mnt_cun_req1,
	cooldown = 50,
	requires_target = true,
	getRareChance = function(self, t) return 12 + self:getTalentLevel(t) * 8 end,
	getConvertChance = function(self, t) return 12 + self:getTalentLevel(t) * 8 end,
	getWolfMin = function(self, t) return math.floor(0.5 + self:getTalentLevel(t) / 2) end,
	getWolfMax = function(self, t) return math.floor(1.5 + self:getTalentLevel(t) / 1.5) end,
	on_pre_use = function(self, t) end,
	action = function(self, t) end,
	info = function(self, t)
		return ([[The wolf summons between %d and %d of its allies, with a %d%% chance for a legendary wolf to be present. Also, as you level this talent, wolves you encounter have a %d%% chance to be friendly if they fail a mental save]]):
		format(
		t.getWolfMin(self, t),
		t.getWolfMax(self, t),
		t.getRareChance(self, t),
		t.getConvertChance(self, t)
		)
	end,
}	

