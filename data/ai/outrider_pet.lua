-------------------------------------------------------------------------------
--- Helper functions.
-------------------------------------------------------------------------------
--- Used when the mount is Riled Up and close to the owner
-- The mount will run around and act a little crazy, even if there's no enemies
-- in sight.
local function rompAroundTheOwner(pet, owner)
	if not owner or self:isRidden() or core.fov.distance(self.x, self.y, owner.x, owner.y) <= 1 then return end

	if core.fov.distance(pet.x, pet.y, owner.x, owner.y) > 1 then return end
	local x, y = util.findFreeGrid(owner.x, owner.y, 1, nil, {[engine.Map.ACTOR]=true})
	if x and y then
		pet:moveDirection(x, y, true)
	else
		return
	end

	if rng.percent(33) then
		if rng.percent(10) then 
			game.logPlayer(owner, "%s licks your face!", self.name:capitalize())
		elseif rng.percent(12) then
			game.logPlayer(owner, "%s is getting really riled up!", self.name:capitalize())
		else
			game.logPlayer(owner, "%s runs wild around you!", self.name:capitalize())
		end
	end
end

--- Get our AI target and check it's not dead etc.
-- @return The target if we have one, otherwise nil.
local function getLiveAITarget(self)
	local target = self.ai_target.actor
	if target and not target.dead and game.level:hasEntity(target) then
		return target
	else
		return nil
	end
end

-------------------------------------------------------------------------------
--- AI routines.
-------------------------------------------------------------------------------

---Special AI behaviours for Outrider mounts.
--Handles mainly disobedience effects, so far, and also calls the targeting
--function in case the pet is mounted. Some behaviours are also set by the
--disobedience effects themselves.
newAI("pet_behaviour", function(self)
	local ox, oy = self.x, self.y
	local target = getLiveAITarget(self)
	local mover = self:getRider() or self

	local skittish = self:hasEffect(self.EFF_OUTRIDER_SKITTISH)
	local riled_up = self:hasEffect(self.EFF_OUTRIDER_RILED_UP) 
	--@todo local obstinate = self:hasEffect(self.EFF_OUTRIDER_OBSTINATE) 
	--@todo local frenzied = self:hasEffect(self.EFF_OUTRIDER_FRENZIED) 
	--@todo local terror_stricken = self:hasEffect(self.EFF_OUTRIDER_TERROR_STRICKEN) 

	if target and skittish then
		if rng.percent(skittish.chance) then
			--Flee from target
			--@todo Consider also "FLEE"-type talents
			game.logSeen(
				mover, "%s backs away from %s due to low Loyalty!", self.name:capitalize(), target.name:capitalize()
			)
			self:runAI("flee_dmap_keep_los")
		end
	end

	if target and riled_up then
		if rng.percent(riled_up.chance) then
			--50% chance to rush in like a madman
			--@todo Consider also "CLOSEIN"-type talents
			game.logSeen(mover,
				"%s rages at %s due to low Loyalty!", self.name:capitalize(), target.name:capitalize()
			)
			if core.fov.distance(self.x, self.y, target.x, target.y)<=1 or not mover:moveDirection(target.x, target.y, true) then
				self:attackTarget(target, nil, 0.6, true)
			end
		end
	end

	--If we're riled, then get a little crazy even if there's no enemies in sight.
	if riled_up and not target and not self.aiSeeTargetPos then 
		rompAroundTheOwner(self, self.owner)
	end

	local ret = {self:runAI("target_mount")}

	local eff = self:hasEffect(self.EFF_OUTRIDER_BEASTMASTER_MARK)
	if eff then	self:runAI("barks", eff) end

	return unpack(ret)
end)

--- The base AI for mounts
-- Can be set up to do more but currently just runs as a party member.
newAI("outrider_pet", function(self)
	self:runAI("pet_behaviour")
	if not self.energy.used then
		return self:runAI("party_member")
	end
end)

newAI("barks", function(self, eff)
	if eff and eff.dissatisfaction >= 3 and not eff.did_bark then
		local texts = {
			"Grrrr!",
			"grrr...",
			"Growl!",
			"Rrrr...",
			"Wruff, wruff!"
		}
		game.logPlayer(self.owner,
			"#RED##{bold}#%s bays to be let at %s!#{normal}##LAST#",
			self.name:capitalize(), eff.target.name)
		self:doEmote(rng.table(texts), 30)
		eff.did_bark = true
		eff.dissatisfaction = 1
	end
end)