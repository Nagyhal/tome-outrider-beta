newTalent{
	name = "Fortitude", short_name = "OUTRIDER_FORTITUDE", image = "talents/fortitude.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	no_unlearn_last = true,
	passives = function(self, t, p)
		local str, con = math.max(0, self:getStat("str") - 10), math.max(0, self:getStat("con") - 10)
		local total = str+con

		self:talentTemporaryValue(p, "combat_armor", t.getArmour(self, t)*total)
		self:talentTemporaryValue(p, "combat_armor_hardiness", t.getArmourHardiness(self, t)*total)
		self:talentTemporaryValue(p, "combat_physresist", t.getSave(self, t)*total)
		self:talentTemporaryValue(p, "combat_spellresist", t.getSave(self, t)*total)
	end,
	on_learn = function(self, t)
	end,
	on_unlearn = function(self, t, p)
	end,
	callbackOnStatChange = function(self, t, stat, v)
		if stat == self.STAT_CON or stat == self.STAT_WIL then
			self:updateTalentPassives(t.id)
			-- t.on_unlearn(self, t, p)
			-- t.on_learn(self, t)
		end	
	end,
	info = function(self, t)
		local armour = t.getArmour(self, t)
		local armour_hardiness = t.getArmourHardiness(self, t)
		local save = t.getSave(self, t)

		local armour_inc = t.getArmourInc(self, t)
		local armour_hardiness_inc = t.getArmourHardinessInc(self, t)
		local save_inc = t.getSaveInc(self, t)

		local total = math.max(0, self:getStat("str") - 10) + math.max(0, self:getStat("con") - 10)

		local total_armour = armour_inc*total
		local total_armour_hardiness = armour_hardiness_inc*total
		local total_save = save_inc*total

		return ([[Constant battle has honed your beast's powers of resilience, allowing it stay in the fight for longer. Gain %d points of armour, %d%% armour hardiness and %d points of physical and spell save.

			Also, Consitution above 10 will now increase armour by %.2f.
			Willpower above 10 will improve physical and spell save by %.2f.

			%s:
			Armour +%d
			Physical Save: +%d
			Spell Save: +%d]]):
		format(armour, armour_hardiness, save,
			armour_inc, save_inc,
			self:knowTalent(t) and "Bonuses at level 1" or "Current Bonuses",
				total_armour, total_save, total_save)
	end,
	getArmour = function(self, t) return self:combatTalentScale(t, 10, 25, 0.35) end,
	getArmourHardiness = function(self, t) return self:combatTalentLimit(t, 50, 30, 45) end,
	getSave = function(self, t) return self:combatTalentScale(t, 7, 27) end,

	getArmourInc = function(self, t) return self:combatTalentScale(t, .5, 1) end,
	getArmourHardinessInc = function(self, t) return self:combatTalentScale(t, .7, 1) end,
	getSaveInc = function(self, t) return self:combatTalentScale(t, .25, .4) end,
	getLifeInc = function(self, t) return self:combatTalentScale(t, 1, 4) end,
}

newTalent{
	name = "Hunting Prowess", short_name = "OUTRIDER_HUNTING_PROWESS", image = "talents/hunting_prowess.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	no_unlearn_last = true,
	passives = function(self, t, p)
		local dex, cun = math.max(0, self:getStat("dex") - 10), math.max(0, self:getStat("cun") - 10)
		local total = dex+cun

		self:talentTemporaryValue(p, "resists_pen", {[DamageType.PHYSICAL] = t.getPhysPen(self, t)*total})

		self:talentTemporaryValue(p, "combat_physcrit", t.getCritChance(self, t)*total)
		self:talentTemporaryValue(p, "combat_spellcrit", t.getCritChance(self, t)*total)
		self:talentTemporaryValue(p, "combat_mindcrit", t.getCritChance(self, t)*total)

		self:talentTemporaryValue(p, "combat_critpower", t.getCritPower(self, t)*total)
		--con life boost found in on_learn
		--armor
		self:talentTemporaryValue(p, "combat_apr", t.getAPR(self, t)*cun)
	end,
	on_learn = function(self, t)
	end,
	on_unlearn = function(self, t, p)
	end,
	callbackOnStatChange = function(self, t, stat, v)
		if stat == self.STAT_WIL or stat == self.STAT_CUN then
			self:updateTalentPassives(t.id)
			-- t.on_unlearn(self, t, p)
			-- t.on_learn(self, t)
		end	
	end,
	info = function(self, t)
		local phys_pen = t.getPhysPen(self, t)
		local crit_chance = t.getCritChance(self, t)
		local crit_power = t.getCritPower(self, t)
		local apr = t.getAPR(self, t)

		local phys_pen_inc = t.getPhysPenInc(self, t)
		local crit_chance_inc = t.getCritChanceInc(self, t)
		local crit_power_inc = t.getCritPowerInc(self, t)
		local apr_inc = t.getAPRInc(self, t)

		local total = math.max(0, self:getStat("dex") - 10) + math.max(0, self:getStat("cun") - 10)
		local total_phys_pen = phys_pen_inc*total
		local total_crit_chance = crit_chance_inc*total
		local total_crit_power = crit_power_inc *total
		local total_apr = apr_inc*math.max(0, self:getStat("cun") - 10)

		return ([[By tooth or claw, your beast learns to take down its mark. Increase your beast's physical resistance penetration by %d%% and armour penetration by %d.

			Also, Cunning above 10 will now increase critical power by %.2f%%

			%s:
			Critical Power: +%d%%]]):
		format(phys_pen, apr, crit_power_inc,
				self:knowTalent(t) and "Bonuses at level 1" or "Current Bonuses",
				total_crit_power)
	end,
	getPhysPen = function(self, t) return self:combatTalentLimit(t, 75, 20, 50) end,
	getAPR = function(self, t) return self:combatTalentScale(t, 7, 25) end,
	getCritChance = function(self, t) return self:combatTalentScale(t, .1, .2) end,
	getCritPower = function(self, t) return self:combatTalentScale(t, .3, .5) end,

	getPhysPenInc = function(self, t) return self:combatTalentScale(t, .45, .7) end,
	getCritChanceInc = function(self, t) return self:combatTalentScale(t, .1, .2) end,
	getCritPowerInc = function(self, t) return self:combatTalentScale(t, .3, .5) end,
	getAPRInc = function(self, t) return self:combatTalentScale(t, .75, 1) end,
}

newTalent{
	name = "Staying Power", short_name = "OUTRIDER_STAYING_POWER", image = "talents/staying_power.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	no_unlearn_last = true,
	passives = function(self, t, p)
		local con, wil = math.max(0, self:getStat("con") - 10), math.max(0, self:getStat("wil") - 10)
		local total = con+wil

		self:talentTemporaryValue(p, "resists", {all = t.getResistAll(self, t)*total})
		self:talentTemporaryValue(p, "ignore_direct_crits", t.getShrugoffChance(self, t)*total)

		self:talentTemporaryValue(p, "max_life", t.getLifeInc(self, t)*con)
	end,
	on_learn = function(self, t)
	end,
	on_unlearn = function(self, t, p)
	end,
	callbackOnStatChange = function(self, t, stat, v)
		if stat == self.STAT_CON or stat == self.STAT_WIL then
			self:updateTalentPassives(t.id)
			-- t.on_unlearn(self, t, p)
			-- t.on_learn(self, t)
		end	
	end,
	info = function(self, t)
		local resist_all = t.getResistAll(self, t)
		local shrugoff_chance = t.getShrugoffChance(self, t)
		local life_inc = t.getLifeInc(self, t)

		local total = math.max(0, self:getStat("con") - 10)
		local total_life = life_inc*total 

		return ([[Increase resist all by %d%%, and reduce chance to be critically hit by %d%%.

			Also, levelling Constitution grants %.1f additional life.

			%s:
			Max Life: +%d]]):
		format(resist_all, shrugoff_chance, life_inc,
				self:knowTalent(t) and "Bonuses at level 1" or "Current Bonuses",
				total_life)
	end,
	getShrugoffChance = function(self, t) return self:combatTalentLimit(t, 50, 20, 35) end,
	getResistAll = function(self, t) return self:combatTalentLimit(t, 35, 6.5, 20) end,
	getLifeInc = function(self, t) return self:combatTalentScale(t, 1, 4) end,
}

newTalent{
	name = "Grit", short_name = "OUTRIDER_GRIT", image = "talents/grit.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	no_unlearn_last = true,
	passives = function(self, t, p)
		local str, dex = math.max(0, self:getStat("str") - 10), math.max(0, self:getStat("dex") - 10)
		local total = str+dex

		self:talentTemporaryValue(p, "stun_immune", t.getRes(self, t)*total/100)
		self:talentTemporaryValue(p, "pin_immune", t.getRes(self, t)*total/100)
		self:talentTemporaryValue(p, "knockback_immune", t.getRes(self, t)*total/100)
		self:talentTemporaryValue(p, "fear_immune", t.getRes(self, t)*total/100)
	end,
	on_learn = function(self, t)
	end,
	on_unlearn = function(self, t, p)
	end,
	callbackOnStatChange = function(self, t, stat, v)
		if stat == self.STAT_STR or stat == self.STAT_DEX then
			self:updateTalentPassives(t.id)
			-- t.on_unlearn(self, t, p)
			-- t.on_learn(self, t)
		end	
	end,
	info = function(self, t)
		local res = t.getRes(self, t)

		-- local total = math.max(0, self:getStat("str") - 10) + math.max(0, self:getStat("dex") - 10)
		-- local total_res = res*total

		return ([[Gain %d%% stun resist, %d%% pin resist, %d%% knockback resist and %d%% fear resist.]]):

			-- %s:
			-- Stun Resist: +%.1f%%
			-- Pin Resist: +%.1f%%
			-- Knockback Resist: +%.1f%%
			-- Fear Resist: +%.1f%%]]):
		format(res, res, res, res)
				-- self:knowTalent(t) and "Values at level 1" or "Current Values",
				-- total_res, total_res, total_res, total_res)
	end,
	getRes = function(self, t) return self:combatTalentLimit(t, 100, 20, 65) end,
}