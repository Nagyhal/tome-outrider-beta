local function filterOnlyAttacks(t, filter)
	local tactical = t.tactical; if not tactical then return end
	if type(tactical) == "function" then tactical = tactical(self, t, aitarget) or {} end
	if #(table.compareKeys(tactical, {ATTACK=true, ATTACKAREA=true, AREAATTACK=true, DISABLE=true})["both"]) > 0 then
		return true
	end
end

local function filterOnlyCloseIn(t, filter)
	local tactical = t.tactical; if not tactical then return end
	if type(tactical) == "function" then tactical = tactical(self, t, aitarget) or {} end
	if #(table.compareKeys(tactical, {CLOSEIN=true})["both"]) > 0 then
		return true
	end
end

newAI("outrider_pet", function(self)
	if self:hasEffect(self.EFF_OUTRIDER_RILED_UP) then
		local p = self:hasEffect(self.EFF_OUTRIDER_RILED_UP) 
		if p.target and not self.ai_target.actor==p.target then
			self.ai_target.actor = p.target
		end
		local target = self.ai_target.actor
		if rng.percent(50) then
			-- Can we attack the target? If so, do that straight away.
			self:runAI(self.ai_state.ai_party, {special=filterOnlyAttacks})
			-- Can't attack? Close in.
			if not self.energy.used and core.fov.distance(self.x, self.y, target.x, target.y) > 1 then
				self:runAI(self.ai_state.ai_party, {special=filterOnlyCloseIn})
				if not self.energy.used then
					self:runAI("move_complex")
				end
			end
		end
		if self.energy.used then return true end
		-- Do what we usually do, ignoring the nice things like leash anchors
		if self.ai_target.actor and self:reactionToward(self.ai_target.actor) >= 0 then self:setTarget(nil) end

		local ret = self:runAI(self.ai_state.ai_party)
		-- game.log "rargh"
	end
	if not ret and not self.energy.used then
--		print("[PARTY AI] moving towards anchor", self.name)
		return self:runAI("party_member")
	end
end)