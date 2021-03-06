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

	local eff=target:getEffectFromId(eff_id); if not eff or not eff.dur then return end
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
	mode = "passive",
	passives = function(self, t, p)
		p.free_off=false
		if hasOutriderWeapon(self) then
			if hasFreeOffhand(self) then
				self:talentTemporaryValue(p, "combat_mindpower", t.getMindpower(self, t))
				self:talentTemporaryValue(p, "combat_critical_power", t.getCritPower2(self, t))
				self:talentTemporaryValue(p, "combat_apr", t.getApr2(self, t))
				p.free_off=true
			else
				self:talentTemporaryValue(p, "combat_mindpower", t.getMindpower(self, t))
				self:talentTemporaryValue(p, "combat_critical_power", t.getCritPower(self, t))
				self:talentTemporaryValue(p, "combat_apr", t.getApr(self, t))
			end
		end
		self:talentTemporaryValue(p, "outrider_master_of_brutality", t.getCritChance(self, t))
		-- Rather than rewriting the basic Shoot and Attack actions, we
		-- make use of the baked-in Temporal Warden swap in rather hackish way.
		self:talentTemporaryValue(p, "warden_swap", 1)
		self:talentTemporaryValue(p, "outrider_swap", 1)
	end,
	callbackOnWear  = function(self, t, o, bypass_set) self:updateTalentPassives(t.id) end,
	callbackOnTakeoff  = function(self, t, o, bypass_set) self:updateTalentPassives(t.id) end,
	callbackOnQuickSwitchWeapons = function(self, t, o) self:updateTalentPassives(t.id) end,
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

			Also, the terror of your foes only heightens your lethality unto them - but you must close the gap from range to take advantage of this: Gain %.1f%% extra chance to crit in melee if your target has a detrimental mental effect.

			Activating Master of Brutality also lets you swap weapons instantly. Shooting or bump-attacking enemies will automatically switch you to the correct weapon set.]]):
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
	name = "Feigned Retreat", short_name = "OUTRIDER_FEIGNED_RETREAT", image="talents/feigned_retreat.png",
	type = {"technique/dreadful-onset", 2},
	require = mnt_dexcun_req2,
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
	getTarget2ForAI = function(self, t, move_dist, tgt_dist)
		local cone_angle = 180/math.pi*math.atan(1/(tgt_dist + 1)) + 5 --5° extra angle
		return {type="cone", cone_angle=cone_angle, source_actor=self, selffire=false, range=0, radius=move_dist, talent=t}
	end,
	on_pre_use = function(self, t, silent, fake) return preCheckCanMove(self, t, silent, fake) end,
	cooldownStop = function(self, t)
		-- Hack to enable resting while talent is permanently cooling down
		self.talents_auto[t.id] = nil
	end,
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
	action = function(self, t)
		-----------------------------------------------------------------------
		-- Shamelessly stolen from Disengage - which seems thoughtfully coded!
		-- I've tried to take it and make it understandable for myself.
		-----------------------------------------------------------------------
		-- Get initial target and distance
		-----------------------------------------------------------------------
		local tg = self:getTalentTarget(t)
		local tx, ty, target = self:getTarget(tg)
		if not (target and self:canSee(target) and self:canProject(tg, tx, ty)) then return end
		
		local tgt_dist, move_dist = core.fov.distance(self.x, self.y, tx, ty), t.getDist(self,t)
		-----------------------------------------------------------------------
		--Get our secondary target
		-----------------------------------------------------------------------
		local dx, dy
		if self.player then
			-- Get furthest possible target square in a straight line backward
			local possible_x, possible_y = projectLineBehind(self, target, t, move_dist)
			if possible_x then
				game.target.target.entity = nil
				game.target.target.x = possible_x
				game.target.target.y = possible_y
			end

			local tg2 = getTargetForProjectLineBehind(self, target, t, move_dist)
			dx, dy = self:getTarget(tg2)
		else 
			local tg2 = t.getTarget2ForAI(self, t, move_dist, tgt_dist)
			local grids = getFreeGridsFromTarget(self, tg2)
			grids:sort(function(gs1, gs2)
				local gs1_dist = core.fov.distance(self.x, self.y, gs1[1], gs1[2])
				local gs2_dist = core.fov.distance(self.x, self.y, gs2[1], gs2[2])
				return gs1_dist > gs2_dist
			end)

			dx, dy = grids[1][1], grids[1][2]
		end
		-----------------------------------------------------------------------
		-- Check the target square
		-----------------------------------------------------------------------
		if not (dx and dy) or not game.level.map:isBound(dx, dy) or core.fov.distance(dx, dy, self.x, self.y) > move_dist then return end
		if not checkUserIsBehindTarget(self, target, dx, dy) then
			game.logPlayer(self, "You must retreat directly away from your target in a straight line.")
			return
		end
		-----------------------------------------------------------------------
		-- Move to the target location
		-----------------------------------------------------------------------
		if not rushTargetTo(self, dx, dy, {}) then
			game.logPlayer(self, "You can't use Feigned Retreat in that direction.")
			return false
		end

		-----------------------------------------------------------------------
		-- Set the temp effects
		target:setEffect(target.EFF_OUTRIDER_FEIGNED_RETREAT_TARGET, 1, {src=self})
		if not target:hasEffect(target.EFF_OUTRIDER_FEIGNED_RETREAT_TARGET) then
			return true
		end
		self:setEffect(self.EFF_OUTRIDER_FEIGNED_RETREAT, 2, {target=target, damage=t.getDamPct(self, t)/100})

		-----------------------------------------------------------------------
		-- Allow player to rest while Feigned Retreat is cooling down
		-----------------------------------------------------------------------
		self.talents_auto[t.id] = true

		return true
	end,
	info = function(self, t)
		local dist = t.getDist(self, t)
		local dam_pct = t.getDamPct(self, t)
		local attacks_no = t.getAttacksNo(self, t)
		local str = attacks_no>1 and "attacks" or "attack"
		return ([[Turning suddenly and feigning flight from battle, you ready a cruel ambush. Rush up to %d squares away from your target, but deal %d%% damage with your next %d %s against it.

			If you fail to slay your mark, Feigned Retreat stays on cooldown, as the ruse is now discovered. You must kill 30 more combatants in order to recover it.]]):
		format(dist, dam_pct, attacks_no, str)
	end,
	getDist = function(self, t) return self:combatTalentScale(t, 4,  7) end,
	getDamPct = function(self, t) return self:combatTalentScale(t, 110, 140) end,
	getAttacksNo = function(self, t) return math.floor(self:combatTalentScale(t, 1, 2.8)) end,
}

newTalent{
	name = "Impalement", short_name = "OUTRIDER_IMPALEMENT", image="talents/impalement.png",
	type = {"technique/dreadful-onset", 3},
	require = mnt_dexcun_req3,
	points = 5,
	cooldown = 16,
	stamina = 15,
	random_ego = "attack",
	range = function(self, t) return self:combatTalentScale(t, 2, 3) end,
	-- @todo (AI): Return a tactical table dependent on current situation
	tactical = { ATTACK = { weapon = 1 }, DISABLE = { pin = 2 } },
	-- @todo (AI): We need to draw past the target and check behind them
	-- onAIGetTarget = function(self, t)
	-- end,
	-- on_pre_use_ai = function(self, t, silent, fake) return t.onAIGetTarget(self, t) and true or false end,
	requires_target = true,
	on_pre_use = function(self, t, silent, fake)
		return preCheckArcheryInAnySlot(self, t, silent, fake)
	end,
	--@todo (AI): We need to draw past the target and check behind them
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {
			range=self:getTalentRange(t),
			weapon=weapon, ammo=ammo, 
			selffire=false, friendlyfire=false, friendlyblock=false,
		}
	end,
	archery_onhit = function(self, t, target, x, y)
		-------------------------------------------------------------
		-- Get initial direction and do knockback
		local dir = util.getDir(target.x, target.y, self.x, self.y)
		target:knockback(self.x, self.y, t.getKnockbackRange(self, t))
		-------------------------------------------------------------
		-- Find a wall behind the target 
		local dx, dy = util.dirToCoord(dir, target.x, target.y)
		local wall_x, wall_y = target.x + dx, target.y +dy

		local ter = game.level.map(wall_x, wall_y, engine.Map.TERRAIN)
		-------------------------------------------------------------
		-- Blocked? Try to pin the enemy - even if it flies!
		if ter and ter.does_block_move then

			-- We need to check canBe:("pin"), but levitation
			-- and flight make pins impossible, which doesn't
			-- make much sense for a wall pin.
			-- So we'll do this:

			local old_fly, old_levitation = target.fly, target.levitation
			target.fly, target.levitation = 0, 0

			-- Easy! But what if something goes wrong while
			-- we set the pin? We'll error out of the function
			-- and the target will be permanently wing-clipped.

			-- We'll make a protected call to try and
			-- set the effect.

			local status, err = pcall(function()
				if target:canBe("pin") then
					target:setEffect(target.EFF_OUTRIDER_PINNED_TO_THE_WALL, t.getDur(self, t), 
						{tile={x=wall_x, y=wall_y}, ox=target.x, oy=target.y, apply_power=self:combatAttack()})
				else
					game.logSeen(target, "%s resists!", target.name:capitalize())
				end
			end)

			-- If something went wrong, no biggie.
			-- Set the target back the way it was:

			target.fly, target.levitation = old_fly, old_levitation

			-- And display the error, without causing any borkage
			-- to the target:

			if err then error(err) end
		end
		-------------------------------------------------------------
		-- Smash a shield if we can:
		if self:getTalentLevel(t) >= 3 and rng.percent(t.getShatterChance(self, t)) then
			local effs=target:effectsFilter({shield=true}, 1)
			local eff_id = effs and effs[1]; if not eff_id then return end

			--Half of the time, does only a half-shatter:
			if rng.percent(50) then
				target:removeEffect(eff_id)
				game.logSeen(self, "#CRIMSON##{bold}# impales %s's shield!#{normal}#", self.name:capitalize(), target.name)
			else
				-- This special function also does the logging on shield-break:
				reduceDamageShieldByPct(self, target, eff_id, 50)
			end
		end
	end,
	-----------------------------------------------------------------
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local targets = getArcheryTargetsWithSwap(self, tg, {one_shot=true})
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
		return ([[Take a point-blank shot for %d%% damage at a maximum range of %d, pushing your enemy back up to %d squares and pinning it (for %d turns) against any suitable obstacle, natural or man-made. You may perform this manoeuvre with a melee weapon; but doing so will force you to switch to your secondary weapon set.

			This damage even goes straight through damage shields. At talent level 3, you attack with such timing that you overload the energies of the shield, shattering it. This has a %d%% chance of happening (%d%% half effect).]]):
		format(dam_pct, range, knockback_range, dur, shatter_chance, half_shatter_chance)
	end,
	getKnockbackRange = function(self, t) return math.round(self:combatTalentScale(t, 3.0, 4.25)) end,
	getDur = function(self, t) return math.round(self:combatTalentScale(t, 3, 4))  end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.0, 1.6) end,
	getShatterChance = function(self, t)
		local mod = self:getTalentTypeMastery(t.type[1])
		local tl = math.max(self:getTalentLevel(t), 3*mod) - 2*mod --Start from TL 3
		return self:combatTalentLimit(tl, 100, 34, 87.1)
	end,
	getHalfShatterChance = function(self, t) return t.getShatterChance(self, t)/2 end,
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
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

		local grappled = false

		-- Break active grapples if the target is not grappled
		if target:isGrappled(self) then
			grappled = true
		else
			self:breakGrapples()
		end

		-- End the talent without effect if the target is to big
		if self:grappleSizeCheck(target) then
			return true
		end

		-- Start the grapple; this will automatically hit and reapply the grapple if we're already grappling the target
		local hit = self:startGrapple(target)
		local eff = target:hasEffect(target.EFF_GRAPPLED)
		local eff2 = self:hasEffect(self.EFF_GRAPPLING)

		local dur = t.getDur(self, t)

		if hit and eff then
			eff.dur=dur
			eff2.dur=dur
			local shield = self:getTalentLevelRaw(t) >= 5 and t.getShield(self, t) or nil
			local min_incoming = t.getMinIncoming(self, t)
			target:setEffect(target.EFF_OUTRIDER_LIVING_SHIELD, dur, {
				src=self, chance=t.getTransferChance(self, t), def=t.getDef(self, t)})
			self:setEffect(self.EFF_OUTRIDER_LIVING_SHIELDED, dur,
				{target=target,
				chance=t.getTransferChance(self, t),
				shield=shield, min_incoming=min_incoming})
			return true
		end
	end,
	info = function(self, t)
		local def = t.getDef(self, t)
		local dur = t.getDur(self, t)
		local chance = t.getTransferChance(self, t)
		local min_incoming = t.getMinIncoming(self, t)
		local shield = t.getShield(self, t)
		return ([[Grapple an adjacent enemy up to one size category larger than you for %d turns; it suffers a %d penalty to defense and all ranged and melee attacks now have a %d%% chance to hit this enemy instead of you. You may move to drag the enemy with you. 
		At talent level 5, you have mastered the art of cruel redirection, gaining the Block talent for a 100%% chance to reduce one incoming attack (of minimum %d damage) by %d%% (scaling with Cunning), switching squares upon an impact.]])
		:format(dur, def, chance, min_incoming, shield)
	end,
	getDef = function(self, t) return self:combatTalentScale(t, 5, 15) end,
	getDur = function(self, t) return 2 + math.floor(self:getTalentLevel(t)) end,
	getPower = function(self, t) return self:combatTalentPhysicalDamage(t, 5, 25) end,
	getTransferChance =  function(self, t) return 30 + self:getTalentLevel(t) * 5 end,
	getMinIncoming = function(self, t) return 45 + self.level*1.5 end,
	getShield = function(self, t) return math.min(75, self:combatStatScale("cun", 45, 75, 0.7)) end,
}

newTalent{
	name = "Block (with Living Shield)", short_name = "OUTRIDER_LIVING_SHIELD_BLOCK",
	image = "talents/block.png",
	type = {"mounted/mounted-base", 1},
	cooldown = function(self, t)
		return 8
	end,
	points = 1, hard_cap = 1,
	range = 1,
	ignored_by_hotkeyautotalents = true,
	requires_target = true,
	tactical = { ATTACK = 3, DEFEND = 3 },
	on_pre_use = function(self, t, silent)
		if not self:hasEffect(self.EFF_OUTRIDER_LIVING_SHIELDED) then if not silent then game.logPlayer(self, "Error! You can only use this talent with a living shield.") end return false end return true end,
	action = function(self, t)
		local p = self:hasEffect(self.EFF_OUTRIDER_LIVING_SHIELDED)
		if not p then return false end

		self:setEffect(self.EFF_OUTRIDER_LIVING_SHIELD_BLOCKING, 2, {power = p.shield, target = p.target, min_incoming=p.min_incoming})
		return true
	end,
	info = function(self, t)
		local p = self:hasEffect(self.EFF_OUTRIDER_LIVING_SHIELDED) 
		local power = p and p.shield or 0
		local min_incoming = p and p.min_incoming or 0
		return ([[You've mastered the art of cruel terror tactics, and can raise the target of your Living Shield as deftly to block damage as you can any shield item. Activate to, for 2 turns, redirect %d%% damage from the next incoming attack (of at least %d damage of any type) to your target.]]):
			format(power, min_incoming)
	end,
}