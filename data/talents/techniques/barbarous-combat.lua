--- Check if the actor has a two handed weapon
function hasOneHandedWeapon(self)
	if self:attr("disarmed") then
		return nil, "disarmed"
	end

	if not self:getInven("MAINHAND") then return end
	local weapon = self:getInven("MAINHAND")[1]
	if not weapon or weapon.twohanded then
		return nil
	end
	return weapon
end

function hasFreeOffhand(self)
	local mainhand = self:getInven("MAINHAND")[1]
	if mainhand and mainhand.twohanded then return nil end
	if not self:getInven("OFFHAND") then return true else return nil end
end

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
	--TODO: Could add an unusual element where knockback relates to creatures hit
	--Or just plain that only creatures knocked back are hit.
	--Sounds good to me and differentiates it well from Repulsion
	getKnockbackRadiusMounted = function(self, t) return math.floor(2 + self:getTalentLevel(t)/3) end,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if self:isUnarmed() then if not silent then game.logPlayer(self, "You require a weapon to use this talent.") end return false end return true end,
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
				if target and target ~= self then
					local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
					if hit and self:checkHit(self:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then
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
		return ([[You release a maniacal display of brutality upon your foes, lashing out with a reckless attack that hits all adjacent enemies for %d%% and scattering those who are puny of will, knocking them back %d squares. If you are mounted, you may have your beast rise up in a terrifying fashion, knocking back instead all foes within a radius of %d.]]):
		format(dam, knockback, radius)
	end,
}

newTalent{
	name = "Master of Brutality",
	type = {"technique/barbarous-combat", 2},
	require = mnt_strcun_req2,
	points = 5,
	mode = "sustained",
	cooldown = 30,
	sustain_stamina = 40,
	tactical = { BUFF = 2 },
	on_pre_use = function(self, t, silent)
		if not hasOneHandedWeapon(self) then
			if not silent then
				game.logPlayer(self, "You require a one-handed weapon to use this talent.")
			end
			return false
		end
		return true
	end,
	activate = function(self, t)
		local weapon = self:hasOneHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Master of Brutality without a one-handed weapon!")
			return nil
		end

		self:talentTemporaryValue("combat_atk", t.getAtk(self, t))
		self:talentTemporaryValue("combat_mindpower", t.getMindpower(self, t))
		return {}
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local atk = t.getAtk(self, t)
		local atk2 = t.getAtk2(self, t)
		local mindpower = t.getMindpower(self, t)
		local mindpower2 = t.getMindpower2(self, t)
		local phys_pen = t.getPhysPen(self, t)
		return ([[While you prefer weapons less visibily impressive than some, the merciless precision with which you wield them makes them no less intimidating in your hands. 
		
		Gain a %d increase to attack and APR and a %d increase to mindpower while wielding a one-handed weapon. Critical hits will reduce the physical resistance of the target by %d%% for 2 turns.

		Gain a %d increase to attack and APR and a %d increase to mindpower if you choose to wield an one-handed weapon, and no offhand.]]):
		format(atk, mindpower, phys_pen, atk2, mindpower2)
	end,
	getAtk = function(self, t) return self:combatTalentScale(t, 5, 12)end,
	getAtk2 = function(self, t) return self:callTalent(t.id, "getAtk")*1.65 end,
	getMindpower = function(self, t) return self:combatTalentScale(t, 6, 15)end,
	getMindpower2 = function(self, t) return self:callTalent(t.id, "getMindpower")*1.65 end,
	getPhysPen = function(self, t) return self:combatTalentScale(t, 15, 35)end,
}

newTalent{
	name = "Gory Spectacle",
	type = {"technique/barbarous-combat", 3},
	require = mnt_strcun_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 15,
	stamina = 30,
	tactical = { ATTACKAREA = { weapon = 1 } },
	range = 0,
	radius = 1,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.5, 1.0) end,
	getBlindDuration = function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getBlindRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 4) end,
	getBlindTarget = function(self, t) return {type="ball", range=self:getTalentRange(t), selffire=false, friendlyfire=false, radius=self:getTalentRadius(t)} end,
	getBleedPower = function(self, t) return self:combatTalentPhysicalDamage(t, 25, 150) end,
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
		local dam = t.getDamage(self, t) * 100
		local dur = t.getBlindDuration(self, t)
		local radius = t.getBlindRadiusMounted(self, t)
		local bleed = t.getBleedPower(self, t)
		return ([[You gouge your enemy for %d%% damage. If it is killed, then the horrific maiming you inflict spreads terror in all nearby foes, blinding them as they must avert their eyes for %d turns. If you are mounted, then you may raise the severed remnants of your victim high above for all to see, blinding instead all enemies in radius %d.

			If you fail to slay your foe, however, then it continues to bleed for %d damage over 5 turns as it struggles to recover from your wicked wound.]]):
			format(dam, dur, radius, bleed)
	end,
}

newTalent{
	name = "Suggest this Talent!",
	short_name = "T_UNNAMED_OUTRIDER_TALENT",
	type = {"technique/barbarous-combat", 4},
	mode = "passive",
	require = function(self, t)
		local ret = mnt_strcun_req4
		ret.special = {fct = function(self, t) return false end,
			desc="I'll need an awesome suggeston to unlock this talent!"}
		return ret
	end,
	points = 5,
	info = function(self, t)
		return ([[Outrider is a class in the very early phases of implementation and testing!

			Throughout its development, many changes have been made to the base idea. Because of talents moving out of the original trees, we have many new trees (either playable now or in the works!)

			But this does mean certain talent categories have lost their original progression. What should I place here? You help decide! Send me your ideas, and I fall in love with any of them, they'll go in! Until then, don't try and put any points into this placeholder talent!]])
	end,
}