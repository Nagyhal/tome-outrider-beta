newTalent{
	name = "Gruesome Depredation",
	type = {"mounted/beast-heart", 1},
	require = mnt_wil_req1,
	points = 5,
	cooldown = 30,
	tactical = { ATTACK = 2 }, --TODO: Complicated AI routine
	range = 1 ,
	requires_target = true,
	target = function(self, t)
		--TODO: There is actually an engine bug making keyboard targeting useless. Let's fix this!
		local mount = self:hasMount()
		local ret = {type="hit", range=self:getTalentRange(t), friendlyfire=false, selffire=false}
		if mount then ret.start_x, ret.start_y=mount.x, mount.y end
		return ret
	end,
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end, 
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		local mount = self:hasMount()
		local hit = mount:attackTarget(target, nil, t.getDam(self, t), true)
		if hit and target.dead then
			local heal = mount.max_life*t.getHeal(self, t)
			mount:heal(heal)
		end
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local loyalty = t.getLoyalty(self, t)
		local heal = t.getHeal(self, t)*100
		return ([[Your mount bites your enemy for %d%% damage. If this kills it, then your mount's bite devours a great chunk of your enemy's carcass, restoring %d Loyalty and healing your mount for %d%% of its total life.]]):
			format(dam, loyalty, heal)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.8, 2.5) end,
	getLoyalty = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getHeal = function(self, t) return self:combatTalentLimit(t, .05, .1, 35) end
}
