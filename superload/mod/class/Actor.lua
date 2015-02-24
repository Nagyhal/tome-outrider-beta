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
	t.loyalty_regen = t.loyalty_regen or 1
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
		local m = self:hasMount()
		if rng.percent(m.mount_data.share_damage) then
			m:takeHit(value, src)
			game.logSeen(self, "%s takes %d damage in %s's stead!", m.name:capitalize(), value, self.name)
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
		target._fake_level_entity = function(level, keyword)
			if keyword=="has" then
				return level:hasEntity(self.rider)
			end
		end
		self:move(old_x, old_y, force)
		self:setEffect(self.EFF_MOUNT, 100, {mount=target})
		target:setEffect(self.EFF_RIDDEN, 100, {rider=self})
		game.logSeen(self, "%s mounts %s!", self.name:capitalize(), target.name:capitalize())
		return true
	else return false end
end

--Should be just a _M:dismount
function _M:dismountTarget(target, x, y)
	if not self:isMounted() then game.logPlayer(self, "You're not mounted!") return false end
	if target ~= self.mount then game.logPlayer(self, "That is not your mount!") return false end
	if not target.dead and (not x or not y) or (x==target.x and y==target.y) then
		x, y = util.findFreeGrid(self.x, self.y, 10, true, {[engine.Map.ACTOR]=true})
	end
	if x then
		game.level:addEntity(target)
		target._fake_level_entity = nil
		-- game.zone:addEntity(game.level, target, "actor", target.x, target.y)
		local ox, oy = self.x, self.y
		local ok = self:move(x, y, true)
		game.level:addEntity(self)
		-- game.zone:addEntity(game.level, self, "actor", self.x, self.y)
		if not ok then return end

		game.logSeen(self, "%s dismounts from %s", self.name:capitalize(), target.name:capitalize())
		--game.level:addEntity(target)
		target.rider= nil
		self.mount = nil
		self:removeEffect(self.EFF_MOUNT, false, true)
		target:removeEffect(self.EFF_RIDDEN, false, true)
		target:added()
		target:move(ox, oy, true)
		target.changed = true
		self.changed = true
		return true
	else return nil end
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

function _M:moveDragged(x, y, force)
	if self.x and self.y then
		local dx, dy = x-self.x, y-self.y
		local sequence = {}
		for e, _ in pairs(self.dragged_entities or {}) do
			local blocking = game.level.map:checkAllEntitiesLayersNoStop(e.x+dx, e.y+dy, "block_move", e)
			for t, v in pairs(blocking) do
				local ee =t[2]
				if not self.dragged_entities[ee] and ee~=self then return false end
			end
			local order = 0
			if dy~=0 then order=order+(e.y-self.y)*dy end
			if dx~=0 then order=order+(e.x-self.x)*dx end
			sequence[#sequence+1] = {e, order}
		end
		table.sort(sequence, function(a, b) return a[2]<b[2] end)
		for _, t in ipairs(sequence) do
			local e = t[1]
			e:move(e.x+dx, e.y+dy, true)
		end
	end

	return true
end

function _M:move(x, y, force)
	--Currently, if you push a dragged enemy into a wall then you can't bump-attack it even when it obviously can no longer be dragged. You'll just have to select the "attack" command instead.
	--TODO: Improve this
	if not self:moveDragged(x, y, force) then return false end

	local energy, mount = self.energy.value, (self:isMounted() and self.mount)
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

local base_projected = _M.projected
function  _M:projected(tx, ty, who, t, x, y, damtype, dam, particles)
	local grids = self.impunity_avoid_grids
	local ret = false
	if grids and not self.impunity_no_recur and rng.percent(self:callTalent(self.T_IMPUNITY_OF_WARLORDS, "getChance")) then
		self.impunity_no_recur = true
		local actors_list = {}
		local t =self:getTalentFromId(self.T_IMPUNITY_OF_WARLORDS)
		local tg = {type="ball", radius=self:getTalentRange(t), talent=t}
		self:project(tg, self.x, self.y, function(px, py)
			--Don't switch with enemies in the danger grids
			if grids[px] and grids[px][py] then return end
			local a = game.level.map(px, py, Map.ACTOR)
			if a and a ~= self and self:reactionToward(a) < 0 and not (a:attr("never_move") or self:attr("never_move")) and a:canBe("knockback") then actors_list[#actors_list+1] = a; end
		end)
		self.impunity_no_recur = false
		local a = rng.tableRemove(actors_list)
		if a then 
			game.level.map:remove(a.x, a.y, engine.Map.ACTOR)
			local ox, oy = self.x, self.y
			self:move(a.x, a.y, true)
			a:move(ox, oy, true)
			self:forceUseTalent(t.id, {ignore_energy=true})
			ret=true
		end
	end
	self.impunity_avoid_grids = nil
	--Handle Vestigial Magicks
	local cur_t = who.__talent_running
	local true_dam = (type(dam)=="table" and dam.dam) or (type(dam)=="number" and dam or 0)
	if cur_t and true_dam>0 and self:hasEffect(self.EFF_VESTIGIAL_MAGICKS) then
		if not self.turn_procs.vestigial_magicks_targets then
			self.turn_procs.vestigial_magicks_targets = {}
		end
		local uids = self.turn_procs.vestigial_magicks_targets 
		uids[target.uid] = uids[target.uid] or {}
		if not uids[target.uid][cur] then
			self:callTalent(self.T_VESTIGIAL_MAGICKS, "doDamage", src)
		end
	end
	return base_projected(self, tx, ty, who, t, x, y, damtype, dam, particles) or ret
end

local base_on_project_acquire = _M.on_project_acquire
function _M:on_project_acquire(tx, ty, who, t, x, y, damtype, dam, particles, is_projectile, mods)
	--Living Shield
	local eff = self:hasEffect(self.EFF_LIVING_SHIELDED); if eff and is_projectile and rng.percent(eff.chance) then 
		eff.trgt:logCombat(who, "#Source# becomes the target of #target#'s' projectile!")
		mods.x = eff.trgt.x-self.x
		mods.y = eff.trgt.x-self.x
	end

	--Handle Impunity of Warlords
	if type(dam)=="table" then dam = dam.dam end
	if self:isTalentActive(self.T_IMPUNITY_OF_WARLORDS) and not self.impunity_no_recur1 and self:reactionToward(who)<0 and dam and dam>0 then 
		self.impunity_no_recur_pre = true
		self.impunity_avoid_grids = who:project(t, x, y, function() end)
		self.impunity_no_recur_pre = false
	end
	return base_on_project_acquire(self, tx, ty, who, t, x, y, damtype, dam, particles, is_projectile, mods)
end

local base_knockback = _M.knockback
function _M:knockback(srcx, srcy, dist, recursive, on_terrain)
	local ox, oy = self.x, self.y
	base_knockback(self, srcx, srcy, dist, recursive, on_terrain)
	if self:isMounted() and self.x~=ox or self.y~=oy then
		if rng.percent(25) then
			local mount = self:hasMount()	
			self:dismountTarget(mount)
		end
	end
end

function _M:disobedienceChance()
	local src = self.outrider_pet
	if not src then return 0 end
	local factor = math.pow(1 - util.bound(self.loyalty/50, 0, 1), 2)
	local chance = factor*10
	return chance, chance -- return this twice so we're compatable with older UIs
end

-- Check if our mount (perhaps used also for other types of ally?) rebels against the owner.
-- Paradox has an "Anomaly Type", used to force an anomaly type for the talent, generally set to ab.anomaly_type. Perhaps Loyalty could do that?
function _M:loyaltyCheck(pet, silent)
	local forced = false
	local chance = self:disobedienceChance()
	if chance == "forced" then
		forced = true
	end

	-- See if we create an anomaly
	if not forced and self.turn_procs.loyalty_checked then return false end  -- This is so players can't chain cancel out of targeting to trigger anomalies on purpose, we clear it out in postUse
	-- if not forced then self.turn_procs.loyalty_checked = true end
	-- return true if we roll an anomly
	if rng.percent(chance) then
		local disobedience_type = "minor"
		if self:getLoyalty() < self.max_loyalty*.25 then
			disobedience_type = "major"
		end

		-- Now pick anomalies filtered by type
		local ts = {}
		for id, t in pairs(pet.talents_def) do
			if disobedience_type == "major" and t.disobedience_type and t.disobedience_type == "major" then
				if t.type[1] == "mounted/disobedience" and not pet:isTalentCoolingDown(t) then ts[#ts+1] = id end
			else
				if t.type[1] == "mounted/disobedience" and not pet:isTalentCoolingDown(t) then ts[#ts+1] = id end
			end
		end

		-- Did we find disobedience options?
		if ts[1] then
			-- Do we have a target?  If not we pass to anomaly targeting
			-- The ignore energy calls here allow anomalies to be cast even when it's not the players turn
			if target then
				pet:attr("anomaly_forced_target", 1)
				pet:forceUseTalent(rng.table(ts), {ignore_energy=true, force_target=target})
				pet:attr("anomaly_forced_target", -1)
			else
				pet:forceUseTalent(rng.table(ts), {ignore_energy=true})
			end
		end
		return true
	end
end

return _M