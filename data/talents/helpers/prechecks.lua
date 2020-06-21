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

-- Helpful functions to avoid code re-use for on_pre_use
-- Must load the weapon helper functions before loading this file!

local Talents = require("engine.interface.ActorTalents")
setfenv(1, Talents.main_env)

function preCheckIsMounted(self, t, silent, fake)
	if self:isMounted() then return true
	else
		if not silent then game.logPlayer(self, "You have to be mounted to do that!") end
		return false
	end
end

function preCheckIsNotMounted(self, t, silent, fake)
	if not self:isMounted() then return true
	else
		if not silent then game.logPlayer(self, "You can't be riding your mount if you want to do that!") end
		return false
	end
end

function preCheckHasMount(self, t, silent, fake)
	if self:hasMount() then return true
	else
		if not silent then game.logPlayer(self, "You must have a mount to do that!") end
		return false
	end
end

function preCheckHasMountPresent(self, t, silent, fake)
	if self:hasMountPresent() then return true
	else
		if not silent then game.logPlayer(self, "You must have a mount present to do that!") end
		return false
	end
end

function preCheckHasMountInRange(self, t, silent, fake, range)
	local mount = self:hasMount()
	assert(range, "no range sent to preCheckHasMountInRange")
	assert(type(range)=="number", "range sent to preCheckHasMountInRange is not a number")
	if mount and core.fov.distance(self.x, self.y, mount.x, mount.y) <= range then return true
	else
		if not silent then game.logPlayer(self, "You must have a mount within range %d to do that!", range) end
		return false
	end
end

--From Disengage. Credit due where credit's due.
function preCheckCanMove(self, t, silent, fake)
	if self:attr("never_move") or self:attr("encased_in_ice") then
		if not silent then game.logPlayer(self, "You must be able to move to use %s!", t.name) end
		return false
	else return true end
end

function preCheckMountCanMove(self, t, silent, fake)
	local mount = self:hasMount()
	local mover = self:isMounted() and self or mount
	if not mount then
		if not silent then game.logPlayer(self, "You need a mount in order to use %s!", t.name) end
		return false
	elseif mover:attr("never_move") or mover:attr("encased_in_ice") then
		if not silent then game.logPlayer(self, "Your mount must be able to move to use %s!", t.name) end
		return false
	end
	return true
end

function preCheckArcheryInAnySlot(self, t, silent, fake)
	if not self:hasArcheryWeapon("bow") and not self:hasArcheryWeaponQS("bow") then
		if not silent then 
			game.logPlayer(self, "You require a bow in one of your weapon slots for this talent.")
		end
		return false
	end
	return true
end

function preCheckMeleeInAnySlot(self, t, silent, fake)
	if not hasMeleeInAnySlot(self) then
		if not silent then 
			game.logPlayer(self, "You require a melee weapon in one of your weapon slots for this talent.")
		end
		return false
	end
	return true
end

function preCheckOutriderWeaponBothSlots(self, t, silent, fake)
	if not hasOutriderWeapon(self) and not hasOutriderWeaponQS(self) then
		if not silent then 
			game.logPlayer(self, "You must have an outrider weapon equipped in one of your weapon slots to use this talent.")
			return false
		end
	end
	return true
end