newTalent{
	name = "Aerial Supremacy",
	type = {"drake/dragonflight", 1},
	points = 5,
	require = techs_dex_req1,
	mode = "passive",
	shared_talent = "T_AERIAL_SUPREMACY_SHARED",
	callbackOnMounted = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	callbackOnDismounted = function(self, t)
		unshareTalentWithOwner(self, t)
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		if not ox or not oy or (ox==self.x and oy==self.y) then return end

		for i = 1, core.fov.distance(self.x, self.y, ox, oy) do
			if not self:attr("building_aerial_supremacy") then
				self:attr("building_aerial_supremacy", 1, true)
			else
				local p = self:hasEffect(self.EFF_STRIKE_AT_THE_HEART)
				self:setEffect(self.EFF_AERIAL_SUPREMACY, 3, {
				power=t.getBuff(self, t)
				}) 
			end
		end
		self.turn_procs["sustain_aerial_supremacy"] =true
	end,
	callbackOnAct = function(self, t)
		if not self.turn_procs.sustain_aerial_supremacy then
			self:attr("building_aerial_supremacy", 0, true)
		end
	end,
	info = function(self, t)
		local buff = t.getBuff(self, t)
		local res = t.getRes(self, t)
		return ([[Gain %d attack, defense, and physical resist for 2 turns after moving at least two squares. In addition your base stun, knockback and blind resistance, gain a %d%% base pin and fear resistance.

		Your rider will share these benefits.]]):
		format(buff, res)
	end,
	getBuff = function(self, t) return self:combatTalentScale(t, 8, 20) end,
	getRes = function(self, t) return self:combatTalentLimit(t, 65, 10, 50) end,

}

newTalent{
	name = "Aerial Supremacy (Shared)",
	short_name = "AERIAL_SUPREMACY_SHARED",
	type = {"mounted/mounted-base", 1},
	points = 1,
	mode = "passive",
	base_talent = "T_AERIAL_SUPREMACY",
	passives = function(self, t, p)
		local mount = self:hasMount()
		local t2 = self:getTalentFromId(t.base_talent)
		self:talentTemporaryValue(p, "pin_immune",  t2.getRes(mount, t2))
		self:talentTemporaryValue(p, "fear_immune",  t2.getRes(mount, t2))
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		local t2 = self:getTalentFromId(t.base_talent)
		return t2.callbackOnMove(self, t2, moved, force, ox, oy, x, y)
	end,
	info = function(self, t)
		local t2 = self:getTalentFromId(t.base_talent)
		local mount = self:hasMount(self, t)
		local buff = t2.getBuff(mount, t2)
		local res = t2.getRes(mount, t2)
		return ([[You have subdued and mounted a great drake! Move two squares in a row to gain %d attack, defense, and physical resist.

			You also share some of the defenses of your beast: a %d%% bonus to pin and fear resistance.]]):
		format(buff, res)
	end,
}

newTalent{
	name = "Carry Aloft",
	type = {"drake/dragonflight", 2},
	require = techs_dex_req1,
	points = 5,
	requires_target = true,
	direct_hit = true,
	tactical = { CLOSEIN = 3, DISABLE = { pin = 2 }  },
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	radius = function(self, t) return self:combatTalentScale(t, 3, 5) end,
	target = function(self, t) return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, talent=t} end,
	action = function(self, t)
		local tg = {type="hit", range=1}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local dam = t.getDamage(self, t)

		if target:canBe("knockback") or rng.percent(t.getKBResistPen(self, t)) then
			self:project({type="hit", range=tg.range}, target.x, target.y, DamageType.PHYSICAL, dam) --Direct Damage
			local tx, ty = util.findFreeGrid(x, y, self:getTalentRadius(t), true, {[Map.ACTOR]=true})
			if tx and ty then
				local ox, oy = target.x, target.y
				target:move(tx, ty, true)
				if config.settings.tome.smooth_move > 0 then
					target:resetMoveAnim()
					target:setMoveAnim(ox, oy, 8, 5)
				end
			end
			tg.act_exclude = {[target.uid]=true} -- Don't hit primary target with AOE
			--Move near our target
			local mx, my = util.findFreeGrid(x, y, 2, false, engine.Map.ACTOR)
			self:move(mx, my, force)	
		else --If the target resists the knockback, do half damage to it.
			target:logCombat(self, "#YELLOW##Source# resists #Target#'s attempt to carry it aloft!")
			self:project({type="hit", range=tg.range}, target.x, target.y, DamageType.PHYSICAL, dam/2)
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		local range = self:getTalentRadius(t)
		local kb_resist_pen = t.getKBResistPen(self, t)
		return ([[Drag a foe into the air, hurtling it and yourself at a location within radius %d, dealing %d%% physical damage increased by 50%% if it is a wall. You will land in a random square of maximum 2 distance from your target. This talent ignores %d%% of the knockback resistance of the thrown target, which takes half damage if it resists being thrown.

		Alternatively, you may use a tempered version of this ability on an ally. In this case, you will deal no damage and land gently in a square of guaranteed distance 1.]]):
		format(range, dam, kb_resist_pen)
	end,
	getDam = function(self, t) return self:combatTalentPhysicalDamage(t, 80, 250) end,
	getKBResistPen = function(self, t) return self:combatTalentLimit(t, 75, 20, 45) end,
}

newTalent{
	name = "Leviathan",
	type = {"drake/dragonflight", 3},
	require = techs_dex_req3,
	points = 5,
	mode = "passive",
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "inc_stats", {
			[Stats.STAT_STR] = math.floor(t.getBonus(self, t)),
			[Stats.STAT_DEX] = math.floor(t.getBonus(self, t)),
			[Stats.STAT_MAG] = math.floor(t.getBonus(self, t))
		})
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		if not core.fov.distance(self.x, self.y, ox, oy) then return end
		local ab = self.__talent_running; if not ab then return end
		self.turn_procs.leviathan = {}
	end,
	info = function(self, t)
		local bonus = t.getBonus(self, t)
		local chance = t.getChance(self, t)
		local stun_dur = t.getStunDur(self, t)
		return ([[Gain %d Strength, Constitution and Willpower.

		In addition, any time you move more than 1 square as part of an attack, you have a %d%% chance to inflict a %d turn stun on any enemies you damage that turn.]]):
		format(bonus, chance, stun_dur)
	end,
	getBonus = function(self, t) return self:combatTalentScale(t, 3, 15) end,
	getChance = function(self, t) return self:combatTalentScale(t, 40, 50) end,
	getStunDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
}

newTalent{
	name = "Dive Bomb",
	type = {"drake/dragonflight", 4},
	require = techs_dex_req4,
	points = 5,
	tactical = { CLOSEIN = 1, BUFF = 1,  DISABLE = { knockback = 1 } },
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	radius = function(self, t) return self:combatTalentScale(t, 3, 5) end,
	target = function(self, t) return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, talent=t} end,
	activate = function(self, t)
		return {charges=0}
	end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(self.T_DIVE_BOMB)
		if p.ct>=3 then self:forceUseTalent(t.id, {no_energy=true}) end
		p.ct = p.ct+1
	end,
	deactivate = function(self, t, p)
		local tg = {type="ball", range=0, selffire=false, radius=self:getTalentRadius(t)}

		--Do the damage component first, rather than in the midst of a bundle of recursive knockbacks
		self:project(tg, self.x, self.y, engine.DamageType.PHYSICAL, t.getDam(self, t))

		local recursive = function(target)
			if self:checkHit(self:combatPhysicalpower(), target:combatPhysicalResist(), 0, 95) and target:canBe("knockback") then 
				return true
			else
				game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
			end
		end

		self:project(tg, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target then
				if not target:canBe("knockback") or not target:knockback(self.x, self.y, t.getDist(self, t), recursive) then
					game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
				end
			end
		end)
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		local radius = self:getTalentRadius(t)
		local knockback = t.getKnockback(self, t)
		local fear_threshold = t.getFearThreshold(self, t)
		local shared_pct = t.getSharedPct(self, t)
		return ([[Charge for up to 3 turns. While you soar aloft, incoming damage is reduced by 75%%, Aerial Supremacy bonuses are automaically gained, and you can not attack nor be targeted by melee abilities. 

			While active, moving will instead try to move you over enemies's heads into the square beyond them. When you deactivate, deal damage equal to %d to all in a radius of %d and knock back those stricken up to %d squares. %d%% of the damage will be shared with you and your rider. Also, gain a damage bonus of 15%% for each turn of charge. If performing this attack, however, would decrease you or your rider's health below %d%% health, then your courage will falter and you will fail to perform the attack.

			Your owner may use this talent as a command.]]):
		format(dam, radius, knockback, shared_pct, fear_threshold)
	end,
	getDam = function(self, t) return self:combatTalentPhysicalDamage(t, 80, 250) end,
	getKnockback = function(self, t) return self:combatTalentScale(t, 2, 4) end,
	getSharedPct = function(self, t) return self:combatTalentLimit(t, 25, 100, 50)  end,
	getFearThreshold = function(self, t) return self:combatTalentLimit(t, 8, 35, 15) end,
}
