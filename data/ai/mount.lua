newAI("target_mount", function(self)
	if not self.x then return end

	--TODO: Target enemies in melee that the rider targets
	
	--Not sure if it should always target the summoner.

	--Without independent movement, there's no sense in targeting an enemy we don't have direct line of sight to.
	--On top of that, prefer to target new enemies that move in closer.
	if self.ai_target.actor and self:hasLOS(self.ai_target.actor.x, self.ai_target.actor.y, "block_move", self.sight) and not self.ai_target.actor:attr("invulnerable") and rng.percent(50) then return true end

	-- Find closer enemy and target it
	-- Get list of actors ordered by distance
	local arr = self.fov.actors_dist
	local act
	local sqsense = math.max(self.lite or 0, self.infravision or 0, self.heightened_senses or 0)
	sqsense = sqsense * sqsense

	for i = 1, #arr do
		act = self.fov.actors_dist[i]
--		print("AI looking for target", self.uid, self.name, "::", act.uid, act.name, self.fov.actors[act].sqdist)
		-- find the closest enemy
		if act and self:reactionToward(act) < 0 and not act.dead and act.x and game.level.map:isBound(act.x, act.y) and
			(
				-- If it has lite we can always see it
				((act.lite or 0) > 0)
				or
				-- Otherwise check if we can see it with our "senses"
				(self:canSee(act) and (self.fov.actors[act].sqdist <= sqsense) or game.level.map.lites(act.x, act.y))
			) and not act:attr("invulnerable") then
			self:setTarget(act)
			self:check("on_acquire_target", act)
			act:check("on_targeted", self)
			print("AI took for target", self.uid, self.name, "::", act.uid, act.name, self.fov.actors[act].sqdist, "<", sqsense)
			return true
		end
	end
end)