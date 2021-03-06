local _M = loadPrevious(...)

local Map = require "engine.Map"
local talents_env = require "engine.interface.ActorTalents".main_env

local base_bumpInto = _M.bumpInto
local base_combatMovementSpeed = _M.combatMovementSpeed
local base_combatPhysicalpower = _M.combatPhysicalpower
local base_hasTwoHandedWeapon = _M.hasTwoHandedWeapon

function _M:combatMovementSpeed(x, y)
	local mount = self.mount
	if mount then
		local mount_move, self_move = base_combatMovementSpeed(mount, x, y),  base_combatMovementSpeed(self, x, y)
		local add_bonuses = 1 + mount_move-1 + self_move-1
		local max_penalty = math.min(mount_move, self_move)
		local used = add_bonuses>1 and add_bonuses or max_penalty
		return used / mount.global_speed
	else return base_combatMovementSpeed(self, x, y)
	end
end

-- function _M:hasTwoHandedWeapon()
-- 	if self:knowTalent(self.T_OUTRIDER_ORCHESTRATOR_OF_DISMAY) then
-- 		local weaponry = self:getInven("MAINHAND") or {}
-- 		return weaponry[1]
-- 	end
-- 	return base_hasTwoHandedWeapon(self)
-- end

function _M:combatPhysicalpower(mod, weapon, add)
	--TODO: Replace this with getOwner or somesuch
	local summoner = self.summoner
	if summoner and summoner.outrider_pet and summoner.outrider_pet == self then
		if summoner:knowTalent(summoner.T_OUTRIDER_CHALLENGE_THE_WILDS) then
			if not add then add=0 end
			add = add + summoner:callTalent(summoner.T_OUTRIDER_CHALLENGE_THE_WILDS, "getDam")
		end
	end
	return base_combatPhysicalpower(self, mod, weapon, add)
end

local base_attackTargetWith = _M.attackTargetWith
function _M:attackTargetWith(target, weapon, damtype, mult, force_dam)
	local eff = target:hasEffect(target.EFF_OUTRIDER_LIVING_SHIELDED)
	if eff and not self.living_shield_bypass then
		if rng.percent(eff.chance) and self~=eff.trgt then
			target:logCombat(eff.trgt, "#Target# becomes the target of %s's attack!", self.name)
			target = eff.trgt
		end
	end
	self.living_shield_bypass=nil
	return base_attackTargetWith(self, target, weapon, damtype, mult, force_dam)
end

local base_physicalCrit = _M.physicalCrit
function _M:physicalCrit(dam, weapon, target, atk, def, add_chance, crit_power_add)
	crit_power_add = crit_power_add or 0
	add_chance = add_chance or 0

	--Flanking
	if target then
		local eff = target:hasEffect(target.EFF_OUTRIDER_FLANKED)
		if eff and table.keys(eff.alies)[self] then
			crit_power_add = crit_power_add + eff.crit_dam
		end
	end

	--Master of Brutality
	if self:attr"outrider_master_of_brutality" then
		if target:effectsFilter({type="mental", status="detrimental"}) then
			add_chance = add_chance + self.outrider_master_of_brutality
		end
	end

	--Spring attack
	local eff = self:hasEffect(self.EFF_OUTRIDER_SPRING_ATTACK)
	if eff then
		-- Do a melee finishing manoeuvre
		if talents_env.hasMeleeWeapon(self) then
			add_chance = add_chance + eff.current_crit*2
			game.logPlayer(self,
				"#FIREBRICK#%s executes a melee Spring Attack!#NORMAL#",
				self.name:capitalize()
			)
			self:removeEffect(self.EFF_OUTRIDER_SPRING_ATTACK)
		-- Or otherwise, do a regular buffed ranged attack
		else
			add_chance = add_chance + eff.current_crit
		end
	end

	return base_physicalCrit(self, dam, weapon, target, atk, def, add_chance, crit_power_add)
end

local base_attackTarget = _M.attackTarget
function _M:attackTarget(target, damtype, mult, noenergy, force_unharmed)
	local eff = target:hasEffect(target.EFF_OUTRIDER_LIVING_SHIELDED)
	if eff then
		self.living_shield_bypass=true
		if rng.percent(eff.chance) and self~=eff.trgt then
			target:logCombat(eff.target, "#Target# becomes the target of %s's attack!", self.name)
			target = eff.target
		end
	end
	local ret = {base_attackTarget(self, target, damtype, mult, noenergy, force_unharmed)}
	self.living_shield_bypass=nil
	return unpack(ret)
end

return _M