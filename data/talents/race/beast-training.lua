newTalent{
	name = "Brute Strength", short_name = "OUTRIDER_BRUTE_STRENGTH", image = "talents/brute_strength.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	info = function(self, t)
		local percent_inc = t.getPercentInc(self, t)*100
		return ([[Your beast is a prodigy of size and sinew, growing in strength well beyond the norm. Gain %d%% increased melee attack damage.]]):
		format(percent_inc)
	end,
	getPercentInc = function(self, t) return math.sqrt(self:getTalentLevel(t) / 5) / 1.5 end,
}

newTalent{
	name = "Natural Armour", short_name = "OUTRIDER_NATURAL_ARMOUR", image = "talents/natural_armour.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_armor", t.getArmour(self, t))
		self:talentTemporaryValue(p, "combat_armor_hardiness", t.getArmourHardiness(self, t))
	end,
	info = function(self, t)
		local armour = t.getArmour(self, t)
		local armour_hardiness = t.getArmourHardiness(self, t)

		return ([[As your beast has grown in prowess, its outer hide has thickened and hardened, becoming like a natural layer of armour. Gain %d points of armour and %d%% armour hardiness.]]):
		format(armour, armour_hardiness)
	end,
	getArmour = function(self, t) return self:combatTalentScale(t, 10, 25, 0.35) end,
	getArmourHardiness = function(self, t) return self:combatTalentLimit(t, 50, 30, 45) end,
}

newTalent{
	name = "Staying Power", short_name = "OUTRIDER_STAYING_POWER", image = "talents/staying_power.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "stun_immune", t.getRes(self, t))
		self:talentTemporaryValue(p, "pin_immune", t.getRes(self, t))
		self:talentTemporaryValue(p, "knockback_immune", t.getRes(self, t))
		self:talentTemporaryValue(p, "fear_immune", t.getRes(self, t))
	end,
	info = function(self, t)
		local res = t.getRes(self, t)

		return ([[Constant battle has honed your beast's powers of resilience, allowing it stay in the fight for longer. Gain %d%% stun resist, %d%% pin resist, %d%% knockback resist and %d%% fear resist.]]):
		format(res, res, res, res)
	end,
	getRes = function(self, t)
		local base = self:combatTalentLimit(t, 100, 20, 65)
		--I couldn't stand the scaling of 20, 39, 51, so let's change it to 20, 40, 50
		if self:getTalentLevelRaw(t) <= 5 and self:getTalentTypeMastery(t.type[1])==1 then
			base = math.round(base, 5)
		end
		return base
	end,
}

newTalent{
	name = "Elemental Adaptation", short_name = "OUTRIDER_ELEMENTAL_ADAPTATION", image = "talents/elemental_adaptation.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	levelup_screen_break_line = true,
	points = 5,
	passives = function(self, t, p)
		local res = t.getRes(self, t)
		self:talentTemporaryValue(p, "resists", {
			fire = res,
			cold = res,
			lightning = res,
			acid = res,
			nature = res,
			light = res,
			darkness = res,
			blight = res,
			temporal = res,
			arcane = res,
		})
	end,
	info = function(self, t)
		local res = t.getRes(self, t)

		return ([[Exposure to many of this world's toughest terrains and most dangerous denizens has acclimatized your beast to magic and elemental attacks, granting resistance to all non-physical, non-mind damage of %d%%.]]):
		format(res)
	end,
	getRes = function(self, t) return self:combatTalentLimit(t, 35, 6.5, 20) end,
}

newTalent{
	name = "Survival Instincts", short_name = "OUTRIDER_SURVIVAL_INSTINCTS", image = "talents/survival_instincts.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "die_at", -t.getLife(self, t))
	end,
	callbackOnLevelup = function(self, t ,level)
		self:updateTalentPassives(t.id)
	end,
	callbackOnTakeDamage = function(self, t)
		-- Do this at the end of the tick, as we haven't taken damage yet.
		game:onTickEnd(function()
			t.doCheck(self, t)
		end, "check_survival_instincts")
	end,
	callbackOnAct = function(self, t)
		t.doCheck(self, t)
	end,
	doCheck = function(self, t)
		if self.life < 0 and not self.dead then
			self:setEffect(self.EFF_OUTRIDER_SURVIVAL_INSTINCTS, 2, {life_pct_needed=25})
		end
	end,
	info = function(self, t)
		local life = t.getLife(self, t)
		local recovery = t.getRecoveryRatio(self, t)*100

		return ([[Your beast is unnaturally surviveable—but on its own terms. It will not die until it reaches %d negative life points (scaling with talent and character level), but instead, going below 0 life, it will lose all Loyalty toward you and flee. You may soothe it by standing next to it and not doing anything else; each turn doing this regains %d%% of max life. At 25%% life it will return to your side to fight anew.]]):
		format(life, recovery)
	end,
	getLife = function(self, t)
		local base = 40 + self.level * 4 
		return base * self:combatTalentScale(t, .7, 1.5)
	end,
	getRecoveryRatio = function(self, t) return self:combatTalentScale(t, .03, .1) end,
}

newTalent{
	name = "Killing Force", short_name = "OUTRIDER_KILLING_FORCE", image = "talents/killing_force.png",
	type = {"race/beast-training", 1},
	mode = "passive",
	points = 5,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "resists_pen", {[DamageType.PHYSICAL] = t.getPhysPen(self, t)})
		self:talentTemporaryValue(p, "combat_apr", t.getAPR(self, t))
	end,
	info = function(self, t)
		local phys_pen = t.getPhysPen(self, t)
		local apr = t.getAPR(self, t)

		return ([[Fangs sharpened and claws honed on the field of war, your beast has learnt how to strike a swift killing blow. Increase your beast's physical resistance penetration by %d%% and armour penetration by %d.]]):
		format(phys_pen, apr)
	end,
	getAPR = function(self, t) return self:combatTalentScale(t, 7, 25) end,
	getPhysPen = function(self, t) return self:combatTalentLimit(t, 75, 20, 50) end,
}