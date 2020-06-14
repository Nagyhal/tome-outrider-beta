-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2015 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even th+e implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
require "mod.class.interface.TooltipsData"

local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local UIContainer = require "engine.ui.UIContainer"
local TalentTrees = require "mod.dialogs.elements.TalentTrees"
local StatusBox = require "mod.dialogs.elements.StatusBox"
local Separator = require "engine.ui.Separator"
local Empty = require "engine.ui.Empty"
local DamageType = require "engine.DamageType"
local FontPackage = require "engine.FontPackage"

module(..., package.seeall, class.inherit(Dialog, mod.class.interface.TooltipsData))

local function backup(original)
	local bak = original:clone()
	bak.uid = original.uid -- Yes ...
	return bak
end

local function restore(dest, backup)
	local bx, by = dest.x, dest.y
	backup.replacedWith = false
	dest:replaceWith(backup)
	dest.replacedWith = nil
	dest.x, dest.y = bx, by
	dest.changed = true
	dest:removeAllMOs()
	if game.level and dest.x then game.level.map:updateMap(dest.x, dest.y) end
end

function _M:init(actor, on_finish, on_birth)
	self.on_birth = on_birth
	actor.no_last_learnt_talents_cap = true
	self.actor = actor
	self.unused_stats = self.actor.unused_stats
	self.new_stats_changed = false
	self.new_talents_changed = false

	self.talents_changed = {}
	self.on_finish = on_finish
	self.running = true
	self.prev_stats = {}
	self.font_h = self.font:lineSkip()
	self.talents_learned = {}
	self.talent_types_learned = {}
	self.stats_increased = {}

	self.font = core.display.newFont(FontPackage:getFont("mono_small", "mono"))
	self.font_h = self.font:lineSkip()

	self.actor.__hidden_talent_types = self.actor.__hidden_talent_types or {}
	self.actor.__increased_talent_types = self.actor.__increased_talent_types or {}

	actor.last_learnt_talents = actor.last_learnt_talents or { class={}, generic={} }
	self.actor_dup = backup(actor)
	if actor.alchemy_golem then self.golem_dup = backup(actor.alchemy_golem) end

	if actor.descriptor then
		for _, v in pairs(engine.Birther.birth_descriptor_def) do
			if v.type == "subclass" and v.name == actor.descriptor.subclass then self.desc_def = v break end
		end
	end

	Dialog.init(self, "Levelup: "..actor.name, game.w * 0.9, game.h * 0.9, game.w * 0.05, game.h * 0.05)
	if game.w * 0.9 >= 1000 then
		self.no_tooltip = true
	end

	self:generateList()

	self:loadUI(self:createDisplay())
	self:setupUI()

	self.key:addCommands{
		__TEXTINPUT = function(c)
			if self.focus_ui.ui.last_mz then
				if c == "+" and self.focus_ui and self.focus_ui.ui.onUse then
					self.focus_ui.ui:onUse(self.focus_ui.ui.last_mz.item, true)
				elseif c == "-" then
					self.focus_ui.ui:onUse(self.focus_ui.ui.last_mz.item, false)
				end
			end
		end,
	}
	self.key:addBinds{
		EXIT = function()
			local changed = false
			-- local changed = #self.actor.last_learnt_talents.class ~= #self.actor_dup.last_learnt_talents.class or #self.actor.last_learnt_talents.generic ~= #self.actor_dup.last_learnt_talents.generic
			if self.actor.unused_traits~=self.actor_dup.unused_traits or changed  then
				self:yesnocancelPopup("Finish","Do you accept changes?", function(yes, cancel)
				if cancel then
					return nil
				else
					if yes then ok = self:finish() else ok = true self:cancel() end
				end
				if ok then
					game:unregisterDialog(self)
					self.actor_dup = {}
					if self.on_finish then self.on_finish() end
				end
				end)
			else
				game:unregisterDialog(self)
				self.actor_dup = {}
				if self.on_finish then self.on_finish() end
			end
		end,
	}
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:unload()
	self.actor.no_last_learnt_talents_cap = nil
	self.actor:capLastLearntTalents("class")
	self.actor:capLastLearntTalents("generic")
end

function _M:cancel()
	restore(self.actor, self.actor_dup)
	if self.golem_dup then restore(self.actor.alchemy_golem, self.golem_dup) end
end

function _M:getMaxTPoints(t)
	if t.points == 1 then return 1 end
	return t.points + math.max(0, math.floor((self.actor.level - 50) / 10)) + (self.actor.talents_inc_cap and self.actor.talents_inc_cap[t.id] or 0)
end

function _M:subtleMessage(title, message, color)
	if not self.t_messages then return self:simplePopup(title, message) end
	return self.t_messages:setTextColor(message, color)
end

-- Some common colors
local subtleMessageErrorColor = {r=255, g=100, b=100}
local subtleMessageWarningColor = {r=255, g=255, b=80}
local subtleMessageOtherColor = {r=255, g=215, b=0}

function _M:finish()
	local ok, dep_miss = self:checkDeps(true, true)
	if not ok then
		self:simpleLongPopup("Impossible", "You cannot learn this talent(s): "..dep_miss, game.w * 0.4)
		return nil
	end

	local txt = "#LIGHT_BLUE#Warning: You have increased some of your statistics or talent. Talent(s) actually sustained: \n %s If these are dependent on one of the stats you changed, you need to re-use them for the changes to take effect."
	local talents = ""
	local reset = {}
	for tid, act in pairs(self.actor.sustain_talents) do
		if act then
			local t = self.actor:getTalentFromId(tid)
			if t.no_sustain_autoreset and self.actor:knowTalent(tid) then
				talents = talents.."#GOLD# - "..t.name.."#LAST#\n"
			else
				reset[#reset+1] = tid
			end
		end
	end
	if talents ~= "" then
		game.logPlayer(self.actor, txt:format(talents))
	end
	for i, tid in ipairs(reset) do
		self.actor:forceUseTalent(tid, {ignore_energy=true, ignore_cd=true, no_talent_fail=true})
		if self.actor:knowTalent(tid) then self.actor:forceUseTalent(tid, {ignore_energy=true, ignore_cd=true, no_talent_fail=true, talent_reuse=true}) end
	end
	
	-- Prodigies
	if self.on_finish_prodigies then
		for tid, ok in pairs(self.on_finish_prodigies) do if ok then self.actor:learnTalent(tid, true, nil, {no_unlearn=true}) end end
	end

	if not self.on_birth then
		for t_id, _ in pairs(self.talents_learned) do
			local t = self.actor:getTalentFromId(t_id)
			if not self.actor:isTalentCoolingDown(t) and not self.actor_dup:knowTalent(t_id) then self.actor:startTalentCooldown(t) end
		end
	end
	return true
end

function _M:computeDeps(t)
	local d = {}
	self.talents_deps[t.id] = d

	-- Check prerequisites
	if rawget(t, "require") then
		local req = t.require
		if type(req) == "function" then req = req(self.actor, t) end

		if req.talent then
			for _, tid in ipairs(req.talent) do
				if type(tid) == "table" then
					d[tid[1]] = true
--					print("Talent deps: ", t.id, "depends on", tid[1])
				else
					d[tid] = true
--					print("Talent deps: ", t.id, "depends on", tid)
				end
			end
		end
	end

	-- Check number of talents
	for id, nt in pairs(self.actor.talents_def) do
		if nt.type[1] == t.type[1] then
			d[id] = true
--			print("Talent deps: ", t.id, "same category as", id)
		end
	end
end

function _M:checkDeps(simple, ignore_special)
	local talents = ""
	local stats_ok = true

	local checked = {}

	local function check(t_id, force)
		if checked[t_id] then return end
		checked[t_id] = true

		local t = self.actor:getTalentFromId(t_id)
		local ok, reason = self.actor:canLearnTalent(t, 0, ignore_special)
		if not ok and (self.actor:knowTalent(t) or force) then talents = talents.."\n#GOLD##{bold}#    - "..t.name.."#{normal}##LAST#("..reason..")" end
		if reason == "not enough stat" then
			stats_ok = false
		end

		local dlist = self.talents_deps[t_id]
		if dlist and not simple then for dtid, _ in pairs(dlist) do check(dtid) end end
	end

	for t_id, _ in pairs(self.talents_changed) do check(t_id) end

	-- Prodigies
	if self.on_finish_prodigies then
		for tid, ok in pairs(self.on_finish_prodigies) do if ok then check(tid, true) end end
	end

	if talents ~="" then
		return false, talents, stats_ok
	else
		return true, "", stats_ok
	end
end

function _M:isUnlearnable(t, limit)
	if not self.actor.last_learnt_talents then return end
	if self.on_birth and self.actor:knowTalent(t.id) and not t.no_unlearn_last then return 1 end -- On birth we can reset any talents except a very few
	local list = self.actor.last_learnt_talents[t.generic and "generic" or "class"]
	local max = self.actor:lastLearntTalentsMax(t.generic and "generic" or "class")
	local min = 1
	if limit then min = math.max(1, #list - (max - 1)) end
	for i = #list, min, -1 do
		if list[i] == t.id then
			if not game.state.birth.force_town_respec or (game.level and game.level.data and game.level.data.allow_respec == "limited") then
				return i
			else
				return nil, i
			end
		end
	end
	return nil
end

function _M:learnTalent(t_id, v)
	self.talents_learned[t_id] = self.talents_learned[t_id] or 0
	local t = self.actor:getTalentFromId(t_id)
	local t_type, t_index = "class", "unused_traits"
	if t.type[1] ~= "mounted/traits" then return end
	if v then
		if self.actor[t_index] < 1 then
			self:subtleMessage("Not enough "..t_type.." trait points", "You have no "..t_type.." trait points left!", subtleMessageErrorColor)
			return
		end
		if not self.actor:canLearnTalent(t) then
			self:subtleMessage("Cannot learn talent", "Prerequisites not met!", subtleMessageErrorColor)
			return
		end
		if self.actor:getTalentLevelRaw(t_id) >= self:getMaxTPoints(t) then
			self:subtleMessage("Already known", "You already fully know this talent!", subtleMessageWarningColor)
			return
		end
		self.actor:learnTalent(t_id, true)
		self.actor[t_index] = self.actor[t_index] - 1
		self.talents_changed[t_id] = true
		self.talents_learned[t_id] = self.talents_learned[t_id] + 1
		self.new_talents_changed = true
	else
		if not self.actor:knowTalent(t_id) then
			self:subtleMessage("Impossible", "You do not know this talent!", subtleMessageErrorColor)
			return
		end
		if not self:isUnlearnable(t, true) and self.actor_dup:getTalentLevelRaw(t_id) >= self.actor:getTalentLevelRaw(t_id) then
			local _, could = self:isUnlearnable(t, true)
			if could then
				self:subtleMessage("Impossible here", "You could unlearn this talent in a quiet place, like a #{bold}#town#{normal}#.", {r=200, g=200, b=255})
			else
				self:subtleMessage("Impossible", "You cannot unlearn this talent!", subtleMessageErrorColor)
			end
			return
		end
		self.actor:unlearnTalent(t_id, nil, true, {no_unlearn=true})
		self.talents_changed[t_id] = true
		local _, reason = self.actor:canLearnTalent(t, 0)
		local ok, dep_miss, stats_ok = self:checkDeps(nil, true)
		self.actor:learnTalent(t_id, true, nil, {no_unlearn=true})
		if ok or reason == "not enough stat" or not stats_ok then
			self.actor:unlearnTalent(t_id)
			self.actor[t_index] = self.actor[t_index] + 1
			self.talents_learned[t_id] = self.talents_learned[t_id] - 1
			self.new_talents_changed = true
		else
			self:simpleLongPopup("Impossible", "You cannot unlearn this talent because of talent(s): "..dep_miss, game.w * 0.4)
			return
		end
	end
	self:updateTooltip()
end

function _M:generateList()
	self.actor.__show_special_talents = self.actor.__show_special_talents or {}

	-- Makes up the list
	local ctree = {}
	local gtree = {}
	self.talents_deps = {}
	for i, tt in ipairs(self.actor.talents_types_def) do
		if tt.type[1]=="race/traitsa" and not (self.actor.talents_types[tt.type] == nil) then
			local cat = tt.type:gsub("/.*", "")
			local ttknown = self.actor:knowTalentType(tt.type)
			local isgeneric = self.actor.talents_types_def[tt.type].generic
			local tshown = (self.actor.__hidden_talent_types[tt.type] == nil and ttknown) or (self.actor.__hidden_talent_types[tt.type] ~= nil and not self.actor.__hidden_talent_types[tt.type])
			local node = {
				name=function(item) return tstring{{"font", "bold"}, cat:capitalize().." / "..tt.name:capitalize() ..(" (%s)"):format((isgeneric and "generic" or "class")), {"font", "normal"}} end,
				rawname=function(item) return cat:capitalize().." / "..tt.name:capitalize() ..(" (x%.2f)"):format(self.actor:getTalentTypeMastery(item.type)) end,
				type=tt.type,
				color=function(item) return ((self.actor:knowTalentType(item.type) ~= self.actor_dup:knowTalentType(item.type)) or ((self.actor.__increased_talent_types[item.type] or 0) ~= (self.actor_dup.__increased_talent_types[item.type] or 0))) and {255, 215, 0} or self.actor:knowTalentType(item.type) and {0,200,0} or {175,175,175} end,
				shown = tshown,
				status = function(item) return self.actor:knowTalentType(item.type) and tstring{{"font", "bold"}, ((self.actor.__increased_talent_types[item.type] or 0) >=1) and {"color", 255, 215, 0} or {"color", 0x00, 0xFF, 0x00}, ("%.2f"):format(self.actor:getTalentTypeMastery(item.type)), {"font", "normal"}} or tstring{{"color",  0xFF, 0x00, 0x00}, "unknown"} end,
				nodes = {},
				isgeneric = isgeneric and 0 or 1,
				order_id = i,
			}
			if isgeneric then gtree[#gtree+1] = node
			else ctree[#ctree+1] = node end

			local list = node.nodes

			-- Find all talents of this school
			for j, t in ipairs(tt.talents) do
				if not t.hide or self.actor.__show_special_talents[t.id] then
					self:computeDeps(t)
					local isgeneric = self.actor.talents_types_def[tt.type].generic

					-- Pregenenerate icon with the Tiles instance that allows images
					if t.display_entity then t.display_entity:getMapObjects(game.uiset.hotkeys_display_icons.tiles, {}, 1) end

					list[#list+1] = {
						__id=t.id,
						name=t.name:toTString(),
						rawname=t.name,
						entity=t.display_entity,
						talent=t.id,
						break_line=t.levelup_screen_break_line,
						isgeneric=isgeneric and 0 or 1,
						_type=tt.type,
						do_shadow = function(item) if not self.actor:canLearnTalent(t) then return true else return false end end,
						color=function(item)
							if ((self.actor.talents[item.talent] or 0) ~= (self.actor_dup.talents[item.talent] or 0)) then return {255, 215, 0}
							elseif self:isUnlearnable(t, true) then return colors.simple(colors.LIGHT_BLUE)
							elseif self.actor:knowTalentType(item._type) then return {255,255,255}
							else return {175,175,175}
							end
						end,
					}
					list[#list].status = function(item)
						local t = self.actor:getTalentFromId(item.talent)
						local ttknown = self.actor:knowTalentType(item._type)
						if self.actor:getTalentLevelRaw(t.id) == self:getMaxTPoints(t) then
							return tstring{{"color", 0x00, 0xFF, 0x00}, self.actor:getTalentLevelRaw(t.id).."/"..self:getMaxTPoints(t)}
						else
							if not self.actor:canLearnTalent(t) then
								return tstring{(ttknown and {"color", 0xFF, 0x00, 0x00} or {"color", 0x80, 0x80, 0x80}), self.actor:getTalentLevelRaw(t.id).."/"..self:getMaxTPoints(t)}
							else
								return tstring{(ttknown and {"color", "WHITE"} or {"color", 0x80, 0x80, 0x80}), self.actor:getTalentLevelRaw(t.id).."/"..self:getMaxTPoints(t)}
							end
						end
					end
				end
			end
		end
	end
	table.sort(ctree, function(a, b)
		if self.actor:knowTalentType(a.type) and not self.actor:knowTalentType(b.type) then return 1
		elseif not self.actor:knowTalentType(a.type) and self.actor:knowTalentType(b.type) then return nil
		else return a.order_id < b.order_id end
	end)
	self.ctree = ctree
	table.sort(gtree, function(a, b)
		if self.actor:knowTalentType(a.type) and not self.actor:knowTalentType(b.type) then return 1
		elseif not self.actor:knowTalentType(a.type) and self.actor:knowTalentType(b.type) then return nil
		else return a.order_id < b.order_id end
	end)
	self.gtree = gtree

	-- Makes up the stats list
	local stats = {}
	self.tree_stats = stats

	for i, sid in ipairs{self.actor.STAT_STR, self.actor.STAT_DEX, self.actor.STAT_CON, self.actor.STAT_MAG, self.actor.STAT_WIL, self.actor.STAT_CUN } do
		local s = self.actor.stats_def[sid]
		local e = engine.Entity.new{image="stats/"..s.name:lower()..".png", is_stat=true}
		e:getMapObjects(game.uiset.hotkeys_display_icons.tiles, {}, 1)

		stats[#stats+1] = {shown=true, nodes={{
			name=s.name,
			rawname=s.name,
			entity=e,
			stat=sid,
			desc=s.description,
			color=function(item)
				if self.actor:getStat(sid, nil, nil, true) ~= self.actor_dup:getStat(sid, nil, nil, true) then return {255, 215, 0}
				elseif self.actor:getStat(sid, nil, nil, true) >= self.actor.level * 1.4 + 20 or
				   self.actor:isStatMax(sid) or
				   self.actor:getStat(sid, nil, nil, true) >= 60 + math.max(0, (self.actor.level - 50)) then
					return {0, 255, 0}
				else
					return {175,175,175}
				end
			end,
			status = function(item)
				if self.actor:getStat(sid, nil, nil, true) >= self.actor.level * 1.4 + 20 or
				   self.actor:isStatMax(sid) or
				   self.actor:getStat(sid, nil, nil, true) >= 60 + math.max(0, (self.actor.level - 50)) then
					return tstring{{"color", 175, 175, 175}, ("%d (%d)"):format(self.actor:getStat(sid), self.actor:getStat(sid, nil, nil, true))}
				else
					return tstring{{"color", 0x00, 0xFF, 0x00}, ("%d (%d)"):format(self.actor:getStat(sid), self.actor:getStat(sid, nil, nil, true))}
				end
			end,
		}}}
	end
end

-----------------------------------------------------------------
-- UI Stuff
-----------------------------------------------------------------

local _points_left = [[
Stats points left: #00FF00#%d#LAST#
Category points left: #00FF00#%d#LAST#
Class talent points left: #00FF00#%d#LAST#
Generic talent points left: #00FF00#%d#LAST#]]

local desc_stats = ([[Stat points allow you to increase your core stats.
Each level you gain 3 new stat points to use.

You may only increase stats to a natural maximum of 60 or lower (relative to your level).]]):toTString()

local desc_class = ([[Class talent points allow you to learn new class talents or improve them.
Class talents are core to your class and can not be learnt by training.

Each level you gain 1 new class point to use.
Each five levels you gain one more.
]]):toTString()

local desc_generic = ([[Generic talent points allow you to learn new generic talents or improve them.
Generic talents comes from your class, your race or various outside training you can get during your adventures.

Each level you gain 1 new generic point to use.
Each five levels you gain one less.
]]):toTString()

local desc_types = ([[Talent category points allow you to either:
- learn a new talent (class or generic) category
- improve a known talent category efficiency by 0.2
- learn a new inscription slot (up to a maximum of 5, learning it is automatic when using an inscription)

You gain a new point at level 10, 20 and 36.
Some races or items may increase them as well.]]):toTString()

local desc_prodigies = ([[Prodigies are special talents that only the most powerful of characters can attain.
All of them require at least 50 in a core stat and many also have more special demands. You can learn a new prodigy at level 30 and 42.]]):toTString()

local desc_inscriptions = ([[You can use a category point to unlock a new inscription slot (up to 5 slots).]]):toTString()

function _M:createDisplay()
	self.c_ctree = TalentTrees.new{
		font = core.display.newFont("/data/font/DroidSans.ttf", 14),
		tiles=game.uiset.hotkeys_display_icons,
		tree=self.ctree,
		width=320, height=self.ih-50,
		tooltip=function(item)
			local x = self.display_x + self.uis[5].x - game.tooltip.max
			if self.display_x + self.w + game.tooltip.max <= game.w then x = self.display_x + self.w end
			local ret = self:getTalentDesc(item), x, nil
			if self.no_tooltip then
				self.c_desc:erase()
				self.c_desc:switchItem(ret, ret)
			end
			return ret
		end,
		on_use = function(item, inc) self:onUseTalent(item, inc) end,
		on_expand = function(item) return end,
		scrollbar = true, no_tooltip = self.no_tooltip,
		message_box = self.t_
	}

	self.c_gtree = TalentTrees.new{
		font = core.display.newFont("/data/font/DroidSans.ttf", 14),
		tiles=game.uiset.hotkeys_display_icons,
		tree=self.gtree,
		width=320, height=(self.no_tooltip and self.ih - 50) or self.ih-50 - math.max((not self.b_prodigies and 0 or self.b_prodigies.h + 5), (not self.b_inscriptions and 0 or self.b_inscriptions.h + 5)),
		tooltip=function(item)
			local x = self.display_x + self.uis[8].x - game.tooltip.max
			if self.display_x + self.w + game.tooltip.max <= game.w then x = self.display_x + self.w end
			local ret = self:getTalentDesc(item), x, nil
			if self.no_tooltip then
				self.c_desc:erase()
				self.c_desc:switchItem(ret, ret)
			end
			return ret
		end,
		on_use = function(item, inc) self:onUseTalent(item, inc) end,
		on_expand = function(item) self.actor.__hidden_talent_types[item.type] = not item.shown end,
		scrollbar = true, no_tooltip = self.no_tooltip,
	}

	self.c_stat = TalentTrees.new{
		font = core.display.newFont("/data/font/DroidSans.ttf", 14),
		tiles=game.uiset.hotkeys_display_icons,
		tree=self.tree_stats, no_cross = true,
		width=50, height=self.ih,
		dont_select_top = true,
		tooltip=function(item)
			local x = self.display_x + self.uis[2].x + self.uis[2].ui.w
			if self.display_x + self.w + game.tooltip.max <= game.w then x = self.display_x + self.w end
			local ret = self:getStatDesc(item), x, nil
			if self.no_tooltip then
				self.c_desc:erase()
				self.c_desc:switchItem(ret, ret)
			end
			return ret
		end,
		on_use = function(item, inc) self:onUseTalent(item, inc) end,
		no_tooltip = self.no_tooltip,
	}

	self.b_traits = Button.new{can_focus = false, can_focus_mouse=true, text="Trait points: "..self.actor.unused_traits, fct=function() end, on_select=function()
		local str = desc_class
		if self.no_tooltip then
			self.c_desc:erase()
			self.c_desc:switchItem(str, str, true)
		-- elseif self.b_stat.last_display_x then
		-- 	game:tooltipDisplayAtMap(self.b_stat.last_display_x + self.	.w, self.b_stat.last_display_y, str)
		end
	end}
	self.t_messages = StatusBox.new{
		font = core.display.newFont("/data/font/DroidSans.ttf", 16),
		width = math.floor(2 * self.iw / 3), delay = 1,
	}
	local vsep1 = Separator.new{dir="horizontal", size=self.ih - 10}
	local vsep2 = Separator.new{dir="horizontal", size=self.ih - 10}
	local hsep = Separator.new{dir="vertical", size=180}
	local align_empty1 = Empty.new{width=0,height=10}
	local align_empty2 = Empty.new{width=0,height=0}

	local ret = {
		-- {left=-10, top=0, ui=0},
		{left=0, top=0, ui=align_empty1},
		-- {left=0, top=align_empty1, ui=self.c_stat},

		-- {left=self.c_stat, top=align_empty1, ui=vsep1},

		-- {left=vsep1, top=0, ui=self.b_traits},
		-- {left=vsep1, top=align_empty1, ui=self.c_ctree},

		{left=self.c_ctree, top=align_empty1, ui=vsep2},

		-- {left=vsep2, top=align_empty1, ui=self.c_gtree},
		-- {left=self.c_gtree, top=0, ui=align_empty2},
		-- {right=align_empty2, top=0, ui=self.b_generic},

		-- {hcenter=vsep2, top=0, ui=self.b_types},

		-- {right=0, bottom=0, ui=self.b_prodigies},

		-- {hcenter=self.b_types, top=-self.t_messages.h, ui=self.t_messages},
	}
	-- if self.b_inscriptions then table.insert(ret, {right=self.b_prodigies.w, bottom=0, ui=self.b_inscriptions}) end
	return ret
end

function _M:getTalentDesc(item)
	local text = tstring{}

 	text:add({"color", "GOLD"}, {"font", "bold"}, util.getval(item.rawname, item), {"color", "LAST"}, {"font", "normal"})
	text:add(true, true)

	if item.type then
		text:add({"color",0x00,0xFF,0xFF}, "Talent Category", true)
		text:add({"color",0x00,0xFF,0xFF}, "A talent category contains talents you may learn. You gain a talent category point at level 10, 20 and 36. You may also find trainers or artifacts that allow you to learn more.\nA talent category point can be used either to learn a new category or increase the mastery of a known one.", true, true, {"color", "WHITE"})

		if self.actor.talents_types_def[item.type].generic then
			text:add({"color",0x00,0xFF,0xFF}, "Generic talent tree", true)
			text:add({"color",0x00,0xFF,0xFF}, "A generic talent allows you to perform various utility actions and improve your character. It represents a skill anybody can learn (should you find a trainer for it). You gain one point every level (except every 5th level). You may also find trainers or artifacts that allow you to learn more.", true, true, {"color", "WHITE"})
		else
			text:add({"color",0x00,0xFF,0xFF}, "Class talent tree", true)
			text:add({"color",0x00,0xFF,0xFF}, "A class talent allows you to perform new combat moves, cast spells, and improve your character. It represents the core function of your class. You gain one point every level and two every 5th level. You may also find trainers or artifacts that allow you to learn more.", true, true, {"color", "WHITE"})
		end

		text:add(self.actor:getTalentTypeFrom(item.type).description)

	else
		local t = self.actor:getTalentFromId(item.talent)

		local unlearnable, could_unlearn = self:isUnlearnable(t, true)
		if unlearnable then
			local max = tostring(self.actor:lastLearntTalentsMax(t.generic and "generic" or "class"))
			text:add({"color","LIGHT_BLUE"}, "This talent was recently learnt, you can still unlearn it.", true, "The last ", max, t.generic and " generic" or " class", " talents you learnt are always unlearnable.", {"color","LAST"}, true, true)
		elseif t.no_unlearn_last then
			text:add({"color","YELLOW"}, "This talent can alter the world in a permanent way, as such you can never unlearn it once known.", {"color","LAST"}, true, true)
		elseif could_unlearn then
			local max = tostring(self.actor:lastLearntTalentsMax(t.generic and "generic" or "class"))
			text:add({"color","LIGHT_BLUE"}, "This talent was recently learnt, you can still unlearn it if you are in a quiet area like a #{bold}#town#{normal}#.", true, "The last ", max, t.generic and " generic" or " class", " talents you learnt are always unlearnable.", {"color","LAST"}, true, true)
		end

		local traw = self.actor:getTalentLevelRaw(t.id)
		local diff = function(i2, i1, res)
			res:add({"color", "LIGHT_GREEN"}, i1, {"color", "LAST"}, " [->", {"color", "YELLOW_GREEN"}, i2, {"color", "LAST"}, "]")
		end
		if traw == 0 then
			local req = self.actor:getTalentReqDesc(item.talent, 1):toTString():tokenize(" ()[]")
			text:add{"color","WHITE"}
			text:add({"font", "bold"}, "First talent level: ", tostring(traw+1), {"font", "normal"})
			text:add(true)
			text:merge(req)
			text:merge(self.actor:getTalentFullDescription(t, 1))
		elseif traw < self:getMaxTPoints(t) then
			local req = self.actor:getTalentReqDesc(item.talent):toTString():tokenize(" ()[]")
			local req2 = self.actor:getTalentReqDesc(item.talent, 1):toTString():tokenize(" ()[]")
			text:add{"color","WHITE"}
			text:add({"font", "bold"}, traw == 0 and "Next talent level" or "Current talent level: ", tostring(traw), " [-> ", tostring(traw + 1), "]", {"font", "normal"})
			text:add(true)
			text:merge(req2:diffWith(req, diff))
			text:merge(self.actor:getTalentFullDescription(t, 1):diffWith(self.actor:getTalentFullDescription(t), diff))
		else
			local req = self.actor:getTalentReqDesc(item.talent)
			text:add({"font", "bold"}, "Current talent level: "..traw, {"font", "normal"})
			text:add(true)
			text:merge(req)
			text:merge(self.actor:getTalentFullDescription(t))
		end
	end

	return text
end

function _M:onUseTalent(item, inc)
	if item.type then
		self:learnType(item.type, inc)
		item.shown = (self.actor.__hidden_talent_types[item.type] == nil and self.actor:knowTalentType(item.type)) or (self.actor.__hidden_talent_types[item.type] ~= nil and not self.actor.__hidden_talent_types[item.type])
		local t = (item.isgeneric==0 and self.c_gtree or self.c_ctree)
		item.shown = not item.shown t:onExpand(item, inc)
		t:redrawAllItems()
	elseif item.talent then
		self:learnTalent(item.talent, inc)
		local t = (item.isgeneric==0 and self.c_gtree or self.c_ctree)
		t:redrawAllItems()
	elseif item.stat then
		self:incStat(item.stat, inc and 1 or -1)
		self.c_stat:redrawAllItems()
		self.c_ctree:redrawAllItems()
		self.c_gtree:redrawAllItems()
	end

	self.b_traits.text = "Trait points: "..self.actor.unused_traits
	self.b_traits:generate()
end

function _M:updateTooltip()
	self.c_gtree:updateTooltip()
	self.c_ctree:updateTooltip()
	self.c_stat:updateTooltip()
	if self.focus_ui and self.focus_ui.ui and self.focus_ui.ui.updateTooltip then self.focus_ui.ui:updateTooltip() end
end
