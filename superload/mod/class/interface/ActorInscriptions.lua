local _M = loadPrevious(...)

--Grant an inscription from the player's inventory.
function _M:grantInscription(target, id, name, data, cooldown, vocal, src, bypass_max_same, bypass_max)
	if not target or not target.max_inscriptions then
		error("Invalid target passed to ActorInscription")
	end
	target.inscription_objects = target.inscription_objects or {}
	-- Check allowance
	local t = target:getTalentFromId(target["T_"..name.."_1"])
	if target.inscription_restrictions and not target.inscription_restrictions[t.type[1]] then
		if vocal then game.logPlayer(self, "Your target is unable to use this kind of inscription.") end
		return
	end

	-- Count occurrences
	local nb_same = 0
	for i = 1, target.max_inscriptions do
		if target.inscriptions[i] and target.inscriptions[i] == name.."_"..i then nb_same = nb_same + 1 end
	end
	if nb_same >= 2 and not bypass_max_same then
		if vocal then game.logPlayer(self, "Your target already has too many of this inscription.") end
		-- Replace chaten
		if self.player and src then
			local t = self:getTalentFromId(self["T_"..name.."_1"])
			src.player = self
			src.target = target
			src.iname = name
			src.idata = data
			src.replace_same = name
			local chat = engine.Chat.new("outrider+player-grant-inscription", target, self, src)
			chat:invoke()
		end
		return
	end

	-- Find a spot
	if not id then
		for i = 1, (bypass_max and 6 or target.max_inscriptions) do
			if not target.inscriptions[i] then id = i break end
		end
	end
	if not id then
		if vocal then
			game.logPlayer(self, "Your target has no more inscription slots.")
		end
		-- Replace chat
		if self.player and src then
			local t = self:getTalentFromId(self["T_"..name.."_1"])
			src.player = self
			src.target = target
			src.iname = name
			src.idata = data
			local chat = engine.Chat.new("outrider+player-grant-inscription", target, self, src)
			chat:invoke()
		end
		return
	end

	-- Unlearn old talent
	local oldname = target.inscriptions[id]
	if oldname then
		if target.drop_unlearnt_inscriptions then
			local o = target.inscription_objects[oldname]
			if o then
				-- self:addObject(self:getInven("INVEN"), o, false, false)
				game.level:addEntity(o)
				game.level.map:addObject(target.x, target.y, o)
				o.auto_pickup = true
				target.inscription_objects[oldname] = nil
			end
		end
		target:unlearnTalent(target["T_"..oldname])
		target.inscriptions_data[oldname] = nil
	end

	-- Learn new talent
	name = name.."_"..id
	data.__id = id
	if src and src.obj then
		data.item_name = src.obj:getName{do_color=true, no_count=true}:toTString()
		target.inscription_objects[name] = src.obj:clone()
	end
	target.inscriptions_data[name] = data
	target.inscriptions[id] = name
--	print("Inscribing on "..self.name..": "..tostring(name))
	target:learnTalent(target["T_"..name], true, 1, {no_unlearn=true})
	local t = target:getTalentFromId(target["T_"..name])
	if cooldown then target:startTalentCooldown(t) end
	if vocal then
		game.logPlayer(self, "Your target is now inscribed with %s.", t.name)
	end
	--Check our mounted player has not disappeared into the void.
	--This is a dialog issue really, but setting dialog attributes doesn' t seem to work, so here it is.
	if not game.level:hasEntity(self) then game.level:addEntity(self) end
	return true
end

return _M