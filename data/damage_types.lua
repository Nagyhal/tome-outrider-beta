local useImplicitCrit = engine.DamageType.useImplicitCrit
-- local initState = engine.DamageType.initState

function initState(state)
	if state == nil then return {}
	elseif state == true or state == false then return {}
	else return state end
end

newDamageType{
	name = "nature blind", type = "NATURE_BLIND", text_color = "#GREEN#",
	projector = function(src, x, y, damtype, dam, state)
		local useImplicitCrit = engine.DamageType.useImplicitCrit
		-- local initState = engine.DamageType.initState
		state =initState(state)
		useImplicitCrit(src, state)
		if type(dam) == "number" then dam = {dam=dam} end
		dam.dur = dam.dur or 3
		local realdam = DamageType:get(DamageType.NATURE).projector(src, x, y, DamageType.NATURE, dam.dam, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			if target:canBe("blind") then
				target:setEffect(target.EFF_BLINDED, dam.dur, {src=src, apply_power=math.max(src:combatPhysicalpower())})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
		return realdam
	end,
}

newDamageType{
	name = "test of mettle", type = "TEST_OF_METTLE",
	projector = function(src, x, y, damtype, dam, state)
		local useImplicitCrit = engine.DamageType.useImplicitCrit
		-- local initState = engine.DamageType.initState
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local dur = dam.dur or 4
			if target:canBe("fear") then
				local recursive = function(target)
					if src:checkHit(src:combatMindpower(), target:combatMentalResist(), 0, 95) and target:canBe("knockback") then 
						return true
					else
						game.logSeen(target, "%s resists the knockback!", target.name:capitalize())
					end
				end
				if rng.percent(50) then
					target:setEffect(target.EFF_PANICKED, dur, {src=src, apply_power=math.max(src:combatMindpower()), chance=50, range=10})
					if target:hasEffect(target.EFF_PANICKED) then game:onTickEnd(function() target:knockback(src.x, src.y, 1, recursive, nil) end) end
				else
					target:setEffect(target.EFF_OUTRIDER_PROVOKED, dur, {src=src, apply_power=math.max(src:combatMindpower()), red=red})
				end
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
	end,
}
