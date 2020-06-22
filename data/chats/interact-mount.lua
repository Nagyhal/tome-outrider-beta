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

local change_inven = function(mount, player)
	local d
	local titleupdator = player:getEncumberTitleUpdator(("Equipment(%s) <=> Inventory(%s)"):format(mount.name:capitalize(), player.name:capitalize()))
	d = require("mod.dialogs.ShowEquipInven").new(titleupdator(), mount, nil, function(o, inven, item, button, event)
		if not o then return end
		local ud = require("mod.dialogs.UseItemDialog").new(event == "button", mount, o, item, inven, function(_, _, _, stop)
			d:generate()
			d:generateList()
			d:updateTitle(titleupdator())
			if stop then game:unregisterDialog(d) end
		end, true, player)
		game:registerDialog(ud)
	end, nil, player)
	game:registerDialog(d)
end

local change_inscriptions = function(mount, player)
	local d
	local titleupdator = player:getEncumberTitleUpdator(("Equipment(%s) <=> Inventory(%s)"):format(mount.name:capitalize(), player.name:capitalize()))
	d = require("mod.dialogs.ShowInventory").new(titleupdator(), player:getInven("INVEN"), function(o) return o.type == "scroll" end , function(o, item)
		local inven = player:getInven("INVEN")
		if player:grantInscription(mount, nil, o.inscription_talent, o.inscription_data, true, true, {obj=o, inven=inven, item=item}) then
			player:removeObject(inven, item)
		end
	end, player)
	table.print(d)
	game:registerDialog(d)
end

local change_talents = function(mount, player)
	local LevelupDialog = require "mod.dialogs.LevelupDialog"
	local ds = LevelupDialog.new(mount, nil, nil)
	game:registerDialog(ds)
end

local change_traits = function(mount, player)
	local TraitsDialog = require "mod.dialogs.TraitsDialog"
	local ds = TraitsDialog.new(mount, nil, nil)
	game:registerDialog(ds)
end

local change_tactics = function(mount, player)
	game.party:giveOrders(mount)
end

local change_control = function(mount, player)
	game.party:select(mount)
end

local change_name = function(mount, player)
	local d = require("engine.dialogs.GetText").new("Change your mount's name", "Name", 2, 25, function(name)
		if name then
			mount.name = name
			mount.changed = true
			mount.done_change_name = true
		end
	end)
	game:registerDialog(d)
end

local ans = {
	{"I want to change your amulet.", action=change_inven},
	{"I want to change your inscriptions.", action=change_inscriptions},
	{"I want to change your talents.", action=change_talents},
	{"I want to change your tactics.", action=change_tactics},
	{"I want to change your name.", action=change_name},
	{"Nothing, let's go."},
}

local test = function(mount, player)
	player:callTalent(player.T_OUTRIDER_CHALLENGE_THE_WILDS, "test")
end

ans[#ans+1] = {"DEBUG: test", action=test}

if player:hasEffect(player.EFF_OUTRIDER_BOND_BEYOND_BLOOD) then table.insert(ans, 4,d {"I want to take direct control.", action=change_control}) end
if player:knowTalent(player.T_OUTRIDER_PRIMAL_BOND) then table.insert(ans, 4, {"I want to train your bestial traits", action=change_traits}) end

newChat{ id="welcome",
	text = [[#LIGHT_GREEN#*Your mount waits at the ready, eager for your next command.*#WHITE#]],
	answers = ans
}

return "welcome"