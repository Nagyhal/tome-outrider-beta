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
	name = "Challenge the Wilds",
	type = {("mounted/bestial-dominion"), 1},
	require = mnt_str_req1,
	points = 5,
	cooldown = 500,
	stamina = 50,
	no_npc_use = true,
--	action = function (self, t)
--		if not self.mount and if not **CHALLENGE** then

	action = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, talent=t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty then return nil end
		local _ _, tx, ty = self:canProject(tg, tx, ty)
		target = game.level.map(tx, ty, Map.ACTOR)
		if target == self then target = nil end

		-- Find space
		local x, y = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "Not enough space to summon!")
			return
		end

		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			type = "animal", subtype = "canine",
			display = "C", color=colors.LIGHT_DARK, image = "npc/summoner_wardog.png",
			name = "doggy", faction = self.faction,
			desc = [[]],
			autolevel = "none",
			ai = "summoned", ai_real = "dumb_talented_simple", ai_state = { talent_in=5, },
			stats = {str=0, dex=0, con=0, cun=0, wil=0, mag=0},
			inc_stats = { str=15 + (self:getCun(130, true) * self:getTalentLevel(t) / 5) + (self:getTalentLevel(t) * 2), dex=10 + self:getTalentLevel(t) * 2, mag=5, con=15},
			level_range = {self.level, self.level}, exp_worth = 0,
			global_speed = 1.2,

			max_life = resolvers.rngavg(25,50),
			life_rating = 6,
			infravision = 10,

			combat_armor = 2, combat_def = 4,
			combat = { dam=self:getTalentLevel(t) * 10 + rng.avg(12,25), atk=10, apr=10, dammod={str=0.8} },

			summoner = self, summoner_gain_exp=true, wild_gift_summon=false,
			summon_time = math.ceil(self:getTalentLevel(t)*5) + 5,
			ai_target = {actor=target}
		}		

		setupSummon(self, m, x, y)

		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	
	info = function(self, t)
		return ([[Your hurl your fury at the wilderness, letting out a luring, primal call and intensifying every one of your senses so that you might close upon a savage ally, a steed to carry you to victory and spoil. Finding a suitable wild mount takes time and effort; you gain the "Challenge the Wilds" status with a counter of %d, and every time you slay an enemy, that counter depletes by 1. As it approaches 0, your chances of happening upon your quarry are increased. The beast that is called will depend on your surroundings: either a wolf, agile and dependable; a spider, ruthless yet versatile; or a rare and mighty drake. You must subdue the beast by blade or bow; it will not come to your side immediately, but after you have asserted your dominance. Care must be taken not to slay it unwittingly. The quality of beast will increase with talent level.]])
		:format(math.ceil(self:getTalentLevel(t)*5) + 10)
	end,
}
