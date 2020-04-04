--- Check if the actor has a two handed weapon
function hasOneHandedWeapon(self)
	if self:attr("disarmed") then
		return nil, "disarmed"
	end

	if not self:getInven("MAINHAND") then return end
	local weapon = self:getInven("MAINHAND")[1]
	if not weapon or weapon.twohanded or weapon.archery then
		return nil
	end
	return weapon
end

function hasFreeOffhand(self)
	local mainhand = self:getInven("MAINHAND")[1]
	if mainhand and mainhand.twohanded then return nil end
	if not (self:getInven("OFFHAND") and self:getInven("OFFHAND")[1]) then return true else return nil end
end

newTalent{
	name = "Brazen Lunge",
	type = {"technique/barbarous-combat", 1},
	require = mnt_strcun_req1,
	points = 5,
	random_ego = "attack",
	--stamina = 0,
	cooldown = 8,
	tactical = { ATTACK = 2 },
	requires_target = true,
	range = function(self, t) return 2 + math.floor(self:getTalentLevel(t)/3 - 0.35) end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.5, 2.1) end,
	getStamina = function(self, t) return self:combatTalentMindDamage(t, 20, 28) end,
	getDuration = function(self, t) return math.floor(math.max(4 - self:getTalentLevel(t)/3, 1)) end,
	getSlowPower = function(self, t) return math.max(0, (50 - (self:getTalentLevel(t) - self:getTalentMastery(t)) * 8 )) end,
	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return end
		local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		if hit then
			self:setEffect(self.EFF_OUTRIDER_REGAIN_POISE, 3, {regen=t.getStamina(self, t), slow=t.getSlowPower(self, t)})
		else self:setEffect(self.EFF_OUTRIDER_REGAIN_POISE, 3, {regen=0, slow=t.getSlowPower(self, t), cause="reckless assault"})
		end
		return true
	end,
	info = function(self, t)
		return ([[You attack for %d%% weapon damage with a range of 2, but the massive momentum you attain leaves you disarmed for %d turns and also slowed by %d%%. While recovering, you regain stamina (%d per turn) for so long as you avoid damage. If you are mounted, this will also hit up to two nearby creatures for 50%% of its full damage.]]):
		format(
		t.getDamage(self, t)*100,
		t.getDuration(self, t),
		t.getSlowPower(self, t),
		t.getStamina(self, t)
		)
	end,
}

newTalent{
	name = "Tyranny of Steel",
	type = {"technique/barbarous-combat", 2},
	require = mnt_strcun_req2,
	points = 5,
	random_ego = "attack",
	cooldown = 15,
	stamina = 18,
	tactical = { ATTACKAREA = { weapon = 3 } },
	range = 0,
	radius = 1,
	getDamage = function(self, t) return self:combatTalentScale(t, 1.11, 1.63, .35) end,
	getKnockbackRange = function(self, t) return self:combatTalentScale(t, 1.3, 4.3) end,
	--TODO: Could add an unusual element where knockback is a function of number of hits
	--Or that only creatures knocked back are hit.
	--Sounds good to me and differentiates it well from Repulsion
	getKnockbackRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 3.8) end,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if not hasOneHandedWeapon(self) then if not silent then game.logPlayer(self, "You require a one-handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local tg_base = table.clone(tg); tg_base.range=1
		if self:isMounted() then tg.radius =  t.getKnockbackRadiusMounted(self, t) end

		--Do we hit at least once?
		local hit
		self:project(tg, self.x, self.y, 
			function(px, py, tg, self)
				local target = game.level.map(px, py, engine.Map.ACTOR)
				if target and self:reactionToward(target)<0 then
					if self:attackTarget(target, nil, t.getDamage(self, t), true) then
						hit = true
					end
				end
			end)
		--If so, MEGA KNOCKBACK!
		if not hit then return true end
		local knockback_range = t.getKnockbackRange(self, t)
		local recursive = function(target)
			if self:reactionToward(target)>=0 then return end
			if self:checkHit(self:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then 
				return true
			else
				game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
			end
		end
		self:project(tg, self.x, self.y, 
			function(px, py, tg, self)
				local target = game.level.map(px, py, engine.Map.ACTOR)
				if target and self:reactionToward(target)<0 then
					if self:checkHit(self:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then
						target:knockback(self.x, self.y, knockback_range, recursive)
					else
						game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
					end
				end
			end)
		return true
	end,
	info = function(self, t)
		local dam = t.getDamage(self, t) * 100
		local knockback = t.getKnockbackRange(self, t)
		local radius = t.getKnockbackRadiusMounted(self, t)
		return ([[You release a maniacal display of brutality upon your foes, lashing out with a reckless attack that hits all adjacent enemies for %d%% while scattering those who are puny of will, knocking them back %d squares. If you are mounted, you may have your beast rise up in a terrifying fashion, knocking back instead all foes within a radius of %d.]]):
		format(dam, knockback, radius)
	end,
}


newTalent{
	name = "Scatter the Unworthy",
	short_name = "UNNAMED_OUTRIDER_TALENT",
	type = {"technique/barbarous-combat", 3},
	require = mnt_strcun_req3,
	points = 5,
	stamina = 10,
	cooldown = 18, 
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	tactical = { ATTACKAREA = { confusion = 1, fear = 1 }, DISABLE = { confusion = 1, fear = 1 } },
	requires_target = true,
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, friendlyfire=false}
	end,
	passives = function(self, t , p)
		self:talentTemporaryValue(p, "combat_mindpower", t.getBuff(self, t))
		self:talentTemporaryValue(p, "combat_mentalresist", t.getBuff(self, t))
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.TEST_OF_METTLE, {dur=t.getDur(self,t), red=t.getReduction(self, t)})
		game.level.map:particleEmitter(self.x, self.y, self:getTalentRadius(t), "directional_shout", {life=8, size=3, tx=x-self.x, ty=y-self.y, distorion_factor=0.1, radius=self:getTalentRadius(t), nb_circles=8, rm=0.8, rM=1, gm=0.4, gM=0.6, bm=0.1, bM=0.2, am=1, aM=1})
		return true
	end,
	info = function(self, t)
		local r = self:getTalentRadius(t)
		local dur = t.getDur(self, t)
		local red = t.getReduction(self, t)
		local buff = t.getBuff(self, t)
		return ([[Test the mettle of your foes, sifting out the worthy from the weak. Targets who fail a mind save in a cone of radius %d face will be either panicked or provoked for %d turns. Panicked foes suffer a 50%% chance to flee from you each turn, while provoked foes increase their damage by 20%% while reducing all resistances by 25%% and defense and armour by %d.

			Levelling Scatter the Unworthy past the first level will hone your powers of tactical dominance, increasing mindpower by %d and mind save by %d.]]):
		format(r, dur, red, buff, buff)
	end,
	getDur = function(self, t) return math.floor(self:combatTalentScale(t, 4, 6)) end,
	getReduction = function(self, t) return math.round(self:combatTalentScale(t, 5, 12)) end,
	getBuff = function(self, t) 
		local offset = self:getTalentMastery(t)
		local tl = self:getTalentLevel(t)
		tl = tl - offset
		return self:getTalentLevelRaw(t)>1 and math.round(self:combatTalentScale(tl, 6, 19, .7, nil, offset)) or 0 end,
}

newTalent{
	name = "Gory Spectacle",
	type = {"technique/barbarous-combat", 4},
	require = mnt_strcun_req4,
	points = 5,
	random_ego = "attack",
	cooldown = 10,
	stamina = 18,
	tactical = { ATTACKAREA = { weapon = 1 } },
	range = 1,
	radius = 1,
	requires_target = true,
	on_pre_use = function(self, t, silent) if not hasOneHandedWeapon(self) then if not silent then game.logPlayer(self, "You require a one-hande5d weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		-- if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local hit = self:attackTarget(target, nil, t.getDam(self, t), true)
		--blind foes on target kill
		if hit and target.dead then
			local tg = {type="ball", range=self:getTalentRange(t), selffire=false, friendlyfire=false, radius=self:getTalentRadius(t)}
			if self:isMounted() then tg.radius = t.getBlindRadiusMounted(self, t) end
			self:project(tg, self.x, self.y, function(px, py, tg, self)
				local target = game.level.map(px, py, engine.Map.ACTOR)
				if target and target ~= self and target:canBe("blinded") then
					target:setEffect(target.EFF_BLINDED, t.getBlindDuration(self, t), {})
				end
			end)
		else 
			target:setEffect(target.EFF_CRIPPLE, 5, {speed=t.getSpeed(self, t)})
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t) * 100
		local dur = t.getBlindDuration(self, t)
		local radius = t.getBlindRadiusMounted(self, t)
		local speed = t.getSpeed(self, t)
		return ([[You gouge your enemy for %d%% damage. If it is killed, then the horrific maiming you inflict spreads terror in all nearby foes, blinding them as they must avert their eyes for %d turns. If you are mounted, then you may raise the severed remnants of your victim high above for all to see, blinding instead all enemies in radius %d.

			If you fail to slay your foe, however, then instead you cripple it for 5 turns, reducing melee, spellcasting and mind speed by %d%% as it struggles to recover from your wicked wound.]]):
			format(dam, dur, radius, speed)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.7) end,
	getBlindDuration = function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getBlindRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 4) end,
	getBleedPower = function(self, t) return self:combatTalentPhysicalDamage(t, 25, 150) end,
	getSpeed = function(self, t) return self:combatTalentLimit(t, 80, 15, 35) end
}