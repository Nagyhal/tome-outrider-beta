newTalent{
	name = "Lord of War",
	short_name="OUTRIDER_WARBANNER", image="talents/warbanner.png",
	type = {"mounted/warbanner", 1},
	require = mnt_wilcun_req_high1,
	no_npc_use = true,
	points = 5,
	cooldown = 50,
	tactical = { BUFF = 4 },
	action = function(self, t)
		-- @todo This is going to require a great deal of bother to implement,
		-- @todo which is why I won't have this ready at launch.

		-- @todo A banner graphic
		-- @todo An interface to create & customize your banner
		-- @todo A routine to create heroes 
		-- @todo A dialog for choosing the heroes at the beginning of each zone
		-- @todo A reminder for players who haven't hired to do so

		-- I can safely say that this talent alone is more complex to implement
		-- than many classes!
	end,
	info = function(self, t)
		local heroes = t.getHeroes(self, t)
		local discount = t.getDiscount(self, t)
		local chance = t.getBonusChance(self, t)
		return ([[Ride with the Beastlord's Warbanner - first, choose a design and set of colors to spread your glory. Now, in each zone, you can hire warriors to journey with you as you ride. Heroes will also join with you after your victories. At this talent level, you have a choice of %d heroes per zone. It will cost 200 gold on average (current discount: %d%%) to add a hero to your war troupe, but different heroes have their own price. They will not adventure with you constantly, fighting every small wild animal along the way; rather, you can summon them once per floor, plus a %d%% chance to gain a bonus summon.]]):
		format(heroes, discount, chance)
	end,
	getHeroes = function(self,t) return self:combatTalentScale(t, 2, 4) end,
	getBonusChance = function(self,t)
		if self:getTalentLevel(t) <= 5 then
			return self:combatTalentScale(t, 10, 75)
		else
			return self:combatTalentLimit(t, 95, 10, 75)
		end
	end,
	getDiscount = function(self,t)
		local mod = self:getTalentTypeMastery(t.type[1])
		local tl = self:getTalentLevel(t) - mod --Start from TL 2
		local base = tl<=5 and self:combatTalentScale(tl, 10, 33) or
			self:combatTalentLimit(tl, 66, 10, 33)
		return tl>0 and base or 0
	end,
}

newTalent{
	name = "Bannerlord's Warshout",
	short_name = "OUTRIDER_BANNERLORDS_WARSHOUT", image = "talents/bannerlords_warshout.png",
	type = {"mounted/warbanner", 2},
	require = mnt_wilcun_req_high2,
	points = 5,
	cooldown = 7,
	stamina = 20,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false}
	end,
	requires_target = true,
	tactical = { ATTACKAREA = { PHYSICAL = 2 } },
	getdamage = function(self,t) return self:combatScale(self:getTalentLevel(t) * self:getStr(), 60, 10, 267, 500)  end,
	action = function(self, t)
		-- @todo Change this talent from just being Shattering Shout!
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.PHYSICAL, self:physicalCrit(t.getdamage(self,t)))
		if self:getTalentLevel(t) >= 5 then
			self:project(tg, x, y, function(px, py)
				local proj = game.level.map(px, py, Map.PROJECTILE)
				if not proj then return end
				proj:terminate(x, y)
				game.level:removeEntity(proj, true)
				proj.dead = true
				self:logCombat(proj, "#Source# shatters '#Target#'.")
			end)
		end
		game.level.map:particleEmitter(self.x, self.y, self:getTalentRadius(t), "directional_shout", {life=8, size=2, tx=x-self.x, ty=y-self.y, distorion_factor=0.1, radius=self:getTalentRadius(t), nb_circles=8, rm=0.8, rM=1, gm=0.8, gM=1, bm=0.1, bM=0.2, am=0.6, aM=0.8})
		return true
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(t)
		local dur = t.getDur(self, t)
		local res = t.getRes(self, t)
		return ([[Yell in a %d cone, stunning your enemies's minds for %d turns as they catch sight of your banner, an omen of devastation to those who oppose you.

			Allies in view, emboldened by your warshout, also gain %d%% resistance to new effects for %d turns.]]):
		format(radius, dur, res, dur)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 2, 5) end,
	getRes = function(self, t) return self:combatTalentLimit(t, 85, 25, 50) end,
}

newTalent{
	name = "Wake of Dust",
	type = {"mounted/warbanner", 3},
	require = mnt_wilcun_req_high3,
	points = 5,
	cooldown = 25,
	no_energy = true,
	tactical = {
		-- prevent overuse out of combat
		BUFF = function(self, t) return self.ai_target.actor and 2 or 0 end,
		ATTACKAREA = function(self, t)
			if self:getTalentLevel(t)>=4 then return {PHYSICAL = 1 } end
		end
	},
	trigger = function(self, t, x, y, rad, eff) -- avoid stacking on map tile
		local oldmucus = eff and eff[x] and eff[x][y] -- get previous mucus at this spot
		if not oldmucus or oldmucus.duration <= 0 then -- make new mucus
			local mucus=game.level.map:addEffect(self,
				x, y, t.getDur(self, t),
				DamageType.MUCUS, {dam=t.getDamage(self, t), self_equi=t.getEqui(self, t), equi=1, bonus_level = 0},
				rad,
				5, nil,
				{zdepth=6, type="mucus"},
				nil, true
			)
			if eff then
				eff[x] = eff[x] or {}
				eff[x][y]=mucus
			end
		else
			if oldmucus.duration > 0 then -- Enhance existing mucus
				oldmucus.duration = t.getDur(self, t)
				oldmucus.dam.bonus_level = oldmucus.dam.bonus_level + 1
				oldmucus.dam.self_equi = oldmucus.dam.self_equi + 1
				oldmucus.dam.dam = t.getDamage(self, t) * (1+ self:combatTalentLimit(oldmucus.dam.bonus_level, 1, 0.25, 0.7)) -- Limit < 2x damage
			end
		end
	end,
	action = function(self, t)
		-- @todo Make this not Mucus.
		local dur = t.getDur(self, t)
		self:setEffect(self.EFF_MUCUS, dur, {})
		return true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local red = t.getReduction(self, t)
		local chance = t.getChance(self, t)
		return ([[Riders in your mounted warband kick up a trail of dust behind their bestial steeds, leaving your enemies to choke in your wake. For %d turns, while mounted, create a dust cloud in each tile you move through, along with a %d%% chance to affect an adjacent square. Enemies in the dust lose %d accuracy, %d defense and %d mental save; each square of dust reduces sight by 3, and lasts for 3-5 turns.]]):
		format(dur, chance, red, red, red)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 5, 8) end, -- Limit < 20
	getReduction = function(self, t) return self:combatTalentScale(t, 9, 20) end,
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 10, 35) end,
}

newTalent{
	name = "Dread Renown",
	short_name = "OUTRIDER_DREAD_RENOWN", image = "talents/dread_renown.png",
	type = {"mounted/warbanner", 4},
	points = 5,
	require = mnt_wilcun_req_high4,
	-- @todo Make this not Rogue's Tools
	cooldown = 10,
	stamina = 0, -- forces learning stamina pool (npcs)
	no_unlearn_last = true,
	on_pre_use = artifice_tools_setup,
	on_learn = function(self, t)
		self:attr("show_gloves_combat", 1)
	end,
	on_unlearn = function(self, t)
		self:attr("show_gloves_combat", -1)
	end,
	tactical = {BUFF = 2},
	on_pre_use_ai = artifice_tools_npc_select, -- NPC's automatically pick a tool
	action = function(self, t)
		local chat = Chat.new("artifice", self, self, {player=self, slot=1, chat_tid=t.id, tool_ids=artifice_tool_tids})
		local d = chat:invoke()
		d.key:addBinds{ EXIT = function()
			game:unregisterDialog(d)
		end}
		local tool_id, m_id = self:talentDialog(d)
		artifice_tools_setup(self, t)
		self:updateModdableTile()
		return tool_id ~= nil -- only use energy/cooldown if a tool was prepared
	end,
	info = function(self, t)
		local red = t.getReduction(self, t)
		local extra_red = t.getExtraReduction(self, t)
		local chance = t.getChance(self, t)
		return ([[As your renown spreads among the towns and cities of Eyal, you extract special privileges while stationed in them. Each talent level, choose a faction of sellers to gain favour with - for example swordsmiths, bow-makers or infusion-sellers. Your prices with them are reduced by %d%%. Each level, also upgrade your favour with one chosen merchant group, increasing it by a further %d%%.

		As your renown increases, merchants may seek to sell you rare goods to attain even greater standing in your eyes; gain a %.1f%% increased chance per item to find special artefacts in stores for each level of favour.]])
		:format(red, extra_red, chance)
	end,
	getReduction = function(self, t) return self:combatTalentLimit(t, 35, 20, 25) end,
	getExtraReduction = function(self, t) return t.getReduction(self, t)/2 end, -- Limit < 20
	getChance = function(self, t) return self:combatTalentLimit(t, 50, 1, 5) end,
}