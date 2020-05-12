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

newEntity{ base = "BASE_WHIP",
	power_source = {technique=true},
	unided_name = "wood-handled whip",
	name = "Mire-Wood Wolf Whip", color=colors.SANDY_BROWN, unique = true, image = "object/generic_whip.png",
	desc = [[A short whip used by wolf-riding denizens of the northern marshes. Crude carvings of lupine faces and jagged fang patterns adorn its wooden haft. This whip, being very short, is not suited to combat; rather it is a specialized riding tool.]],

--What do I want it to do?
--Aww, nah, now the Goad idea seems too unimaginative for this one!

--+WILLPOWER
--+mental save of mount

--Increase Loyalty with use of Goad
--Decrease cooldown of Goad
--On Goad, wolf performs an attack action

-- 	require = { stat = { dex=28 }, },
-- 	cost = math.random(225,350),
-- 	rarity = 340,
-- 	level_range = {20, 30},
-- 	material_level = 3,
-- 	combat = {
-- 		dam = 28,
-- 		apr = 8,
-- 		physcrit = 5,
-- 		dammod = {dex=1},
-- 		melee_project={[DamageType.POISON] = 22, [DamageType.BLEED] = 22},
-- 		talent_on_hit = { T_DISARM = {level=3, chance=30} },
-- 	},
-- 	wielder = {
-- 		combat_atk = 10,
-- 		see_invisible = 9,
-- 		see_stealth = 9,
-- 	},
-- }