newTalent{
	name = "Brazen Lunge",
	type = {"technique/barbarous-combat",1},
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
			self:setEffect(self.EFF_REGAIN_POISE, 3, {regen=t.getStamina(self, t), slow=t.getSlowPower(self, t)})
		else self:setEffect(self.EFF_REGAIN_POISE, 3, {regen=0, slow=t.getSlowPower(self, t), cause="reckless assault"})
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
	type = {"technique/barbarous-combat", 1},
	require = mnt_strcun_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 15,
	stamina = 30,
	tactical = { ATTACKAREA = { weapon = 3 } },
	range = 0,
	radius = 1,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.5, 2.1) end,
	getKnockbackRange = function(self, t) return math.floor(3 + self:getTalentLevel(t)/3) end,
	--REM: Could add an unusual element where knockback relates to creatures hit
	--REM: Or just plain that only creatures knocked back are hit.
	--REM: Sounds good to me and differentiates it well from Repulsion
	getKnockbackRadiusMounted = function(self, t) return math.floor(2 + self:getTalentLevel(t)/3) end,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if self:isUnarmed() then if not silent then game.logPlayer(self, "You require a weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		self:project(tg, self.x, self.y, 
		function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
				if hit and target:canBe("knockback") then
					target:knockback(self.x, self.y, 2 + t.getKnockbackRange(self, t))
					else
					game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
				end
			end
		end)
		return true
	end,
	info = function(self, t)
		return ([[You release a maniacal display of brutality upon your foes, lashing out with a reckless attack that hits all adjacent enemies for %d%% and scattering those who are puny of will, knocking them back %d squares. If you are mounted, you may have your beast rise up in a terrifying fashion, knocking back instead all foes within a radius of %d.]]):
		format(t.getDamage(self, t) * 100,
		t.getKnockbackRange(self, t),
		t.getKnockbackRadiusMounted(self, t)
		)
	end,
}

newTalent{
	name = "Gory Spectacle",
	type = {"technique/barbarous-combat", 1},
	require = mnt_strcun_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 15,
	stamina = 30,
	tactical = { ATTACKAREA = { weapon = 1 } },
	range = 0,
	radius = 1,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.5, 1.0) end,
	getBlindDuration = function(self, t) return math.floor(2 + self:getTalentLevel(t)/2) end,
	getBlindRadiusMounted = function(self, t) return math.floor(2 + self:getTalentLevel(t)/2) end,
	getBlindTarget = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)} 
	end,
	getBleedPower = function(self, t) return self:getCun() * 0.5 end,
	requires_target = true,
	-- on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "You require a two handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		--blind foes on target kill
		if hit and target.dead then
			local tg = t.getBlindTarget(self, t)
			self:project(tg, self.x, self.y, function(px, py, tg, self)
				local target = game.level.map(px, py, Map.ACTOR)
				if target and target ~= self and target:canBe("blinded") then
					target:setEffect(target.EFF_BLINDED, t.getBlindDuration(self, t), {})
				end
			end)
		elseif target:canBe("cut") then 
			target:setEffect(target.EFF_CUT, 5, {power=t.getBleedPower(self, t), src=self})
		end
		return true
	end,
	info = function(self, t)
		return ([[You gouge your enemy for %d%% damage. If it is killed, then the horrific maiming you inflict spreads terror in all nearby foes, blinding them as they must avert their eyes for %d turns. If you are mounted, then you may raise the severed remnants of your victim high above for all to see, blinding instead all enemies in radius %d.

If you fail to slay your foe, however, then it continues to bleed for %d damage over 5 turns as it struggles to recover from your wicked wound.]]):
		format(t.getDamage(self, t) * 100,
		t.getBlindDuration(self, t),
		t.getBlindRadiusMounted(self, t),
		t.getBleedPower(self, t)
		)
	end,
}