-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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
	name = "Beastmaster's Mark",
	type = {"mounted/skirmish-tactics", 1},
	points = 5,
	cooldown = 10,
	stamina = 15,
	require = techs_dex_req1,
	range = archery_range,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 } },
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon() then if not silent then game.logPlayer(self, "You require a bow or sling for this talent.") end return false end return true end,
	action = function(self, t)
		local targets = self:archeryAcquireTargets(nil, {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, nil, {mult=self:combatTalentWeaponDamage(t, 1.1, 2.2)})
		local target = targets[1]
		if not target then return true end
		if target:canBe("cut") then target:setEffect(mount.EFF_BLEED,  t.getDur(self, t), {power=t.getBleed(self, t)}) end
		local mount = self:hasMount()
		if not mount then return true end
		mount:setEffect(mount.EFF_BEASTMASTER_MARK,  t.getDur(self, t), {target=target})
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local bleed = t.getBleed(self, t)
		local dur = t.getDur(self, t)
		local speed = t.getSpeed(self, t)*100
		local loyalty = t.getLoyalty(self, t)
		-- local range = t.getRushRange(self, t)
		return ([[You let off a jagged missile that fills your steed with a savage thirst for blood, enraging it. You shoot your enemy for %d%% damage, bleeding it for %d damage each turn and marking it with the Beastmaster's Mark for %d turns. While this is in effect, your steed concentrates solely upon this foe, moving and attacking %d%% faster, but if you hold it back it will lose %.1f Loyalty per turn that you do this.]]):
		format(dam, bleed, dur, speed, loyalty, range)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	getBleed = function(self, t) return self:combatTalentPhysicalDamage(t, 10, 16)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 5, 9) end,
	getLoyalty = function(self, t) return self:combatTalentLimit(t, 1, 5, 3) end,
	getSpeed = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
	-- getRushRange = function(self, t) return math.min(10, self:combatTalentScale(t, 3, 8)) end,
}