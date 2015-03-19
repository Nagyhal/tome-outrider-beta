newTalent{
	name = "Feast of Blood",
	type = {"mounted/beast-heart", 1},
	require = mnt_wil_req1,
	points = 5,
	cooldown = function(self, t) return self:combatTalentLimit(t, 15, 35, 25) end,
	loyalty = 20,
	tactical = { HEAL = 2 }, --TODO: Complicated AI routine
	on_pre_use = function(self, t, silent)
		if self:isMounted() then
			if not silent then
				game.logPlayer(self, "You must be dismounted and adjacent to your beast!")
			end
			return false
		end
		local mount=self:hasMount()
		if not mount or core.fov.distance(self.x, self.y, mount.x, mount.y)~=1 then
			if not silent then
				game.logPlayer(self, "You must be dismounted and adjacent to your beast!")
			end
			return false
		end	
		return true
	end, 
	action = function(self, t)
		local mount=self:hasMount()
		mount:setEffect(mount.EFF_CUT, 6, {power=t.getBleed(self, t)/6})
		self:heal(t.getHeal(self, t))
		self:incStamina(t.getStamina(self, t))
		return true
	end,
	info = function(self, t)
		local heal = t.getHeal(self, t)
		local stamina = t.getStamina(self, t)
		local bleed_per = t.getBleed(self, t)/6
		return ([[Partaking of your bestial mount's unfaltering devotion through times of greatest need, you quench your hunger by loosing a little of its blood. Must be dismounted and adjacent to the beast. Regain %d health and %d stamina, while inflicting 6 turns of bleeding for %d damage upon your beast.]]):
			format(heal, stamina, bleed_per)
	end,
	getStamina = function(self, t) return self:combatTalentScale(t, 10, 60) end,
	getHeal = function(self, t) return self:combatTalentScale(t, 120, 300) end,
	getBleed = function(self, t)
			local heal = t.getHeal(self, t)
			return heal / self:combatTalentScale(t, 5, 6)
	end,
}


newTalent{
	name = "Primal Bond",
	type = {"mounted/beast-heart", 2},
	require = mnt_wil_req2,
	mode = "passive",
	no_unlearn_last = true,
	points = 5,
	on_learn = function(self, t)
		local pet = self.outrider_pet
		if not pet:knowTalentType("race/traits") then pet:learnTalentType("race/traits") end
		pet.bestial_traits = pet.bestial_traits or {}
		local ct = t.getNumber(self, t) - #pet.bestial_traits
		if ct >= 1 then
			local tt = pet:getTalentTypeFrom("race/traits")	
			local traits = {}
			for _, t in ipairs(tt.talents) do
				if not pet:knowTalent(t.id) then
					traits[#traits+1] = t.id
				end
			end
			for i = 1, ct do
				pet.bestial_traits[i] = rng.tableRemove(traits)
			end
		end
		learnTraits(pet)
		if not pet.unused_traits then pet.unused_traits = 0 end
		local last = self.talents_learn_vals[t.id] and self.talents_learn_vals[t.id].last or 0
		if pet then
			local increase = t.getTraitPoints(self, t)-last
			pet.unused_traits = pet.unused_traits + increase
		end
		self:updateTalentPassives(t)
	end,
	passives = function(self, t, p)
		p.last = t.getTraitPoints(self, t)
	end,
	info = function(self, t)
		local number = t.getNumber(self, t)
		local trait_points = t.getTraitPoints(self, t)
		return ([[As you and your beast gain experience, you become sensitive to the traits or latent abilities specific to your beast, to which a lesser handler would be unawares. It takes a full level of experience with your beast and no other to attain this depth of understanding.

			Currently, you may level %d of a maximum of 4 bestial traits, and gain a total of %d "trait points" you may apply specifically to levels in these trait talents.]]):
		format(number, trait_points)
	end,
	getNumber = function(self, t) return math.round(math.min(4, self:combatTalentScale(t, 2, 3.5))) end,
	getTraitPoints = function(self, t) return math.round(self:combatTalentScale(t, 1, 8, .85)) end,
}

newTalent{
	name = "Twin Threat",
	type = {"mounted/beast-heart", 3},
	require = mnt_wil_req3,
	mode = "sustained",
	points = 5,
	sustain_stamina = 100,
	cooldown = 10,
	activate = function(self, t)
		return {}
	end,
	deactivate = function(self, t, p)
		t.removeAllEffects(self, t)
		return true
	end,
	removeAllEffects= function(self, t, exclude)
		if not exclude then exclude = {} end
		for _, eff_id in pairs(t.effects) do
			if not exclude[eff_id] then
				self:removeEffect(eff_id, nil, true)
			end
		end
	end,
	callbackOnAct = function(self, t)
		local mount = self:hasMount()
		if not mount then self:forceUseTalent(t.id, {no_energy=true}) return nil end
		local dist = core.fov.distance(self.x, self.y, mount.x, mount.y)
		if dist == 0 then
			if not self:hasEffect(t.effects.mounted) then
				self:setEffect(t.effects.mounted, 2, {chance=t.getChance(self, t)})
			end
		elseif dist == 1 then
			if not self:hasEffect(t.effects.adjacent) then
				self:setEffect(t.effects.adjacent, 2, {heal_mod=t.getHealMod(self, t), regen=t.getRegen(self, t)})
			end
		elseif dist <= 5 then
			if not self:hasEffect(t.effects.mid) then
				self:setEffect(t.effects.mid, 2, {move=t.getMove(self, t), cooldown=t.getCooldownPct(self, t)})
			end
		elseif dist > 5 then
			if not self:hasEffect(t.effects.long) then
				self:setEffect(t.effects.long, 2, {regen=t.getRegenOnShot(self, t), life_total=t.getLifeTotal(self, t)})
			end
		end
	end,
	effects = {mounted="EFF_TWIN_THREAT_MOUNTED",
		adjacent="EFF_TWIN_THREAT_ADJACENT",
		mid="EFF_TWIN_THREAT_MID",
		long="EFF_TWIN_THREAT_LONG"
	},
	info = function(self, t)
		local chance = t.getChance(self, t)
		--
		local heal_mod = t.getHealMod(self, t)
		local regen = t.getRegen(self, t)
		--
		local move = t.getMove(self, t)
		local cooldown_pct = t.getCooldownPct(self, t)
		--
		local regen_on_shot = t.getRegenOnShot(self, t)
		local life_total = t.getLifeTotal(self, t)
		return ([[When you and your beast ride together, your physical critical hits grant a %d%% chance for your beast to attack again.

			When you and your beast fight adjacent to one another, increase your healing modifiers by %d%%, and regain Stamina and Loyalty at a rate of %.1f per turn.

			When you and your beast fight at mid range (up to 5 squares apart from one another) you are ready to exploit any opening, gaining %d%% movement speed and %d%% reduced cooldowns in any techniques talent tree.

			When you and your beast fight at long range (up to 10 squares apart) you pay close attention to one anothers' stratagems. All attacks that hit enemies within range 1 of your beast will regenerate its Loyalty by %d, and when your beast falls to %d%% of its total life, you may hasten to its side using a desperate dash.]]):
			format(chance, heal_mod, regen, move, cooldown_pct, regen_on_shot, life_total)
	end,
	getChance = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getHealMod = function(self, t) return self:combatTalentScale(t, 10, 30) end,
	getRegen = function(self, t) return self:combatTalentScale(t, 1, 3) end,
	getMove = function(self, t) return self:combatTalentScale(t, 20, 45) end,
	getCooldownPct = function(self, t) return self:combatTalentScale(t, 7, 20) end,
	getRegenOnShot = function(self, t) return self:combatTalentScale(t, 1.5, 3.5) end,
	getLifeTotal = function(self, t) return self:combatTalentLimit(t, 50, 10, 35) end,
}

newTalent{
	name = "Twin Hearts",
	short_name = "TWIN_THREAT_DASH",
	type = {"mounted/mounted-base", 1},
	points = 1,
	cooldown = 6,
	range = 10,
	no_energy=true,
	getHealMod = function(self, t) return math.round(self:combatTalentScale(t, 5, 20), 5) end,
	getDam = function(self, t) return self:combatTalentScale(1, 1.2, 1.75) end,
	getRegen = function(self, t) return 1 + self:getTalentLevel(t) end,
	getThreshold = function(self,t) return 10 + self:getTalentLevel(t) * 2.5 end,
	on_pre_use = function(self, t, silent)
		local ret = preCheckHasMountPresent(self, t, silent)
		if ret then 
			local t2 = self:getTalentFromId(self.T_TWIN_THREAT)
			local mount = self:hasMount()
			if mount.life > mount.max_life*t2.getLifeTotal(self, t)/100 then
				if not silent then 
					game.logPlayer(self, "Your mount must be close to death before you can use Twin Hearts!")
				end
				return false
			end
		end
		return ret
	end,
	action = function(self, t)
		local pet = self:hasMount()
		--TODO: This will be improved once target filtering is properly sorted out.
		--(What's up with that anyway? I just want to restrict targeting to a radius 1-ball of squares some distance from the user)
		local tg = {type="hit", range=10}
		local x, y, target = self:getTarget(tg)
		if not x or not y or target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		if core.fov.distance(pet.x, pet.y, x, y) > 1 then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local linestep = self:lineFOV(x, y, block_actor)
		
		local tx, ty, lx, ly, is_corner_blocked 
		repeat  -- make sure each tile is passable
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = linestep:step()
		until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
		if not tx or core.fov.distance(self.x, self.y, tx, ty) < 1 then
			game.logPlayer(self, "You are too close to build up momentum!")
			return
		end
		if not tx or not ty or core.fov.distance(x, y, tx, ty) > 1 then return nil end

		local ox, oy = self.x, self.y
		self:move(tx, ty, true)
		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(ox, oy, 8, 5)
		end

		return true
	end,
	info = function(self, t)
		local t2 = self:getTalentFromId(self.T_TWIN_THREAT)
		local life_total = t2.getLifeTotal(self, t)
		return ([[Fighting at long range, your Twin Threat allows you to dash into a space adjacent to your mount as an instant action, but only when it is at less than %d%% of its max health!]]):
		format(life_total)
	end
}

newTalent{
	name = "Bond Beyond Blood",
	type = {"mounted/beast-heart", 4},
	points = 5,
	require = mnt_wil_req4,
	cooldown = 30,
	action = function(self, t)
		self:setEffect(self.EFF_BOND_BEYOND_BLOOD, t.getDur(self, t), {loyalty_discount=t.getLoyaltyDiscount(self, t), res=t.getResist(self, t)})
		return true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local loyalty_discount = t.getLoyaltyDiscount(self, t)
		local res = t.getResist(self, t)
		return ([[You and your mount act as one, allowing you to switch between control of yourself and your mount at will for %d turns. While this talent is in effect, your mount loses loyalty at a reduced rate; all loyalty costs are reduced by %d%%.

			While controlling your mount, incoming damage to you is reduced by %d%%.

			Each enemy slain by you or your mount adds 1 to the duration of Bond Beyond Blood.]]):
			format(dur, loyalty_discount, res)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 5, 12) end,
	getLoyaltyDiscount = function(self, t) return self:combatTalentLimit(t, 75, 20, 50) end,
	getResist = function(self, t) return self:combatTalentLimit(t, 100, 40, 70) end,
}