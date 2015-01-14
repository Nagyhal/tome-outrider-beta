newTalent{
	name = "Orchestrator of Dismay",
	type = {"cunning/raider", 1},
	mode = "passive",
	points = 5,
	require = cun_req1,
	info = function(self, t)
		local fatigue_pct = t.getFatiguePct(self, t)
		local counter_pct = t.getCounterPct(self, t)
		return ([[Your advanced training in the pinciples of psychological warfare allows you to inflict terror and devastation with the most humdrum of tools.
			You can treat one-handed weapons as two-handed for the purposes of talent prerequites, allowing you to use them while mounted in your saddle with ease; however, doing so increases your effective fatigue by %d%% for each such ability.
			Also, scattering your enemies and sundering their armour now exposes opportunity that would go unnoticed by less honed combatants. Gain a %d%% chance to apply the counterattack debuff for each enemy who attacks you while they are under any such effect (sunder, confusion, or fear).]])
		:format(fatigue_pct, counter_pct)
	end,
	doCounterCheck = function(self, t, src)
		if not rng.percent(t.getCounterPct(self, t)) then return end
		local effs = src:effectsFilter{ subtype = { confusion=true, fear=true, sunder=true }, status = "detrimental" }
		if #effs>0 then src:setEffect(src.EFF_COUNTERSTRIKE, 2, {src=self}) end
	end,
	callbackOnMeleeHit = function(self, t, src, dam)
		t.doCounterCheck(self, t, src)
	end,
	callbackOnMeleeMiss = function(self, t, src, dam)
		t.doCounterCheck(self, t, src)
	end,
	getFatiguePct = function(self, t) return self:combatTalentScale(t, 70, 35) end,
	getCounterPct = function(self, t) return self:combatTalentScale(t, 15, 50) end
}

newTalent{
	name = "Strike at the Heart",
	type = {"cunning/raider", 2},
	mode = "passive",
	require = cun_req2,
	points = 5,
	info = function(self, t)
		local move = t.getMove(self, t)
		local atk = t.getAtk(self, t)
		local crit = t.getCrit(self, t)
		local def = t.getDef(self, t)
		local sunder = t.getSunder(self, t)
		return ([[When you set your sights on the highest of castles, nothing can stand in your way.
			As long as you move toward an enemy in an unbroken line, gain a bonus to movement speed, accuracy, critical chance and defense. You may diverge from your path to centre on an evading or awkwardly located enemy,; however, any other non-instantaneous action will reset the effect.
			If the enemy's rank is above 1, the effect will be increased by 50%% for each rank.
			Also, successfully striking with melee weapons while in this state confers a chance to sunder weaponry and armour, affecting either armour and saves or accuracy by %d for 3 turns.
			Current bonuses:
			Movement Speed: %d%%
			Accuracy: %d
			Critical Chance: %d%%
			Defense: %d]]):
		format(sunder, move, atk, crit, def)
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		if not ox or not oy or (ox==x and oy==y) then return end
		local _, dx, dy = util.getDir(x, y, ox, oy)
		local tg = {type="cone", angle=45, radius=self.sight}
		local ok = false
		local acts = {}
		local filter = function(px, py, t, self)
			local a = game.level.map(px, py, engine.Map.ACTOR) 
			if a then acts[a], ok = true, true end
		end
		local grids = self:project(tg, self.x+dx, self.y+dy, filter)
		if ok then 
			self:setEffect(self.EFF_STRIKE_THE_HEART, 3, {
				move=t.getMove(self, t),
				atk=t.getAtk(self, t),
				crit=t.getCrit(self, t),
				def=t.getDef(self, t)
			}) 
		end
	end,
	getMove = function(self, t) return self:combatTalentScale(t, 10, 30) end,
	getAtk = function(self, t) return self:combatTalentScale(t, 3, 8) end,
	getCrit = function(self, t) return self:combatTalentScale(t, 8, 15) end,
	getDef = function(self, t) return self:combatTalentScale(t, 5, 12) end,
	getSunder = function(self, t) return self:combatTalentScale(t, 6, 18) end,
}

newTalent{
	name = "Spring Attack",
	type = {"cunning/raider", 3},
	mode = "passive",
	require = cun_req3,
	points = 5,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local min_pct = t.getMinPct(self, t)
		local max_pct = t.getMaxPct(self, t)
		return ([[After charging, for %d turns, the defense and movement speed components of your Strike at the Heart bonuses will persist.

			Also, you gain a bonus to ranged damage against the foe struck for the duration. This bonus is dependent on the distance you gain after that attack: %d%% at 2 tiles, increasing to %d%% at 5.

			Only distance gained from the moment of your attack will count.]]):
		format(dur, min_pct, max_pct)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
	getMinPct = function(self, t) return self:combatTalentScale(t, 5, 15) end,
	getMaxPct = function(self, t) return self:combatTalentScale(t, 15, 30) end,
}


newTalent{
	name = "Impunity of Warlords",
	type = {"cunning/raider", 4},
	mode = "sustained",
	require = cun_req4,
	points = 5,
	sustain_stamina = 50,
	cooldown = 10,
	range = function(self, t) return util.bound(self:combatTalentScale(t, .8, 2.2), 1, 3) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_def", t.getDef(self, t))
		local saves = self:combatDefenseBase() * t.getSavesPct(self, t)/100
		self:talentTemporaryValue(p, "combat_physresist", saves)
		self:talentTemporaryValue(p, "combat_spellresist", saves)
		self:talentTemporaryValue(p, "combat_mindresist", saves)
	end,
	activate = function(self, t)
		return {}
	end,
	deactivate = function(self, t, p)
	end,
	info = function(self, t)
		local def = t.getDef(self, t)
		local saves_pct = t.getSavesPct(self, t)
		local range = self:getTalentRange(t)
		local chance = t.getChance(self, t)
		return ([[Increase your defense by %d (mitigated by your fatigue) and your saves by %d%% of your defense.

			Also, you may sustain to gain positional dominance on the battlefield. When you are within range %d of an enemy, and have an attack projected against you, have a %d%% chance to switch places with that enemy if it would take you out of the projection area. This effect scales with defense, and its activation will put Impunity of Warlords on cooldown.]]):
		format(def, saves_pct, range, chance)
	end,
	getDef = function(self, t) return self:combatTalentScale(t, 6, 18) end,
	getSavesPct = function(self, t) return self:combatTalentScale(t, 8, 20) end,
	getChance= function(self, t)
		local def = self:combatDefense()
		local tl_factor = self:combatTalentScale(t, .65, 1) 
		return self:combatStatScale(def, 10, 30) * tl_factor
	end,
}