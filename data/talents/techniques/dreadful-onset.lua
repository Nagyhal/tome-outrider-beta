newTalent{
	name = "Wailing Weapon",
	type = {"technique/dreadful-onset", 1},
	points = 5,
	cooldown = 10,
	stamina = 10,
	require = mnt_cun_req1,
	no_energy = true,
	tactical = { BUFF = { weapon = 2 }, DISABLE = { confusion = 2 } }, 
	on_pre_use = function(self, t)
		if self:hasEffect(self.EFF_DISARMED) or self:isUnarmed() then if silent then game.logPlayer(self, "You must equip a weapon to convert it into a Wailing Weapon!") end return false end
		return true
	end,
	action = function(self, t)
		local eff_id
		if self:hasArcheryWeapon() then eff_id = self.EFF_HOWLING_ARROWS else eff_id = self.EFF_SHRIEKING_STRIKES end
		self:setEffect(eff_id, t.getDur(self, t), {power=t.getConfusePower(self, t)})
		return true
	end,
	doTryConfuse = function(self, t, target)
		assert(target, "No target sent to doTryConfuse")
		if target:canBe("confusion") and rng.percent(t.getConfuseChance(self, t)) then
			target:setEffect(target.EFF_CONFUSED, t.getConfuseDur(self, t), {power=t.getConfusePower(self, t)})
			local eff = target:hasEffect(target.EFF_CONFUSED)
			if eff then
				if self:hasEffect(self.EFF_HOWLING_ARROWS) then self:logCombat(target, "#Source#'s howling arrows confuse #target#!") end
				if self:hasEffect(self.EFF_SHRIEKING_STRIKES) then self:logCombat(target, "#Source#'s shrieking strikes confuse #target#!") end
			end
		end
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local confuse_dur = t.getConfuseDur(self, t)
		local chance = t.getConfuseChance(self, t)
		local power = t.getConfusePower(self, t)
		local silence_chance = t.getSilenceChance(self, t)
		return ([[Taking either specially notched arrows from your quiver, or sought-after feathers which you affix to your melee weaponry, you let loose horridly screeching missiles or hack at your foes with howling strikes. For %d turns, attacks you make with your current weaponry have a %d%% chance to confuse their target (power %d, duration %d). At level 5, the cacophony created is enough to drown out the chants of spellcasters, applying an additional silence chance of %d%%.]])
		:format(dur, chance, power, confuse_dur, silence_chance)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 2.75, 6, .35) end,
	getConfuseDur = function(self, t) return self:combatTalentScale(t, 2.75, 4, .35) end,
	getConfusePower = function(self, t) return self:combatTalentLimit(t, 70, 25, 50) end,
	getConfuseChance = function(self, t)
		local base = self:combatStatTalentIntervalDamage(t, "combatMindpower", 10, 50)
		return self:combatLimit(base, 100, 10, 10, 75, 75)
	end,
	getSilenceChance = function(self, t)
		local base = self:combatStatTalentIntervalDamage(t, "combatMindpower", 5, 20)
		return self:combatLimit(base, 50, 5, 5, 25,25)
	end
}

newTalent{
	name = "Living Shield",
	type = {"technique/dreadful-onset", 2},
	require = mnt_cun_req2,
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	stamina = 30,
	tactical = { ATTACK = 2, DISABLE = 2, DEFEND = 2 },
	requires_target = true,
	getDef = function(self, t) return self:combatTalentScale(t, 5, 15) end,
	getDuration = function(self, t) return 2 + math.floor(self:getTalentLevel(t)) end,
	getPower = function(self, t) return self:combatTalentPhysicalDamage(t, 5, 25) end,
	getTransferChance =  function(self, t) return 30 + self:getTalentLevel(t) * 5 end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

		local grappled = false

		--force stance change
		-- if target and not self:isTalentActive(self.T_GRAPPLING_STANCE) then
			-- self:forceUseTalent(self.T_GRAPPLING_STANCE, {ignore_energy=true, ignore_cd = true})
		-- end

		-- breaks active grapples if the target is not grappled
		if target:isGrappled(self) then
			grappled = true
		else
			self:breakGrapples()
		end
		-- end the talent without effect if the target is to big
		if self:grappleSizeCheck(target) then
			return true
		end
		-- start the grapple; this will automatically hit and reapply the grapple if we're already grappling the target
		local hit = self:startGrapple(target)
		local eff = target:hasEffect(target.EFF_GRAPPLED)

		local duration = t.getDuration(self, t)

		if hit and eff then
			eff.dur=duration
			target:setEffect(target.EFF_LIVING_SHIELD, duration, {src=self, chance=t.getTransferChance(self, t), def=t.getDef(self, t)})
			self:setEffect(target.EFF_LIVING_SHIELDED, duration, {trgt=target, chance=t.getTransferChance(self, t)})
			return true
		end
	end,
	info = function(self, t)
		local def = t.getDef(self, t)
		local duration = t.getDuration(self, t)
		local chance = t.getTransferChance(self, t)
		return ([[Grapple an adjacent enemy up to one size category larger than you for %d turns; it suffers a %d penalty to defense and all ranged and melee attacks now have a %d%% chance to hit this enemy instead of you. You may move to drag the enemy with you. 
		At talent level 5, you have mastered the art of cruel redirection, gaining the Block talent for a 100%% chance to reduce up to 100 damage, switching squares upon an impact.]])
		:format(def, duration, chance)
	end,
}

newTalent{
	name = "Impalement",
	type = {"technique/dreadful-onset", 3},
	points = 5,
	cooldown = function (self, t) return 21 - self:getTalentLevel(t) end,
	stamina = 25,
	random_ego = "attack",
	require = mnt_cun_req3,
	getArcheryTargetType = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {range=t.getArcheryRange(self, t)}
	end,
	getArcheryRange = function(self, t) return math.floor(self:getTalentLevel(t)) end,
	range = function(self, t)
		return t.getArcheryRange(self, t)
	end,
	getFinalRange = function(self, t)
		if self:hasArcheryWeapon("bow") then return t.getArcheryRange(self, t)
		else return 1 end
	end,
	getKnockbackRange = function (self, t)
		return math.floor ((self:getTalentLevel(t) / 2) + 2)
	end,
	getDuration = function (self, t)
		return math.floor (self:getTalentLevel(t) + 2)
	end,
	getDamage = function (self, t)
		return self:combatTalentWeaponDamage(t, 1, 1.4)
	end,
	tactical = { ATTACK = { weapon = 1 }, DISABLE = { pin = 2 } },
	requires_target = true,
	on_pre_use = function(self, t, silent) --No longer a ranged-focussed tree!
		if not self:hasArcheryWeapon("bow") then
			if not self:hasTwoHandedWeapon() then
				if not silent then 
					game.logPlayer(self, "You require a bow or a two-handed weapon for this talent.")
					return false
				end
			end
		end
	return true
	end,
	archery_onhit = function(self, t, target, x, y)
		--TODO: Clean up this nonsense.
		dx, dy = target.x - self.x, target.y - self.y
		if math.max(math.abs(dx), math.abs(dy))>1 then
			dx, dy = dx / math.max(dx, dy), dy / math.max(dx, dy)
		end
		target:knockback(self.x, self.y, t.getKnockbackRange(self, t))
		--we need to detect if the target hits an obstacle, and the obstacle must be within knockback range
		local tx, ty = target.x + dx, target.y + dy
		if math.floor(core.fov.distance(self.x, self.y, tx, ty)) > t.getKnockbackRange(self, t)+1 then return nil end
		local ter = game.level.map(tx, ty, engine.Map.TERRAIN)
		if ter and ter.does_block_move then
			if target:canBe("pin") then
				target:setEffect(target.EFF_PINNED_TO_THE_WALL, t.getDuration(self, t), {tile={x=tx, y=ty}, ox=target.x, oy=target.y, apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
	end,
	action = function(self, t)
		if self:hasArcheryWeapon("bow") then
			local targets = self:archeryAcquireTargets(t.getArcheryTargetType(self, t), {one_shot=true})
			if not targets then return end
			self:archeryShoot(targets, t, nil, {mult=self:combatTalentWeaponDamage(t, 1, 1.4)})
			return true
		else 
			--melee routine
			local tg = {type="hit", range=t.getFinalRange(self, t)}
			local x, y, target = self:getTarget(tg)
			if not x or not y or not target then return nil end
			if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
			t.archery_onhit(self, t, target, x, y)
			self:quickSwitchWeapons()
			return true
		end
	end,
	info = function(self, t)
		return ([[Take a point-blank shot for %d%% damage, pushing your enemy back up to %d squares and pinning it (for %d turns) against any suitable obstacle, natural or man-made. You may perform this manoeuvre with a melee weapon; but doing so will force you to switch to your secondary weapon set.]]):
		format(t.getDamage(self, t) * 100, t.getKnockbackRange(self, t), t.getDuration(self, t))
	end,
}

newTalent{
	name = "Catch!",
	short_name = "CATCH",
	type = {"technique/dreadful-onset", 4},
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	stamina = 35,
	require = mnt_cun_req4,
	tactical = { DISABLE = { fear = 4 } },
	range = function (self, t) return math.floor(self:getTalentLevel(t) +4)  end,
	requires_target = true,
	target = function(self, t)
		return {type="ball", radius=1, range=self:getTalentRange(t)}
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_CATCH_PASSIVE) then self:learnTalent(self.T_CATCH_PASSIVE, true) end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 and self:knowTalent(self.T_CATCH_PASSIVE) then self:unlearnTalentFull(self.T_CATCH_PASSIVE) end
	end,
	on_pre_use = function(self, t, silent)
		if not self:hasEffect(self.EFF_CATCH) then
			if not silent then
				game.logPlayer(self, "You must have recently slain an aenemy wih a critical hit to use Catch!")
			end
			return false
		end
		return true
	end,
	callbackOnKill = function(self, t, target, death_note)
		if not self.turn_procs and self.turn_procs.is_crit then return end
		if core.fov.distance(target.x, target.y, self.x, self.y)>1 then return end
		self:setEffect(self.EFF_CATCH, t.getUsageWindow(self, t), {})
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
			if target:canBe("confusion") then
				target:setEffect(target.EFF_CONFUSED, t.getDur(self, t), {power=30 + self:getCun(70), apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists the terror!", target.name:capitalize())
			end
		return true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local window = t.getUsageWindow(self, t)
		local passive_cooldown = t.getPassiveCooldown(self, t)
		local life_pct = t.getLifePct(self, t)
		local crit_bonus = t.getCritBonus(self, t)
		return ([[Hurl the severed head of your enemies' comrade back at them, causing them to gape in terror and flee for %d turns. You may use this talent only after killing an adjacent enemy (up to %d turns afterward), and then only with a critical hit.

			Levelling Catch also gives you a passive chance to perform a swift execution strike when adjacent to an enemy with less than %d%% health (cooldown %d). You must use a 1-handed weapon for this, but if one is in your off-slot, you will use that instead of your currently equipped weaponry. This strike will have a critical chance bonus of %d%%.]]):
		format(dur, window, life_pct, passive_cooldown, crit_bonus)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 4,  7) end,
	getUsageWindow = function(self, t) return self:combatTalentLimit(t, 5, 2, 3.5) end,
	getPassiveCooldown = function(self, t) return self:combatTalentLimit(t, 6, 12, 8) end,
	getLifePct = function(self, t) return self:combatTalentLimit(t, 30, 10, 20) end,
	getCritBonus = function(self, t) return self:combatTalentScale(t, 15, 30) end,
}

newTalent{
	name = "Catch! (Passive)",
	short_name = "CATCH_PASSIVE",
	type = {"technique/other", 1},
	hide = "always",
	points = 1,
	cooldown = function(self, t) return self:callTalent(self.T_CATCH, "getPassiveCooldown")end,
	callbackOnAct = function(self, t)
		if self:isTalentCoolingDown(t.id) then return false end
		--I'm only doing it as callbackOnAct so I can use this lazy methodology :P
		--(fov.actors_dist will not work if it isn't the user's turn.)
		local foes = {}
		for i = 1, #self.fov.actors_dist do
			act = self.fov.actors_dist[i]
			-- Possible bug with this formula
			if act and game.level:hasEntity(act) and self:reactionToward(act) < 0 and self:canSee(act) and act["__sqdist"] == 1 and act.life <= act.max_life*t.getLifePct(self, t)/100 then
				foes[#foes+1] = act
			end
		end
		if #foes>=1 then
			local offhand, choice
			local mh1 = self.inven[self.INVEN_MAINHAND] and self.inven[self.INVEN_MAINHAND][1]
			local oh1 = self.inven[self.INVEN_OFFHAND] and self.inven[self.INVEN_OFFHAND][1]
			local mh2 = self.inven[self.INVEN_QS_MAINHAND] and self.inven[self.INVEN_QS_MAINHAND][1]
			local oh2 = self.inven[self.INVEN_QS_OFFHAND] and self.inven[self.INVEN_QS_OFFHAND][1]
			for _, weap in ipairs({mh1, mh2, oh1, oh2}) do
				if weap and not weapon.twohanded and not weapon.archery then
					choice = weap
					-- if weap == oh1 or 
				end
			end
			local target = rng.table(foes)
			local crit_bonus = t.getCritBonus(self, t)
			-- if offhand then
			-- 	self:quickSwitchWeapons(true, false)
			-- end
			self.combat_physcrit = self.combat_physcrit+crit_bonus
			self:attackTargetWith(target, weap)
			self.combat_physcrit = self.combat_physcrit-crit_bonus
			-- if offhand then
			-- 	self:quickSwitchWeapons(true, false)
			-- end
			self:startTalentCooldown(t.id)
		end
	end,
	info = function(self, t) return [[Handles passive ability of Catch!]] end,
}