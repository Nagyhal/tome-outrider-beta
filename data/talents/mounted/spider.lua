

newTalent{
	name = "Blinding Spittle",
	type = {"spider/stalker-in-the-shadows", 1},
	require = cuns_req1,
	points = 5,
	random_ego = "attack",
	stamina = 10,
	no_energy=true,
	cooldown = function(self, t) return math.max(6, self:combatTalentScale(t, 10, 8)) end,
	tactical = { ATTACK = { NATURE = 2}, DISABLE = 1 },
	range = function(self, t) return math.min(10, self:combatTalentScale(t, 5, 10)) end,
	proj_speed = 4,
	target = function(self, t) return {type="bolt", range=self:getTalentRange(t), selffire=false, friendlyfire=false, talent=t, display={particle="bolt_slime"}, name = t.name, speed = t.proj_speed} end,
	requires_target = true,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:projectile(tg, x, y, DamageType.NATURE_BLIND, {dam=self:mindCrit(t.getDam(self, t)), dur=t.getEffDur(self, t), {type="slime"}})
		game:playSoundNear(self, "talents/slime")
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		local eff_dur = t.getEffDur(self, t)
		return ([[Heave a ball of blinding spittle at your target. A successful hit will deal %d nature damage (scaling with Physical Power) while blinding it for %d turns.
		
			Levelling this talent will improve the range and the cooldown.]]):
		format(dam, eff_dur)	
	end,
	getDam = function(self, t) return self:combatTalentPhysicalDamage(t, 20, 150) end,
	getEffDur = function(self, t) return self:combatTalentScale(t, 4, 6) end,
}
