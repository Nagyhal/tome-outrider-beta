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

local Talents = require("engine.interface.ActorTalents")
---------------------------------------------------------------
--Nagy's magic table of talent requirements
---------------------------------------------------------------

--If we need to create any more Outrider talent requirements,
--all it takes is to edit the following table:


local req_tables1 = {
	--Single-stat requirements
	["mnt_str_req"] = {{"str"}},
	["mnt_str_req_high"] = {{"str"}, high=true},
	["mnt_dex_req"] = {{"dex"}},
	["mnt_wil_req"] = {{"wil"}},
	["mnt_wil_req_broad"] = {{"wil"}, broad=true},
	["mnt_cun_req"] = {{"cun"}},
	--Multi-stat requirements
	["mnt_strcun_req"] = {{"str", "cun"}, "Strength or Cunning at %d"},
	["mnt_strdex_req"] = {{"str", "dex"}, "Strength or Dexterity at %d"},
	["mnt_strwil_req"] = {{"str", "wil"}, "Strength or Willpower at %d"},
	["mnt_dexwil_req"] = {{"dex", "wil"}, "Dexterity or Willpower at %d"},
	["mnt_dexcun_req"] = {{"dex", "cun"}, "Dexterity or Cunning at %d"},
	["mnt_wilcun_req"] = {{"wil", "cun"}, "Willpower or Cunning at %d"},
	["mnt_wilcun_req_high"] = {{"wil", "cun"}, "Willpower or Cunning at %d", high=true},
}

---------------------------------------------------------------
--Components for our "requirement factory"
---------------------------------------------------------------

local getSpecialRequirements = function(attrs, desc, r)
	local special_reqs = {}
	--Create the function which checks every attribute listed
	--in the "attrs" parameter
	special_reqs.fct = function(self, t, offset)
		local ok = false
		for _, stat in ipairs(attrs) do
			if self:getStat(stat) >= r then ok = true end
		end
		return ok
	end
	--Build the descriptor.
	special_reqs.desc = (desc):format(r)

	return special_reqs
end

local makeMultiStatReqs = function(reqs_name, stats, desc, base_r, level_mod)
	for i = 1,4 do
		local f = function(self, t, offset)
			local tlev = self:getTalentLevelRaw(t.id) + (offset or 0)
			local r  = base_r + i*8 + tlev*2
			return {
				special=getSpecialRequirements(stats, desc, r),
				level=function(level) return (i-1)*4 + (level+level_mod) end,
			}
		end
		Talents.main_env[reqs_name..i] = f
	end
end

local makeSingleStatReqs = function(reqs_name, stat_name, desc, base_r, level_mod, broad)
	local mult = broad and 5 or 1
	for i = 1,4 do
		Talents.main_env[reqs_name..i] = {
			stat = { [stat_name]=function(level) return base_r + i*8 + (level-1) * 2 end },
			level = function(level) return -4 + i*4 + (level*mult+level_mod)  end
		}		
	end
end

---------------------------------------------------------------
--Nagy's big dirty talent requirement factory
---------------------------------------------------------------

--All together this might look complicated but you'll have to believe it works
--Saving lines saves LIVES, folks!

for reqs_name, t in pairs(req_tables1) do
	local stats, desc = t[1], t[2]
	local high = t.high
	local broad = t.broad  --For mastery talents. First L1, then L6 & so on.

	local base_r, level_mod = 4, -1; if high then base_r, level_mod = 12, 9 end

	if #stats>1 then makeMultiStatReqs(reqs_name, stats, desc, base_r, level_mod)
	else makeSingleStatReqs(reqs_name, stats[1], desc, base_r, level_mod, broad)
	end
end