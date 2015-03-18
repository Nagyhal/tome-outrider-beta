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

-- Talent trees
setfenv(1, Talents.main_env)

newTalentType{ allow_random=true, type="mounted/mounted-base", name = "mounted - base", description = "Basic mount abilities"}
newTalentType{ allow_random=true, type="mounted/disobedience", name = "disobedience", description = "Commanding wild beasts requires a strong will and a steady hand; without these, you look just as much like prey as any enemy."}
newTalentType{ allow_random=true, type="mounted/bestial-dominion", name = "bestial dominion", description = "Exercise your dominion over the wild beasts of Maj'Eyal."}
newTalentType{ allow_random=true, type="mounted/mounted-mobility", name = "mounted mobility", generic = true, description = "Wresting mastery over your fleet pawed steed, you leave slower foes bleeding in the dust."}
newTalentType{ allow_random=true, type="mounted/teamwork", name = "teamwork", description = "Wresting mastery over your fleet pawed steed, you dance the last dance with those not quick enough to match you."}
newTalentType{ allow_random=true, type="mounted/skirmish-tactics", name = "skirmish tactics", description = "Beside your beast, not even the winds can outpace you; atop it, not even the sky can outreach your aim."}
newTalentType{ allow_random=true, type="mounted/shock-tactics", name = "shock tactics", description = "Shattering your foes' ranks with devastating charge attacks, your shock tactics represent the pinnacle of mounted martial domination and the ultimate unison of steel and steed."}
newTalentType{ allow_random=true, type="mounted/beast-heart", name = "beast heart", description = "Become no longer beast-rider, but beast-kind."}

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
newTalentType{ type="bear/claw-and-crush", name = "claw and crush", description = "Bear power abilities." }
--Xorn, dwarf mount
newTalentType{ type="xorn/embodiment-of-stone", name = "xorn/embodiment of stone", description = "Xorn defensive and travel abilities." }
--Yeeks, yeek mount
newTalentType{ type="yeek/upholder-of-the-way", name = "upholder of the way", description = "Yeek cooperative abilities." }
--Ritch, yeek mount
newTalentType{ type="ritch/hive-sentinel", name = "hive sentinel", description = "Ritch cooperative power abilities." }


--Techniques and Cunning
newTalentType{ allow_random=true, type="technique/dreadful-onset", name = "dreadful onset", description = "Far and wide, kingdoms shall quake at the onset of your terrible reign of blood, arrows and steel."}
newTalentType{ allow_random=true, type="technique/barbarous-combat", name = "barbarous combat", description = "Mounted or afoot, your brutal blademastery shall ravage legions."}
newTalentType{ allow_random=true, type="technique/combined-arms", name = "combined arms", description = "Master many styles of warfare, each complimenting the others."}
newTalentType{ allow_random=true, type="cunning/raider", name = "seasoned raider", generic = true, description = "Relish the danger the unknown brings."}


mnt_str_req1 = {
	stat = { str=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_str_req2 = {
	stat = { str=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_str_req3 = {
	stat = { str=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_str_req4 = {
	stat = { str=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}


mnt_str_req_high1 = {
	stat = { str=function(level) return 22 + (level-1) * 2 end },
	level = function(level) return 10 + (level-1)  end,
}
mnt_str_req_high2 = {
	stat = { str=function(level) return 30 + (level-1) * 2 end },
	level = function(level) return 14 + (level-1)  end,
}
mnt_str_req_high3 = {
	stat = { str=function(level) return 38 + (level-1) * 2 end },
	level = function(level) return 18 + (level-1)  end,
}
mnt_str_req_high4 = {
	stat = { str=function(level) return 46 + (level-1) * 2 end },
	level = function(level) return 22 + (level-1)  end,
}


mnt_wil_req1 = {
	stat = { wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_wil_req2 = {
	stat = { wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_wil_req3 = {
	stat = { wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_wil_req4 = {
	stat = { wil=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_cun_req1 = {
	stat = { cun=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_cun_req2 = {
	stat = { cun=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_cun_req3 = {
	stat = { cun=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_cun_req4 = {
	stat = { cun=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_dex_req1 = {
	stat = { dex=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_dex_req2 = {
	stat = { dex=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_dex_req3 = {
	stat = { dex=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_dex_req4 = {
	stat = { dex=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_wil_req_broad1 = {
	stat = { wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1) *5  end,
}
mnt_wil_req_broad2 = {
	stat = { wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1) *5 end,
}
mnt_wil_req_broad3 = {
	stat = { wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1) *5 end,
}
mnt_wil_req_broad4 = {
	stat = { wil=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1) *5 end,
}

mnt_strcun_req1 = {
	stat = { str=function(level) return 12 + (level-1) * 2 end, cun=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_strcun_req2 = {
	stat = { str=function(level) return 20 + (level-1) * 2 end, cun=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_strcun_req3 = {
	stat = { str=function(level) return 28 + (level-1) * 2 end, cun=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_strcun_req4 = {
	stat = { str=function(level) return 36 + (level-1) * 2 end, cun=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_dexwil_req1 = {
	stat = { dex=function(level) return 12 + (level-1) * 2 end, wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_dexwil_req2 = {
	stat = { dex=function(level) return 20 + (level-1) * 2 end, wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_dexwil_req3 = {
	stat = { dex=function(level) return 28 + (level-1) * 2 end, wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_dexwil_req4 = {
	stat = { dex=function(level) return 36 + (level-1) * 2 end, wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

function learnTraits(self)
	if not self.bestial_traits then return nil end
	self.__show_special_talents = self.__show_special_talents or {}
	for i, tid in ipairs(self.bestial_traits) do
		self.__show_special_talents[tid] = true
	end
end

--These pre-check functions are used by on_pre_use
function preCheckIsMounted(self, t, silent)
	if self:isMounted() then return true
	else
		if not silent then game.logPlayer(self, "You have to be mounted to do that!") end
		return false
	end
end

function preCheckHasMountPresent(self, t, silent)
	if self:hasMountPresent() then return true
	else
		if not silent then game.logPlayer(self, "You must have a mount present to do that!") end
		return false
	end
end

function preCheckHasMountInRange(self, t, silent, range)
	local mount = self:hasMount()
	assert(range, "no range sent to preCheckHasMountInRange")
	assert(type(range)=="number", "range sent to preCheckHasMountInRange is not a number")
	if mount and core.fov.distance(self.x, self.y, mount.x, mount.y) <= range then return true
	else
		if not silent then game.logPlayer(self, "You must have a mount within range %d to do that!", range) end
		return false
	end
end


function shareTalentWithOwner(self, t)
	if not t.shared_talent then error(("No shared talent for talent %s"):format(t.id))end
	if self.owner then self.owner:learnTalent(t.shared_talent, true, 1) else error(("No owner to share with for talent %s"):format(t.id)) end
end

function unshareTalentWithOwner(self, t)
	if not t.shared_talent then error(("No shared talent for talent %s"):format(t.id)) end
	if self.owner then 
		if not self:knowTalent(t) then 
			self.owner:unlearnTalent(t.shared_talent)
		end
	end
end

--- Finds free grids within a given area
-- This will return a random grid. If the coordinates for the region's "epicentre" are given, then it will try to find a square as close to that as possible
-- @param grids the grids in which to search, given as the usual nested tables
-- @param sx the epicenter coordinates
-- @param sy the epicenter coordinates
-- @param block true if we only consider line of sight
-- @param what a table which can have the fields Map.ACTOR, Map.OBJECT, ..., set to true. If so it will only return grids that are free of this kind of entities.
function util.findFreeGridsWithin(grids, sx, sy, block, what)
	if not grids then return nil, nil, {} end
	what = what or {}
	local grids = grids
	local gs = {}
	for x, yy in pairs(grids) do for y, _ in pairs(yy) do
		local ok = true
		if not game.level.map:isBound(x, y) then ok = false end
		for w, _ in pairs(what) do
--			print("findFreeGrid test", x, y, w, ":=>", game.level.map(x, y, w))
			if game.level.map(x, y, w) then ok = false end
		end
		if game.level.map:checkEntity(x, y, game.level.map.TERRAIN, "block_move") then ok = false end
--		print("findFreeGrid", x, y, "from", sx,sy,"=>", ok)
		if ok then
			local dist=1
			if sx and sy then dist = core.fov.distance(sx, sy, x, y) end
			gs[#gs+1] = {x, y, dist, rng.range(1, 1000)}
		end
	end end

	if #gs == 0 then return nil end

	table.sort(gs, function(a, b)
		if a[3] == b[3] then
			return  a[4] < b[4]
		else
			return a[3] < b[3]
		end
	end)

--	print("findFreeGrid using", gs[1][1], gs[1][2])
	return gs[1][1], gs[1][2], gs
end

load("/data-outrider/talents/mounted/mounts.lua")
load("/data-outrider/talents/mounted/disobedience.lua")
load("/data-outrider/talents/mounted/wolf.lua")
load("/data-outrider/talents/mounted/spider.lua")
load("/data-outrider/talents/mounted/drake.lua")
load("/data-outrider/talents/mounted/bestial-dominion.lua")
load("/data-outrider/talents/mounted/mounted-mobility.lua")
load("/data-outrider/talents/mounted/teamwork.lua")
load("/data-outrider/talents/mounted/skirmish-tactics.lua")
load("/data-outrider/talents/mounted/shock-tactics.lua")
load("/data-outrider/talents/mounted/beast-heart.lua")
load("/data-outrider/talents/race/traits.lua")

--technique and cunning
load("/data-outrider/talents/techniques/barbarous-combat.lua")
load("/data-outrider/talents/techniques/dreadful-onset.lua")
load("/data-outrider/talents/cunning/raider.lua")
