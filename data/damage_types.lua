newDamageType{
	name = "nature blind", type = "NATURE_BLIND", text_color = "#GREEN#",
	projector = function(src, x, y, damtype, dam)
		if type(dam) == "number" then dam = {dam=dam} end
		dam.dur = dam.dur or 3
		local realdam = DamageType:get(DamageType.NATURE).projector(src, x, y, DamageType.NATURE, dam.dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			if target:canBe("blind") then
				target:setEffect(target.EFF_BLINDED, dam.dur, {src=src, apply_power=math.max(src:combatPhyspower())})
			else
				game.logSeen(target, "%s resists!", target.name:capitalize())
			end
		end
		return realdam
	end,
}
