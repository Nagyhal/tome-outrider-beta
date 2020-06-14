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

local _M = loadPrevious(...)

local Talents = require "engine.interface.ActorTalents"
local ActorAI = require "engine.interface.ActorAI"

--Generate a new mount
----------------------
--Destroys the current mount and spawns a new wolf adjacent to 
--the player.
---------------------------------------------------------------
_M:bindHook("DebugMain:use", function(self, data)
	if data.act == "outrider-make-mount" then
		local env = require("engine.interface.ActorTalents").main_env
		env.debugGenerateNewMount(game.player)
	end
end)

_M:bindHook("DebugMain:generate", function(self, data)
	if game.player:hasDescriptor("subclass", "Outrider") then
		data.menu[#data.menu+1] = {name="Outrider: Generate a new mount", action="outrider-make-mount"}
	end
end)

--Cool down all talents
----------------------
--Cools down all player talents for speedy testing.
---------------------------------------------------------------
_M:bindHook("DebugMain:use", function(self, data)
	if data.act == "outrider-cooldown-all-talents" then
		local max = table.max(game.player.talents_cd) or 0
		game.log ("Cooling down all talents by "..(max+1).." turns.")
		game.player:cooldownTalents(max+1)
	end
end)

_M:bindHook("DebugMain:generate", function(self, data)
	data.menu[#data.menu+1] = {name="Outrider: Cool down all talents", action="outrider-cooldown-all-talents"}
end)


--Reload talents afresh from lua files.
---------------------------------------
--This is extremely unsafe and I make no suggestion you use
--this for anything other than speedy re-testing!
--This could be much better, but it would be rather painful to
--write as I need to extract data from the talent files without
--running them as Lua code.
---------------------------------------------------------------

local function forgetTalent(tid)
	game.log("DEBUG: Nilling talent "..tid)
	Talents.talents_def[tid] = nil
	Talents[tid] = nil
end

local function tryReloadTalents(tt)
	local class, cat = tt:match "([^/]+)/([^/]+)"
	local fnames = {
		-- "/data/talents/"..class.."/"..cat..".lua",
		"/data-outrider/talents/"..class.."/"..cat..".lua"
	}
	for _, fname in ipairs(fnames) do
		game.log("DEBUG: Try to load file "..fname)
		if fs.exists(fname) then
			for i, t in ipairs(Talents.talents_types_def[tt].talents) do
				Talents.talents_types_def[tt].talents[i] = nil
				forgetTalent(t.id)
			end		
			Talents:loadDefinition(fname)
			return true
		end
	end
end

local function reloadPetAI()
	ActorAI.ai_def.outrider_pet = nil
	ActorAI.ai_def.target_mount = nil
	ActorAI:loadDefinition("/data-outrider/ai/")

end

local function reloadTalents()
	--Which talents are lurking outside of their proper categories?
	local base_talents = {
		"T_OUTRIDER_GIBLETS",
		"T_OUTRIDER_BESTIAL_DOMINION",
		"T_OUTRIDER_TWIN_THREAT_DASH"
	}

	for _, tid in ipairs(base_talents) do
		forgetTalent(tid)
	end
	--Sorry for the bad coding. This is a proper hack.
	local mounted_base = Talents.talents_types_def["mounted/mounted-base"]
	local len = #mounted_base.talents
	for i = 1, 3 do
		mounted_base.talents[i] = nil
	end
	for tt, _ in pairs(game.player.talents_types) do
		if tt~="mounted/mounted-base" then
			tryReloadTalents(tt)
		end
	end
	for i = 1, #base_talents do
		mounted_base.talents[i] = mounted_base.talents[len+i]
		mounted_base.talents[len+i] = nil
	end
end

_M:bindHook("DebugMain:use", function(self, data)
	if data.act == "outrider-reload-player-talents" then
		reloadTalents()
	end
end)

_M:bindHook("DebugMain:generate", function(self, data)
	data.menu[#data.menu+1] = {name="Outrider: Reload all outrider talents (warning: unsafe!)", action="outrider-reload-player-talents"}
end)

_M:bindHook("DebugMain:use", function(self, data)
	if data.act == "outrider-reload-pet-AI" then
		reloadPetAI()
	end
end)

_M:bindHook("DebugMain:generate", function(self, data)
	data.menu[#data.menu+1] = {name="Outrider: Reload pet AI", action="outrider-reload-pet-AI"}
end)

return _M