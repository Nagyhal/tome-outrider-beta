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

function hasFreeOffhand(self)
	local mainhand = table.get(self:getInven("MAINHAND"), 1)
	if mainhand and mainhand.twohanded or mainhand.slot_forbid=="OFFHAND" then return nil end
	if not table.get(self:getInven("OFFHAND"), 1) then return true else return nil end
end

function hasMeleeWeapon(self)
	if self:attr("disarmed") then return nil end
	
	local mh = self:hasMHWeapon()
	local oh = self:hasOffWeaponType()
	for _, weapon in ipairs{mh, oh} do
		if weapon and weapon.combat and not weapon.archery_kind then return true else return false end
	end
end

function mustSwapForMeleeWeapon(self)
	if self:attr("disarmed") then return nil end

	--If we have a melee weapon in the main set, FALSE, don't need to switch.
	if hasMeleeWeapon(self) then return false end

	--Now check the QS slots.
	local qs_mh = table.get(self:getInven("QS_MAINHAND"), 1)
	local qs_oh = table.get(self:getInven("QS_OFFHAND"), 1)
	for _, weapon in ipairs{qs_mh, qs_oh} do
		--So maybe we want to switch to the QS set, but only if we have a melee weapon.
		if weapon and weapon.combat and not weapon.archery_kind then return true end
	end
end		--Nil result if we just don't have a melee weapon.

function mustSwapForArcheryWeapon(self)
	if self:attr("disarmed") then return nil end

	if self:hasArcheryWeapon() then return false
	elseif self:hasArcheryWeaponQS() then return true end
end

function hasMeleeInAnySlot(self)
	if hasMeleeWeapon(self) or mustSwapForMeleeWeapon(self) then return true else return false end
end

-- Swaps weapons if needed
--------------------------
-- Maybe we need to swap to our melee weapon to do some stuff, then swap back
-- to our archery weapon afterward?
-- By returning the second value as true, we can record whether we want to swap back.
-- @return has_archery_weapon True if we have an archery weapon.
-- @return did_swap True if we had to swap.
function swapToMelee(self)
	if hasMeleeWeapon(self) then return true, false

	elseif mustSwapForMeleeWeapon(self) then
		self:quickSwitchWeapons(true, nil, true)
		--If we succeeded to swap, return true
		if not mustSwapForMeleeWeapon(self) then
			return true, true
		end
	else return false, false end
end

-- @return has_archery_weapon True if we have an archery weapon.
-- @return did_swap True if we had to swap.
function swapToArchery(self)
	if self:hasArcheryWeapon() then return true, false

	elseif self:hasArcheryWeaponQS() then
		self:quickSwitchWeapons(true, nil, true)
		--If we succeeded to swap, return true
		if not mustSwapForArcheryWeapon(self) then
			return true, true
		end
	else return false, false end
end

function isOutriderWeapon(weapon)
	if weapon.archery then return true
	elseif weapon.slot_forbid~="OFFHAND" then return true
	elseif weapon.subtype=="trident" then return true
	elseif weapon.subtype=="lance" then return true
	else return false end
end

function hasOutriderWeapon(self)
	local weapon = table.get(self:getInven("MAINHAND"), 1)
	if weapon and isOutriderWeapon(weapon) then return true
	else return false end
end

function hasOutriderWeaponQS(self)
	local weapon = table.get(self:getInven("QS_MAINHAND"), 1)
	if weapon and isOutriderWeapon(weapon) then return true
	else return false end
end

function getArcheryTargetsWithSwap(self)
	local _, done_swap = swapToArchery(self)
	if not self:hasArcheryWeapon() then
		game.logPlayer(self, "You can't swap to your ranged weapon to use this talent!")
		return nil
	end

	local targets = self:archeryAcquireTargets(nil, {one_shot=true})
	if not targets then
		if done_swap then self:quickSwitchWeapons(true, nil, true) end
		return nil
	end
	return targets
end