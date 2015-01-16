local _M = loadPrevious(...)

local base_move = _M.move
local base_init = _M.init
local base_onTakeHit = _M.onTakeHit

function _M:init(t, no_default)
	t.mount = nil
	t.can_mount = t.can_mount or false
	t.mount_data = t.mount_data or {
		base_loyalty = 100 and t.can_mount or 0,
		loyalty_loss_coeff = 1 and t.can_mount or 0,
		loyalty_regen_coeff = 1 and t.can_mount or 0,
		share_damage = 50 and t.can_mount or 0
	}
	base_init(self, t, no_default)
end


-- local base_learnTalent = _M:learnTalent

-- function _M:learnPool(t_id, force, nb)
-- 	base_learnTalent(t_id, force, nb)
-- 	if t.type[1]:find("^mounted/") and not self:knowTalent(self.T_MOUNT) then
-- 		self:learnTalent(self.T_MOUNT, true)
-- 	end
-- end


-- function _M:mountAct()
-- 	local m = self.mount
-- 	if not self.mount then return end
-- end

function _M:onTakeHit(value, src)
	if self:isMounted() then
		local m = self:getMount()
		if rng.percent(m.mount_data.share_damage) then
			m:takeHit(value, src)
			game.logSeen(self, "%s takes %d damage in %s's stead!", self.mount.name:capitalize(), value, self.name)
			value = 0
		end
	end
	return base_onTakeHit(self, value, src)
end

--New mount functions
function _M:isMounted()
	local mount = self:hasMount()
	if mount and self:hasEffect(self.EFF_MOUNT) then return true else return false end
end

function _M:getMount()
	if self:isMounted() then return self.mount else return nil end
end

function _M:canMount(mount)
	if mount.can_mount and mount.summoner == self and not mount:hasEffect(mount.EFF_UNBRIDLED_FEROCITY) then
		return true
	else return false
	end
end

function _M:hasMount()
	--Truly simple placeholder function intended for Outrider use only
	--TODO: Make it accept any kind of mount
	--TODO: Make hasEntity return true if the player is riding a (hidden) mount
	local mount = self.outrider_pet
	if mount and not mount.dead and (mount.x==self.x and mount.y==self.y or game.level:hasEntity(mount)) then return mount else return false end
	--OLD: return #self.mounts_owned>0 and true or nil
end

function _M:hasMountPresent()
	local mount = self:hasMount(); if not mount then return false end
	if self:isMounted() or self:hasLOS(mount.x, mount.y, "block_sight", self.sight) then return true else return false end
end

-- function _M:getOutriderPet()
-- 	return self.outrider_pet or nil
-- end


local Map = require "engine.Map"

function _M:getMountList()
	local mts = {}
	local grids = core.fov.circle_grids(self.x, self.y, 10, true)
	for x, yy in pairs(grids) do
		for y, _ in pairs(grids[x]) do
			local target = game.level.map(x, y, Map.ACTOR)
			if target and target:canMount(self) then
				mts[#mts+1] = target
			end
		end
	end
	return mts
end

function _M:mountTarget(target)
	if self:isMounted() then game.logPlayer(self, "You are already mounted!") return false end
	if self:canMount(target) then
		self.mount = target
		self.mount.rider = self
		local old_x, old_y = target.x, target.y  -- not sure this is necessary, test
		game.level:removeEntity(target)
		self:move(old_x, old_y, force)
		self:setEffect(self.EFF_MOUNT, 100, {mount=target})
		target:setEffect(self.EFF_RIDDEN, 100, {rider=self})
		game.logSeen(self, "%s mounts %s!", self.name:capitalize(), target.name:capitalize())
		return true
	else return false end
end

function _M:dismountTarget(target, x, y)
	if not self:isMounted() then game.logPlayer(self, "You're not mounted!") return false end
	if target ~= self.mount then game.logPlayer(self, "That is not your mount!") return false end
	if not target.dead and (not x or not y) or (x==target.x and y==target.y) then
		x, y = util.findFreeGrid(self.x, self.y, 10, true, {[engine.Map.ACTOR]=true})
	end
	if x then
		game.logSeen(self, "%s dismounts from %s", self.name:capitalize(), target.name:capitalize())
		--game.level:addEntity(target)
		target.rider= nil
		self.mount = nil
		self:removeEffect(self.EFF_MOUNT, false, true)
		target:removeEffect(self.EFF_RIDDEN, false, true)
		ox, oy = self.x, self.y
		self:move(x, y, true)
		game.zone:addEntity(game.level, target, "actor", target.x, target.y)
		target:added()
		target:move(ox, oy, true)
		target.changed = true
		self.changed = true
	else return false end
	
end

function _M:mountActBase()
	return self:actBase()
end

function _M:mountAct()
	local ret = self:act()
	if self.rider then game.level.map(self.rider.x, self.rider.y, engine.Map.ACTOR, self.rider) end
	return ret
end

local base_learnPool = _M.learnPool

function _M:learnPool(t)
	if t.loyalty or t.sustain_loyalty then
		self:checkPool(t.id, self.T_LOYALTY_POOL)
		self:checkPool(t.id, self.T_MOUNT)
		self:checkPool(t.id, self.T_DISMOUNT)
	end
	base_learnPool(self,t)
end

function _M:move(x, y, force)
	local energy, mount = self.energy.value, self.mount
	local ox, oy = self.x, self.y
	local ret = base_move(self, x, y, force)
	local new_x, new_y = self.x, self.y
	local energy_diff = energy - self.energy .value
	if mount and energy_diff>0 and (ox~=new_x or oy~=new_y) then
		--Global speed multiplier depletes mount's and rider's energy at same rate
		--TODO: Consider removing rider's global speed from movespeed calculation altogether
		local factor = mount.global_speed
		mount:useEnergy(energy_diff*factor)
		--Quick hack while I work on multi-occupant tiles.
		mount:doFOV()
		--Let the mount get targets and use instant-activate abilities, as if it had had a turn.
		mount:runAI("target_mount")
		mount:doAI()
	end
	return ret
end

-- function _M:learnPool(t)
-- 	local tt = self:getTalentTypeFrom(t.type[1])

-- --	if tt.mana_regen and self.mana_regen == 0 then self.mana_regen = 0.5 end

-- 	if t.type[1]:find("^spell/") and not self:knowTalent(self.T_MANA_POOL) and t.mana or t.sustain_mana then
-- 		self:learnTalent(self.T_MANA_POOL, true)
-- 		self.resource_pool_refs[self.T_MANA_POOL] = (self.resource_pool_refs[self.T_MANA_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^wild%-gift/") and not self:knowTalent(self.T_EQUILIBRIUM_POOL) and t.equilibrium or t.sustain_equilibrium then
-- 		self:learnTalent(self.T_EQUILIBRIUM_POOL, true)
-- 		self.resource_pool_refs[self.T_EQUILIBRIUM_POOL] = (self.resource_pool_refs[self.T_EQUILIBRIUM_POOL] or 0) + 1
-- 	end
-- 	if (t.type[1]:find("^technique/") or t.type[1]:find("^cunning/")) and not self:knowTalent(self.T_STAMINA_POOL) and t.stamina or t.sustain_stamina then
-- 		self:learnTalent(self.T_STAMINA_POOL, true)
-- 		self.resource_pool_refs[self.T_STAMINA_POOL] = (self.resource_pool_refs[self.T_STAMINA_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^corruption/") and not self:knowTalent(self.T_VIM_POOL) and t.vim or t.sustain_vim then
-- 		self:learnTalent(self.T_VIM_POOL, true)
-- 		self.resource_pool_refs[self.T_VIM_POOL] = (self.resource_pool_refs[self.T_VIM_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^celestial/") and (t.positive or t.sustain_positive) and not self:knowTalent(self.T_POSITIVE_POOL) then
-- 		self:learnTalent(self.T_POSITIVE_POOL, true)
-- 		self.resource_pool_refs[self.T_POSITIVE_POOL] = (self.resource_pool_refs[self.T_POSITIVE_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^celestial/") and (t.negative or t.sustain_negative) and not self:knowTalent(self.T_NEGATIVE_POOL) then
-- 		self:learnTalent(self.T_NEGATIVE_POOL, true)
-- 		self.resource_pool_refs[self.T_NEGATIVE_POOL] = (self.resource_pool_refs[self.T_NEGATIVE_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^cursed/") and not self:knowTalent(self.T_HATE_POOL) and t.hate then
-- 		self:learnTalent(self.T_HATE_POOL, true)
-- 		self.resource_pool_refs[self.T_HATE_POOL] = (self.resource_pool_refs[self.T_HATE_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^chronomancy/") and not self:knowTalent(self.T_PARADOX_POOL) then
-- 		self:learnTalent(self.T_PARADOX_POOL, true)
-- 		self.resource_pool_refs[self.T_PARADOX_POOL] = (self.resource_pool_refs[self.T_PARADOX_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^psionic/") and not (t.type[1]:find("^psionic/feedback") or t.type[1]:find("^psionic/discharge")) and not self:knowTalent(self.T_PSI_POOL) then
-- 		self:learnTalent(self.T_PSI_POOL, true)
-- 		self.resource_pool_refs[self.T_PSI_POOL] = (self.resource_pool_refs[self.T_PSI_POOL] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^psionic/feedback") or t.type[1]:find("^psionic/discharge") and not self:knowTalent(self.T_FEEDBACK_POOL) then
-- 		self:learnTalent(self.T_FEEDBACK_POOL, true)
-- 	end
-- 	-- If we learn an archery talent, also learn to shoot
-- 	if t.type[1]:find("^technique/archery") and not self:knowTalent(self.T_SHOOT) then
-- 		self:learnTalent(self.T_SHOOT, true)
-- 		self.resource_pool_refs[self.T_SHOOT] = (self.resource_pool_refs[self.T_SHOOT] or 0) + 1
-- 	end
-- 	if t.type[1]:find("^technique/archery") and not self:knowTalent(self.T_RELOAD) then
-- 		self:learnTalent(self.T_RELOAD, true)
-- 		self.resource_pool_refs[self.T_RELOAD] = (self.resource_pool_refs[self.T_RELOAD] or 0) + 1
-- 	end

-- 	-- If we learn mounted combat talents, learn Mount and Dismount
-- 	if t.type[1]:find("^mounted/") and not self:knowTalent(self.T_MOUNT) then
-- 		self:learnTalent(self.T_MOUNT, true)
-- 		self.resource_pool_refs[self.T_MOUNT] = (self.resource_pool_refs[self.T_MOUNT] or 0) + 1
-- 	end

-- 	if t.type[1]:find("^mounted/") and not self:knowTalent(self.T_DISMOUNT) then
-- 		self:learnTalent(self.T_DISMOUNT, true)
-- 		self.resource_pool_refs[self.T_DISMOUNT] = (self.resource_pool_refs[self.T_DISMOUNT] or 0) + 1
-- 	end

-- 	if t.type[1]:find("^mounted/") and not self:knowTalent(self.T_LOYALTY_POOL) then
-- 		self:learnTalent(self.T_LOYALTY_POOL, true)
-- 		self.resource_pool_refs[self.T_LOYALTY_POOL] = (self.resource_pool_refs[self.T_LOYALTY_POOL] or 0) + 1
-- 	end


-- 	self:recomputeRegenResources()

-- 	return true
-- end

return _M