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