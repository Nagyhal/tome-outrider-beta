newTalent{
	name = "Combative",
	short_name = "OUTRIDER_TRAIT_COMBATIVE",  image = "talents/trait_combative.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_physpower", t.getBoost(self, t))
	end,
	callbackOnActBase = function(self, t)
		local ct = 0
		for _, c in pairs(util.adjacentCoords(self.x, self.y)) do
			local target = game.level.map(c[1], c[2], Map.ACTOR)
			if target and self:reactionToward(target) < 0 then ct=ct+1 end
		end
		if ct>0 then
			local chance = t.getChance(self, t)
			local val = util.bound(ct-1, 0, 5)
			local chance = chance + val * t.getAdditonalChance(self, t)
			self:setEffect(self.EFF_EVASION, 2, {chance=chance})
		else
			self:removeEffect(self.EFF_EVASION)
		end
	end,
	info = function(self, t)
		local boost = t.getBoost(self, t)
		local chance = t.getChance(self, t)
		local additional_chance = t.getAdditonalChance(self, t)
		return ([[Gain a %d boost to physical power and a %d%% evasion chance when adjacent to any enemy. Gain an additional %d%% evasion chance for each enemy after the first (up to 6 enemies.)]]):
		format(boost, chance, additional_chance)
	end,
	getBoost = function(self, t) return self:combatTalentScale(t, 7, 20) end,
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 15, 35) end,
	getAdditonalChance = function(self, t) return self:combatTalentLimit(t, 10, 3, 7) end,
}

newTalent{
	name = "Opportunistic",
	short_name = "OUTRIDER_TRAIT_OPPORTUNISTIC", image = "talents/trait_opportunistic.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	shared_talent = "T_OUTRIDER_TRAIT_OPPORTUNISTIC_SHARED",
	on_learn = function(self, t)
		shareTalentWithOwner(self, t)
	end,
	on_unlearn = function(self, t, p)
		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithOwner(self, t)
		end
	end,
	callbackOnKill = function(self, t, target, death_note)
		if rng.percent(t.getChance(self,t)) then
			local filter = function(t)
				if not t.is_inscription then return true end
			end
			self:talentCooldownFilter(t, 3, 1, false)
		end
	end,
	info = function(self, t)
		local bonus = t.getBonus(self, t)
		local chance = t.getChance(self, t)
		return ([[Gain a %d%% damage bonus against any enemy under 25%% health. %d%% chance to recover 3 turns from any one bestial talent after either you or your owner kill an enemy.]]):
		format(bonus, chance)
	end,
	getBonus = function(self, t) return self:combatTalentScale(t, 10, 30) end,
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 15, 35) end,
}

newTalent{
	name = "Opportunistic",
	short_name = "OUTRIDER_TRAIT_OPPORTUNISTIC_SHARED", image = "talents/trait_opportunistic.png",
	type = {"mounted/mounted-base", 1},
	points = 1,
	hide = true,
	mode = "passive",
	always_hide=true,
	base_talent = "TRAIT_OPPORTUNISTIC",
	callbackOnKill = function(self, t, target, death_note)
		local pet = self.outrider_pet
		pet:callTalent(t.base_talent, "callbackOnKill", target, death_note)
	end,
	info = function(self, t)
		local pet = self.outrider_pet
		local t2 = self:getTalentFromId(t.base_talent)
		local chance = t2.getChance(pet, t2)
		return ([[%d%% for your beast to recover 3 turns from any one bestial talent after you kill an enemy.]]):
		format(chance)
	end,
}

newTalent{
	name = "Hardy",
	short_name = "OUTRIDER_TRAIT_HARDY", image = "talents/trait_hardy.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	passives = function(self, t, p)
		local res = t.getRes(self, t)
		self:talentTemporaryValue(p, "resists", {fire=res, cold=res, nature=res})
		self:talentTemporaryValue(p, "combat_physresist", t.getSave(self, t))
	end,
	callbackOnTakeDamage = function(self, t, src, x, y, type, dam, state)
		if state.crit_type then
			local new_crit_power = state.crit_power - t.getDecrease(self, t)/100
			dam = dam * new_crit_power / state.crit_power
		end
		return {dam=dam}
	end,
	info = function(self, t)
		local res = t.getRes(self, t)
		local save = t.getSave(self, t)
		local decrease = t.getDecrease(self, t)
		return ([[Gain %d%% fire, cold and nature resistance and %d physical save. Reduce damage bonus of any incoming crits by %d%%.]]):
		format(res, save, decrease)
	end,
	getRes = function(self, t) return self:combatTalentScale(t, 10, 25) end,
	getSave = function(self, t) return self:combatTalentScale(t, 7, 20) end,
	getDecrease = function(self, t) return self:combatTalentLimit(t, 100, 10, 30) end,
}

newTalent{
	name = "Unbreakable",
	short_name = "OUTRIDER_TRAIT_UNBREAKABLE", image = "talents/trait_unbreakable.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	passives = function(self, t, p)
		local res = t.getRes(self, t)
		self:talentTemporaryValue(p, "resists", {arcane=res, mind=res, blight=res, temporal=res})
		self:talentTemporaryValue(p, "combat_spellresist", t.getSave(self, t))
		self:talentTemporaryValue(p, "combat_physresist", t.getSave(self, t))
	end,
	callbackonTakeDamage = function(self, t, src, x, y, type, dam, state)
		if state.is_crit and not self.turn_procs.done_trait_unbreakable then
			if rng.percent(t.getChance(self, t)) then
				local filter = {types={"spell", "mental"}}
				local effs = self:effectsFilter(filter)
				for _, eff_id in ipairs(effs) do
					--This function /should/ take a number and is supposed to.
					--But for some reason it doesn't
					--Instead it just automatically subtracts 1 from the duration.
					--So, we just call it twice instead
					self:alterEffectDuration(eff_id)
					self:alterEffectDuration(eff_id)
				end
			end
			self.turn_procs.done_trait_unbreakable = true
		end
	end,
	info = function(self, t)
		local res = t.getRes(self, t)
		local save = t.getSave(self, t)
		local chance = t.getChance(self, t)
		return ([[Gain %d%% arcane, mind, temporal and blight resistance, plus %d spell and mental save. Any incoming critical hit has a %d%% chance to reduce all spell and mental detrimental effects by 1 turn.]]):
		format(res, save, chance)
	end,
	getRes = function(self, t) return self:combatTalentScale(t, 10, 25) end,
	getSave = function(self, t) return self:combatTalentScale(t, 7, 20) end,
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 15, 35) end,
}

newTalent{
	name = "Long Fangs",
	short_name = "OUTRIDER_TRAIT_LONG_FANGS", image = "talents/trait_long_fangs.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_critical_power", t.getBoost(self, t))
	end,
	callbackOnMeleeHit = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		if hitted then
			if rng.percent(15) then
				local dur = t.getDur(self, t)
				local power = t.getPower(self, t)
				target:setEffect(target.EFF_SUNDER_ARMOUR, dur, {power=power})
			end
		end
	end,
	info = function(self, t)
		local boost = t.getBoost(self, t)
		local power = t.getPower(self, t)
		local dur = t.getDur(self, t)
		return ([[Increase critical hit damage by %d%%. Attacks have a 15%% chance to sunder armour and saves by %d for %d turns.]]):
		format(boost, power, dur)
	end,
	getBoost = function(self, t) return self:combatTalentScale(t, 15, 45) end,
	getPower = function(self, t) return self:combatTalentScale(t, 7, 20) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 6) end,
}

newTalent{
	name = "Strong Bite",
	short_name = "OUTRIDER_TRAIT_STRONG_BITE", image = "talents/trait_strong_bite.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	callbackOnMeleeHit = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		if hitted then
			if rng.percent(t.getChance(self, t)) then
				local dur = t.getDur(self, t)
				local spped = t.getSpeed(self, t)
				target:setEffect(target.EFF_SUNDER_ARMOUR, dur, {speed=speed})
			end
		end
	end,
	info = function(self, t)
		local chance = t.getChance(self, t)
		local speed_pct = t.getSpeed(self, t)*100
		local dur = t.getDur(self, t)
		return ([[The beast has a chance to break bones on every attack, having a %d%% chance to cripple its foe for a %d%% reduction in attack, spell and mind casting speed over %d turns.]]):
		format(chance, speed_pct, dur)
	end,
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 8, 15) end,
	getSpeed = function(self, t) return self:combatTalentScale(t, .15, .3) end,
	getDur = function(self, t) return self:combatTalentScale(t, 3, 6) end,
}

newTalent{
	name = "High Back",
	short_name = "OUTRIDER_TRAIT_HIGH_BACK", image = "talents/trait_high_back.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	callbackOnMount = function(self, t)
		self:updateTalentPassives(t.id)
	end,
	callbackOnDismount = function(self, t)
		self:updateTalentPassives(t.id)
	end,
	-- @todo Implement this properly, i.e. share it with the rider.
	passives = function(self, t, p)
		if self:isMounted() then
			self:talentTemporaryValue(p, "combat_atk_ranged", t.getDam(self, t))
			self:talentTemporaryValue(p, "combat_def", t.getDef(self, t))
			self:talentTemporaryValue(p, "sight", t.getSight(self, t))
		else
			--This is a special Nagyhal function to make code simpler and cleaner
			self:removeTalentTemporaryValues(p)
		end
	end,
	info = function(self, t)
		local dam_pct = t.getDam(self, t)*100
		local def = t.getDef(self, t)
		local sight = t.getSight(self, t)
		return ([[This beast's back is high, seating you a fair bit higher than average; gain %d%% ranged weapon damage, %d defense and %d extra sight distance while riding your beast.]]):
		format(dam_pct, def, sight)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, .05, .11) end,
	getDef = function(self, t) return self:combatTalentScale(t, 7, 19) end,
	getSight = function(self, t) return self:getTalentLevelRaw(t) < 5 and 1 or 2 end,
}

-- @todo : Actually implement this
newTalent{
	name = "Aspect of Tyranny",
	short_name = "OUTRIDER_TRAIT_ASPECT_OF_TYRANNY", image = "talents/trait_aspect_of_tyranny.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "tyrannical_aspect", {t.getDur(self, t), t.getChance(self, t)})
		self:talentTemporaryValue(p, "crit_vs_mental", t.getDef(self, t))
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local chance = t.getChance(self, t)
		local crit_pct = t.getCritPct(self, t)
		return ([[Your beast's character is cruel, with a streak of tyranny about it; it was born to menace and bully. If you use Tyranny of Steel while riding, your knockback effect gains an extra 1 radius. In addition, you'll frighten all targeted foes for %d turns, causing them to run away each turn (%d%% chance.) Your beast also gains an extra %d%% to crit against foes suffering a mental detrimental effect.]]):
		format(dur, chance, crit_pct)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 30, 43) end,
	getCritPct = function(self, t) return  self:combatTalentLimit(t, 20, 5, 8) end,
}

-- @todo : Actually implement this
newTalent{
	name = "Savage Acrobat",
	short_name = "OUTRIDER_TRAIT_SAVAGE_ACROBAT", image = "talents/trait_savage_acrobat.png",
	type = {"race/traits", 1},
	mode = "passive",
	points = 5,
	hide = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "savage_acrobat", t.getDamPct(self, t))
	end,
	info = function(self, t)
		local chance = t.getChance(self, t)
		local dam_pct = t.getDamPct(self, t)
		return ([[Your pet's bloodlust inspires a fearsome agility. When you use Savage Bound, you have a %d%% chance to reduce the cooldown by half. Also, your pet's Savage Bound, Run Them Down and Let 'Em Have It attacks increase in damage by %d%%.]]):
		format(chance, dam_pct)
	end,
	getChance = function(self, t) return self:combatTalentLimit(t, 90, 20, 65) end,
	getDamPct = function(self, t) return  self:combatTalentLimit(t, 220, 80, 150) end,
}