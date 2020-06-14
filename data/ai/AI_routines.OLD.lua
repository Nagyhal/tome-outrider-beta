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

-- 	if target and rng.percent(50) then
-- 		-- Can we attack the target? If so, do that straight away.
-- 		self:runAI(self.ai_state.ai_party, {special=filterOnlyAttacks})
-- 		-- Can't attack? Close in.
-- 		if not self.energy.used and core.fov.distance(self.x, self.y, target.x, target.y) > 1 then
-- 			self:runAI(self.ai_state.ai_party, {special=filterOnlyCloseIn})
-- 			if not self.energy.used then
-- 				self:runAI("move_complex")
-- 			end
-- 		end
-- 	end
-- 	if not self.energy.used then return true end
-- 	-- Do what we usually do, ignoring the nice things like leash anchors
-- 	if self.ai_target.actor and self:reactionToward(self.ai_target.actor) >= 0 then self:setTarget(nil) end

-- 	local ret = self:runAI(self.ai_state.ai_party)
-- 	-- game.log "rargh"
-- end


-- do_act = function(self, eff)
-- 	if not self:enoughEnergy() then return nil end
-- 	if eff.src.dead then return true end

-- 	if rng.percent(eff.chance) then
-- 		local distance = core.fov.distance(self.x, self.y, eff.src.x, eff.src.y)
-- 		if distance <= eff.range then
-- 			-- in range
-- 			if not self:attr("never_move") then
-- 				local sourceX, sourceY = eff.src.x, eff.src.y

-- 				local bestX, bestY
-- 				local bestDistance = 0
-- 				local start = rng.range(0, 8)
-- 				for i = start, start + 8 do
-- 					local x = self.x + (i % 3) - 1
-- 					local y = self.y + math.floor((i % 9) / 3) - 1

-- 					if x ~= self.x or y ~= self.y then
-- 						local distance = core.fov.distance(x, y, sourceX, sourceY)
-- 						if distance > bestDistance
-- 								and game.level.map:isBound(x, y)
-- 								and not game.level.map:checkAllEntities(x, y, "block_move", self)
-- 								and not game.level.map(x, y, Map.ACTOR) then
-- 							bestDistance = distance
-- 							bestX = x
-- 							bestY = y
-- 						end
-- 					end
-- 				end

-- 				if bestX then
-- 					self:move(bestX, bestY, false)
-- 					game.logPlayer(self, "#F53CBE#You panic and flee from %s.", eff.src.name)
-- 				else
-- 					self:logCombat(eff.src, "#F53CBE##Source# panics but fails to flee from #Target#.")
-- 					self:useEnergy(game.energy_to_act * self:combatMovementSpeed(bestX, bestY))
-- 				end
-- 			end
-- 		end
-- 	end