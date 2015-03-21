-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2014 Nicolas Casalini
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

local change_inven = function(npc, player)
	local d
	local titleupdator = player:getEncumberTitleUpdator(("Equipment(%s) <=> Inventory(%s)"):format(npc.name:capitalize(), player.name:capitalize()))
	d = require("mod.dialogs.ShowEquipInven").new(titleupdator(), npc, nil, function(o, inven, item, button, event)
		if not o then return end
		local ud = require("mod.dialogs.UseItemDialog").new(event == "button", npc, o, item, inven, function(_, _, _, stop)
			d:generate()
			d:generateList()
			d:updateTitle(titleupdator())
			if stop then game:unregisterDialog(d) end
		end, true, player)
		game:registerDialog(ud)
	end, nil, player)
	game:registerDialog(d)
end

local change_inscriptions = function(npc, player)
	local d
	local titleupdator = player:getEncumberTitleUpdator(("Equipment(%s) <=> Inventory(%s)"):format(npc.name:capitalize(), player.name:capitalize()))
	d = require("mod.dialogs.ShowInventory").new(titleupdator(), player:getInven("INVEN"), function(o) return o.type == "scroll" end , function(o, item)
		local inven = player:getInven("INVEN")
		if player:grantInscription(npc, nil, o.inscription_talent, o.inscription_data, true, true, {obj=o, inven=inven, item=item}) then
			player:removeObject(inven, item)
		end
	end, player)
	table.print(d)
	game:registerDialog(d)
end

local change_talents = function(npc, player)
	local LevelupDialog = require "mod.dialogs.LevelupDialog"
	local ds = LevelupDialog.new(npc, nil, nil)
	game:registerDialog(ds)
end

local change_traits = function(npc, player)
	local TraitsDialog = require "mod.dialogs.TraitsDialog"
	local ds = TraitsDialog.new(npc, nil, nil)
	game:registerDialog(ds)
end

local change_tactics = function(npc, player)
	game.party:giveOrders(npc)
end

local change_control = function(npc, player)
	game.party:select(npc)
end

local change_name = function(npc, player)
	local d = require("engine.dialogs.GetText").new("Change your mount's name", "Name", 2, 25, function(name)
		if name then
			npc.name = name.." (mount of "..player.name..")"
			npc.changed = true
		end
	end)
	game:registerDialog(d)
end

local ans = {
	{"I want to change your equipment.", action=change_inven},
	{"I want to change your inscriptions.", action=change_inscriptions},
	{"I want to change your talents.", action=change_talents},
	{"I want to change your tactics.", action=change_tactics},
	{"I want to take direct control.", action=change_control},
	{"I want to change your name.", action=change_name},
	{"Nothing, let's go."},
}

if player:knowTalent(player.T_PRIMAL_BOND) then table.insert(ans, 4, {"I want to train your bestial traits", action=change_traits}) end

newChat{ id="welcome",
	text = [[#LIGHT_GREEN#*Your mount waits at the ready, eager for your next command.*#WHITE#]],
	answers = ans
}

return "welcome"