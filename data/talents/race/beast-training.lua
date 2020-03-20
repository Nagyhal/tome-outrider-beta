newTalent{
	name = "Staying Power",
	-- short_name = "",
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
		if stat == self.STAT_STR or stat == self.STAT_CON then
			self:updateTalentPassives(t.id)
			-- t.on_unlearn(self, t, p)
			-- t.on_learn(self, t)
		end	
	end,
	info = function(self, t)
		local armour = t.getArmour(self, t)
		local armour_hardiness = t.getArmourHardiness(self, t)
		local save = t.getSave(self, t)
		local life = t.getLife(self, t)

		local total = math.max(0, self:getStat("str") - 10) + math.max(0, self:getStat("con") - 10)

		local total_armour = t.getArmour(self, t)*total
		local total_armour_hardiness = t.getArmourHardiness(self, t)*total
		local total_save = t.getSave(self, t)*total
		local total_life = t.getLife(self, t)*math.max(0, self:getStat("con") - 10)

		return ([[Gain %.2f points of armour, %.2f%% armour hardiness and %.2f points of physical and spell save for each point of Constituion and Strength above 10.

			%s:
			Armour +%d
			Armour Hardiness: +%.1f%%
			Physical Save: +%d
			Spell Save: +%d]]):
		format(armour, armour_hardiness, save,
			self:knowTalent(t) and "Values at level 1" or "Current Values",
				total_armour, total_armour_hardiness, total_save, total_save)
	end,
	getArmour = function(self, t) return self:combatTalentScale(t, .5, 1) end,
	getArmourHardiness = function(self, t) return self:combatTalentScale(t, .7, 1) end,
	getSave = function(self, t) return self:combatTalentScale(t, .75, 1.25) end,
	getLife = function(self, t) return self:combatTalentScale(t, 1, 6) end,
}

newTalent{
	name = "Hunting Prowess",
	-- short_name = "	",
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

		local total = math.max(0, self:getStat("dex") - 10) + math.max(0, self:getStat("cun") - 10)
		local total_phys_pen = t.getPhysPen(self, t)*total
		local total_crit_chance = t.getCritChance(self, t)*total
		local total_crit_power = t.getCritPower(self, t)*total
		local total_apr = t.getAPR(self, t)*math.max(0, self:getStat("cun") - 10)

		return ([[Increase physical resistance penetration by %.2f%%, critical chance by %.2f%% and critical damage by %.2f%% for each point of Dexterity and Cunning above 10.
			Levelling Cunning above 10 also increases APR by %.2f%% for each point.

			%s:
			Physical Resistance Penetration: +%d%%
			Critical Chance: +%d%%
			Criticial Power: +%d%%
			APR: +%d]]):
		format(phys_pen, crit_chance, crit_power, apr,
				self:knowTalent(t) and "Values at level 1" or "Current Values",
				total_phys_pen, total_crit_chance, total_crit_power, total_apr)
	end,
	getPhysPen = function(self, t) return self:combatTalentScale(t, .45, .7) end,
	getCritChance = function(self, t) return self:combatTalentScale(t, .1, .2) end,
	getCritPower = function(self, t) return self:combatTalentScale(t, .3, .5) end,
	getAPR = function(self, t) return self:combatTalentScale(t, .75, 1) end,
}

newTalent{
	name = "Fortitude",
	-- short_name = "	",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	no_unlearn_last = true,
	passives = function(self, t, p)
		local con, wil = math.max(0, self:getStat("con") - 10), math.max(0, self:getStat("wil") - 10)
		local total = con+wil

		self:talentTemporaryValue(p, "resists", {all = t.getResistAll(self, t)*total})
		self:talentTemporaryValue(p, "ignore_direct_crits", t.getShrugoffChance(self, t)*total)

		self:talentTemporaryValue(p, "max_life", t.getLife(self, t)*con)
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
		local life = t.getLife(self, t)

		local total = math.max(0, self:getStat("con") - 10) + math.max(0, self:getStat("wil") - 10)
		local total_resist_all = resist_all*total
		local total_shrugoff_chance = shrugoff_chance*total
		local total_life = life*math.max(0, self:getStat("con") - 10) 

		return ([[Increase resist all by %.2f%%, and reduce chance to be critically hit by %.2f%% for each point of Willpower and Constitution above 10.
			Levelling Constitution also grants %.1f additional life.

			%s:
			Resist All +%.1f%%
			Crit Shrug Off Chance: +%.1f%%
			Max Life: +%d]]):
		format(resist_all, shrugoff_chance, life,
				self:knowTalent(t) and "Values at level 1" or "Current Values",
				total_resist_all, total_shrugoff_chance, total_life)
	end,
	getShrugoffChance = function(self, t) return self:combatTalentScale(t, .3, .5) end,
	getResistAll = function(self, t) return self:combatTalentScale(t, .2, .35) end,
	getLife = function(self, t) return self:combatTalentScale(t, 1, 8) end,
}

newTalent{
	name = "Grit",
	-- short_name = "	",
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

		local total = math.max(0, self:getStat("str") - 10) + math.max(0, self:getStat("dex") - 10)
		local total_res = res*total

		return ([[Gain %.1f%% stun resist, %.1f%% pin resist, %.1f%% knockback resist and %.1f%% fear resist for each point of Strength and Dexterity above 10.

			%s:
			Stun Resist: +%.1f%%
			Pin Resist: +%.1f%%
			Knockback Resist: +%.1f%%
			Fear Resist: +%.1f%%]]):
		format(res, res, res, res,
				self:knowTalent(t) and "Values at level 1" or "Current Values",
				total_res, total_res, total_res, total_res)
	end,
	getRes = function(self, t) return self:combatTalentScale(t, .5, 1) end,
}