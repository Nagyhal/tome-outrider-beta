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

name = "The Hunt Begins!"
desc = function(self, who)
	local desc = {}
	desc[#desc+1] = "You are an Outrider, elite mount-riding warrior of your 'barbaric' people. Present circumstances, however, find you without a mount.\n"
	desc[#desc+1] = "Seek in the #BOLD#wilderness#BOLD# a natural ally to carry you to glory.\n"
	if self:isCompleted() then
		desc[#desc+1] = "#LIGHT_GREEN#Out from the wilderness, you have subdued a mighty #BOLD#wolf!#BOLD# There is much you can do with this beast, an ally that will prove true and steadfast so long as the blood of your noble people flows through you, and the ancient knowledge of your elders lives and grows within you.#WHITE#"
		desc[#desc+1] = "#LIGHT_GREEN#You can teach it talents as it levels, change its name, even inscribe it with potent infusions.#WHITE#"
		desc[#desc+1] = "#LIGHT_GREEN#Take great care not to let your beast fall in battle, for you will have to complete the arduous hunt again! #WHITE#"
	else
		desc[#desc+1] = "#BLUE#To find your first mount, you will need to slay only 10 enemies while Challenge the Wilds is active. For all subsequent uses of Challenge the Wilds, the amount will be higher.#WHITE#"
	end
		
	return table.concat(desc, "\n")
end
