-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
--
-- This program is free softwarfe: you can redistribute it and/or modify
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

-- Talent trees
setfenv(1, Talents.main_env)

-- Helpful stuff
util.load_lua_dir("/data-outrider/talents/helpers/", dofile) 

newTalentType{ allow_random=true, type="mounted/mounted-base", name = "mounted - base", description = "Basic mount abilities"}
newTalentType{ allow_random=true, type="mounted/disobedience", name = "disobedience", description = "Commanding wild beasts requires a strong will and a steady hand; without these, you look just as much like prey as any enemy."}
newTalentType{ allow_random=true, type="mounted/bestial-dominion", name = "bestial dominion", description = "Exercise your dominion over the wild beasts of Maj'Eyal."}
newTalentType{ allow_random=true, type="mounted/mounted-mobility", name = "mounted mobility", generic = true, description = "Leave puny foot-soldiers bleeding in the dust."}
newTalentType{ allow_random=true, type="mounted/teamwork", name = "teamwork", description = "Wresting mastery over your fleet pawed steed, you dance the last dance with those not quick enough to match you."}
newTalentType{ allow_random=true, type="mounted/skirmish-tactics", name = "skirmish tactics", description = "Beside your beast, not even the winds can outpace you; atop it, not even the sky can outreach your aim."}
newTalentType{ allow_random=true, type="mounted/barbarous-combat", name = "barbarous combat", description = "Mounted or afoot, your brutal blademastery shall ravage legions."}
newTalentType{ allow_random=true, type="mounted/shock-tactics", name = "shock tactics", description = "Shattering your foes' ranks with devastating charge attacks, your shock tactics represent the pinnacle of mounted martial domination and the ultimate unison of steel and steed."}
newTalentType{ allow_random=true, type="mounted/beast-heart", name = "beast heart", description = "Become no longer beast-rider, but beast-kind."}
newTalentType{ allow_random=true, type="mounted/warbanner", name = "warbanner", description = "Raise your warbanner for all to see, high above the ashes of your conquests."}

local sort_traits = function(dialog, node)
	local act = dialog.actor
	if not act.bestial_traits then return end
	--Lookup tables to retrieve indexes
	local ranks = table.keys_to_values(act.bestial_traits)
	local lookup = table.keys_to_values(node.nodes)
	table.sort(node.nodes, function(a, b)
		if ranks[a.__id] and ranks[b.__id] then
			if ranks[a.__id] < ranks[b.__id] then return true end
		elseif ranks[a.__id] then
			return true
		elseif ranks[b.__id] then
			return false
		else
			return lookup[a] < lookup[b] 
		end
	end)
end

newTalentType{ allow_random=true, type="race/traits", name = "bestial traits", description = "Even the most mundane of beasts, when handled with wisdom, can reveal hidden traits that make it appear prodigious when compared to its natural kin.", sort=sort_traits}
newTalentType{ allow_random=true, type="race/beast-training", name = "beast training", generic=true, description = "Develop the natural talents of your beast."}

--Mount talents
--Wolf, the basic mount, and its subtypes
newTalentType{ type="wolf/tenacity", name = "tenacity", description = "Wolf offensive abilities" }
newTalentType{ type="wolf/pack-hunter", name = "pack hunter", description = "Wolf cooperative abilities" }
newTalentType{ type="wolf/will-of-winter", name = "will of winter", description = "White wolf gifts" }
newTalentType{ type="wolf/alpha-predator", name = "alpha predator", description = "Wolf power abilities" }
--Spider, the basic underground / tactical mount
newTalentType{ type="spider/stalker-in-the-shadows", name = "stalker in the shadows", description = "Spider ambush tactics" }
newTalentType{ type="spider/weaver-of-woes", name = "fanged killer", description = "Spider web attacks and stealth" }
--Drakes, the basic power mount
newTalentType{ type="drake/dragonflight", name = "dragonflight", description = "Drake airborne abilities." }
--Griffins, secret aerial mount.
newTalentType{ type="griffin/wingborne-supremacy", name = "wingborne supremacy", description = "Griffin airborne abilities." }
--Dread steeds, undead / corrupted mount
newTalentType{ type="dread-steed/dread-herald", name = "dread herald", description = "Dread steed basic abilities." }
--Treants, halfing mount
newTalentType{ type="treant/striding-canopy", name = "striding canopy", description = "Treant defensive abilities." }
--Minotaurs, halfling mount
newTalentType{ type="minotaur/rampaging-mazefarer", name = "rampaging mazefarer", description = "Minotaur navigational abilities." }
--Great elks, thalore mount
newTalentType{ type="great-elk/monarch-of-the-woods", name = "monarch of the woods", description = "Great elk defensive gifts." }
--Mammoths, thalore mount
newTalentType{ type="mammoth/thundering-colossus", name = "thundering colossus", description = "Mammoth utility abilities." }
--Shalore can ride exotic drakes
--Bears, dwarf mount
newTalentType{ type="bear/crushing-claws", name = "crushing claws", description = "Bear power abilities." }
--Xorn, dwarf mount
newTalentType{ type="xorn/embodiment-of-stone", name = "xorn/embodiment of stone", description = "Xorn defensive and travel abilities." }
--Yeeks, yeek mount
newTalentType{ type="yeek/upholder-of-the-way", name = "upholder of the way", description = "Yeek cooperative abilities." }
--Ritch, yeek mount
newTalentType{ type="ritch/hive-sentinel", name = "hive sentinel", description = "Ritch cooperative power abilities." }
--Lion, by popular domand
newTalentType{ type="lion/pride-of-the-steppes", name = "pride of the steppes", description = "Powerful lion combat abilities." }

--Techniques and Cunning
newTalentType{ allow_random=true, type="technique/dreadful-onset", name = "dreadful onset", description = "Far and wide, kingdoms shall quake at the onset of your terrible reign of blood, arrows and steel."}
newTalentType{ allow_random=true, type="technique/combined-arms", name = "combined arms", description = "Master many styles of warfare, each complimenting the others."}
newTalentType{ allow_random=true, type="cunning/raider", name = "seasoned raider", generic = true, description = "Relish the danger the unknown brings."}

util.load_lua_dir("/data-outrider/talents/mounted/", load) 
util.load_lua_dir("/data-outrider/talents/race/", load) 
util.load_lua_dir("/data-outrider/talents/techniques/", load)