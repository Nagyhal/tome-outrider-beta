local _M = loadPrevious(...)

local Map = require "engine.Map"

local base_bumpInto = _M.bumpInto
local base_combatMovementSpeed = _M.combatMovementSpeed
local base_combatPhysicalPower = _M.combatPhysicalpower
local base_hasTwoHandedWeapon = _M.hasTwoHandedWeapon

-- function _M:bumpInto(target, x, y)
-- 	if self:hasEffect(self.EFF_LIVING_SHIELDED) and target==self.tmp[self.EFF_LIVING_SHIELDED].trgt then
-- 		local dx, dy = util.dirToCoord(util.getDir(target.x, target.y, self.x, self.y))
-- 		game.logPlayer(game.player, "move enemy from "..x..", "..y.." to "..x+dx..", "..y+dy)
-- 		local blocks = game.level.map:checkAllEntitiesLayersNoStop(x+dx, y+dy, "block_move", target)
-- 			for kind, v in pairs(blocks) do if kind[1] and v then return end end
-- 		local blocks = game.level.map:checkAllEntitiesLayersNoStop(x, y, "block_move", self)
-- 			for kind, v in pairs(blocks) do if kind[1] ~= Map.ACTOR and v then return end end
-- 		target:move(x+dx, y+dy, true)
-- 		self:move(x, y, true)
-- 		self:useEnergy(game.energy_to_act * self:combatMovementSpeed(x, y))
-- 		self.did_energy = true
-- 		return
-- 	end
-- 	base_bumpInto(self, target, x, y)
-- end

-- function _M:bumpInto(target, x, y)
-- 	if self:hasEffect(self.EFF_LIVING_SHIELDED) and target==self.tmp[self.EFF_LIVING_SHIELDED].trgt then
-- 		local tg = self.tmp[self.EFF_LIVING_SHIELDED].trgt
-- 		if not self.reaction_actor then self.reaction_actor = {} end
-- 		if not self.reaction_actor[tg] then self.reaction_actor[tg.name] = 0 end
-- 		self.reaction_actor[tg] = self.reaction_actor[tg.name] + 200
-- 		base_bumpInto(self, target, x, y)
-- 		self.reaction_actor[tg] = self.reaction_actor[tg.name] - 200
-- 		return
-- 	end
-- 	base_bumpInto(self, target, x, y)
-- end

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

function _M:hasTwoHandedWeapon()
	if self:knowTalent(self.T_ORCHESTRATOR_OF_DISMAY) then
		local weaponry = self:getInven("MAINHAND") or {}
		return weaponry[1]
	end
	return base_hasTwoHandedWeapon(self)
end

function _M:combatPhysicalpower(mod, weapon, add)
	--TODO: Replace this with getOwner or somesuch
	local summoner = self.summoner
	if summoner and summoner.outrider_pet and summoner.outrider_pet == self then
		if summoner:knowTalent(summoner.T_CHALLENGE_THE_WILDS) then
			if not add then add=0 end
			add = add + summoner:callTalent(summoner.T_CHALLENGE_THE_WILDS, "getDam")
		end
	end
	return base_combatPhysicalPower(self, mod, weapon, add)
end

local base_attackTargetWith = _M.attackTargetWith
function _M:attackTargetWith(target, weapon, damtype, mult, force_dam)
	local eff = target:hasEffect(target.EFF_LIVING_SHIELDED)
	if eff and not self.living_shield_bypass then
		if rng.percent(eff.chance) and self~=eff.trgt then
			target:logCombat(eff.trgt, "#Target# becomes the target of %s's attack!", self.name)
			target = eff.trgt
		end
	end
	self.living_shield_bypass=nil
	return base_attackTargetWith(self, target, weapon, damtype, mult, force_dam)
end

local base_attackTarget = _M.attackTarget
function _M:attackTarget(target, damtype, mult, noenergy, force_unharmed)
	local eff = target:hasEffect(target.EFF_LIVING_SHIELDED)
	if eff then
		self.living_shield_bypass=true
		if rng.percent(eff.chance) and self~=eff.trgt then
			target:logCombat(eff.trgt, "#Target# becomes the target of %s's attack!", self.name)
			target = eff.trgt
		end
	end
	local ret = {base_attackTarget(self, target, damtype, mult, noenergy, force_unharmed)}
	self.living_shield_bypass=nil
	return unpack(ret)
end

return _M