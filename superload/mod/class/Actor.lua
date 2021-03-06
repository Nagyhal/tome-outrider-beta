local _M = loadPrevious(...)

local base_init = _M.init
function _M:init(t, no_default)
	t.mount = nil
	t.can_mount = t.can_mount or false
	t.mount_data = t.mount_data or {
		loyalty_mod = 0,
		loyalty_loss_coeff = 1 and t.can_mount or 0,
		loyalty_regen_coeff = 1 and t.can_mount or 0,
		share_damage = 50 and t.can_mount or 0
	}
	t.loyalty_regen = t.loyalty_regen or .5
	base_init(self, t, no_default)
end

local base_onTakeHit = _M.onTakeHit
function _M:onTakeHit(value, src)
	--The mount has a chance to take damage in its rider's stead
	if self:isMounted() then
		local has_taunt = src:hasEffect(src.EFF_OUTRIDER_TAUNT) --Rider can tank using taunts
		local m = self:hasMount()
		if rng.percent(m.mount_data.share_damage) then
			if has_taunt and has_taunt.src==self then
				game.logSeen(self, "%s taunts the damage away from %s!", self.name:capitalize(), m.name:capitalize())
			else
				-- Mount takes the hit for the rider
				m:takeHit(value, src)
				-- But, instead of logging the damage straight away, we record it in a table
				if m.turn_procs.temp_mount_damage then
					m.turn_procs.temp_mount_damage[#m.turn_procs.temp_mount_damage+1] = value
				else
					m.turn_procs.temp_mount_damage = {value}
				end
				-- And log the values from the table at the end of the tick
				-- (though doing it per-turn might be too complex or confusing, we'll see)
				if not self.on_tick_end or not self.on_tick_end.names["do_temp_mount_damage_log"] then
					game:onTickEnd(function()
						-- Firstly let's the damage using standard C rounding style
						-- which, I *think*, is "round to nearest and ties to even".


						--Safety check
						if not m.turn_procs.temp_mount_damage or not next(m.turn_procs.temp_mount_damage) then
							return
						end

						-- We'll also tally total damage taken as we do that.
						local total = 0 

						local strings_list = table.mapv(
							function(v) total=total+v; return ("%d"):format(v) end,
							m.turn_procs.temp_mount_damage
						)
						local nice_string = table.concat(strings_list, ", ")

						--Don't forget to append a damage total!
						local total_str = ""
						if #strings_list > 1 then
							total_str = (" (#RED##{bold}#%d #{normal}##LAST#total damage)"):format(total)
						end

						game.logSeen(self, "%s takes %s damage in %s's stead"..total_str.."!", 
							m.name:capitalize(), nice_string, self.name)
						m.turn_procs.temp_mount_damage = nil
					end,
					-- This sets the name of the function
					-- We need this because we only want to call the onTickEnd function once.
					"do_temp_mount_damage_log"
					)
				end
				value = 0
			end
		end
	end
	return base_onTakeHit(self, value, src)
end

--New mount functions
function _M:isMounted()
	local mount = self:hasMount()
	if mount and self:hasEffect(self.EFF_OUTRIDER_MOUNT) then return true else return false end
end

function _M:isRidden()
	if self:hasEffect(self.EFF_OUTRIDER_RIDDEN) then return true else return false end
end

function _M:getRider()
	local p = self:hasEffect(self.EFF_OUTRIDER_RIDDEN)
	if p then return p.rider else return nil end
end

function _M:getMount()
	if self:isMounted() then return self.mount else return nil end
end

function _M:getOutriderPet()
	local pet = self.outrider_pet
	if pet and not pet.dead and (self:isMounted() or game.level:hasEntity(pet)) then return pet end
end

function _M:canMount(mount)
	if mount.can_mount and mount.summoner == self and not mount:hasEffect(mount.EFF_OUTRIDER_UNBRIDLED_FEROCITY) then
		return true
	else return false
	end
end

function _M:hasMount()
	--Truly simple placeholder function intended for Outrider use only
	--TODO: Make it accept any kind of mount
	local mount = self.outrider_pet
	if mount and not mount.dead and game.level then return (game.level:hasEntity(mount) or self.mount) end
end

function _M:hasMountPresent()
	local mount = self:hasMount(); if not mount then return false end
	if self:isMounted() or self:hasLOS(mount.x, mount.y, "block_sight", self.sight) then return true else return false end
end

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
		self:move(old_x, old_y, true)
		self:setEffect(self.EFF_OUTRIDER_MOUNT, 100, {mount=target})
		target:setEffect(self.EFF_OUTRIDER_RIDDEN, 100, {rider=self})
		game.logSeen(self, "%s mounts %s!", self.name:capitalize(), target.name:capitalize())
		self:fireTalentCheck("callbackOnMount")
		target:fireTalentCheck("callbackOnMounted")
		--Looks like our attempt was successful.
		--Now to switch the talent icon to Dismount.
		if self.hotkey and self.isHotkeyBound then
			local pos = self:isHotkeyBound("talent", self.T_OUTRIDER_MOUNT)
			if pos then
				self.hotkey[pos] = {"talent", self.T_OUTRIDER_DISMOUNT}
			end
		end

		if not self:knowTalent(self.T_OUTRIDER_DISMOUNT) then
			local ohk = self.hotkey
			self.hotkey = nil -- Prevent assigning hotkey, we just did
			self:learnTalent(self.T_OUTRIDER_DISMOUNT, true, 1, {no_unlearn=true})
			self.hotkey = ohk
		end
		return true
	else return false end
end

--Should be just a _M:dismount
function _M:dismount(x, y, silent, force)
	local mount = self:getMount()
	if not self:isMounted() or not mount then
		if not silent then game.logPlayer(self, "You're not mounted!") end
		return false
	end
	if not mount.dead and (not x or not y) or (x==mount.x and y==mount.y) then
		x, y = util.findFreeGrid(self.x, self.y, 10, true, {[engine.Map.ACTOR]=true})
	end
	if x then
		game.level:addEntity(mount)
		-- game.zone:addEntity(game.level, mount, "actor", mount.x, mount.y)
		local ox, oy = self.x, self.y
		local ok = self:move(x, y, true)
		self:removeEffect(self.EFF_OUTRIDER_MOUNT, false, true)
		mount:removeEffect(self.EFF_OUTRIDER_RIDDEN, false, true)
		if force==true then
			--Dismount for between 1-4 turns, based on your loyalty
			local mod = (1 - self.loyalty/self.max_loyalty) * 4
			local max_dur = mod>=1 and math.round(mod) or 0
			local dur = max_dur>0 and rng.range(1, max_dur) or 0

			local str = dur>0 and (" for %d turns"):format(dur) or ""
			game.logSeen(self, "#RED#%s is knocked from %s"..str.."!#LAST#", self.name:capitalize(), mount.name:capitalize())
			if dur>0 then
				self:startTalentCooldown(self.T_OUTRIDER_MOUNT, math.max(dur, self.talents_cd["T_OUTRIDER_MOUNT"] or 0))
			end
		else
			game.logSeen(self, "%s dismounts from %s", self.name:capitalize(), mount.name:capitalize())
		end
		game.level:addEntity(self)
		-- game.zone:addEntity(game.level, self, "actor", self.x, self.y)
		if not ok then return end

		--game.level:addEntity(mount)
		mount:added()
		mount:move(ox, oy, true)
		mount.changed = true
		self.changed = true
		self:fireTalentCheck("callbackOnDismount", mount)
		mount:fireTalentCheck("callbackOnDismounted", self)
		if self.hotkey and self.isHotkeyBound then
			local pos = self:isHotkeyBound("talent", self.T_OUTRIDER_DISMOUNT)
			if pos then
				self.hotkey[pos] = {"talent", self.T_OUTRIDER_MOUNT}
			end
		end
		return true
	else return nil end
end

--- Something of a legacy / shorthand method, may be changed at a later date
function _M:forceDismount()
	self:dismount(nil, nil, nil, true)
end

function _M:flyOver(x, y, dist)
	--This is a slightly modified Probability Travel
	if game.zone.wilderness then return true end
	if self:attr("encased_in_ice") then return end

	local dirx, diry = x - self.x, y - self.y
	local tx, ty = x, y
	local can = true
	while game.level.map:isBound(tx, ty) and game.level.map:checkAllEntities(tx, ty, "block_move", self) and dist > 0 do
		if game.level.map:checkEntity(tx, ty, engine.Map.TERRAIN, "block_move") then can=false break end
		tx = tx + dirx
		ty = ty + diry
		dist = dist - 1
	end
	if can and game.level.map:isBound(tx, ty) and not game.level.map:checkAllEntities(tx, ty, "block_move", self) then
		return engine.Actor.move(self, tx, ty, false)
	end
	return true
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
		local no_hotkey, ohk = not self:hasMount(), _
		if no_hotkey then ohk, self.hotkey = self.hotkey,nil end
		local done, err = pcall(self:checkPool(t.id, self.T_OUTRIDER_MOUNT))
		if no_hotkey then self.hotkey = ohk end
	end
	base_learnPool(self,t)
end

function _M:moveDragged(x, y, force)
	-- Make sure we have the dragged_entities table
	self.dragged_entities = self.dragged_entities or {}

	-- Check if the dragged_entities table is empty
	if next(self.dragged_entities) == nil then return true end

	-- Here, we get the entities we want to drag, but also the safe order, so 
	-- as to never move an actor into the space of another.
	if self.x and self.y then
		local dx, dy = x-self.x, y-self.y
		local sequence = {}

		for e, _ in pairs(table.merge({[self]=1}, self.dragged_entities)) do
			local blocking = game.level.map:checkAllEntitiesLayersNoStop(e.x+dx, e.y+dy, "block_move", e)
			for t, _ in pairs(blocking) do
				local ee = t[2]
				if not self.dragged_entities[ee] and ee~=self then 
					if e~=self then game.logPlayer(self, ("You can't take your dragged %s there!"):format(e.name)) end
					-- If we can't drag the target, but we're gonna use a talent like a teleport etc.,
					-- don't interrupt the teleport and just move without the dragged target.
					if core.fov.distance(self.x, self.y, x, y) > 1 then
						return true
					else
						return false
					end
				end
			end
			local order = 0
			if dy~=0 then order=order+(e.y-self.y)*dy end
			if dx~=0 then order=order+(e.x-self.x)*dx end
			sequence[#sequence+1] = {e, order}
		end
		table.sort(sequence, function(a, b) return a[2]<b[2] end)
		for _, t in ipairs(sequence) do
			local e = t[1]
			if e~=self then e:move(e.x+dx, e.y+dy, true) end
		end
	end

	return true
end

local base_move = _M.move
function _M:move(x, y, force)
	if not self:moveDragged(x, y, force) then
		if not force and game.level.map:checkAllEntities(x, y, "block_move", self, true) then
			return true
		else
			return false
		end
	end

	local energy, mount = self.energy.value, (self:isMounted() and self.mount)
	local ox, oy = self.x, self.y
	local ret = {base_move(self, x, y, force)}
	local new_x, new_y = self.x, self.y
	local energy_diff = energy - self.energy.value
	if mount and energy_diff>0 and (ox~=new_x or oy~=new_y) then
		-- Global speed multiplier depletes mount's and rider's energy at same rate
		-- @todo Consider removing rider's global speed from movespeed calculation altogether
		local factor = mount.global_speed
		mount:useEnergy(energy_diff*factor)
		--Quick hack while I work on multi-occupant tiles.
		mount:doFOV()
		--Let the mount get targets while riding.
		mount:runAI("target_mount")
	end
	return unpack(ret)
end

local base_projected = _M.projected

function  _M:projected(tx, ty, who, t, x, y, damtype, dam, particles)
	local grids = self.impunity_avoid_grids
	local ret = false
	if grids and not self.impunity_no_recur and rng.percent(self:callTalent(self.T_OUTRIDER_IMPUNITY_OF_WARLORDS, "getChance")) then
		self.impunity_no_recur = true
		local actors_list = {}
		local t =self:getTalentFromId(self.T_OUTRIDER_IMPUNITY_OF_WARLORDS)
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
	if cur_t and true_dam>0 and self:hasEffect(self.EFF_OUTRIDER_VESTIGIAL_MAGICKS) then
		if not self.turn_procs.vestigial_magicks_targets then
			self.turn_procs.vestigial_magicks_targets = {}
		end
		local uids = self.turn_procs.vestigial_magicks_targets
		uids[target.uid] = uids[target.uid] or {}
		if not uids[target.uid][cur] then
			self:callTalent(self.T_OUTRIDER_VESTIGIAL_MAGICKS, "doDamage", src)
		end
	end
	return base_projected(self, tx, ty, who, t, x, y, damtype, dam, particles) or ret
end

local base_on_project_acquire = _M.on_project_acquire
function _M:on_project_acquire(tx, ty, who, t, x, y, damtype, dam, particles, is_projectile, mods)
	--Living Shield
	local eff = self:hasEffect(self.EFF_OUTRIDER_LIVING_SHIELDED); if eff and is_projectile and rng.percent(eff.chance) then
		eff.trgt:logCombat(who, "#Source# becomes the target of #target#'s' projectile!")
		mods.x = eff.trgt.x-self.x
		mods.y = eff.trgt.x-self.x
	end

	--Handle Impunity of Warlords
	if type(dam)=="table" then dam = dam.dam end
	if self:isTalentActive(self.T_OUTRIDER_IMPUNITY_OF_WARLORDS) and not self.impunity_no_recur1 and self:reactionToward(who)<0 and dam and dam>0 then
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
			self:forceDismount()
		end
	end
end

function _M:removeTalentTemporaryValues(p)
	--I'm using pairs so that we really get everything in the __tmpval table.
	for _, val in pairs(p.__tmpvals) do
		self:removeTemporaryValue(val[1], val[2])
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

	-- See if we create an "anomaly"
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

--- Prevent the mount from teleporting away from the rider
local base_teleportRandom = _M.teleportRandom
function _M:teleportRandom(x, y, dist, min_dist)
	if self:isRidden() then return true end

	local ret = {base_teleportRandom(self, x, y, dist, min_dist)}
	return unpack(ret)
end

--- A ludicrous hack.
local base_quickSwitchWeapons = _M.quickSwitchWeapons
function _M:quickSwitchWeapons(free_swap, message, silent)
	if self:knowTalent(self.T_OUTRIDER_MASTER_OF_BRUTALITY) and message=="warden" then
		message = nil
	end

	local ret = {base_quickSwitchWeapons(self, free_swap, message, silent)}
	return unpack(ret)
end

--Useful debugging function, saved for later.
-- local base_callTalent = _M.callTalent
-- function _M:callTalent(tid, name, ...)
-- 	game.log (format("DEBUG: tid=%s, name=%s", tostring(tid), tostring(name)) )
-- 	return base_callTalent(self, tid, name, ...)
-- end

_M.sustainCallbackCheck.callbackOnMount = "talents_on_mount"
_M.sustainCallbackCheck.callbackOnDismount = "talents_on_dismount"
_M.sustainCallbackCheck.callbackOnMounted = "talents_on_mounted"
_M.sustainCallbackCheck.callbackOnDismounted = "talents_on_dismounted"

return _M