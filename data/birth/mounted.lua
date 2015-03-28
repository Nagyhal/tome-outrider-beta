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

newBirthDescriptor{
	type = "class",
	name = "Mounted",
	locked = function() return true end, --profile.mod.allow_build.mounted_outrider end,
	locked_desc = "Few venture into the wilds of Maj'Eyal alone, and many and varied are the alliances forged by the hopeful. Some seek service from tavern hirelings, some call them from the far planes or even raise them into being by necromantic magics, but none stand as faithful throughout time, and still none command such decisive advantage on the massed fields of war, as that eternal dearest friend of civilized man and elf alike, the trained and mounted wild steed.",
	desc = {
		"Mounted characters are a diverse group united by their use of the mounted steed.",
		"Their strength depends on the continuing loyalty of the beasts they ride.",
	},
	descriptor_choices =
	{
		subclass =
		{
			__ALL__ = "disallow",
			Outrider = "allow-nochange",
		},
	}
}

newBirthDescriptor{
	type = "subclass",
	name = "Outrider",
	locked = function() return true end,  --profile.mod.allow_build.mounted_outrider end,
	locked_desc = "You are weak and unseasoned; you have tasted only your first kiss with the fanged children of the wilderness, and have mistaken it for a cooing maiden's. Soon our ragged tides will sweep down from out of the mountains of the north and upon your sweet Maj'Eyal; then, you will know the true glory of our homeland which you call barbarous.",
	desc = {
		"Outriders are the mounted military elite of those scattered and forgotten peoples who roam beyond the limits of known order and rule.",
		"Their most important stats are: Strength and Cunning in melee, OR Dexterity and Willpower at range.",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * +3 Strength, +3 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +0 Magic, +1 Willpower, +2 Cunning",
	},
	stats = { str=3, dex=3, wil=1, cun=3},
	not_on_random_boss = true,
	talents_types = {
		["technique/archery-bow"]={true, 0.1},
		["technique/combat-techniques-passive"]={true, 0.1},
		["technique/combat-training"]={true, 0.1},
		["technique/superiority"]={false, 0.3},
		["technique/warcries"]={false, 0.3},
		["cunning/survival"]={true, 0.1},
		["technique/conditioning"]={true, 0.1},
		["mounted/bestial-dominion"]={true, 0.3},
		["mounted/teamwork"]={true, 0.3},
		["mounted/mounted-mobility"]={true, 0.3},
		-- ["mounted/skirmish-tactics"]={false, 0.3},
		["technique/barbarous-combat"]={true, 0.3},
		["technique/dreadful-onset"]={true, 0.3},
		-- ["mounted/shock-tactics"]={false, -0.1},
		["mounted/beast-heart"]={false, 0.3},
		["cunning/raider"]={true, 0.3},
	},

	talents = {
		[ActorTalents.T_CHALLENGE_THE_WILDS] = 1,
		[ActorTalents.T_BOW_MASTERY] = 1,
		[ActorTalents.T_WEAPON_COMBAT] = 1,
		[ActorTalents.T_WEAPONS_MASTERY] = 1,
		[ActorTalents.T_OVERRUN] = 1,
		[ActorTalents.T_SHOOT] = 1
	},
	
	copy = {
		max_life = 120,
		class_start_check = function(self)
			self:grantQuest("outrider-start")
		end,
		resolvers.equip{ id=true,
			{type="armor", subtype="light", name="rough leather armour", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="longsword", name="iron longsword", autoreq=true, ego_chance=-1000, ego_chance=-1000},
			 {defined="HUNTING_HORN"}
		},
		resolvers.inventory{ id=true, inven="QS_MAINHAND",
			{type="weapon", subtype="longbow", name="elm longbow", autoreq=true, ego_chance=-1000},
		},
		resolvers.inventory{ id=true, inven="QS_QUIVER",
			{type="ammo", subtype="arrow", name="quiver of elm arrows", autoreq=true, ego_chance=-1000},
		},
		resolvers.generic(function(e)
			e.auto_shoot_talent = e.T_SHOOT
		end),
	},
	copy_add = {
		life_rating = 3,
	},
}


-- Allow it in Maj'Eyal campaign
getBirthDescriptor("world", "Maj'Eyal").descriptor_choices.class.Mounted = "allow"