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
		self.inc_stats[self.STAT_DEF] = self.inc_stats[self.STAT_DEF] + t.getDexterityInc(self, t)
		self:onStatChange(self.STAT_DEF,  t.getDexterityInc(self, t))
		self.combat_def = who.combat_def + t.getDefenseInc(self, t)
		self.combat_physresist = self.combat_physresist + t.getSavesInc(self, t)
	end,
	on_unlearn = function(self, t)
		self.inc_stats[self.STAT_DEF] = self.inc_stats[self.STAT_DEF] - t.getDexterityInc(self, t)
		self:onStatChange(self.STAT_DEF, -t.getDexterityInc(self, t))
		self.combat_def = who.combat_def - t.getDefenseInc(self, t)
		self.combat_physresist = self.combat_physresist - t.getSavesInc(self, t)
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
	stamina = 12,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 } },
	getDamage = function (self, t) return self:combatTalentPhysicalDamage(t, 0.9, 1.4) end,
	targetTry = function(self, t)
		return {type="ball", radius=self:getTalentRange(t), 0}
	end,
	on_pre_use = function(self, t)
		local tgs = {}
		local tg_vulnerable = false
		self:project(t.targetTry(self, t), self.x, self.y,
		function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				tgs[#tgs+1] = target
			end
		end)
		for target in tgs do
			for effect, _ in pairs(target.tmp) do
				if target.tmp.type == "stun" or "pin" then vulnerable = true
				end
			end
		end
		if not tg_vulnerable then game.logPlayer(self, "There must be a stunned or pinned enemy within talent range!")
			return false 
		end
		return true
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local freecrit = false
		if target:attr("stunned") or target:attr("confused") then
			freecrit = true
			self.combat_physcrit = self.combat_physcrit + 1000
		end
		local speed, hit = self:attackTarget(target, nil, t.getDamage(self, t))
		if hit and freecrit then 
			if target:canBe("cut") then target:setEffect(target.EFF_CUT, 5, {power=t.getDamage(self, t)*12, src=self}) end
		end
		if freecrit then	
			self.combat_physcrit = self.combat_physcrit - 1000
		end
		return true
	end,
	info = function(self, t)
		return ([[The wolf makes a ferocious crippling blow for %d damage; if the wolf attacks a stunned, pinned or disabled enemy with Go For the Throat, it is a sure critical strike for which also causes bleeding for 60%% of this damage over 5 turns.]]):format(100 * t.getDamage(self, t))
	end
}

newTalent{
	name = "Uncanny Tenacity",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_str_req1,
	mode = "passive",
	getThreshold = function (self, t) return ( 13 + self:getTalentLevelRaw(t) * 12 ) end,
	getSave = function (self, t) return math.floor( 3 * self:getTalentLevel(t)) end,
	getReduction = function (self, t) return math.floor(10 * self:getTalentLevel(t)) end,
	info = function(self, t)
		return ([[The wolf will stop at nothing to hound and harry its prey; if it is inflicted with status effects by an enemy it targets at less than %d health,  the wolf gains a %d bonus to the relevant save, as well as a %d reduction in status duration should it fail to save.]]):
		format(t.getThreshold(self, t), t.getSave(self, t), t.getReduction(self, t))
	end,
}

newTalent{
	name = "Fetch!",
	short_name = "FETCH",
	type = {"wolf/tenacity", 1},
	points = 5,
	require = mnt_str_req1,
	stamina = 50,
	cooldown = 30,
	requires_target = true,
	tactical = { ATTACK = { PHYSICAL = 2 } },
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, .6, 1.2) end,
	getReduction = function (self, t) return 3 + math.floor(self:getTalentLevel(t) *1.8) end,
	getFetchDistance = function (self, t) return math.floor(self:getTalentLevel(t) + 1) end,
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
