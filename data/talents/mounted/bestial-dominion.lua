-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

local mounts_list = {
	wolf = {
		base = "BASE_NPC_CANINE",
		type = "animal", subtype = "canine",
		name = "wolf",
		display = "C", color=colors.LIGHT_DARK, image = "npc/summoner_wardog.png",
		combat = { dam=resolvers.levelup(10, 1, 1.2), atk=10, apr=4, dammod={str=.6}}, --{ dam=resolvers.levelup(resolvers.mbonus(45, 20), 1, 1), atk=15, apr=10, dammod={str=0.8} },
		body = { INVEN = 10},
		life_rating = 12,
		rank = 1,
		size_category = 2,
		ai = "tactical", 
		ai_state = { talent_in=2, ally_compassion=0},
		ai_tactic = resolvers.tactic("melee"),
		-- ai_tactic = resolvers.talented_ai_tactic(), --this breaks things :(
		life_rating = 10,
		global_speed_base = 1,
		desc = [[A large and sturdy wolf, this one seems to have some greater cunning or purpose about it.]],
		resolvers.nice_tile{image="invis.png", color=colors.UMBER, image="npc/canine_w.png"},
		max_life = 100,
		level_range = {1, nil}, exp_worth = 0,
		combat_armor = 1, combat_def = 3,
		talents_types = {
			["wolf/tenacity"] = true,
			["wolf/pack-hunter"] = true,
		},
		unused_stats = 0,
		unused_talents = 0,
		unused_generics = 0,
		unused_talents_types = 0,
		mount_data = {
			loyalty = 100,
			share_damage = 0.4
		},
		max_inscriptions =1
	},
	spider = {	
		base = "BASE_NPC_SPIDER",
		type = "spiderkin", subtype = "spider",
		name = "giant spider", color=colors.DARK_GREY,
		display = "S", image = "npc/spiderkin_spider_giant_spider.png",
		desc = [[A jagged hulk of chitinous appendages and bristles. Its quick, tentative movement belies a great cunning.]],
		rarity = 1,
		max_life = 90,
		life_rating = 9,
		combat_armor = 5, combat_def = 5,
		combat = { dam=resolvers.levelup(7, 1, 1), atk=12, apr=8 },
		body = { INVEN = 10},
		rank = 1,
		size_category = 3,
		ai = "tactical", 
		ai_state = { talent_in=1, ai_move="move_complex"},
		ai_tactic = resolvers.tactic("melee"),
		global_speed_base = 1.0,
		resolvers.nice_tile{image="invis.png", color=colors.UMBER, image="npc/spiderkin_spider_giant_spider.png"},
		level_range = {1, nil}, exp_worth = 0,
		talents_types = {
			["spider/stalker-in-the-shadows"] = true,
		},
		unused_stats = 0,
		unused_talents = 0,
		unused_generics = 0,
		unused_talents_types = 0,
		mount_data = {
			loyalty = 90,
			share_damage = 0.5
		},
	},
	cold_drake = {
		base = "BASE_NPC_COLD_DRAKE",
		type="dragon", subtype="cold",
		name = "cold drake",
		display="D", color=colors.SLATE,  image = "npc/dragon_cold_cold_drake.png",
		desc = [[A mature cold drake, armed with deadly breath and nasty claws.]],
		rank = 1,
		size_category = 2,
		ai = "tactical", 
		ai_state = { talent_in=2, ally_compassion=0,  ai_move="move_complex"},
		ai_tactic = resolvers.tactic("melee"),
		life_rating = 11,
		max_life = 105,
		combat_armor = 12, combat_def = 0,
		combat = { dam=resolvers.levelup(20, 1, 1.2), atk=6, apr=12, dammod={str=1.1}, sound={"creatures/cold_drake/attack%d",1,2, vol=1} },
		on_melee_hit = {[DamageType.COLD]=resolvers.mbonus(15, 10)},
		lite = 1,
		level_range = {1, nil}, exp_worth = 1,

		sound_moam = {"creatures/cold_drake/on_hit%d", 1, 2, vol=1},
		sound_die = {"creatures/cold_drake/death%d", 1, 1, vol=1},

		talents_types = {
			["drake/dragonflight"] = true,
			["wild-gift/cold-drake"] = true,
		},
		unused_stats = 0,
		unused_talents = 0,
		unused_generics = 0,
		unused_talents_types = 0,
		mount_data = {
			loyalty = 100,
			share_damage = 0.4
		},
		max_inscriptions =1
	}
}

local function getBestialMountChances(self)
	return {wolf = 100, giant_spider=10}
end

local function makeBestialMount(self, lev)
	local chances = getBestialMountChances(self)
	local tot = 0
	local list = {}
	for k, e in pairs(chances) do for i = 1, e do list[#list+1] = k end tot = tot + e end
	local m = require "mod.class.NPC".new(mounts_list.wolf)
	return m
end

function befriendMount(self, m)
	m.summoner = self
	m.faction = self.faction
	if game.party:hasMember(self) then
		m.remove_from_party_on_death = true
		game.party:addMember(m, {
			control="no",
			type="mount",
			title="Mount",
			orders = {target=true, leash=true, anchor=true, talents=true},
			on_control = function(self)
				self.old_move_others = self.move_others
				self.move_others = true
			end,
			on_uncontrol = function(self)
				self.move_others = self.old_move_others
			end,
		})
	end
	--Mount used for Mounted Combat abilities, TODO: Consider making this more modular for multiple mounts owned
	self.outrider_pet = m
	m.owner = self
	m.summoner= self
	m.summoner_gain_exp = true
	-- Summons never flee
	m.ai_tactic.escape = 0
	m.ai_state = m.ai_state or {}
	m.ai_state.tactic_leash = 10
	m.ai_state.ai_move="move_astar"
	m.ai_state.ally_compassion=10
	m.ai_state.talent_in=1
	--Bind rider to mount
	self.mounts_owned = self.mounts_owned or {}
	self.mounts_owned[#self.mounts_owned+1] = m
	m.show_owner_loyalty_pool = true

	--Other mount stuff
	shareAllTalentsWithPet(self, m)
	self.unused_traits = 0
	if self:knowTalent(self.T_PRIMAL_BOND) then
		self:callTalent(self.T_PRIMAL_BOND, "on_learn")
	end
	m:resetToFull()
	--Loyalty
	if not self.base_max_loyalty then self.base_max_loyalty=100 end
	self.max_loyalty = self.max_loyalty + (m.mount_data.base_loyalty-self.base_max_loyalty)
	--Quest complete
	if self:isQuestStatus("outrider-start", engine.Quest.PENDING) then
		self:setQuestStatus("outrider-start", engine.Quest.COMPLETED)
	end
end

function mountSetupSummon(self, m, x, y, no_control)
	m.can_mount = true
	m.mount_data = {
	base_loyalty = 100,
	loyalty_loss_coeff = 1,
	loyalty_regen_coeff = 1,
	share_damage = 50
	}
	m.no_inventory_access = true
	m.no_points_on_levelup = false
	m.save_hotkeys = true
	-- Try to use stored AI talents to preserve tweaking over multiple summons
	-- m.ai_talents = self.stored_ai_talents and self.stored_ai_talents[m.name] or {}
	local main_weapon = self:getInven("MAINHAND") and self:getInven("MAINHAND")[1]
	m:attr("combat_apr", self:combatAPR(main_weapon))
	m.inc_damage = table.clone(self.inc_damage, true)
	m.resists_pen = table.clone(self.resists_pen, true)
	m:attr("stun_immune", self:attr("stun_immune"))
	m:attr("blind_immune", self:attr("blind_immune"))
	m:attr("pin_immune", self:attr("pin_immune"))
	m:attr("confusion_immune", self:attr("confusion_immune"))
	m:attr("numbed", self:attr("numbed"))
	m.gainExp = function() end
	m.forceLevelup = function(self) if self.summoner then return mod.class.Actor.forceLevelup(self, self.summoner.level) end end
	m.no_points_on_levelup = function(self)
		self.unused_stats = self.unused_stats + (self.level % 2==0  and 3 or 2)
		if self.level >= 2 and (self.level % 2 == 0) then self.unused_talents = self.unused_talents + 1 end
	end
	mod.class.Actor.forceLevelup(m, self.level)	
	m:resolve() m:resolve(nil, true)
	m:forceLevelup(self.level)
	game.zone:addEntity(game.level, m, "actor", x, y)
	game.level.map:particleEmitter(x, y, 1, "summon")
end

newTalent{
	name = "Challenge the Wilds",
	type = {("mounted/bestial-dominion"), 1},
	autolearn_talent = "T_INTERACT_MOUNT",
	require =  mnt_strwil_req1,
	points = 5,
	cooldown = 50,
	stamina = 50,
	no_npc_use = true,
	range = 10,
	tactical = { BUFF = 5 },
	on_pre_use = function(self, t, silent)
		if self:hasMount() then if not silent then game.logPlayer(self, "Use Challenge the Wilds when you seek a mount, not when you already have one.") end return false
		else
			local eff = self:hasEffect(self.EFF_WILD_CHALLENGE)
			if eff and eff.ct>0 then if not silent then game.logPlayer(self, "You must slay %d enemies before you may prove your might to the wilderness.", eff.ct) end return false 
			else return true
			end
		end
	end,
	callbackOnSummonDeath = function(self, t, summon, src, death_note)
		if summon ~= self.outrider_pet then return end
		for tid, nb in pairs(summon.talents) do
			local t2 = summon:getTalentFromId(tid)
			if t2.shared_talent then
				self:unlearnTalentFull(t2.shared_talent)
			end
		end
		if summon.inscription_objects then
			for name, o in pairs(summon.inscription_objects) do
				game.level:addEntity(o)
				game.level.map:addObject(summon.x, summon.y, o)
				o.auto_pickup = true
				summon.inscription_objects[name] = nil
				summon:unlearnTalent(summon["T_"..name])
			end
		end
		--Unset pet
		self.outrider_pet = nil
		self.max_loyalty = self.max_loyalty + (self.base_max_loyalty-summon.mount_data.base_loyalty)
	end,
	--Handle sharing of inscriptions here.
	callbackOnTalentPost = function(self, t, ab, ret, silent)
		-- if ab.tactical and (ab.tactical.attack or ab.tactical.attackarea or ab.tactical.disable) then return end
		local mount = self:hasMount(); if not mount then return end
		local max_dist = self:callTalent(self.T_FERAL_AFFINITY, "getMaxDist") or 1
		if core.fov.distance(self.x, self.y, mount.x, mount.y)<=max_dist and string.find(ab.type[1],  "inscriptions") then
			old_fake = mount.__inscription_data_fake
			local name = string.sub(ab.id, 3)
			mount.__inscription_data_fake = self.inscriptions_data[name]
			mount:forceUseTalent(ab.id, {no_energy=true, talent_reuse=true, no_talent_fail=true, silent=true})
			mount.__inscription_data_fake=old_fake
		end
	end,
	callbackOnLevelup = function(self, t, level)
		local pet = self.outrider_pet
		if pet then pet:forceLevelup(level) end
	end,
	action = function(self, t)
		if self:hasEffect(self.EFF_WILD_CHALLENGE) then
			t.doWarning(self, t)
			--No return values from dialogs?
		else
			local ct = self:isQuestStatus("outrider-start", engine.Quest.PENDING) and 10 or t.getNum(self, t)
			self:setEffect(self.EFF_WILD_CHALLENGE, 3, {ct=ct})
		end
		return
	end,
	doWarning = function (self, t)
		local Dialog = require "engine.ui.Dialog"
		local fct = function(ret)
			if not ret then return end
			t.doSummon(self, t)
			self:removeEffect(self.EFF_WILD_CHALLENGE, nil, true)
			self:startTalentCooldown(self.T_CHALLENGE_THE_WILDS)
			return true
		end
		return Dialog:yesnoLongPopup("Your quarry is near...", "You can feel your quarry stalking nearby - but it does not stalk alone. Moreover, letting out your Wild Challenge could bring threats greater than mere beasts upon you. If the time is not ripe or the area not primed for the hunt, then it is better you do not proceed.", 300, fct, "I am ready! RELEASE MY FURY!", "I need to prepare for my trial.")
	end,
	doSummon = function(self, t)
		--params: file, no_default, res, mod, loaded
		-- local npc_list = mod.class.NPC:loadList("data/general/npcs/canine.lua")
		local coords = {}
		local block = function(_, lx, ly) return game.level.map:checkAllEntities(lx, ly, "block_move") end
		self:project({type="ball", radius=10, block_radius=block, talent=t}, self.x, self.y, function(px, py)
			local a = game.level.map(px, py, engine.Map.ACTOR)
			local terrain = game.level.map(px, py, engine.Map.TERRAIN)
			if not a and not terrain.does_block_move then coords[#coords+1] = {px, py, core.fov.distance(self.x, self.y, px, py), rng.float(0,1)} end
		end)
		local f = function(a, b)
			if a[3]~=b[3] then return a[3] > b[3] else return a[4] < b[4] end
		end
		table.sort(coords, f)

		--TODO: Make this not crash if not enough room.
		local first = true
		for i=1, rng.range(6, 8) do
			if first then 
				local mount = makeBestialMount(self, self:getTalentLevel(t))
				mountSetupSummon(self, mount, coords[i][1], coords[i][2], true)
				mount:setEffect(mount.EFF_WILD_CHALLENGER, 2, {src=self})
			else
				if not coords[i] then return end
				local base_list=require("mod.class.NPC"):loadList("data/general/npcs/canine.lua")
				local filter = {base_list=base_list
				}

				local e = game.zone:makeEntity(game.level, "actor", filter)
				e.make_escort = nil
				e.exp_worth=0
				game.zone:addEntity(game.level, e, "actor", coords[i][1], coords[i][2])
			end

			first=false
		end
	end,
	doBefriendMount = function(self, t, mount)
		return befriendMount(self, mount)
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		local num = t.getNum(self, t)
		return ([[Your hurl your fury at the wilderness, letting out a luring, primal call and intensifying every one of your senses so that you might close upon a savage ally, a steed to carry you to victory and spoil. Finding a suitable wild mount takes time and effort; you gain the "Challenge the Wilds" status with a counter of %d, and every time you slay an enemy, that counter depletes by 1. When it reaches 0, you may activate Challenge the Wilds to call forth a beast worthy of your command. The beast that is called will depend on your surroundings: either a wolf, agile and dependable; a spider, ruthless yet versatile; or a rare and mighty drake. You must subdue the beast by blade or bow; it will not come to your side immediately, but after you have asserted your dominance. Care must be taken not to slay it unwittingly, and beware- it will not arrive alone. The quality of beast will increase with talent level.

			Levelling Bestial Dominion will also increase the physical power of your mount by %d.]])
		:format(num, dam)
	end,
	getDam = function(self, t) return self:getTalentLevel(t) * 10 end,
	getNum = function(self, t) return math.ceil(self:getTalentLevelRaw(t)*5) + 10 end,
}



newTalent{
	name = "Gruesome Depredation",
	type = {"mounted/bestial-dominion", 2},
	require = mnt_strwil_req2,
	points = 5,
	cooldown = 16,
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
			mount:logCombat(target, "#Source# devours the flesh of #Target#!")
			self:attr("allow_on_heal", 1)
			local heal = mount.max_life*t.getHeal(self, t)
			mount:heal(heal)
			if core.shader.active(4) then
				self:addParticles(Particles.new("shader_shield_temp", 1, {toback=false,size_factor=1.5, y=-0.3, img="healgreen", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=1.0}))
			end
			self:attr("allow_on_heal", -1)
		else
			mount:logCombat(target, "#Source# gains no life from Gruesome Depredation!")
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local loyalty = t.getLoyalty(self, t)
		local heal = t.getHeal(self, t)*100
		return ([[Your mount bites your enemy for %d%% damage. If this hits, then your mount's bite devours a great chunk of your enemy's carcass, restoring %d Loyalty and healing your mount for %d%% of its total life.]]):
			format(dam, loyalty, heal)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.8, 2.5) end,
	getLoyalty = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getHeal = function(self, t) return self:combatTalentLimit(t, .5, .1, .35) end
}

newTalent{
	name = "Subdue The Beast",
	type = {"mounted/bestial-dominion", 3},
	require = mnt_strwil_req3,
	points = 5,
	stamina = 30,
	cooldown = 50,
	-- tactical = { STAMINA = 2 },
	getRestore = function(self, t) return self:combatTalentScale(t, 20, 40) end,
	getMaxLoyalty = function(self, t) return math.round(self:combatTalentScale(t, 5, 15), 5) end,
	on_pre_use = function(self, t, silent)
		return preCheckHasMount(self, t, silent)
	end,
	action = function(self, t)
		self:incLoyalty(t.getRestore(self, t)*self.max_loyalty/ 100)
		return true
	end,
	info = function(self, t)
		local restore = t.getRestore(self, t)
		local max_loyalty = t.getMaxLoyalty(self, t)
		return ([[With a mighty effort, you rein in your mount's feral tendencies, recovering Loyalty equal to %d%% of its maximum. Also grants a passive increase of %d to maximum Loyalty with all mounts.

			As you master the domestication of wild riding beasts, you are able to still their fury long enough to inscribe them with infusions. You gain an infusion slot for your mount, and may gain others for each Bestial Dominion talent you raise to 5/5 (up to 3 slots).]]):
		format(restore, max_loyalty, max_dist)
	end,
}

newTalent{
	name = "Unbridled Ferocity",
	type = {"mounted/bestial-dominion", 4},
	points = 5,
	cooldown = function(self, t) return self:combatTalentLimit(t, 20, 50, 30) end,
	stamina = 50,
	require = mnt_strwil_req4,
	no_energy = true,
	tactical = { BUFF = 3 }, 
	on_pre_use = function(self, t, silent)
		return preCheckHasMountPresent(self, t, silent)
	end,
	action = function(self, t)
		local mount = self:hasMount()
		mount:setEffect(mount.EFF_UNBRIDLED_FEROCITY, t.getDur(self, t), {power=t.getPower(self, t), atk=t.getAtk(self, t), move=t.getMove(self, t)})
		return true
	end,
	info = function(self, t)
		local dur = t.getDur(self, t)
		local power = t.getPower(self, t)
		local atk = t.getAtk(self, t)
		local move_pct = t.getMove(self, t)*100
		return ([[You throw caution to the wind and let your bestial steed revel in the glory of the hunt, gaining a %d increase in physical power for %d turns, %d to accuracy, %d%% to move speed and not depleting but regaining Loyalty with each hit that it endures. However, if you fall from your beast while it is in this furious state, you will not be able to re-mount.]]):
		format(power, dur, atk, move_pct)
	end,
	getDur = function(self, t) return self:combatTalentScale(t, 4.75, 6, .35) end,
	getPower = function(self, t) return self:combatTalentScale(t, 10, 30) end,
	getAtk = function(self, t) return math.round(t.getPower(self, t)/2) end,
	getMove = function(self, t) return .5 end,
}
