local _M = loadPrevious(...)

local function spotHostiles(self, actors_only)
	local seen = {}
	if not self.x then return seen end

	-- Check for visible monsters, only see LOS actors, so telepathy wont prevent resting
	core.fov.calc_circle(self.x, self.y, game.level.map.w, game.level.map.h, self.sight or 10, function(_, x, y) return game.level.map:opaque(x, y) end, function(_, x, y)
		local actor = game.level.map(x, y, game.level.map.ACTOR)
		if actor and self:reactionToward(actor) < 0 and self:canSee(actor) and game.level.map.seens(x, y) then
			seen[#seen + 1] = {x=x,y=y,actor=actor, entity=actor, name=actor.name}
		end
	end, nil)

	if not actors_only then
		-- Check for projectiles in line of sight
		core.fov.calc_circle(self.x, self.y, game.level.map.w, game.level.map.h, self.sight or 10, function(_, x, y) return game.level.map:opaque(x, y) end, function(_, x, y)
			local proj = game.level.map(x, y, game.level.map.PROJECTILE)
			if not proj or not game.level.map.seens(x, y) then return end

			-- trust ourselves but not our friends
			if proj.src and self == proj.src then return end
			local sx, sy = proj.start_x, proj.start_y
			local tx, ty

			-- Bresenham is too so check if we're anywhere near the mathematical line of flight
			if type(proj.project) == "table" then
				tx, ty = proj.project.def.x, proj.project.def.y
			elseif proj.homing then
				tx, ty = proj.homing.target.x, proj.homing.target.y
			end
			if tx and ty then
				local dist_to_line = math.abs((self.x - sx) * (ty - sy) - (self.y - sy) * (tx - sx)) / core.fov.distance(sx, sy, tx, ty)
				local our_way = ((self.x - x) * (tx - x) + (self.y - y) * (ty - y)) > 0
				if our_way and dist_to_line < 1.0 then
					seen[#seen+1] = {x=x, y=y, projectile=proj, entity=proj, name=(proj.getName and proj:getName()) or proj.name}
				end
			end
		end, nil)
	end
	return seen
end

function _M:restCheck()
	if game:hasDialogUp(1) then return false, "dialog is displayed" end

	local spotted = spotHostiles(self)
	if #spotted > 0 then
		for _, node in ipairs(spotted) do
			node.entity:addParticles(engine.Particles.new("notice_enemy", 1))
		end
		local dir = game.level.map:compassDirection(spotted[1].x - self.x, spotted[1].y - self.y)
		return false, ("hostile spotted to the %s (%s%s)"):format(dir or "???", spotted[1].name, game.level.map:isOnScreen(spotted[1].x, spotted[1].y) and "" or " - offscreen")
	end

	-- Resting improves regen
	for act, def in pairs(game.party.members) do if game.level:hasEntity(act) and not act.dead then
		local perc = math.min(self.resting.cnt / 10, 8)
		local old_shield = act.arcane_shield
		act.arcane_shield = nil
		act:heal(act.life_regen * perc)
		act.arcane_shield = old_shield
		act:incStamina(act.stamina_regen * perc)
		act:incMana(act.mana_regen * perc)
		act:incPsi(act.psi_regen * perc)
	end end

	-- Reload
	local ammo = self:hasAmmo()
	if ammo and ammo.combat.shots_left < ammo.combat.capacity then return true end
	-- Spacetime Tuning handles Paradox regen
	if self:hasEffect(self.EFF_SPACETIME_TUNING) then return true end
	
	-- Check resources, make sure they CAN go up, otherwise we will never stop
	if not self.resting.rest_turns then
		local mount = self:hasMount()
		if mount then
			if mount.air_regen < 0 then return false, "mount losing breath!" end
			if mount.life_regen <= 0 then return false, "mount losing health!" end
		end
		if self.air_regen < 0 then return false, "losing breath!" end
		if self.life_regen <= 0 then return false, "losing health!" end
		if self:getMana() < self:getMaxMana() and self.mana_regen > 0 then return true end
		if self:getStamina() < self:getMaxStamina() and self.stamina_regen > 0 then return true end
		if self:getPsi() < self:getMaxPsi() and self.psi_regen > 0 then return true end
		if self:getVim() < self:getMaxVim() and self.vim_regen > 0 then return true end
		if self:getEquilibrium() > self:getMinEquilibrium() and self.equilibrium_regen < 0 then return true end
		if self:getLoyalty() > self:getMinLoyalty() and self.loyalty_regen > 0 then return true end
		if self.life < self.max_life and self.life_regen> 0 then return true end
		if self.air < self.max_air and self.air_regen > 0 and not self.is_suffocating then return true end
		for act, def in pairs(game.party.members) do if game.level:hasEntity(act) and not act.dead then
			if act.life < act.max_life and act.life_regen > 0 and not act:attr("no_life_regen") then return true end
		end end
		if ammo and ammo.combat.shots_left < ammo.combat.capacity then return true end

		-- Check for detrimental effects
		for id, _ in pairs(self.tmp) do
			local def = self.tempeffect_def[id]
			if def.type ~= "other" and def.status == "detrimental" and (def.decrease or 1) > 0 then
				return true
			end
		end
		
		if self:fireTalentCheck("callbackOnRest", "check") then return true end
	else
		return true
	end

	-- Enter cooldown waiting rest if we are at max already
	if self.resting.cnt == 0 then
		self.resting.wait_cooldowns = true
	end

	if self.resting.wait_cooldowns then
		for tid, cd in pairs(self.talents_cd) do
--			if self:isTalentActive(self.T_CONDUIT) and (tid == self.T_KINETIC_AURA or tid == self.T_CHARGED_AURA or tid == self.T_THERMAL_AURA) then
				-- nothing
--			else
			if self.talents_auto[tid] then
				-- nothing
			else
				if cd > 0 then return true end
			end
		end
		for tid, sus in pairs(self.talents) do
			local p = self:isTalentActive(tid)
			if p and p.rest_count and p.rest_count > 0 then return true end
		end
		for inven_id, inven in pairs(self.inven) do
			for _, o in ipairs(inven) do
				local cd = o:getObjectCooldown(self)
				if cd and cd > 0 then return true end
			end
		end
	end

	self.resting.wait_cooldowns = nil

	-- Enter full recharge rest if we waited for cooldowns already
	if self.resting.cnt == 0 then
		self.resting.wait_powers = true
	end

	if self.resting.wait_powers then
		for inven_id, inven in pairs(self.inven) do
			for _, o in ipairs(inven) do
				if o.power and o.power_regen and o.power_regen > 0 and o.power < o.max_power then
					return true
				end
			end
		end
	end

	self.resting.wait_powers = nil

	-- Enter recall waiting rest if we are at max already
	if self.resting.cnt == 0 and self:hasEffect(self.EFF_RECALL) then
		self.resting.wait_recall = true
	end

	if self.resting.wait_recall then
		if self:hasEffect(self.EFF_RECALL) then
			return true
		end
	end

	self.resting.wait_recall = nil
	self.resting.rested_fully = true

	return false, "all resources and life at maximum"
end

return _M