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
	name = "Disobedience", short_name = "OUTRIDER_DISOBEDIENCE", image = "talents/disobedience",
	type = {"mounted/disobedience", 1},
	mode = "passive",
	-- hide = true,
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	no_energy = true,
	callbackOnActBase = function(self, t)
		--for debugging, we'll set this to every turn.
		t.callbackOnTakeDamage(self, t)
		self.outrider_done_disobedience = nil
	end,
	callbackOnTakeDamage = function(self, t)
		if self.outrider_done_disobedience then return end
		if not self.owner or self.owner.dead then error("Outrider: T_OUTRIDER_DISOBEDIENCE: Mount has no owner!") return end
		local pct = self.owner.loyalty / self.owner.max_loyalty * 100

		--Quickly return if it isn't neccessary to run the routine
		if pct >= t.getLoyaltyHighThreshold(self, t) then return end

		self.outrider_done_disobedience = true
		
		--Watch how I've done this, next we check the high threshold
		if pct >= t.getLoyaltyLowThreshold(self, t) and rng.percent(t.getLoyaltyHighChance(self, t)) then
			local eff_id = rng.table{
				"EFF_OUTRIDER_FLITFUL",
				-- "EFF_OUTRIDER_FLITFUL",
				-- "EFF_OUTRIDER_OBSTINATE"
				}
			self:setEffect(eff_id, 5, {})
		--And then the low.
		elseif rng.percent(t.getLoyaltyLowChance(self, t)) then
			local eff_id = rng.table{
				"EFF_OUTRIDER_FLITFUL",
				-- "EFF_OUTRIDER_FRENZIED",
				-- "EFF_OUTRIDER_TERROR-STRICKEN",
				-- "EFF_OUTRIDER_DEFIANT"
				}
			self:setEffect(eff_id, 5, {})	
		end
	end,
	--I may want to modify these later; for example, to make a talent which reduces the chance of disobedience effects
	--while mounted.
	getLoyaltyHighThreshold = function(self, t)
		return 50
	end,
	getLoyaltyLowThreshold = function(self, t)
		return 25
	end,
	getLoyaltyHighChance = function(self, t)
		return 25
	end,
	getLoyaltyLowChance = function(self, t)
		return 35
	end,
	info = function(self, t)
		local loyalty_high_threshold = t.getLoyaltyHighThreshold(self, t)
		local loyalty_high_chance = t.getLoyaltyHighChance(self, t)
		local loyalty_low_threshold = t.getLoyaltyLowThreshold(self, t)
		local loyalty_low_chance = t.getLoyaltyLowChance(self, t)

		return ([[Bestial mounts are wilful and not easily tamed. Moreover, their tamer must learn to survive by instilling constant mutual respect.

			In combat, when your beast's Loyalty reserves are below %d%%, once per turn after taking damage it has a %d%% chance to turn either Riled Up, Flitful or Obstinate #RED#(DEBUG: Obstinate not yet implemented)#LAST#. 

			If your beast's Loyalty to you is below %d%%, the effects are more serious: It has a %d%% chance to become Frenzied, Terror-Stricken or Defiant. These effects are stronger versions of the above effects and will override them when they occur.

			It doesn't matter whether you are mounted or unmounted for these effects to happen.]]
		):format(loyalty_high_threshold, loyalty_high_chance, loyalty_low_threshold, loyalty_low_chance)
	end,
}

newTalent{
	name = "Cowardice",
	type = {"mounted/disobedience", 1},
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	cooldown = 0,
	no_energy = true, 
	action = function(self, t)
		self:setEffect(self.EFF_TERRIFIED, 5, {actionFailureChance=50})
		return true
	end,
	info = function(self, t)
		return ([[The beast succumbs to cowardice, and stands a 50%% chance not to attack for 5 turns.]])
	end,
}

newTalent{
	name = "Flee",
	type = {"mounted/disobedience", 1},
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	cooldown = 0,
	no_energy = true, 
	action = function(self, t)
		self:setEffect(self.EFF_PANICKED, 5, {src=self.owner, chance=50})
		return true
	end,
	info = function(self, t)
		return ([[The beast begins to flee, and stands a 50%% chance to run away for 5 turns.]])
	end,
}

newTalent{
	name = "Rebellion",
	type = {"mounted/disobedience", 1},
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	disobedience_type = "major",
	cooldown = 0,
	no_energy = true, 
	action = function(self, t)
		self:setEffect(self.EFF_PARANOID, 5, {src=self.owner, attackChance=50})
		return true
	end,
	info = function(self, t)
		return ([[The beast is overcome by a fury, and stands a 50%% chance to attack anything in sight.]])
	end,
}