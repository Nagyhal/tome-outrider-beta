-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2019 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

newTalent{
	name = "Wailing Weapon", short_name = "OUTRIDER_WAILING_WEAPON", image="talents/wailing_weapon.png",
	type = {"technique/dreadful-onset", 1},
	points = 5,
	cooldown = 15,
	-- stamina = 5,
	require = mnt_dexcun_req1,
	no_energy = true,
	tactical = { BUFF = { weapon = 2 }, DISABLE = { confusion = 2 } }, 
	on_pre_use = function(self, t)
		if self:hasEffect(self.EFF_DISARMED) or self:isUnarmed() then if silent then game.logPlayer(self, "You must equip a weapon to convert it into a Wailing Weapon!") end return false end
		return true
	end,
	radius = function(self, t) return math.round(self:combatTalentScale(t, 2, 3)) end,
	action = function(self, t)
		local eff_id
		if self:hasArcheryWeapon() then eff_id = self.EFF_OUTRIDER_HOWLING_ARROWS else eff_id = self.EFF_OUTRIDER_SHRIEKING_STRIKES end
		self:setEffect(eff_id, t.getDur(self, t), {power=t.getConfusePower(self, t)})
		return true
	end,
	doTryConfuse = function(self, t, target)
		assert(target, "No target sent to doTryConfuse")
		if self.turn_procs.done_wailing_weapon then return end
		local acts = {}
		self:project({type="ball", target.x, target.y, radius=self:getTalentRadius(t), selffire=false, friendlyfire=false}, target.x, target.y, function(px, py)
			local a = game.level.map(px, py, engine.Map.ACTOR)
			if a and a~=target and self:reactionToward(a)<0 then acts[a] = true end
		end)
		local target2 = rng.tableIndex(acts)
		if target2 and target2:canBe("confusion") and rng.percent(t.getConfuseChance(self, t)) then
			target2:setEffect(target.EFF_CONFUSED, t.getConfuseDur(self, t), {power=t.getConfusePower(self, t)})
			local eff = target2:hasEffect(target2.EFF_CONFUSED)
			if eff then
				if self:hasEffect(self.EFF_OUTRIDER_HOWLING_ARROWS) then self:logCombat(target2, "#Source#'s howling arrows confuse #target#!") end
				if self:hasEffect(self.EFF_OUTRIDER_SHRIEKING_STRIKES) then self:logCombat(target2, "#Source#'s shrieking strikes confuse #target#!") end
			end
		end
		self.turn_procs.done_wailing_weapon = true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local confuse_dur = t.getConfuseDur(self, t)
		local radius = self:getTalentRadius(t)
		local chance = t.getConfuseChance(self, t)
		local power = t.getConfusePower(self, t)
		local silence_chance = t.getSilenceChance(self, t)
		return ([[Taking either specially notched arrows from your quiver, or sought-after feathers which you affix to your melee weaponry, you let loose horridly screeching missiles or hack at your foes with howling strikes. For %d turns, attacks you make with your current weaponry have a %d%% chance to confuse a single enemy in radius %d around your target (power %d, duration %d). At level 5, the cacophony created is enough to drown out the chants of spellcasters, applying an additional silence chance of %d%%. This effect can proc once per turn.]])
		:format(dur, chance, radius, power, confuse_dur, silence_chance)
	end,
	getDur = function(self, t) return self:combatTalentLimit(t, 10, 3.75, 5.5, .35) end,
	getConfuseDur = function(self, t) return self:combatTalentScale(t, 2.75, 4, .35) end,
	getConfusePower = function(self, t) return self:combatTalentLimit(t, 70, 25, 50) end,
	getConfuseChance = function(self, t)
		local base = self:combatStatTalentIntervalDamage(t, "combatMindpower", 10, 50)
		return self:combatLimit(base, 100, 10, 10, 75, 75)
	end,
	getSilenceChance = function(self, t)
		local old_level = self.talents[t.id]
		self.talents[t.id] =math.max(self.talents[t.id], 5)
		local base = self:combatStatTalentIntervalDamage(t, "combatMindpower", 5, 20)
		self.talents[t.id] = old_level
		return self:combatLimit(base, 50, 5, 5, 25,25)
	end
}

newTalent{
	name = "Impalement", short_name = "OUTRIDER_IMPALEMENT", image="talents/impalement.png",
	type = {"technique/dreadful-onset", 2},
	require = mnt_dexcun_req2,
	points = 5,
	cooldown = 16,
	stamina = 15,
	random_ego = "attack",
	range = function(self, t) return t.getKnockbackRange(self, t)-1 end,
	tactical = { ATTACK = { weapon = 1 }, DISABLE = { pin = 2 } },
	requires_target = true,
	on_pre_use = function(self, t, silent, fake) --No longer a ranged-focussed tree!
		if not self:hasArcheryWeapon("bow") and not self:hasArcheryWeaponQS("bow") then
			if not silent then 
				game.logPlayer(self, "You require a bow in one of your weapon slots for this talent.")
				return false
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
		local dist = core.fov.distance(self.x, self.y, target.x, target.y)
		local total_knockback = t.getKnockbackRange(self, t) - dist
		target:knockback(self.x, self.y, total_knockback)
		--we need to detect if the target hits an obstacle, and the obstacle must be within knockback range
		local tx, ty = target.x + dx, target.y + dy
		local ter = game.level.map(tx, ty, engine.Map.TERRAIN)
		if ter and ter.does_block_move then
			if target:canBe("pin") then
				target:setEffect(target.EFF_OUTRIDER_PINNED_TO_THE_WALL, t.getDuration(self, t), {tile={x=tx, y=ty}, ox=target.x, oy=target.y, apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
	end,
	action = function(self, t)
		if not self:hasArcheryWeapon("bow") then --do nothing
			if self:hasArcheryWeaponQS("bow") then
				self:quickSwitchWeapons(true, nil, true)
			end
		end
		if not self:hasArcheryWeapon("bow") then return end
		local targets = self:archeryAcquireTargets(t.getArcheryTargetType(self, t), {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, nil, {mult=self:combatTalentWeaponDamage(t, 1, 1.4)})
		return true
	end,
	info = function(self, t)
		local dam_pct = t.getDamage(self, t) * 100
		local range = self:getTalentRange(t)
		local knockback_range = t.getKnockbackRange(self, t)
		local dur = t.getDuration(self, t)
		return ([[Take a point-blank shot for %d%% damage at a maximum range of %d, pushing your enemy back up to a maximum distance of %d and pinning it (for %d turns) against any suitable obstacle, natural or man-made. You may perform this manoeuvre with a melee weapon; but doing so will force you to switch to your secondary weapon set.]]):
		format(dam_pct, range, knockback_range, dur)
	end,
	getArcheryTargetType = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {range=self:getTalentRange(t)}
	end,
	getKnockbackRange = function (self, t) return math.round(self:combatTalentScale(t, 2.7, 4.2)) end,
	getDuration = function (self, t) return math.round(self:combatTalentScale(t, 3, 6))  end,
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 1.0, 1.6) end,
}

newTalent{
	name = "Catch!", short_name = "OUTRIDER_CATCH", image="talents/catch.png",
	type = {"technique/dreadful-onset", 3},
	require = mnt_dexcun_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	-- stamina = 35,
	tactical = { DISABLE = { fear = 4 } },
	range = function (self, t) return math.floor(self:getTalentLevel(t) +4)  end,
	radius = 2,
	requires_target = true,
	target = function(self, t)
		return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t, friendlyfire=false, selffire=false}
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_OUTRIDER_CATCH_PASSIVE) then self:learnTalent(self.T_OUTRIDER_CATCH_PASSIVE, true) end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 and self:knowTalent(self.T_OUTRIDER_CATCH_PASSIVE) then self:unlearnTalentFull(self.T_OUTRIDER_CATCH_PASSIVE) end
	end,
	on_pre_use = function(self, t, silent, fake)
		if not self:hasEffect(self.EFF_OUTRIDER_CATCH) then
			if not silent then
				game.logPlayer(self, "You must have recently slain an aenemy wih a critical hit to use Catch!")
			end
			return false
		end
		return true
	end,
	callbackOnCrit = function(self, t, type, dam, chance, target)
			if type=="physical" then
				self.turn_procs.truephyscrit = true
		end
	end,
	callbackOnKill = function(self, t, target, death_note)
			if not (self.turn_procs and self.turn_procs.truephyscrit) then return end
			if core.fov.distance(target.x, target.y, self.x, self.y)>1 then return end
		self:setEffect(self.EFF_OUTRIDER_CATCH, t.getUsageWindow(self, t), {})
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y  then return nil end
		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, engine.Map.ACTOR)
			if not target then return end
			if target:canBe("confusion") then
				target:setEffect(target.EFF_CONFUSED, t.getDur(self, t), {power=30 + self:getCun(70), apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists the terror!", target.name:capitalize())
			end
		end)
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
	name = "Catch! (Passive)", short_name = "OUTRIDER_CATCH_PASSIVE", image="talents/catch.png",
	type = {"technique/other", 1},
	hide = "always",
	points = 1,
	cooldown = function(self, t) return self:callTalent(self.T_OUTRIDER_CATCH, "getPassiveCooldown")end,
	callbackOnAct = function(self, t)
		if self:isTalentCoolingDown(t.id) then return false end
		local t2 = self:getTalentFromId(self.T_OUTRIDER_CATCH)
		--I'm only doing it as callbackOnAct so I can use this lazy methodology :P
		--(fov.actors_dist will not work if it isn't the user's turn.)
		local foes = {}
		for i = 1, #self.fov.actors_dist do
			act = self.fov.actors_dist[i]
			-- Possible bug with this formula
			if act and game.level:hasEntity(act) and self:reactionToward(act) < 0 and self:canSee(act) and act["__sqdist"] == 1 and act.life <= act.max_life*t2.getLifePct(self, t)/100 then
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
				if weap and not weap.twohanded and not weap.archery then
					choice = weap
					-- if weap == oh1 or 
				end
			end
			local target = rng.table(foes)
			local crit_bonus = t2.getCritBonus(self, t)
			-- if offhand then
			-- 	self:quickSwitchWeapons(true, false)
			-- end
			self.combat_physcrit = self.combat_physcrit+crit_bonus
			self:logCombat(target, "#Source# attempts an executioner's strike against #target#!")
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


newTalent{
	name = "Living Shield", short_name = "OUTRIDER_LIVING_SHIELD", image="talents/living_shield.png",
	type = {"technique/dreadful-onset", 4},
	require = mnt_dexcun_req4,
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
			target:setEffect(target.EFF_OUTRIDER_LIVING_SHIELD, duration, {src=self, chance=t.getTransferChance(self, t), def=t.getDef(self, t)})
			self:setEffect(target.EFF_OUTRIDER_LIVING_SHIELDED, duration, {trgt=target, chance=t.getTransferChance(self, t)})
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

newEffect{
	name = "OUTRIDER_WINGS_CLIPPED", image = "talents/wings_clipped.png",
	desc = "Pinned in Flight",
	long_desc = function(self, eff) return ("For the duration of %d%%, flight and levitation will not be useable.") end,
	type = "other",
	subtype = {},
	status = "detrimental",
	parameters = { },
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "levitation", 1)
		self:effectTemporaryValue(eff, "levitation", 1)
	end,
}