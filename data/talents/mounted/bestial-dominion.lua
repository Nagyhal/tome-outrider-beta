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
local Chat = require "engine.Chat"

local mounts_list = {
	wolf = {
		base = "BASE_NPC_CANINE",
		type = "animal", subtype = "canine",
		name = "wolf",
		display = "C", color=colors.LIGHT_DARK, image = "npc/summoner_wardog.png",
		combat = { dam=resolvers.levelup(9, 1, 0.9), atk=5, apr=4}, --{ dam=resolvers.levelup(resolvers.mbonus(45, 20), 1, 1), atk=15, apr=10, dammod={str=0.8} },
		body = { INVEN = 10},
		life_rating = 12,
		rank = 1,
		size_category = 2,
		autolevel = "warrior",
		ai = "tactical", ai_state = { ai_move="move_dmap", talent_in=2, },
		ai_state = { talent_in=1, ai_move="move_astar", ally_compassion=10 },
		ai_tactic = resolvers.tactic("tank"),
		life_rating = 10,
		global_speed_base = 1.2,
		desc = [[A large and sturdy wolf, this one seems to have some greater cunning or purpose about it.]],
		resolvers.nice_tile{image="invis.png", color=colors.UMBER, image="npc/canine_w.png"},
		max_life = 100,
		level_range = {1, nil}, exp_worth = 0,
		combat_armor = 1, combat_def = 3,
		talents_types = {
			["wolf/tenacity"] = true,
			["wolf/pack-hunter"] = true,
		},
		gainExp = function() end,
		unused_stats = 0,
		unused_talents = 0,
		unused_generics = 0,
		unused_talents_types = 0,
		mount = {
			loyalty = 100,
			share_damage = 0.4
		}
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
		combat = { dam=resolvers.levelup(9, 1, 1), atk=8, apr=8 },
		body = { INVEN = 10},
		rank = 1,
		size_category = 3,
		autolevel = "rogue",
		ai = "tactical", 
		ai_state = { talent_in=1, ai_move="move_astar", ally_compassion=10 },
		ai_tactic = resolvers.tactic("melee"),
		global_speed_base = 1.0,
		resolvers.nice_tile{image="invis.png", color=colors.UMBER, image="npc/spiderkin_spider_giant_spider.png"},
		level_range = {1, nil}, exp_worth = 0,
		talents_types = {
			["wolf/tenacity"] = true,
			["wolf/pack-hunter"] = true,
		},
		gainExp = function() end,
		talents_types = {
			["spider/stalker-in-the-shadows"] = true,
		},
		unused_stats = 0,
		unused_talents = 0,
		unused_generics = 0,
		unused_talents_types = 0,
		mount = {
			loyalty = 90,
			share_damage = 0.5
		},
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
	local m = require "mod.class.NPC".new(mounts_list.spider)
	return m
end

function mountSetupSummon(self, m, x, y, no_control)
	m.can_mount = true
	m.mount_data = {
	base_loyalty = 100,
	loyalty_loss_coeff = 1,
	loyalty_regen_coeff = 1,
	share_damage = 50
	}
	m.faction = self.faction
	m.unused_stats = 30
	m.unused_talents = 30
	m.unused_generics = 0
	m.unused_talents_types = 0
	m.no_inventory_access = true
	m.no_points_on_levelup = false
	m.save_hotkeys = true
	m.ai_state = m.ai_state or {}
	m.ai_state.tactic_leash = 10
	-- Try to use stored AI talents to preserve tweaking over multiple summons
	m.ai_talents = self.stored_ai_talents and self.stored_ai_talents[m.name] or {}
	local main_weapon = self:getInven("MAINHAND") and self:getInven("MAINHAND")[1]
	m:attr("combat_apr", self:combatAPR(main_weapon))
	m.inc_damage = table.clone(self.inc_damage, true)
	m.resists_pen = table.clone(self.resists_pen, true)
	m:attr("stun_immune", self:attr("stun_immune"))
	m:attr("blind_immune", self:attr("blind_immune"))
	m:attr("pin_immune", self:attr("pin_immune"))
	m:attr("confusion_immune", self:attr("confusion_immune"))
	m:attr("numbed", self:attr("numbed"))
	if game.party:hasMember(self) then
		local can_control = not no_control
		m.remove_from_party_on_death = true
		game.party:addMember(m, {
			control=can_control and "full" or "no",
			type="mount",
			title="Mount",
			orders = {target=true, leash=true, anchor=true, talents=true},
			on_control = function(self)
				-- local summoner = self.summoner
				-- self:setEffect(self.EFF_SUMMON_CONTROL, 1000, {incdur=2 + summoner:getTalentLevel(self.T_CHALLENGE_THE_WILDS) * 3, res=summoner:getCun(7, true) * summoner:getTalentLevelRaw(self.T_CHALLENGE_THE_WILDS)})
				-- self:hotkeyAutoTalents()
			end,
			on_uncontrol = function(self)
				self:removeEffect(self.EFF_SUMMON_CONTROL)
			end,
		})
	end

	m:forceLevelup(self.level)
	m:resolve() m:resolve(nil, true)
	game.zone:addEntity(game.level, m, "actor", x, y)
	game.level.map:particleEmitter(x, y, 1, "summon")

	-- Summons never flee
	m.ai_tactic = m.ai_tactic or {}
	m.ai_tactic.escape = 0

	--Bind rider to mount
	self.mounts_owned = self.mounts_owned or {}
	self.mounts_owned[#self.mounts_owned+1] = m
	m.show_owner_loyalty_pool = true
	--Other mount stuff
	if self:knowTalent(self.T_FERAL_AFFINITY) then
		m:learnTalent(m.T_FERAL_AFFINITY_MOUNT, true, 1)
	end
	--Mount used for Mounted Combat abilities, TODO: Consider making this more modular for multiple mounts owned
	self.outrider_pet = m
end

newTalent{
	name = "Challenge the Wilds",
	type = {("mounted/bestial-dominion"), 1},
	require = mnt_str_req1,
	points = 5,
	cooldown = 50,
	stamina = 50,
	no_npc_use = true,
	range = 10,
	requires_target = true,
--	action = function (self, t)
--		if not self.mount and if not **CHALLENGE** then
	tactical = { BUFF = 5 },
	target = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, talent=t}
		return tg
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local tx, ty = self:getTarget(tg)
		if not tx or not ty then return nil end
		local _ _, tx, ty = self:canProject(tg, tx, ty)
		target = game.level.map(tx, ty, Map.ACTOR)
		if target == self then target = nil end

		-- Find space
		local x, y = tx, ty
		
		local m = makeBestialMount(self, self:getTalentLevel(t))
		m.summoner = self
		mountSetupSummon(self, m, x, y, false)
		self:mountTarget(m)

		-- local m = NPC.new{
			-- type = "animal", subtype = "canine",
			-- display = "C", color=colors.LIGHT_DARK, image = "npc/summoner_wardog.png",
			-- name = "doggy", faction = self.faction,
			-- desc = [[]],
			-- autolevel = "none",
			-- ai = "summoned", ai_real = "dumb_talented_simple", ai_state = { talent_in=5, },
			-- stats = {str=0, dex=0, con=0, cun=0, wil=0, mag=0},
			-- inc_stats = { str=15 + (self:getCun(130, true) * self:getTalentLevel(t) / 5) + (self:getTalentLevel(t) * 2), dex=10 + self:getTalentLevel(t) * 2, mag=5, con=15},
			-- level_range = {self.level, self.level}, exp_worth = 0,
			-- global_speed = 1.2,

			-- max_life = resolvers.rngavg(25,50),
			-- life_rating = 6,
			-- infravision = 10,

			-- combat_armor = 2, combat_def = 4,
			-- combat = { dam=self:getTalentLevel(t) * 10 + rng.avg(12,25), atk=10, apr=10, dammod={str=0.8} },

			-- summoner = self, summoner_gain_exp=true, wild_gift_summon=false,
			-- summon_time = math.ceil(self:getTalentLevel(t)*5) + 5,
			-- ai_target = {actor=target}
		-- }		

		--game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	--Handle sharing of inscriptions here.
	callbackOnTalentPost = function(self, t, ab, ret, silent)
		-- if ab.tactical and (ab.tactical.attack or ab.tactical.attackarea or ab.tactical.disable) then return end
		local mount = self.outrider_pet
		local max_dist = self:callTalent(self.T_FERAL_AFFINITY, "getMaxDist") or 1
		if mount and core.fov.distance(self.x, self.y, mount.x, mount.y)<max_dist and string.find(ab.type[1],  "inscriptions") then
			old_fake = mount.__inscription_data_fake
			local name = string.sub(ab.id, 3)
			mount.__inscription_data_fake = self.inscriptions_data[name]
			mount:forceUseTalent(ab.id, {no_energy=true, talent_reuse=true, no_talent_fail=true, silent=true})
			if old_fake then mount.__inscription_data_fake=old_fake end
		end
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)
		return ([[Your hurl your fury at the wilderness, letting out a luring, primal call and intensifying every one of your senses so that you might close upon a savage ally, a steed to carry you to victory and spoil. Finding a suitable wild mount takes time and effort; you gain the "Challenge the Wilds" status with a counter of %d, and every time you slay an enemy, that counter depletes by 1. As it approaches 0, your chances of happening upon your quarry are increased. The beast that is called will depend on your surroundings: either a wolf, agile and dependable; a spider, ruthless yet versatile; or a rare and mighty drake. You must subdue the beast by blade or bow; it will not come to your side immediately, but after you have asserted your dominance. Care must be taken not to slay it unwittingly. The quality of beast will increase with talent level.

			Levelling Bestial Dominion will also increase the physical power of your mount by %d.]])
		:format(math.ceil(self:getTalentLevel(t)*5) + 10, dam)
	end,
	getDam = function(self, t) return self:getTalentLevel(t) * 10 end,

}

newTalent{
	name = "Subdue The Beast",
	type = {"mounted/bestial-dominion", 2},
	require = mnt_str_req2,
	points = 5,
	cooldown = 50,
	-- tactical = { STAMINA = 2 },
	getRestore = function(self, t) return self:combatTalentScale(t, 20, 40) end,
	getMaxLoyalty = function(self, t) return math.round(self:combatTalentScale(t, 5, 15), 5) end,
	action = function(self, t)
		self:incLoyalty(t.getRestore(self, t)*self.max_loyalty/ 100)
		return true
	end,
	info = function(self, t)
		local restore = t.getRestore(self, t)
		local max_loyalty = t.getMaxLoyalty(self, t)
		return ([[With a mighty effort, you rein in your mount's feral tendencies, increasing its Loyalty by %d%% of its maximum. Also grants a passive increase of %d to maximum Loyalty with all mounts.

			As you master the domestication of wild riding beasts, you are able to still their fury long enough to inscribe them with infusions. You gain an infusion slot for your mount, and may gain others for each Bestial Dominion talent you raise to 5/5 (up to 3 slots).]]):
		format(restore, max_loyalty, max_dist)
	end,
}


newTalent{
	name = "Feral Affinity",
	type = {"mounted/bestial-dominion", 3},
	require = mnt_str_req3,
	mode = "passive",
	points = 5,
	passives = function(self, t, p)
		local mount = self.outrider_pet
		if mount then
			for damtype, val in pairs(mount.resists) do
				self:talentTemporaryValue(p, "resists", {[damtype]=val*t.getResistPct(self, t)})
			end
		end
	end,
	on_learn = function(self, t)
		local mount = self.outrider_pet
		if mount then
			mount:learnTalent(mount.T_FERAL_AFFINITY_MOUNT, true, 1)
		end
	end,
	info = function(self, t)
		local res = t.getResistPct(self, t)
		local save = t.getSavePct(self, t)
		local max_dist = t.getMaxDist(self, t)
		return ([[You share %d%% of the resistances of your steed, while your steed partakes of some of your own defenses against mental attacks (%d%% of your mindpower, contributing to mental save, and up to %d%% of your confusion & fear resistance).

			Levelling Feral Affinity will increase the distance at which you can share your infusions with your mount; currently %d]]
			):format(res, save, res, max_dist)
	end,
	getSavePct = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getResistPct = function(self, t) return self:combatTalentScale(t, 25, 50) end,
	getMaxDist = function(self, t) return math.round(self:combatTalentScale(t, 1, 4.2, .85)) end,
}

newTalent{
	name = "Feral Affinity (Mount)",
	short_name = "FERAL_AFFINITY_MOUNT",
	type = {"technique/other", 1},
	mode = "passive",
	points = 1,
	passives = function(self, t, p)
		--TODO: These need to be updated frequently
		local owner = self.summoner
		if owner then
			local save_pct = owner:callTalent(owner.T_FERAL_AFFINITY, "getSavePct")/100
			local resist_pct = owner:callTalent(owner.T_FERAL_AFFINITY, "getResistPct")/100
			local save = owner:combatMindpower()*save_pct
			self:talentTemporaryValue(p, "combat_mentalresist", save)
			local confusion = (owner:attr("confusion_immune") or 0) * resist_pct
			local fear = (owner:attr("fear_immune") or 0) * resist_pct
			local sleep = (owner:attr("sleep_immune") or 0) * resist_pct
			self:talentTemporaryValue(p, "confusion_immune", confusion)
			self:talentTemporaryValue(p, "fear_immune", fear)
			self:talentTemporaryValue(p, "sleep_immune", sleep)
		end
	end,
	info = function(self, t)
		local res = t.getResistPct(self, t)
		local save = t.getSavePct(self, t)
		local max_dist = t.getMaxDist(self, t)
		return ([[You share some of your rider's defenses against mental attacks (%d%% of mindpower, contributing to mental save, and up to %d%% of your confusion, sleep & fear resistance).

			Levelling Feral Affinity will increase the distance at which you can share your infusions with your mount; currently %d]]
			):format(res, save, res, max_dist)
	end,
	getSavePct = function(self, t) return self:combatTalentScale(t, 25, 50) end,
	getResistPct = function(self, t) return self:combatTalentScale(t, 35, 60) end,
	getMaxDist = function(self, t) return math.round(self:combatTalentScale(t, 1, 4.2, .85)) end,
}