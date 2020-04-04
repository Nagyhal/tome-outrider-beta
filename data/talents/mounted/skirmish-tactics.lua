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
	name = "Beastmaster's Mark", short_name = "OUTRIDER_BEASTMASTERS_MARK", image = "talents/beastmasters_mark.png",
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
		mount:setEffect(mount.EFF_OUTRIDER_BEASTMASTER_MARK,  t.getDur(self, t), {target=target})
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local bleed = t.getBleed(self, t)
		local dur = t.getDur(self, t)
		local speed = t.getSpeed(self, t)*100
		local loyalty = t.getLoyalty(self, t)
		-- local range = t.getRushRange(self, t)
		return ([[You let off a jagged missile that fills your steed with a savage thirst for blood, enraging it. You shoot your enemy for %d%% damage, bleeding it for %d damage and marking it with the Beastmaster's Mark for %d turns. While this is in effect, your steed concentrates solely upon this foe, moving and attacking %d%% faster, but if you hold it back it will lose %.1f Loyalty per turn that you do this.]]):
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

newTalent{
	name = "Set-up Shot", short_name = "OUTRIDER_SET_UP_SHOT", image = "talents/set_up_shot.png",
	type = {"mounted/skirmish-tactics", 2},
	points = 5,
	cooldown = function(self, t) return math.max(6, self:combatTalentScale(t, 8, 6)) end,
	require = techs_dex_req2,
	range = archery_range,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 } },
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon() then if not silent then game.logPlayer(self, "You require a bow or sling for this talent.") end return false end return true end,
	action = function(self, t)
		local targets = self:archeryAcquireTargets(nil, {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, nil, {})
		local target = targets[1]
		if not target then return true end
		local allies = {}
		for i = 0, 8 do
			local x = currentX + (i % 3) - 1
			local y = currentY + math.floor((i % 9) / 3) - 1
			local a = game.level.map(x, y, Map.ACTOR)
			if a and self:reactionToward(a) > 0  then
				local dam = t.getDam(self, t)
				a:attackTarget(target, nil, dam, true)

				game:playSoundNear(a, "actions/melee")
			end
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100

		return ([[You shoot your enemy for 100%% damage, granting any adjacent alllies a free attack for %d%% damage. This shot consumes no stamina. Extra talent levels increase the ally damage and reduce the cooldown.]]):
		format(dam)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
}

newTalent{
	name = "Loose in the Saddle", short_name = "LOOSE_IN_THE_SADDLE", image = "talents/loose_in_the_saddle.png",
	type = {"mounted/skirmish-tactics", 3},
	points = 5,
	mode = "sustained",
	sustain_stamina = 50,
	no_energy = true,
	cooldown = function(self, t) return self:combatTalentLimit(t, 8, 20, 12) end,
	require = techs_dex_req3,
	activate = function(self, t)
		local mount = self:hasMount()
		local ret = {
			reduction=t.getReduction(self, t)/100,
		}
		if mount then
			mount:setEffect(mount.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED, 2, ret)
			ret.mount = mount
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if ret.mount then
			ret.mount:removeEffect(ret.mount.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE_SHARED, true, true)
		end
		return true
	end,
	callbackOnTakeDamage = function(self, t, src, x, y, type, dam, state)
		if not self:isMounted() then return end
		local p = self:isTalentActive(t.id)
		if dam>self.max_life*.15 then
			dam = dam - dam*p.reduction
			self:setEffect(self.EFF_OUTRIDER_LOOSE_IN_THE_SADDLE, 2, {speed=t.getSpeed(self, t)/100})
			self:forceUseTalent(self.T_OUTRIDER_LOOSE_IN_THE_SADDLE, {ignore_energy=true})
		end
		return {dam=dam}
	end,
	info = function(self, t)
		local reduction = t.getReduction(self, t)
		local speed = t.getSpeed(self, t)
		return ([[While mounted, if you or your mount are hit for over 15%% of your max health (but not enough to kill you), then you take only %d%% of that damage, this sustain deactivates, and you gain a movement speed increase of %d%% for one turn and may mount or dismount freely - but if you do anything other than mount, dismount or move, then this bonus ends.]]):
		format(reduction, speed)
	end,
	getReduction = function(self, t) return self:combatTalentLimit(t, 80, 35, 60) end,
	getSpeed = function(self, t) return self:combatTalentScale(t, 400, 650) end,
}