-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2020 Nicolas Casalini
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

function reduceDamageShieldByPct(src, target, eff_id, pct)
	pct = pct or 50

	local shields = {
		EFF_STORMSHIELD = "blocks",
		EFF_DAMAGE_SHIELD = "damage_shield_absorb",
		EFF_DISPLACEMENT_SHIELD = "displacement_shield",
		EFF_ELDRITCH_STONE = "power",
		EFF_KINSPIKE_SHIELD = "kinspike_shield_absorb",
		EFF_THERMSPIKE_SHIELD = "thermspike_shield_absorb",
		EFF_CHARGESPIKE_SHIELD = "chargespike_shield_absorb",
		EFF_RESONANCE_FIELD = "resonance_field_absorb",
		EFF_SHADOW_DECOY = "power",
		EFF_PSI_DAMAGE_SHIELD = "damage_shield_absorb",
		EFF_STEAM_SHIELD = "damage_shield_absorb",
		EFF_OVERCLOCK = "static_shield_absorb",
	}

	local eff=target:getEffectFromId(eff_id); if not eff then return end
	local shield_param = shields[eff_id]

	if not shield_param then
		local change = math.ceiling(eff.dur * (1-pct/100))
		target:alterEffectDuration(eff_id, -change)
		if target:hasEffect(eff_id) then
			game.logSeen(src, "#CRIMSON#%s reduces the duration of %s's shield by %d%%!", src.name:capitalize(), target.name, pct)
		else
			game.logSeen(src, "#CRIMSON#%s completely destroys %s's shield!", src.name:capitalize(), target.name)
		end
		return true
	end

	eff[shield_param] = math.floor(eff[shield_param] * (1-pct/100))
	if eff[shield_param] > 0 then
		game.logSeen(src, "#CRIMSON#%s takes off %d%% of %s's shield!", src.name:capitalize(), pct, target.name)
	else
		target:removeEffect(target[eff_id])
		game.logSeen(src, "#CRIMSON#%s completely destroys %s's shield!", src.name:capitalize(), target.name)
	end
	return true
end

newTalent{
	name = "Master of Brutality", short_name = "OUTRIDER_MASTER_OF_BRUTALITY", image = "talents/master_of_brutality.png",
	type = {"technique/dreadful-onset", 1},
	require = mnt_dexcun_req1,
	points = 5,
	mode = "sustained",
	cooldown = 30,
	sustain_stamina = 40,
	tactical = { BUFF = 3 },
	on_pre_use = function(self, t, silent, fake)
		return preCheckOutriderWeaponBothSlots(self, t, silent, fake)
	end,
	callbackOMeleeAttackBonuses = function(self, t, hd)
		local dam = t.getBonusDamagePct(self, t)/100
		local num = #hd.target:effectsFilter({
			type="mental",
			status={detrimental=true}
		}) or 0
		hd.mult = hd.mult + dam*num
	end,
	clearTempVals = function(self, t, p)
		for i = #(p.__tmpvals or {}), 1, -1  do
			self:removeTemporaryValue(p.__tmpvals[i][1], p.__tmpvals[i][2])
			p.__tmpvals[i] = nil
		end
	end,
	addTempVals = function(self, t, tab)
		tab.free_off=false
		if hasOutriderWeapon(self) then
			if hasFreeOffhand(self) then
				self:talentTemporaryValue(tab, "combat_mindpower", t.getMindpower(self, t))
				self:talentTemporaryValue(tab, "combat_critical_power", t.getCritPower2(self, t))
				self:talentTemporaryValue(tab, "combat_apr", t.getApr2(self, t))
				tab.free_off=true
			else
				self:talentTemporaryValue(tab, "combat_mindpower", t.getMindpower(self, t))
				self:talentTemporaryValue(tab, "combat_critical_power", t.getCritPower(self, t))
				self:talentTemporaryValue(tab, "combat_apr", t.getApr(self, t))
			end
		end
		return tab
	end,
	callbackOnWear  = function(self, t, o, bypass_set) t.checkOnWeaponSwap(self, t, o) end,
	callbackOnTakeoff  = function(self, t, o, bypass_set) t.checkOnWeaponSwap(self, t, o) end,
	checkOnWeaponSwap = function(self, t, o)
		if o.type and o.type=="weapon" then
			game:onTickEnd(function()
				local p = self:isTalentActive(t.id)
				if p and hasOutriderWeapon(self) or hasOutriderWeaponQS(self) then 
					t.clearTempVals(self, t, p)
					t.addTempVals(self, t, p)
				else
					self:forceUseTalent(t.id, {no_energy=true})
				end
			end)
		end
	end,
	activate = function(self, t)
		local ret = {}
		return t.addTempVals(self, t, ret)
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local mindpower = t.getMindpower(self, t)
		local crit_power = t.getCritPower(self, t)
		local crit_power2 = t.getCritPower2(self, t)
		local apr = t.getApr(self, t)
		local apr2 = t.getApr2(self, t)
		local crit_chance = t.getCritChance(self, t)
		return ([[While the profession of an Outrider calls for lighter weapons than some, the merciless precision with which you wield them makes them no less intimidating in your hands. As an Outrider, you have mounted proficiency with one-handed weapons, tridents, bows and slings, and lances - if you can find a lance! Wielding one of these weapons, you gain bonuses:

			+%d mindpower
			+%d%% critical power
			+%d APR

			If you have nothing in your offhand, these increase to:
			+%d%% critical power
			+%d APR

			Also, the terror of your foes only heightens your lethality unto them - but you must close the gap from range to take advantage of this: Gain %.1f%% extra chance to crit in melee if your target has a detrimental mental effect.]]):
		format(mindpower, crit_power, apr, crit_power2, apr2, crit_chance)
	end,
	getApr = function(self, t) return self:combatTalentScale(t, 3, 10) end,
	getApr2 = function(self, t) return self:callTalent(t.id, "getApr")*1.5 end,
	getCritPower = function(self, t) return self:combatTalentScale(t, 10, 30) end,
	getCritPower2 = function(self, t) return self:callTalent(t.id, "getCritPower")*1.65 end,
	getMindpower = function(self, t) return self:combatTalentScale(t, 4, 17) end,
	getCritChance = function(self, t)
		local mod = self:getTalentTypeMastery(t.type[1])
		local tl = self:getTalentLevel(t) - mod --Start from TL 2
		return tl>0 and self:combatTalentScale(tl, 4.3, 10.8) or 0
	end,
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
		--TODO (AI): Return a tactical table dependent on current situation
	tactical = { ATTACK = { weapon = 1 }, DISABLE = { pin = 2 } },
		--TODO (AI): We need to draw past the target and check behind them
	-- onAIGetTarget = function(self, t)
	-- end,
	-- on_pre_use_ai = function(self, t, silent, fake) return t.onAIGetTarget(self, t) and true or false end,
	requires_target = true,
	on_pre_use = function(self, t, silent, fake)
		return preCheckArcheryInAnySlot(self, t, silent, fake)
	end,
		--TODO (AI): We need to draw past the target and check behind them
	getArcheryTargetType = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {
			range=self:getTalentRange(t),
			weapon=weapon, ammo=ammo, 
			selffire=false, friendlyfire=false, friendlyblock=false
		}
	end,
	archery_onhit = function(self, t, target, x, y)
		local dir = util.getDir(target.x, target.y, self.x, self.y)
		local dist = core.fov.distance(self.x, self.y, target.x, target.y)
		local knockback = t.getKnockbackRange(self, t) - dist
		target:knockback(self.x, self.y, knockback)

		--We need to detect if the target hits an obstacle, and the obstacle must be within knockback range
		local dx, dy = util.dirToCoord(dir, target.x, target.y)
		local wall_x, wall_y = target.x + dx, target.y +dy

		local ter = game.level.map(wall_x, wall_y, engine.Map.TERRAIN)
		if ter and ter.does_block_move then
			if target:canBe("pin") then
				target:setEffect(target.EFF_OUTRIDER_PINNED_TO_THE_WALL, t.getDur(self, t), 
					{tile={x=wall_x, y=wall_y}, ox=target.x, oy=target.y, apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end

		if self:getTalentLevel(t) >= 3 and rng.percent(t.getShatterChance(self, t)) then
			local effs=target:effectsFilter({shield=true}, 1)
			local eff_id = effs and effs[1]; if not eff_id then return end

			if rng.percent(50) then --Half of the time, does only a half-shatter:
				target:removeEffect(eff_id)
				game.logSeen(self, "#CRIMSON#%s impales %s's shield!", self.name:capitalize(), target.name)
			else
				reduceDamageShieldByPct(self, target, eff_id, 50) --log handled in this function
			end
		end
	end,
	action = function(self, t)
		if not self:hasArcheryWeapon("bow") then
			if self:hasArcheryWeaponQS("bow") then
				self:quickSwitchWeapons(true, nil, true)
			end
		end
		if not self:hasArcheryWeapon("bow") then return end
		local targets = self:archeryAcquireTargets(t.getArcheryTargetType(self, t), {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, nil, {mult=t.getDam(self, t)})
		return true
	end,
	info = function(self, t)
		local dam_pct = t.getDam(self, t) * 100
		local range = self:getTalentRange(t)
		local knockback_range = t.getKnockbackRange(self, t)
		local dur = t.getDur(self, t)
		local shatter_chance = t.getShatterChance(self, t)
		local half_shatter_chance = t.getHalfShatterChance(self, t)
		return ([[Take a point-blank shot for %d%% damage at a maximum range of %d, pushing your enemy back up to a maximum distance of %d and pinning it (for %d turns) against any suitable obstacle, natural or man-made. You may perform this manoeuvre with a melee weapon; but doing so will force you to switch to your secondary weapon set.

			This damage even goes straight through damage shields. At talent level 3, you attack with such timing that you overload the energies of the shield, shattering it. This has a %d%% chance of happening (%d%% half effect).]]):
		format(dam_pct, range, knockback_range, dur, shatter_chance, half_shatter_chance)
	end,
	getKnockbackRange = function (self, t) return math.round(self:combatTalentScale(t, 2.7, 4.2)) end,
	getDur = function (self, t) return math.round(self:combatTalentScale(t, 3, 6))  end,
	getDam = function (self, t) return self:combatTalentWeaponDamage(t, 1.0, 1.6) end,
	getShatterChance = function(self, t)
		local mod = self:getTalentTypeMastery(t.type[1])
		local tl = math.max(self:getTalentLevel(t), 3*mod) - 2*mod --Start from TL 3
		return self:combatTalentLimit(tl, 100, 34, 87.1)
	end,
	getHalfShatterChance = function(self, t) return t.getShatterChance(self, t)/2 end,
}

newTalent{
	name = "Feigned Retreat", short_name = "OUTRIDER_FEIGNED_RETREAT", image="talents/feigned_retreat.png",
	type = {"technique/dreadful-onset", 3},
	hide="always", --DEBUG : Hiding untested talents 
	require = mnt_dexcun_req3,
	points = 5,
	range = 7,
	cooldown = 30,
	stamina = 25,
	--AI : Increase viability as an escape option as the enemy loses health
	tactical = function(self, t)
		local a = self.ai_target.actor
		if a and self:getReactionToward(a) > 0 then
			local coeff = util.bound(1-a.life/a.max_life, 0, 1)
			return { ESCAPE = util.lerp(1, 4, coeff) }
		else
			return { ESCAPE = 2 }
		end
	end,
	requires_target = true,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	getTarget2ForPlayer = function(self, t, move_dist)
		local tg2 = {type="beam", source_actor=self, selffire=false, range=move_dist, talent=t, no_start_scan=true, no_move_tooltip=true}
		tg2.display_line_step = function(self, d) -- highlight permissible grids for the player
			local t_range = core.fov.distance(self.target_type.start_x, self.target_type.start_y, d.lx, d.ly)
			if t_range >= 1 and t_range <= tg2.range and not d.block and check_dest(d.lx, d.ly) then
				d.s = self.sb
			else
				d.s = self.sr
			end
			d.display_highlight(d.s, d.lx, d.ly)
		end
		return tg2
	end,
	getTarget2ForAI = function(self, t, move_dist, tgt_dist)
		local cone_angle = 180/math.pi*math.atan(1/(tgt_dist + 1)) + 5 --5° extra angle
		return {type="cone", cone_angle=cone_angle, source_actor=self, selffire=false, range=0, radius=move_dist, talent=t}
	end,
	on_pre_use = function(self, t, silent, fake) return preCheckCanMove(self, t, silent, fake) end,
	callbackOnActBase = function(self, t)
		if self:hasEffect(self.EFF_OUTRIDER_FEIGNED_RETREAT) then
			if self.talents_cd[t.id] then
				self.talents_cd[t.id] = 30
			else
				print("OUTRIDER DEBUG: T_OUTRIDER_FEIGNED_RETREAT cooled down without "..
					"removing EFF_OUTRIDER_FEIGNED_RETREAT")
			end
		end
	end,
	--Shamelessly stolen from Disengage - which seems very thoughtfully coded!
	--I've tried to take it and make it understandable for myself.
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local tx, ty, target = self:getTarget(tg)
		if not (target and self:canSee(target) and self:canProject(tg, tx, ty)) then return end
		
		local tgt_dist, move_dist = core.fov.distance(self.x, self.y, tx, ty), t.getDist(self,t)

		--Get our secondary target
		local dx, dy
		if self.player then
			local possible_x, possible_y = projectLineBehind(self, target.x, target.y, move_dist)
			dx, dy = self:getTarget(t.getTarget2ForPlayer(self, t, move_dist))
		else 
			local tg2 = t.getTarget2ForAI(self, t, move_dist, tgt_dist)
			local grids = getFreeGridsFromTarget(self, tg)
			grids:sort(function(gs1, gs2) end) --sort by distance here

			dx, dy = grids[1][1], grids[1][2]
		end

		if not (dx and dy) or not game.level.map:isBound(dx, dy) or core.fov.distance(dx, dy, self.x, self.y) > move_dist then return end
		if not check_dest(dx, dy) then
			game.logPlayer(self, "You must retreat directly away from your target in a straight line.")
			return
		end

		if not rushTargetTo(self, dx, dy, {}) then
			game.logPlayer(self, "You can't use Feigned Retreat in that direction.")
			return false
		end

		if not target:setEeffect(target.EFF_OUTRIDER_FEIGNED_RETREAT_TARGET, 1, {src=self}) then return true end
		self:setEeffect(
			self.EFF_EVASION,
			t.getEvasionDur(self, t),
			{chance=t.getCurrentEvasion(self, t)})
		self:setEffect(self.EFF_OUTRIDER_FEIGNED_RETREAT, 2, {target=target, damage=t.getDamPct(self, t)/100})

		return true
	end,
	info = function(self, t)
		local evasion_dur = t.getEvasionDur(self, t)
		local distance = t.getDistance(self, t)
		local dam_pct = t.getDamPct(self, t)
		local attacks_no = t.getAttacksNo(self, t)
		return ([[One of the most famous tools in the Outrider repertory of mobile combat strategy and psychological warfare.

			Turn suddenly and flee the battle, as you rush up to %d squares away from your target. The more you seem at a genuine disadvantage, the more your enemies are taken in; for %d turns, gain 20%% evasion which increases to 50%% if you are on death's door.

			But it is only a ruse! For when you turn to face the enemy anew, you do so at the moment it is most vulnerable; gain %d%% damage to your next %d attacks. But you MUST turn back, to regain your honour, or you can't use this strategem again. Feigned Retreat stays on cooldown until you either defeat the original target, or move on and kill 30 more combatants.]]):
		format(distance, evasion_dur, dam_pct, attacks_no)
	end,
	getEvasionDur = function(self, t) return self:combatTalentScale(t, 3, 7) end,
	getDistance = function(self, t) return self:combatTalentScale(t, 4,  7) end,
	getDamPct = function(self, t) return self:combatTalentScale(t, 110, 140) end,
	getAttacksNo = function(self, t) return math.floor(self:combatTalentScale(t, 1, 2.8)) end,
	getCurrentEvasion = function(self, t)
		local life_portion_left = util.bound(self.life, 0, self.max_life) / self.max_life
		--LERP, a fantastic and underused utility function. Do you LERP?
		return util.lerp(20, 50, life_portion_left)
	end,
}

newTalent{
	name = "Living Shield", short_name = "OUTRIDER_LIVING_SHIELD", image="talents/living_shield.png",
	type = {"technique/dreadful-onset", 4},
	hide="always", --DEBUG: Hiding untested talents 
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