-- TE4 - T-Engine 4
-- Copyright (C) 2009 - 2015 Nicolas Casalini
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

local Talents = require "engine.interface.ActorTalents"

newEntity{base = "BASE_TOOL_MISC",
	define_as = "HUNTING_HORN",
	image = "object/artifact/hunting_horn.png",
	power_source = {technique=true},
	plot = true,
	unique = true,
	name = "Hunting Horn", color = colors.YELLOW,
	desc = [[Inlaid with scenes of hunting, revelry and righteous war-making from your homeland. A hunting horn is an indispensable tool in the chase and capture of wild beasts.]],
	cost = 1,
	material_level = 1,
	rarity = false,
	encumberance = 0,
	special_desc = function(self) return "During your Wild Challenge:\n  +5 attack\n  +5 physical power\n\nWhile in control of a wild beast:\n  beast gains +5 attack\n  beast gains +5 physical power" end,
	wielder = {
		challenge_the_wilds_boost = 5
	},
	on_wear = function(self, who)
		local pet = who.outrider_pet
		if pet then
			if self.current_buff_target then
				local old_pet = self.current_buff_target 
				old_pet:unlearnTalent(old_pet.T_OUTRIDER_HUNTING_HORN_BUFF, true)
			end
			pet:learnTalent(pet.T_OUTRIDER_HUNTING_HORN_BUFF, true, 1)
			self.current_buff_target = pet
		end
	end,
	on_takeoff = function(self, who)
		local pet = self.current_buff_target
		if pet then
			pet:unlearnTalentFull(pet.T_OUTRIDER_HUNTING_HORN_BUFF)
		end
	end,
	callbackOnActBase = function(self, who)
		local pet = who.outrider_pet
		local old = self.current_buff_target
		if pet and (not old or old~=pet) then
			if old then
				old:unlearnTalentFull(old.T_OUTRIDER_HUNTING_HORN_BUFF)
			end
			pet:learnTalent(pet.T_OUTRIDER_HUNTING_HORN_BUFF, true, 1)
			self.current_buff_target = pet
		elseif not pet and old then
			old:unlearnTalentFull(old.T_OUTRIDER_HUNTING_HORN_BUFF)
		end
	end,
	max_power = 25, power_regen = 1,
	use_talent = { id = Talents.T_OUTRIDER_HUNTING_HORN_BLAST, level = 2, power = 25 },
}