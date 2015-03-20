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

newEntity{base = "BASE_TOOL_MISC",
	define_as = "HUNTING_HORN",
	image = "object/artifact/hunting_horn.png",
	power_source = {technique=true},
	plot = true,
	unique = true,
	name = "Hunting Horn", color = colors.YELLOW,
	desc = [[Inlaid with scenes of hunting, revelry and righteous war-making, just as you remember them from your homeland. The hunting horn is an indispensable tool in the chase and capture of wild beasts.]],
	cost = 1,
	material_level = 1,
	rarity = false,
	encumberance = 0,
	special_desc = function(self) return [[During your Wild Challenge:
		+5 attack
		+5 physical power
While in control of a wild beast:
		beast gains +5 attack
		beast gains +5 physical power]] end,
	wielder = {
		challenge_the_wilds_boost = 5
	},
}
