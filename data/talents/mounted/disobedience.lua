newTalent{
	name = "Cowardice",
	type = {"mounted/disobedience", 1},
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	-- loyalty = 0,
	cooldown = 0,
	no_energy = true, 
	-- message = "@Source@ causes a spacetime hiccup.",
	action = function(self, t)
		self:setEffect(self.EFF_TERRIFIED, 5, {actionFailureChance=50})
		return true
	end,
	info = function(self, t)
		return ([[The beast succumbs to cowardice, and stands a 50%% chance not to attack for 5 turns.]])
	end,
}

newTalent{
	name = "Flee",
	type = {"mounted/disobedience", 1},
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	cooldown = 0,
	no_energy = true, 
	action = function(self, t)
		self:setEffect(self.EFF_PANICKED, 5, {src=self.owner, chance=50})
		return true
	end,
	info = function(self, t)
		return ([[The beast begins to flee, and stands a 50%% chance to run away for 5 turns.]])
	end,
}

newTalent{
	name = "Rebellion",
	type = {"mounted/disobedience", 1},
	type_no_req = true,
	no_unlearn_last = true,
	points = 1,
	disobedience_type = "major",
	cooldown = 0,
	no_energy = true, 
	action = function(self, t)
		self:setEffect(self.EFF_PARANOID, 5, {src=self.owner, attackChance=50})
		return true
	end,
	info = function(self, t)
		return ([[The beast is overcome by a fury, and stands a 50%% chance to attack anything in sight.]])
	end,
}