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
	name = "Master of Brutality",
	type = {"technique/barbarous-combat", 1},
	require = mnt_strcun_req1,
	points = 5,
	mode = "sustained",
	cooldown = 30,
	sustain_stamina = 40,
	tactical = { BUFF = 2 },
	on_pre_use = function(self, t, silent)
		-- if not hasOneHandedWeapon(self) then
		if not t.checkBothWeaponSets(self, t) then
			if not silent then
				game.logPlayer(self, "You require a one-handed weapon to use this talent.")
			end
			return false
		end
		return true
	end,
	--TODO: This code is virtually nonsensical at this stage, let's delete most of it.
	checkBothWeaponSets = function(self, t)
		local mains = {main=self:getInven("MAINHAND") and self:getInven("MAINHAND")[1],
			qs = self:getInven("QS_MAINHAND") and self:getInven("QS_MAINHAND")[1]}
		local offhands = {main=self:getInven("OFFHAND") and self:getInven("OFFHAND")[1],
			qs = self:getInven("QS_OFFHAND") and self:getInven("QS_OFFHAND")[1]}
		local one_handed = false
		local free_off = false
		for _, set in ipairs{"main"} do
			local main = mains[set]
			if main and not main.twohanded then--and not main.archery then
				one_handed = true
				free_off = true
				if offhands[set] or main.archery then free_off = false end
			end
		end
		return one_handed, free_off
	end,
	activate = function(self, t)
		-- local weapon = hasOneHandedWeapon(self)
		-- if not weapon then
		-- 	game.logPlayer(self, "You cannot use Master of Brutality without a one-handed weapon!")
		-- 	return false
		-- end

		local ret = {free_off=false}
		if hasFreeOffhand(self) then
				self:talentTemporaryValue(ret, "combat_mindpower", t.getMindpower2(self, t))
				self:talentTemporaryValue(ret, "combat_physcrit", t.getPhysCrit2(self, t))
				self:talentTemporaryValue(ret, "combat_critical_power", t.getCritPower2(self, t))
				self:talentTemporaryValue(ret, "combat_apr", t.getApr2(self, t))
				free_off=true
		else 
			self:talentTemporaryValue(ret, "combat_mindpower", t.getMindpower(self, t))
			self:talentTemporaryValue(ret, "combat_physcrit", t.getPhysCrit(self, t))
			self:talentTemporaryValue(ret, "combat_critical_power", t.getCritPower(self, t))
			self:talentTemporaryValue(ret, "combat_apr", t.getApr(self, t))
		end
		return ret
	end,
	callbackOnWear  = function(self, t, o, bypass_set) t.checkWeapons(self, t, o, bypass_set) end,
	callbackOnTakeoff  = function(self, t, o, bypass_set) t.checkWeapons(self, t, o, bypass_set) end,
	checkWeapons = function(self, t, o, bypass_set)
		if o.type and o.type=="weapon" then
			game:onTickEnd(function()
				local one_handed, free_off = t.checkBothWeaponSets(self, t)
				if one_handed then
					local p = self:isTalentActive(t.id); if not p then return end
					for i = #p.__tmpvals, 1, -1  do
						self:removeTemporaryValue(p.__tmpvals[i][1], p.__tmpvals[i][2])
						p.__tmpvals[i] = nil
					end
					if free_off then
						game.log("DEBUG: melee equipped")
						self:talentTemporaryValue(p, "combat_mindpower", t.getMindpower2(self, t))
						self:talentTemporaryValue(p, "combat_physcrit", t.getPhysCrit2(self, t))
						self:talentTemporaryValue(p, "combat_critical_power", t.getCritPower2(self, t))
						self:talentTemporaryValue(p, "combat_apr", t.getApr2(self, t))
						p.free_off=true
					else
						self:talentTemporaryValue(p, "combat_mindpower", t.getMindpower(self, t))
						self:talentTemporaryValue(p, "combat_physcrit", t.getPhysCrit(self, t))
						self:talentTemporaryValue(p, "combat_critical_power", t.getCritPower(self, t))
						self:talentTemporaryValue(p, "combat_apr", t.getApr(self, t))
						p.free_off=false
					end
				else
					self:forceUseTalent(t.id, {no_energy=true})
				end
			end)
		end
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local apr = t.getApr(self, t)
		local apr2 = t.getApr2(self, t)
		local crit_power = t.getCritPower(self, t)
		local crit_power2 = t.getCritPower2(self, t)
		local phys_crit = t.getPhysCrit(self, t)
		local phys_crit2 = t.getPhysCrit2(self, t)
		local mindpower = t.getMindpower(self, t)
		local mindpower2 = t.getMindpower2(self, t)
		local phys_pen = t.getPhysPen(self, t)
		return ([[While you prefer weapons less visibily impressive than some, the merciless precision with which you wield them makes them no less intimidating in your hands. Critical hits will reduce the physical resistance of the target by %d%% for 2 turns.
		
		Also, while wielding a one-handed or an archery weapon, gain the following bonuses:
		+%d mindpower
		+%d%% physical crit chance
		+%d%% critical power
		+%d APR

		If you hold nothing in your off-hand, instead gain the following benefits:
		+%d mindpower
		+%d%% physical crit chance
		+%d%% critical power
		+%d APR]]):
		format(phys_pen, mindpower, phys_crit, crit_power, apr, mindpower2, phys_crit2, crit_power2, apr2)
	end,
	getApr = function(self, t) return self:combatTalentScale(t, 5, 12) end,
	getApr2 = function(self, t) return self:callTalent(t.id, "getApr")*1.65 end,
	getPhysCrit = function(self, t) return self:combatTalentScale(t, 3, 7) end,
	getPhysCrit2 = function(self, t) return self:callTalent(t.id, "getPhysCrit")*1.85 end,
	getCritPower = function(self, t) return self:combatTalentScale(t, 15, 30) end,
	getCritPower2 = function(self, t) return self:callTalent(t.id, "getCritPower")*1.65 end,
	getMindpower = function(self, t) return self:combatTalentScale(t, 6, 15) end,
	getMindpower2 = function(self, t) return self:callTalent(t.id, "getMindpower")*1.65 end,
	getPhysPen = function(self, t) return self:combatTalentScale(t, 15, 35) end,
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
	getDamage = function(self, t) return self:combatTalentScale(t, 1.21, 1.94, .35) end,
	getKnockbackRange = function(self, t) return self:combatTalentScale(t, 2.5, 4.3) end,
	--TODO: Could add an unusual element where knockback is a function of number of hits
	--Or that only creatures knocked back are hit.
	--Sounds good to me and differentiates it well from Repulsion
	getKnockbackRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 3.8) end,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if not hasOneHandedWeapon(self) then if not silent then game.logPlayer(self, "You require a one-handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		if self:isMounted() then tg.radius =  t.getKnockbackRadiusMounted(self, t) end

		local recursive = function(target)
			if self:checkHit(self:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then 
				return true
			else
				game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
			end
		end

		self:project(tg, self.x, self.y, 
			function(px, py, tg, self)
				local target = game.level.map(px, py, Map.ACTOR)
				local dist = core.fov.distance(px, py, self.x, self.y)
				if target and self:reactionToward(target)<0 then
					if dist == 1 then
						local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
					end
					if self:checkHit(self:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then
						target:knockback(self.x, self.y, t.getKnockbackRange(self, t), recursive)
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
		return ([[Test the mettle of your foes, sifting out the worthy from the weak. Targets who fail a mind save in a cone of radius %d face will be either panicked or provoked for %d turns. Panicked foes suffer a 50%% chance to be flee from you each turn, while provoked foes increase their damage by 20%% while reducing all resistances by 25%% and defense and armour by %d.

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
	on_pre_use = function(self, t, silent) if not hasOneHandedWeapon(self) then if not silent then game.logPlayer(self, "You require a one-handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local hit = self:attackTarget(target, nil, t.getDam(self, t), true)
		--blind foes on target kill
		if hit and target.dead then
			local tg = {type="ball", range=self:getTalentRange(t), selffire=false, friendlyfire=false, radius=self:getTalentRadius(t)}
			if self:isMounted() then tg.radius = t.getBlindRadiusMounted(self, t) end
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
		local dam = t.getDam(self, t) * 100
		local dur = t.getBlindDuration(self, t)
		local radius = t.getBlindRadiusMounted(self, t)
		local bleed = t.getBleedPower(self, t)
		return ([[You gouge your enemy for %d%% damage. If it is killed, then the horrific maiming you inflict spreads terror in all nearby foes, blinding them as they must avert their eyes for %d turns. If you are mounted, then you may raise the severed remnants of your victim high above for all to see, blinding instead all enemies in radius %d.

			If you fail to slay your foe, however, then it continues to bleed for %d damage over 5 turns as it struggles to recover from your wicked wound.]]):
			format(dam, dur, radius, bleed)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.7) end,
	getBlindDuration = function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getBlindRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 4) end,
	getBleedPower = function(self, t) return self:combatTalentPhysicalDamage(t, 25, 150) end,
}