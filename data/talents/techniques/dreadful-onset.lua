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

function hasNonTwoHander(self)
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
	if mainhand and (mainhand.twohanded or mainhand.archery) then return nil end
	if not (self:getInven("OFFHAND") and self:getInven("OFFHAND")[1]) then return true else return nil end
end

newTalent{
	name = "Master of Brutality", short_name = "OUTRIDER_MASTER_OF_BRUTALITY", image = "talents/master_of_brutality.png",
	type = {"technique/dreadful-onset", 1},
	require = mnt_dexcun_req1,
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
	callbackOnCrit = function(self, t, type, dam, chance, target)
		if not type=="physical" then return end
		local val = t.getPhysPen(self, t)
		target:setEffect(target.EFF_WEAKENED_DEFENSES, 3, {inc=-val, max=-val})
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
		return ([[While you prefer weapons less visibily impressive than some, the merciless precision with which you wield them makes them no less intimidating in your hands.

		Also, while wielding a one-handed or an archery weapon, gain the following bonuses:
		+%d mindpower
		+%d%% physical crit chance
		+%d%% critical power
		+%d APR
		Critical hits will reduce the physical resistance of the target by %d%% for 3 turns.

		If you hold nothing in your off-hand, instead gain the following benefits:
		+%d mindpower
		+%d%% physical crit chance
		+%d%% critical power
		+%d APR
		Critical hits will reduce the physical resistance of the target by %d%% for 3 turns.]]):
		format(mindpower, phys_crit, crit_power, apr, phys_pen, mindpower2, phys_crit2, crit_power2, apr2, phys_pen)
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
	on_pre_use = function(self, t, silent) --No longer a ranged-focussed tree!
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
	name = "Feigned Retreat", short_name = "OUTRIDER_FEIGNED_RETREAT", image="talents/feigned_retreat.png",
	type = {"technique/dreadful-onset", 3},
	require = mnt_dexcun_req3,
	points = 5,
	-- random_ego = "attack",
	cooldown = 30,
	stamina = -25,
	-- tactical = { DISABLE = { fear = 4 } },
	range = function (self, t) return math.floor(self:getTalentLevel(t) +4)  end,
	radius = 2,
	requires_target = true,
	target = function(self, t)
		-- return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t, friendlyfire=false, selffire=false}
	end,
	-- on_pre_use = function(self, t, silent)
	-- 	if not self:hasEffect(self.EFF_OUTRIDER_CATCH) then
	-- 		if not silent then
	-- 			game.logPlayer(self, "You must have recently slain an aenemy wih a critical hit to use Catch!")
	-- 		end
	-- 		return false
	-- 	end
	-- 	return true
	-- end,
	action = function(self, t)
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