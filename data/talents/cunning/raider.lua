newTalent{
	name = "Orchestrator of Dismay",
	type = {"cunning/raider", 1},
	mode = "passive",
	points = 5,
	require = mnt_dexcun_req1,
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
		if #effs>0 then src:setEffect(src.EFF_COUNTERSTRIKE, 2, {src=self, power=0}) end
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
	require = mnt_dexcun_req2,
	points = 5,
	info = function(self, t)
		local mult1 = t.getMult(self, t, 1)
		local mult3= t.getMult(self, t, 3)
		local move = t.getMove(self, t)  --; local move_max = move * t.getMult(self, t, ct)
		local atk = t.getAtk(self, t)
		local crit = t.getCrit(self, t)
		local def = t.getDef(self, t)
		local sunder = t.getSunder(self, t)
		local stacks = t.getSunderStacks(self, t)
		local stacks_string = stacks..(stacks>1 and " stacks" or " stack")
		return ([[When you set your sights on the highest of castles, nothing can stand in your way.
			As long as you move toward an enemy in an unbroken line, gain a bonus to movement speed, accuracy, critical chance and defense. You may diverge from your path to centre on an evading or awkwardly located enemy; however, any other non-instantaneous action will reset the effect.
			If the enemy's rank is above 1, the effect will be increased by 50%%.
			Also, successfully striking with melee weapons while in this state confers a chance to sunder the enemy's defenses, reducing armour and saves by %d for 3 turns. The effect requires a minimum of %s.
			Current bonuses:
			Movement Speed: %d%% to %d%%
			Accuracy: %d to %d
			Critical Chance: %d%% to %d%%
			Defense: %d to %d]]):
		format(sunder, stacks_string, move*mult1, move*mult3, atk*mult1, atk*mult3, crit*mult1, crit*mult3, def*mult1, def*mult3)
	end,
	handleStrike = function(self, t, target, hitted)
		local eff = self:hasEffect(self.EFF_STRIKE_AT_THE_HEART)
		if not (eff and target) then return end
		--Only do this once, on the first target
		if not eff.done then
			game:onTickEnd(function() 
				local eff = self:hasEffect(self.EFF_STRIKE_AT_THE_HEART)
				if hitted and eff.sunder>0 then
					for target in pairs(eff.targets) do
						target:setEffect(target.EFF_SUNDER_ARMOUR, 3, {power=eff.sunder, apply_power=self:combatPhysicalpower()})
					end
				end
				-- if eff.store then eff.doUnstoreBonuses(self, eff) end
				self:removeEffect(self.EFF_STRIKE_AT_THE_HEART)
			end)
		end
		eff.targets[target] = true
		eff.done=true
	end,
	callbackOnMove = function(self, t, moved, force, ox, oy, x, y)
		if not ox or not oy or (ox==self.x and oy==self.y) then return end
		local ab = self.__talent_running or (self.mount and self.mount.__talent_running); if ab and ab.is_teleport then return end

		local stacks = core.fov.distance(ox, oy, self.x, self.y)

		local found_target
		local tg = {type="ball", radius=self.sight, selfifre=false, friendlyfire=false}
		local function getSqDist(x1, y1, x2, y2)
			local distx = math.abs(x1-x2)
			local disty = math.abs(y1-y2)
			return math.max(distx, disty)
		end
		local fct = function(px, py, t, self)
			local a = game.level.map(px, py, engine.Map.ACTOR) 
			if a and self:reactionToward(a) < 0 and self:hasLOS(px, py) then
				local dist1 = getSqDist(ox, oy, px, py)
				local dist2 = getSqDist(self.x, self.y, px, py)

				if dist2 < dist1 then found_target=true end
			end
		end
		self:project(tg, self.x, self.y, fct)
		
		if found_target then
			for i = 1, stacks do
				if not self:attr("building_strike_at_heart") then
					self:attr("building_strike_at_heart", 1, true)
				else
					local p = self:hasEffect(self.EFF_STRIKE_AT_THE_HEART)
					local ct=p and math.min(3, p.ct+1) or 1
					local mult = t.getMult(self, t, ct)
					self:setEffect(self.EFF_STRIKE_AT_THE_HEART, 3, {
						ct=ct,
						move=t.getMove(self, t)*mult,
						atk=t.getAtk(self, t)*mult,
						crit=t.getCrit(self, t)*mult,
						def=t.getDef(self, t)*mult,
						sunder=ct>=t.getSunderStacks(self,t) and t.getSunder(self, t) or 0
					}) 
				end
			end
		else
			self:removeEffect(self.EFF_STRIKE_AT_THE_HEART)
			self:attr("building_strike_at_heart", 0, true)
			self.turn_procs.did_strike = true
		end
	end,
	callbackonActBase = function(self, t)
		if self:attr("building_strike_at_heart") and not self.turn_procs.did_strike then
			self:attr("building_strike_at_heart", 0, true)
		end
	end,
	getMult = function(self, t, ct) return self:combatScale(ct, 1, 1, 2.5, 3, .75) end,
	getMove = function(self, t) return self:combatTalentScale(t, 10, 30) end,
	getAtk = function(self, t) return self:combatTalentScale(t, 3, 8) end,
	getCrit = function(self, t) return self:combatTalentScale(t, 10, 18) end,
	getDef = function(self, t) return self:combatTalentScale(t, 5, 12) end,
	getSunder = function(self, t) return self:combatTalentScale(t, 6, 18) end,
	getSunderStacks = function(self, t) return math.max(1, math.ceil(self:combatTalentScale(t, 3, 1, 1))) end,
}

newTalent{
	name = "Spring Attack",
	type = {"cunning/raider", 3},
	mode = "passive",
	require = mnt_dexcun_req3,
	points = 5,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local min_pct = t.getMinPct(self, t)
		local max_pct = t.getMaxPct(self, t)
		return ([[After charging, for %d turns, the defense and movement speed components of your Strike at the Heart bonuses will persist.

			Also, you gain a bonus to ranged damage against the foe struck for the duration. This bonus is dependent on the distance you gain after that attack: %d%% at 2 tiles, increasing to %d%% at 5 or more.

			Only distance gained from the moment of your attack will count.]]):
		format(dur, min_pct, max_pct)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
	getMinPct = function(self, t) return self:combatTalentScale(t, 10, 22.5) end,
	getMaxPct = function(self, t) return self:combatTalentScale(t, 20, 35) end,
}


newTalent{
	name = "Impunity of Warlords",
	type = {"cunning/raider", 4},
	mode = "sustained",
	require = mnt_dexcun_req4,
	points = 5,
	sustain_stamina = 50,
	no_energy=true,
	cooldown = 10,
	range = function(self, t) return util.bound(self:combatTalentScale(t, .8, 2.2), 1, 3) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_def", t.getDef(self, t))
		local saves = self:combatDefenseBase() * t.getSavesPct(self, t)/100
		self:talentTemporaryValue(p, "combat_physresist", saves)
		self:talentTemporaryValue(p, "combat_spellresist", saves)
		self:talentTemporaryValue(p, "combat_mentalresist", saves)
	end,
	activate = function(self, t)
		return {}
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local def = t.getDef(self, t)
		local saves_pct = t.getSavesPct(self, t)
		local range = self:getTalentRange(t)
		local chance = t.getChance(self, t)
		return ([[Increase your defense by %d (mitigated by your fatigue) and your saves by %d%% of your defense.

			Also, you may sustain to gain positional supremacy on the battlefield. When an enemy projects an attack against you, you have a %d%% chance to switch places with another enemy in range %d if it would take you out of the projection area. This puts Impunity of Warlords on cooldown. The effect scales with defense, and will check for pins and knockback resistance.]]):
		format(def, saves_pct, chance, range)
	end,
	getDef = function(self, t) return self:combatTalentScale(t, 6, 18) end,
	getSavesPct = function(self, t) return self:combatTalentScale(t, 8, 20) end,
	getChance= function(self, t)
		local def = self:combatDefense()
		local tl_factor = self:combatTalentScale(t, .55, 1) 
		return self:combatStatScale(def, 10, 75) * tl_factor
	end,
}