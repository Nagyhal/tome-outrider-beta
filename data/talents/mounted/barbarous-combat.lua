newTalent{
	name = "Brazen Charge", short_name = "OUTRIDER_BRAZEN_LUNGE", image = "talents/brazen_lunge.png",
	type = {"mounted/barbarous-combat", 1},
	require = mnt_strcun_req1,
	points = 5,
	random_ego = "attack",
	stamina = function(self, t)
		return math.max(0.5, 7.5 - self:getTalentLevelRaw(t)*1.5)
	end,
	cooldown = 8,
	--TODO (AI) : Make it use this effectively to protect the mount
	tactical = function(self, t)
		if self:isMounted() then return { ATTACK = 2, CLOSEIN = 1, DEFEND = 2 }
		else return { ATTACK =2, CLOSEIN =2 }
		end
	end,
	requires_target = true,
	range = function(self, t) return math.min(14, math.floor(self:combatTalentScale(t, 4, 8))) end,
	target = function(self, t) return {type="bolt", range=self:getTalentRange(t), requires_knowledge=false, stop__block=true} end,
	on_pre_use = function(self, t, silent, fake)
		return preCheckCanMove(self, t, silent, fake) and preCheckMeleeInAnySlot(self, t, silent, fake)
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		if not self:isMounted(t) then tg.range = t.getRangeOnFoot(self, t) end
		local x, y, target = self:getTargetLimited(tg)
		if not target then game.logPlayer(self, "You can only charge to a creature.") return nil end

		if not rushTargetTo(self, x, y, {go_through_friends=true}) then return end

		if not target or core.fov.distance(self.x, self.y, target.x, target.y) > 1 then return true end

		local grids = util.adjacentCoords(target.x, target.y)
		local targets = {}
		for _, coord in pairs(grids) do
			local x, y = coord[1], coord[2]
			if game.level.map:isBound(x, y) then
				local a = game.level.map(x, y, engine.Map.ACTOR)
				if a and self:reactionToward(a) > 0 then targets[#targets+1] = a end
		end end
		targets = rng.tableSample(targets, 2)

		local function doSecondaryAttack(eff_id, eff_type)
			if self:getTalentLevel(t)<3 then return end
			for _, target in ipairs(targets) do
				if self:attackTarget(target, nil, t.getDam(self, t)/2, true) and target:canBe(eff_type, eff_id) then
					target:setEffect(target[effid], t.getStunDur(self, t), {
						apply_power=self:combatPhysicalpower()
					})
				end
			end
		end

		--Swap if we have a melee weapon in the off slot.
		swapToMelee(self)

		if self:isMounted() then
			mount = self:getMount()
			local rider_hit = self:attackTarget(target, nil, t.getDam(self, t), true) 
			local mount_hit = mount:attackTarget(target, nil, t.getDam(self, t), true)
			if rider_hit or mount_hit and target:canBe("stun") then
				target:setEffect(target.EFF_STUNNED, t.getStunDur(self, t), {
					apply_power=rider_hit and self:combatPhysicalpower() or mount:combatPhysicalpower()
				})
			end
			doSecondaryAttack("EFF_STUNNED", "stun")
		else
			if self:attackTarget(target, nil, t.getDam(self, t), true) and target:canBe("stun") then
				target:setEffect(target.EFF_DAZED, t.getDazeDur(self, t), {
					apply_power=self:combatPhysicalpower()
				})
			end
			doSecondaryAttack("EFF_DAZED", "stun")
			for _, a in ipairs(table.append(targets, {target})) do
				--We want to provoke regardless of whether we hit anything
				a:setEffect(a.EFF_OUTRIDER_TAUNT, t.getProvokeDur(self, t), {
					src=self,
					apply_power=self:combatMindpower()
				})
			end
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local stun_dur = t.getStunDur(self, t)
		local daze_dur = t.getDazeDur(self, t)
		local extra_targets = t.getExtraTargets(self, t)
		local range_on_foot = t.getRangeOnFoot(self, t)
		local provoke_dur = t.getProvokeDur(self, t)
		local str = extra_targets>1 and "victims" or "victim"
		return ([[Make a brazen rush at your foes, mounted or on foot. #SALMON#If you are mounted#LAST#, both you and mount deal %d%% damage to your immediate target. The massive impact of your mounted charge inflicts a %d turn stun and, as you train, can easily break the enemies' ranks. After talent level 3, your charge will smash %d other nearby %s (next to either you or the target) for half damage. 

			#SALMON#On foot#LAST#, your range is only %d. Daze your primary target for %d turns and hit secondary targets for half weapon damage. The sheer recklessness of your swing forces your targets to attack you, ignoring your allies, for %d turns.]]):
		format(
			dam,
			stun_dur,
			extra_targets,
			str,
			range_on_foot,
			daze_dur,
			provoke_dur
		)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.11, 1.63, .35) end,
	getRangeOnFoot = function(self, t) return math.round(self:getTalentRange(t)/2) end,
	getStunDur = function(self, t) return self:combatTalentScale(t, 2.7, 4) end,
	getDazeDur = function(self, t) return 2 end,
	getProvokeDur = function(self, t) return self:combatTalentScale(t, 2.7, 4) end,
	getExtraTargets = function(self, t)
		local mod = self:getTalentTypeMastery(t.type[1])
		local tl = math.max(self:getTalentLevel(t), 3*mod) - 2*mod --Start from TL 3
		return math.floor(self:combatTalentScale(tl, 1.5, 3))
	end, 
}

newTalent{
	name = "Tyranny of Steel", short_name = "OUTRIDER_TYRANNY_OF_STEEL", image = "talents/tyranny_of_steel.png",
	type = {"mounted/barbarous-combat", 2},
	require = mnt_strcun_req2,
	points = 5,
	random_ego = "attack",
	cooldown = 15,
	stamina = 18,
	tactical = { ATTACKAREA = { weapon = 2 }, SURROUNDED = 3 },
	range = 0,
	radius = 1,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent, fake) return preCheckMeleeInAnySlot(self, t, silent, fake) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local knockback_range = t.getKnockbackRange(self, t)
		if self:isMounted() then tg.radius = t.getKnockbackRadiusMounted(self, t) end

		if not swapToMelee(self, t) then
			game.logPlayer(self, "You can't swap to your melee weapon to use Tyranny of Steel!")
			return nil
		end

		--Do we hit at least once?
		local hit
		self:project(tg, self.x, self.y, 
			function(px, py, tg, self)
				local target = game.level.map(px, py, engine.Map.ACTOR)
				if target and self:reactionToward(target)<0 then
					if self:attackTarget(target, nil, t.getDam(self, t), true) then hit = true end
				end
			end)

		--If we hit, MEGA KNOCKBACK!
		--Set up our recursive knockback function.
		if hit then 
			local knockback_check = function(target)
				if not target or self:reactionToward(target)>=0 then return end
				if target:checkHit(self:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then
					return true
				else
					game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
				end
			end

			--This is a nice concise way of projecting knockback effects.
			self:project(tg, self.x, self.y, function(px, py, tg, self)
				local target = game.level.map(px, py, engine.Map.ACTOR)
				if knockback_check(target) then
					target:knockback(self.x, self.y, knockback_range, knockback_check)
				end
			end)
		end

		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t) * 100
		local knockback = t.getKnockbackRange(self, t)
		local radius = t.getKnockbackRadiusMounted(self, t)
		return ([[You release a maniacal display of brutality upon your foes, lashing out with a reckless attack that hits all adjacent enemies for %d%% while scattering those who are puny of will, knocking them back %d squares. If you are mounted, you may have your beast rise up in a terrifying fashion, knocking back instead all foes within a radius of %d.]]):
		format(dam, knockback, radius)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 1.5, 2.1) end,
	getKnockbackRange = function(self, t) return self:combatTalentScale(t, 1.3, 4.3) end,
	getKnockbackRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 3.8) end,
}


newTalent{
	name = "Scatter the Unworthy", short_name = "OUTRIDER_SCATTER_THE_UNWORTHY", image = "talents/scatter_the_unworthy.png",
	type = {"mounted/barbarous-combat", 3},
	hide="always", --DEBUG: Hiding untested talents 
	require = mnt_strcun_req3,
	points = 5,
	stamina = 10,
	cooldown = 18, 
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	tactical = { ATTACKAREA = { confusion = 2, fear = 2 }, DISABLE = { confusion = 2, fear = 2 } },
	requires_target = true,
	target = function(self, t)
		local radius_bonus = self:isMounted() and 2 or 0
		return {
			type="cone",
			range=self:getTalentRange(t),
			radius=self:getTalentRadius(t) + radius_bonus,
			selffire=false,
			friendlyfire=false
		} 
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
		return ([[Test the mettle of your foes, sifting out the worthy from the weak. Targets who fail a mind save in a cone of radius %d will be either panicked or provoked for %d turns. Panicked foes suffer a 50%% chance to flee from you each turn, while provoked foes increase their damage by 20%% while reducing all resistances by 25%% and defense and armour by %d

			If you are mounted, add 2 to the range of the attack as you menace the battlefield from on high.

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
	name = "Toss Giblets",short_name = "OUTRIDER_GIBLETS", image = "talents/giblets.png",
	display_name = function(self, t)
		local eff = self:hasEffect(self.EFF_OUTRIDER_GIBLETS)
		return eff and eff.display_name or "Giblets"
	end,
	type = {"mounted/mounted-base", 1},
	hide = true,
	ignored_by_hotkeyautotalents = true,
	points = 1,
	cooldown = 0,
	tactical = { ATTACKAREA = { confusion = 1 }, DISABLE = { blind = 1} },
	range = 5,
	radius = 1,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), talent=t, friendlyfire=false}
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, function(tx, ty)
			local target = game.level.map(tx, ty, Map.ACTOR)
			if not target then return end
		end)
		-- TODO: Add a sound
		-- game:playSoundNear(self, "talents/slime")
		return true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local life = t.getLife(self, t)
		local loyalty = t.getLoyalty(self, t)
		return ([[You have the %d, a gruesome trophy of your dominance in combat. Throw at your foes, causing all in radius 1 to flee for %d turns. Or better yet, feed to your beast to renew %d life and % loyalty.

			Lasts until Gory Spectacle comes back off cooldown.]]):
			format(dam, dur, radius, speed)
	end,
	getDur = function(self, t) return 2 end,
	getLife = function(self, t) 
		local tl = self:getTalentLevel(self.T_OUTRIDER_GORY_SPECTACLE)
		return self:combatTalentScale(tl, 60, 180)
	end,
	getLoyalty = function(self, t)
		local tl = self:getTalentLevel(self.T_OUTRIDER_GORY_SPECTACLE)
		return self:combatTalentScale(tl, 5, 9)
	end,
}

newTalent{
	name = "Gory Spectacle", short_name = "OUTRIDER_GORY_SPECTACLE", image = "talents/gory_spectacle.png",
	type = {"mounted/barbarous-combat", 4},
	hide="always", --DEBUG: Hiding untested talents
	require = mnt_strcun_req4,
	points = 5,
	random_ego = "attack",
	cooldown = 10,
	stamina = 25,
	tactical = { ATTACK = { weapon = 1 } },
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	getSecondaryTarget = function(self, t)
		local radius = self:getTalentRadius(t)
		if self:isMounted() then radius = t.getBlindRadiusMounted(self, t) end
		return {
			type="ball",
			range=self:getTalentRange(t), radius=radius,
			selffire=false, friendlyfire=false,
		}
	end,
	range = 1,
	radius = 1,
	requires_target = true,
	on_pre_use = function(self, t, silent, fake) return preCheckMeleeInAnySlot(self, t, silent, fake) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end

		local hit = self:attackTarget(target, nil, t.getDam(self, t), true)

		--Do we hit and kill it? Things are about to get SPECTACULAR. And very gory.
		if hit and target.dead then
			local tg = t.getSecondaryTarget(self, t)
			local dur = t.getBlindDur(self, t)
			self:project(tg, self.x, self.y, function(px, py, tg, self)
				local target = game.level.map(px, py, engine.Map.ACTOR)
				if target and self:reactionToward(target)<0 and target:canBe("blinded") then
					target:setEffect(target.EFF_BLINDED, dur, {apply_power=self:combatMindpower()})
				end
			end)
		elseif hit then
			target:setEffect(target.EFF_CRIPPLE, t.getCrippleDur(self, t),
				{speed=t.getSpeed(self, t), apply_power=self:combatPhysicalpower()})
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t) * 100
		local blind_dur = t.getBlindDur(self, t)
		local cripple_dur = t.getBlindDur(self, t)
		local radius = t.getBlindRadiusMounted(self, t)
		local speed = t.getSpeed(self, t)
		return ([[You gouge your enemy for %d%% damage. If it is killed, then the horrific maiming you inflict spreads terror in all nearby foes, blinding them as they must avert their eyes for %d turns. If you are mounted, then you may raise the severed remnants of your victim high above for all to see, blinding instead all enemies in radius %d.

			If you fail to slay your foe, however, then instead you cripple it for %d turns, reducing melee, spellcasting and mind speed by %d%% as it struggles to recover from your wicked wound.]]):
			format(dam, blind_dur, radius, cripple_dur, speed)
	end,
	getDam = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.7) end,
	getBlindDur = function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getCrippleDur = function(self, t) return self:combatTalentScale(t, 4, 6) end,
	getBlindRadiusMounted = function(self, t) return self:combatTalentScale(t, 2, 4) end,
	getBleedPower = function(self, t) return self:combatTalentPhysicalDamage(t, 25, 150) end,
	getSpeed = function(self, t) return self:combatTalentLimit(t, 80, 15, 35) end
}