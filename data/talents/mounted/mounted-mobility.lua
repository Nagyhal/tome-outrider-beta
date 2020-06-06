-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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

--Return values for block_path:
--b (block), h (hit) and hr (hit radius)
local block_path = function(typ, lx, ly, for_highlights)
	--Check that we aren't going out of the game map.
	if not game.level.map:isBound(lx, ly) then return true, false, false end
	--Unrestricted movement--blocked by nothing!
	if typ.no_restrict then return false, true, true end
	--Check we're within range
	if typ.range then 
		local start_x = typ.start_x or (typ.source_actor and typ.source_actor.x)
		local start_y = typ.start_y or (typ.source_actor and typ.source_actor.y)
		if core.fov.distance(start_x, start_y, lx, ly) > typ.range then return true, false, false end
	end
	--In the case we can't move into an unseen square, stop here.	
	local is_known = game.level.map.remembers(lx, ly) or game.level.map.seens(lx, ly)
	if typ.requires_knowledge and not is_known then
		return true, false, false
	end
	--Check blocking terrain, which if unknown is highlighted yellow.
	if game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, "block_move") then
		if for_highlights then
			if not is_known then return true, "unknown", true end --Unknown grids = yellow highlight
		end
		return true, false, true
	else
		if for_highlights and not is_known then
			return false, "unknown", true
		end
	end
	--No problems? Good to go!
	return false, true, true
end

newTalent{
	name = "Run Them Down!", short_name = "OUTRIDER_RUN_THEM_DOWN", image = "talents/run_them_down.png",
	type = {"mounted/mounted-mobility", 1},
	require = mnt_strdex_req1,
	points = 5,
	loyalty = 15,
	cooldown = 15,
	requires_target = true,
	target = function(self, t)
		return {
			type="beam",
			range=self:getTalentRange(t),
			friendlyfire=false, nolock=true, talent=t,
			block_path=block_path
		}
	end,
	range = function(self, t) return math.floor(self:getTalentLevel(t) + 2) end,
	tactical = { ATTACK = { weapon = 2 }, CLOSEIN = 3 },
	on_pre_use = function(self, t, silent, fake)
		return preCheckIsMounted(self, t, silent, fake) and
		preCheckMountCanMove(self, t, silent, fake)
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty or game.level.map(tx, ty, engine.Map.ACTOR) then return nil end
		if core.fov.distance(self.x, self.y, tx, ty) > self:getTalentRange(t) then return nil end

		--This code gets targets for our bonus melee attack (after talent level 3!)
		local nearby_targets, checked_grids = {}, {}
		local function populateNearbyTargets(ox, oy)
			for _, coord in pairs(util.adjacentCoords(ox, oy)) do
				local x, y = coord[1], coord[2]
				if game.level.map:isBound(x, y) then
					if checked_grids[x] and not checked_grids[x][y] then
						local a = game.level.map(x, y, Map.ACTOR)
						if a and self:reactionToward(a)<0 then nearby_targets[#nearby_targets+1] = a end
					end
					if not checked_grids[x] then checked_grids[x] = {} end
					checked_grids[x][y] = true
				end
			end
		end

		local do_weapon_attack = self:getTalentLevel(t) >= 3 and true or false

		local mount_targets = targetTramplesTo(self, tx, ty, (do_weapon_attack and populateNearbyTargets or nil))

		--Do the mount attack
		for _, target in ipairs(mount_targets) do
			self.mount:attackTarget(target, nil, t.getDam(self, t), true)
		end

		--After talent level 3, do the bonus weapon attack!
		if do_weapon_attack then
			local qs_done = false
			if mustSwapForMeleeWeapon(self) then
				self:quickSwitchWeapons(true, nil, true)
				local qs_done = true
			end

			local i = t.getExtraStrikes(self, t)
			while i>0 and #nearby_targets>0 do
				local target = rng.tableRemove(nearby_targets)
				self:attackTarget(target, nil, t.getExtraDam(self, t), true)
			end

			if qs_done then self:quickSwitchWeapons(true, nil, true) end
		end
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam_pct = t.getDam(self, t)*100
		local extra_strikes = t.getExtraStrikes(self, t)
		local extra_dam_pct = t.getExtraDam(self, t)*100
		local str = extra_strikes > 1 and "enemies" or "enemy"
		return ([[Riding your mount, you charge to a vacant point up to %d squares away, trampling over enemies brutally as you do so, your mount dealing %d%% damage to all who those who dare obstruct you.

			At talent level 3, your mastery of the deadly application of momentum grants you a chance to strike at up to %d %s adjacent to your original path for %d%% weapon damage, if you have a suitable melee weapon. You will automatically use your secondary weapon for this if you have it swapped out.]]
		):format(range, dam_pct, extra_strikes, str, extra_dam_pct) end,
		getDam = function(self, t) return self:combatTalentScale(t, 1.5, 2.25) end,
		getExtraStrikes = function(self, t)
			local mod = self:getTalentTypeMastery(t.type[1])
			local tl = math.max(self:getTalentLevel(t), 3*mod) - 2*mod --Start from TL 3
			return math.floor(self:combatTalentScale(tl, 1.5, 3)) end, 
		getExtraDam = function(self, t)
			local mod = self:getTalentTypeMastery(t.type[1])
			local tl = math.max(self:getTalentLevel(t), 3*mod) - 2*mod --Start from TL 3
			return self:combatTalentScale(tl, 1.4, 1.75) end,
}

newTalent{
	name = "Goad", short_name = "OUTRIDER_GOAD", image = "talents/goad.png",
	type = {"mounted/mounted-mobility", 2},
	points = 5,
	cooldown = function (self, t) return math.floor(20-2*self:getTalentLevel(t)) end,
	loyalty = 25,
	no_energy = true,
	require = mnt_strdex_req2,
	tactical = { BUFF = 2, CLOSEIN = 2, ESCAPE = 2 },
	on_pre_use = function(self, t, silent, fake)
		return preCheckHasMountInRange(self, t, silent, fake, 1)
	end,
	action = function(self, t)
		local mount = self:hasMount()
		mount:setEffect(self.EFF_SPEED, 5, {power=t.getGoadSpeed(self, t)})
		return true
	end,
	info = function(self, t)
		local global_speed_pct = t.getGlobalSpeed(self, t)*100
		return ([[For 5 turns, your mount's global speed is increased by %d%%. You may be riding or adjacent to your mount to activate this effect.]]):format(global_speed_pct)
	end,
	getGlobalSpeed = function (self, t) return self:combatTalentScale(t, 0.2, 0.65, 0.85) end,
}

newTalent{
	name = "Savage Bound", short_name = "OUTRIDER_SAVAGE_BOUND", image = "talents/savage_bound.png",
	type = {"mounted/mounted-mobility", 3},
	require = mnt_strdex_req3,
	points = 5,
	cooldown = 8,
	loyalty = 8,
	tactical = { CLOSEIN = 3, DISABLE = { pin = 2 } },
	direct_hit = true,
	range = function(self, t) return math.floor(2.5 + 0.7*self:getTalentLevel(t)) end,
	requires_target = true,
	on_pre_use = function(self, t, silent, fake)
		return preCheckHasMountPresent(self, t, silent, fake)
		and preCheckMountCanMove(self, t, silent, fake)
	end,
	target = function(self, t) return {
		type="hit",
		range=self:getTalentRange(t),
		start_x=mount.x, start_y=mount.y,
		friendlyfire=false, selffire=false
	} end,
	action = function(self, t)
		local mount = self:hasMount()	
		local mover = self:isMounted() and self or mount
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end

		jumpTargetTo(mover, x, y)

		if not target then return true end
		if not mount:canProject({type="hit", range=1}, target.x, target.y) then return true end

		local hit = mount:attackTarget(target, nil, t.getDamageMultiplier(self, t), true)
		if hit and target:canBe("pin")then
			target:setEffect(target.EFF_PINNED, t.getPinDur(self, t), {
				apply_power=mount:combatPhysicalpower(),
				apply_save="combatPhysicalResist"
			})
		end
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam_pct = t.getDamageMultiplier(self,t)*100
		local pin_dur = t.getPinDur(self, t)
		return ([[Your mount bounds into the air, landing up to %d squares away. If an enemy is in this square, your mount pounces upon it, dealing %d%% damage while landing in the square in front of it and pinning it for %d turns.]]):format(range, dam_pct, pin_dur)
	end,
	getWeaponDam = function(self, t) return self:combatTalentWeaponDamage(t, 0.9, 1.4) end,
	getDamageMultiplier = function(self, t) return self:combatTalentScale(t, 1.25, 1.75) end,
	getPinDur = function(self, t) return math.floor(3 + 0.5*self:getTalentLevel(t)) end, 
}

local function getEnemiesFromProjection(self, tg, x, y, project_check)
	local actors = {}

	self:project(tg, x, y, function(px, py)
		local a = game.level.map(px, py, Map.ACTOR)
		if a and a ~= self and self:reactionToward(a) < 0 then
			if not project_check or project_check(self, a) then actors[a] = true end
		end
	end)
	return table.reverse(actors)
end

newTalent{
	name = "Mounted Acrobatics", short_name = "OUTRIDER_MOUNTED_ACROBATICS", image = "talents/mounted_acrobatics.png",
	type = {"mounted/mounted-mobility", 4},
	require = mnt_strdex_req4,
	points = 5,
	mode = "passive",
	range = function(self, t) return math.floor(3 + self:getTalentLevel(t)/2) end,
	cooldown = function(self, t) return 13-self:getTalentLevelRaw(t) end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.8, 1.6) end,
	getMeleeTarget = function(self, t, ox, oy)
		return {type="beam", start_x=ox, start_y=oy, talent=t, range=self:getTalentRange(t)}
	end,
	getArcheryTarget = function(self, t)
		local block = function(_, lx, ly) return game.level.map:checkAllEntities(lx, ly, "block_move") end
		return {type="ball", block_radius=block, radius=archery_range(self, t), talent=t}
	end,
	doAttack = function(self, t, ox, oy, x, y)
		local main = self:getInven"MAINHAND"; if main then main=main[1] else return end
		if main.archery then t.doArcheryAttack(self, t, ox, oy, x, y) 
		elseif main.combat then t.doMeleeAttack(self, t, ox, oy, x ,y) end
	end,
	doArcheryAttack = function(self, t, ox, oy, x, y)
		-- Not just a weapon check; this checks for ammo & disarming among
		---other things.
		if not self:hasArcheryWeapon() then return end

		local actors = getEnemiesFromProjection(self, tg, x, y)

		local tg = {friendlyfire=false, friendlyblock=false, no_energy=true}
		for _, a in ipairs(rng.tableSample(actors, 2)) do
			local tg = self:archeryAcquireTargets(tg, {x=a.x, y=a.y})
			self:archeryShoot(tg, t, nil, {mult=t.getDamage(self, t)})
		end
	end,
	doMeleeAttack = function(self, t, ox, oy, x, y)
		-- Not just a weapon check, this also checks for disarming
		if not self:hasWeaponType() then return end
		local actors = getEnemiesFromProjection(self, tg, x, y)
		
		for _, a in ipairs(actors) do
			self:attackTarget(a, nil, t.getDamage(self, t), true)
		end
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local dam = t.getDamage(self, t)*100
		return ([[When you mount or dismount, you may leap a great distance, jumping an extra %d squares away. All enemies you pass through during this manoeuvre suffer a %d%% damage attack, if you are wielding a melee weapon; if you wield a ranged weapon, then when you land you shoot up to two enemies within range for %d%% damage.]]
		):format(range, dam, dam, range)
	end,
}