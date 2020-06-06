function learnTraits(self)
	if not self.bestial_traits then return nil end
	self.__show_special_talents = self.__show_special_talents or {}
	for i, tid in ipairs(self.bestial_traits) do
		self.__show_special_talents[tid] = true
	end
end

function shareTalentWithOwner(self, t)
	if not t.shared_talent then error(("No shared talent for talent %s"):format(t.id))end
	if self.owner then self.owner:learnTalent(t.shared_talent, true, 1) else error(("No owner to share with for talent %s"):format(t.id)) end
end

function shareAllTalentsWithPet(self, pet)
	if not pet then return end
	for tid, _ in pairs(self.talents) do
		local t = self:getTalentFromId(tid)
		if t and t.shared_talent then
			pet:learnTalent(t.shared_talent, true, 1)
		end
	end
end

function shareTalentWithPet(self, pet, t)
	if not pet then return end
	if t and t.shared_talent then
		pet:learnTalent(t.shared_talent, true, 1)
	end
end

function unshareTalentWithPet(self, pet, t)
	if not pet then return end
	if t and t.shared_talent then
		pet:unlearnTalent(t.shared_talent)
	end
end

function unshareTalentWithOwner(self, t)
	if not t.shared_talent then error(("No shared talent for talent %s"):format(t.id)) end
	if self.owner then 
		if not self:knowTalent(t) then 
			self.owner:unlearnTalent(t.shared_talent)
		end
	end
end

--Automatically target an enemy next to the pet, if there is only 1 target.
function autoPetTarget(self, pet)
	local foes = {}
	for _, c in pairs(util.adjacentCoords(pet.x, pet.y)) do
			local target = game.level.map(c[1], c[2], Map.ACTOR)
			if target and self:reactionToward(target) < 0 then foes[#foes+1] = target end
		end
		if #foes == 1 then
		game.target.target.entity = foes[1]
		game.target.target.x = foes[1].x
		game.target.target.y = foes[1].y
		return game.target.target.x, game.target.target.y, game.target.target.entity
	end
end

