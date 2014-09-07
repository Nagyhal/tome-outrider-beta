newTalent{
	name = "Howling Arrows",
	type = {"technique/dreadful-onset", 1},
	--no_energy = "fake",  --What does this mean?
	points = 5,
	--random_ego = "attack",  --What?
	cooldown = 10,
	stamina = 10,
	require = mnt_cun_req1,
	range = archery_range,
	radius = function(self, t)
		return 2
		--return 2 + math.floor(self:getTalentLevel(t) / 3)
	end,
	tactical = { ATTACKAREA = { weapon = 2 }, DISABLE = { stun = 3 } }, 
	getDamage = function(self, t)
		return self:combatTalentWeaponDamage(t, 0.3, 0.8)
	end,
	getDuration = function(self, t)
		return 3 + math.floor(self:getTalentLevel(t) / 2)
	end,
	getConfusePower = function(self, t) --cheeky hack so Cat point spenders are not left out.
		return 25 + 5 * math.max(self:getTalentLevel(t) / 1.3, self:getTalentLevelRaw(t))
	end,
	tactical = { ATTACKAREA = { weapon = 2 }, DISABLE = { stun = 3 } },
	requires_target = true,
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), display=self:archeryDefaultProjectileVisual(weapon, ammo)}
	end,
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon() then if not silent then game.logPlayer(self, "You require a bow or sling for this talent.") end return false end return true end,
	archery_onhit = function(self, t, target, x, y)
		local eff ="confuse"  --Not sure which fear to use
		--if self:getTalentLevelRaw(t) >= 3 then eff = rngtable({"fear", "confuse"}) else eff="fear" end
		--if eff == "fear" then
			--if target:canBe("fear") then
				--if actor:checkHit(self:combatMindpower(), actor:combatMentalResist(), 0, 95) then      --code from fears.lua
				--target:setEffect(target.EFF_PANICKED, 2 + self:getTalentLevelRaw(t), {apply_power=self:combatAttack()})     --bad code, do not use
			--else
				--game.logSeen(target, "%s resists!", target.name:capitalize())
		--end
		--end
		if eff == "confuse" then
			if target:canBe("confused") then
				target:setEffect(target.EFF_CONFUSED, t.getDuration(self, t), {power=t.getConfusePower(self, t)})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
		if self:getTalentLevelRaw(t) >= 5 then
			if target:canBe("silenced") then
				target:setEffect(target.EFF_SILENCED, t.getDuration(self, t))
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local targets = self:archeryAcquireTargets(tg, {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, tg, {mult=t.getDamage(self, t)})
		return true
	end,
	info = function(self, t)
		return ([[Taking specially notched arrows from your quiver, you let off a volley of whistling arrows, besieging your enemies in a radius of %d with horridly screeching missiles and breaking their ranks, doing %d%% damage with a chance to confuse (power %d). At level 5, the cacophony created is enough to drown out the chants of spellcasters, applying an additional silence chance.]])
		:format(self:getTalentRadius(t), 
		t.getDamage(self, t)*100, 
		t.getConfusePower(self, t))
	end,
}
	
--[[	
	Living Shield
	Grapple an adjacent enemy; all ranged and melee attacks now have a XX% chance to hit this enemy instead of you. You may move to drag the enemy with you.
--]]

newTalent{
	name = "Living Shield",
	type = {"technique/dreadful-onset", 1},
	require = mnt_cun_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	stamina = 30,
	tactical = { ATTACK = 2, DISABLE = 2, DEFEND = 2 },
	requires_target = true,
	getDuration = function(self, t) return 2 + math.floor(self:getTalentLevel(t)) end,
	getPower = function(self, t) return self:combatTalentPhysicalDamage(t, 5, 25) end,
	getTransferChance =  function(self, t) return 30 + self:getTalentLevel(t) * 5 end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

		local grappled = false

		--force stance change
		-- if target and not self:isTalentActive(self.T_GRAPPLING_STANCE) then
			-- self:forceUseTalent(self.T_GRAPPLING_STANCE, {ignore_energy=true, ignore_cd = true})
		-- end

		-- breaks active grapples if the target is not grappled
		if target:isGrappled(self) then
			grappled = true
		else
			self:breakGrapples()
		end
		-- end the talent without effect if the target is to big
		if self:grappleSizeCheck(target) then
			return true
		end
		-- start the grapple; this will automatically hit and reapply the grapple if we're already grappling the target
		local hit = self:startGrapple(target)

		local duration = t.getDuration(self, t)

		if hit then
			target:setEffect(target.EFF_LIVING_SHIELD, duration, {src=self, chance=t.getTransferChance(self, t)})
			self:setEffect(target.EFF_LIVING_SHIELDED, duration, {trgt=target, chance=t.getTransferChance(self, t)})
			self:setEffect(target.EFF_DRAGGING, duration, {trgt=target})
			target:setEffect(target.EFF_DRAGGED, duration, {src=self})
		
		-- -- do crushing hold or strangle if we're already grappling the target
		-- if hit and self:knowTalent(self.T_CRUSHING_HOLD) then
			-- local t = self:getTalentFromId(self.T_CRUSHING_HOLD)
			-- if grappled and not target.no_breath and not target.undead and target:canBe("silence") then
				-- target:setEffect(target.EFF_STRANGLE_HOLD, duration, {src=self, power=t.getDamage(self, t) * 1.5})
			-- else
				-- target:setEffect(target.EFF_CRUSHING_HOLD, duration, {src=self, power=t.getDamage(self, t)})
			-- end
		-- end	
			return true
		end
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		-- local power = t.getPower(self, t)
		local chance = t.getTransferChance(self, t)
		return ([[Grapple an adjacent enemy up to one size category larger than you for %d turns; all ranged and melee attacks now have a %d%% chance to hit this enemy instead of you. You may move to drag the enemy with you. 
		At talent level 5, you have mastered the art of cruel redirection, gaining the Block talent for a 100%% chance to reduce up to 100 damage, switching squares upon an impact.]])
		:format(duration, chance)
	end,
}

--[[
Impalement/ Active, 25 stamina, 
	Take a point-blank shot, pushing your enemy back and pinning it against any suitable obstacle, natural or man-made. At level 3 you may perform this manoeuvre with a melee weapon; but using it disarms you for the duration of the pin.
--]]

newTalent{
	name = "Impalement",
	type = {"technique/dreadful-onset", 1}, --REM:3
	--no_energy = "fake",
	points = 5,
	--random_ego = "attack",
	cooldown = function (self, t) return 21 - self:getTalentLevel(t) end,
	stamina = 25,
	require = mnt_cun_req1, --REM: mnt_cun_req3
	getArcheryTargetType = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {range=t.getArcheryRange(self, t)}
	end,
	getArcheryRange = function(self, t) return math.floor(self:getTalentLevel(t)) end,
	range = function(self, t)
		return t.getArcheryRange(self, t)
	end,
	getFinalRange = function(self, t)
		if self:hasArcheryWeapon("bow") then return t.getArcheryRange(self, t) end
		if self:hasTwoHandedWeapon().subtype == "trident" then return 2
		else return 1 end --REM: Should this be some kind of "melee" marker?
	end,
	getKnockbackRange = function (self, t)
		return math.floor ((self:getTalentLevel(t) / 2) + 2)
	end,
	getDuration = function (self, t)
		return math.floor (self:getTalentLevel(t) + 2)
	end,
	getDamage = function (self, t)
		return self:combatTalentWeaponDamage(t, 1, 1.4)
	end,
	tactical = { ATTACK = { weapon = 1 }, DISABLE = { pin = 2 } },
	requires_target = true,
	on_pre_use = function(self, t, silent) --No longer a ranged-focussed tree!
		if not self:hasArcheryWeapon("bow") then
			if not self:hasTwoHandedWeapon() then
				if not silent then 
					game.logPlayer(self, "You require a bow or a two-handed weapon for this talent.")
					return false
				end
			end
		end
	return true
	end,
	archery_onhit = function(self, t, target, x, y)
		dx, dy = target.x - self.x, target.y - self.y
		if math.max(math.abs(dx), math.abs(dy))>1 then
			dx, dy = dx / math.max(dx, dy), dy / math.max(dx, dy)
		end
		target:knockback(self.x, self.y, t.getKnockbackRange(self, t))
		--we need to detect if the target hits an obstacle, and the obstacle must be within knockback range
		if math.floor(core.fov.distance(self.x, self.y, target.x + dx, target.y + dy)) > t.getKnockbackRange(self, t)+1 then return nil end
		if game.level.map:checkAllEntities(target.x + dx, target.y + dy, "block_move", self) then
			if target:canBe("pin") then
				target:setEffect(target.EFF_PINNED, t.getDuration(self, t), {apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
	end,
	action = function(self, t)
		if self:hasArcheryWeapon("bow") then
			local targets = self:archeryAcquireTargets(t.getArcheryTargetType(self, t), {one_shot=true})
			if not targets then return end
			self:archeryShoot(targets, t, nil, {mult=self:combatTalentWeaponDamage(t, 1, 1.4)})
			return true
		else 
			--melee routine
			local tg = {type="hit", range=t.getFinalRange(self, t)}
			local x, y, target = self:getTarget(tg)
			if not x or not y or not target then return nil end
			if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
			local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
			if hit then
				if target:canBe("pin") then --REM: Need to make an "Impaled" effect
					target:setEffect(target.EFF_PINNED, t.getDuration(self, t), {apply_power=self:combatAttack()})					
					local pin = target:hasEffect(target.EFF_PINNED)
					if pin then
						self:setEffect(self.EFF_DISARMED, pin.dur, {})
					end
				else
					game.logSeen(target, "%s resists!", target.name:capitalize())
				end
			end
		return true
		end
	end,
	info = function(self, t)
		return ([[Take a point-blank shot for %d%% damage, pushing your enemy back up to %d squares and pinning it (for %d turns) against any suitable obstacle, natural or man-made. At level 3 you may perform this manoeuvre with a melee weapon; but using it disarms you for the duration of the pin.]])
		:format(t.getDamage(self, t) * 100,
		t.getKnockbackRange(self, t),
		t.getDuration(self, t))
	end,
}

--[[
Catch!
	Hurl the severed head of your enemies' comrade back at them, causing them to gape in terror and flee. You may use this talent only after killing an adjacent enemy (up to 2->6 turns afterward), and then only with a critical hit.
--]]

newTalent{
	name = "Catch!",
	short_name = "CATCH",
	type = {"technique/dreadful-onset", 1},
	no_energy = "fake",
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	stamina = 35,
	tactical = { DISABLE = { fear = 4 } },
	require = mnt_cun_req1,
	getRange = function (self, t) return math.floor(self:getTalentLevel(t) +4) end,
	range = function (self, t) return t.getRange(self, t) end,
	getDuration = function(self, t) return 3 + math.ceil(self:getTalentLevel(t)) end,
	getUsageWindow = function(self, t) return 2 + math.floor(self:getTalentLevel(t)) end,
	requires_target = true,
	target = function(self, t)
		return {type="ball", radius=1, range=self:getTalentRange(t)}
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
			if target:canBe("confusion") then
				target:setEffect(target.EFF_CONFUSED, t.getDuration(self, t), {power=30 + self:getCun(70), apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s resists the terror!", target.name:capitalize())
			end
		return true
	end,
	info = function(self, t)
		return ([[Hurl the severed head of your enemies' comrade back at them, causing them to gape in terror and flee for %d turns. You may use this talent only after killing an adjacent enemy (up to %d turns afterward), and then only with a critical hit.]]):
		format(t.getDuration(self, t), t.getUsageWindow(self, t))
	end,
}

--Junk code goes here (I'm new so I need this):

--Old pre-use weapon check for Impalement
		-- if self:getTalentLevelRaw(t) < 3 then 
			-- if not self:hasArcheryWeapon("bow")  then
				-- if not silent then game.logPlayer(self, "You require a bow for this talent.")	
				-- end
				-- return false
			-- end
			-- return true 
		-- end
		-- if self:getTalentLevelRaw(t) >= 3 then
			-- if self:hasArcheryWeapon() and not self:hasArcheryWeapon("bow")  then 
				-- if not silent then game.logPlayer(self, "Only arrows can impale with range!") 
				-- end
			-- return false
			-- end 
		-- return true
		-- end