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

-- Talent trees
newTalentType{ allow_random=true, type="mounted/mounted-base", name = "mounted - base", description = "Exercise your dominion over the wild beasts of Maj'Eyal."}
newTalentType{ allow_random=true, type="mounted/bestial-dominion", name = "bestial dominion", generic = true, description = "Exercise your dominion over the wild beasts of Maj'Eyal."}
newTalentType{ allow_random=true, type="mounted/mounted-mobility", name = "mounted mobility", generic = true, description = "Wresting mastery over your fleet pawed steed,  you dance the last dance with those not quick enough to match you."}
newTalentType{ allow_random=true, type="mounted/teamwork", name = "teamwork", description = "Wresting mastery over your fleet pawed steed, you dance the last dance with those not quick enough to match you."}
newTalentType{ allow_random=true, type="mounted/skirmish-tactics", name = "skirmish tactics", description = "Beside your beast, not even the winds can outpace your surging onslaught; atop it, not even the sky can outreach your aim."}
newTalentType{ allow_random=true, type="mounted/shock-tactics", name = "shock tactics", description = "Shattering your foes' ranks with devastating charge attacks, your shock tactics represent the pinnacle of mounted martial domination and the ultimate unison of steel and steed."}
newTalentType{ allow_random=true, type="mounted/beast-heart", name = "beast heart", description = "Become no longer beastrider, but beastbrother."}

--Mount talents
--Wolf, the basic mount, and its subtypes
newTalentType{ type="wolf/tenacity", name = "tenacity", description = "Wolf offensive abilities" }
newTalentType{ type="wolf/pack-hunter", name = "pack hunter", description = "Wolf cooperative abilities" }
newTalentType{ type="wolf/will-of-winter", name = "will of winter", description = "White wolf gifts" }
newTalentType{ type="wolf/alpha-predator", name = "alpha predator", description = "Wolf power abilities" }
--Spider, the basic underground / tactical mount
newTalentType{ type="spider/fanged-killer", name = "fanged killer", description = "Spider tactical abilities" }
newTalentType{ type="spider/lurking-menace", name = "lurking menace", description = "Spider tactical abilities" }
--Drakes, the basic power mount
newTalentType{ type="drake/dragonflight", name = "dragonflight", description = "Drake airborne abilities." }
--Griffins, secret aerial mount.
newTalentType{ type="griffin/wingborne-supremacy", name = "wingborne supremacy", description = "Griffin airborne abilities." }
--Dread steeds, undead / corrupted mount
newTalentType{ type="drake/dread-herald", name = "dread herald", description = "Dread steed basic abilities." }
--Treants, halfing mount
newTalentType{ type="treant/striding-canopy", name = "striding canopy", description = "Treant defensive abilities." }
--Minotaurs, halfling mount
newTalentType{ type="minotaur/rampaging-mazefarer", name = "rampaging mazefarer", description = "Minotaur navigational abilities." }
--Great elks, thalore mount
newTalentType{ type="great-elk/monarch-of-the-woods", name = "monarch of the woods", description = "Great elk defensive gifts." }
--Mammoths, thalore mount
newTalentType{ type="mammoth/thundering-colossus", name = "thundering colossus", description = "Mammoth utility abilities." }
--Shalore can ride exotic drakes
--Bears, dwarf mount
newTalentType{ type="bear/claw-and-crush", name = "claw and crush", description = "Bear power abilities." }
--Xorn, dwarf mount
newTalentType{ type="xorn/embodiment-of-stone", name = "xorn/embodiment of stone", description = "Xorn defensive and travel abilities." }
--Yeeks, yeek mount
newTalentType{ type="yeek/upholder-of-the-way", name = "upholder of the way", description = "Yeek cooperative abilities." }
--Ritch, yeek mount
newTalentType{ type="ritch/hive-sentinel", name = "hive sentinel", description = "Ritch cooperative power abilities." }


--technique
newTalentType{ allow_random=true, type="technique/dreadful-onset", name = "dreadful onset", description = "Far and wide, kingdoms shall quake at the onset of your terrible reign of blood, arrows and steel."}
newTalentType{ allow_random=true, type="technique/barbarous-combat", name = "barbarous combat", description = "Mounted or afoot, your brutal blademastery shall ravage legions."}

mnt_str_req1 = {
	stat = { str=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_str_req2 = {
	stat = { str=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_str_req3 = {
	stat = { str=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_str_req4 = {
	stat = { str=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}


mnt_str_req_high1 = {
	stat = { str=function(level) return 22 + (level-1) * 2 end },
	level = function(level) return 10 + (level-1)  end,
}
mnt_str_req_high2 = {
	stat = { str=function(level) return 30 + (level-1) * 2 end },
	level = function(level) return 14 + (level-1)  end,
}
mnt_str_req_high3 = {
	stat = { str=function(level) return 38 + (level-1) * 2 end },
	level = function(level) return 18 + (level-1)  end,
}
mnt_str_req_high4 = {
	stat = { str=function(level) return 46 + (level-1) * 2 end },
	level = function(level) return 22 + (level-1)  end,
}


mnt_wil_req1 = {
	stat = { wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_wil_req2 = {
	stat = { wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_wil_req3 = {
	stat = { wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_wil_req4 = {
	stat = { wil=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_cun_req1 = {
	stat = { cun=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_cun_req2 = {
	stat = { cun=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_cun_req3 = {
	stat = { cun=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_cun_req4 = {
	stat = { cun=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_dex_req1 = {
	stat = { dex=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_dex_req2 = {
	stat = { dex=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_dex_req3 = {
	stat = { dex=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_dex_req4 = {
	stat = { dex=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_wil_req_broad1 = {
	stat = { wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1) *5  end,
}
mnt_wil_req_broad2 = {
	stat = { wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1) *5 end,
}
mnt_wil_req_broad3 = {
	stat = { wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1) *5 end,
}
mnt_wil_req_broad4 = {
	stat = { wil=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1) *5 end,
}

mnt_strcun_req1 = {
	stat = { str=function(level) return 12 + (level-1) * 2 end, cun=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_strcun_req2 = {
	stat = { str=function(level) return 20 + (level-1) * 2 end, cun=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_strcun_req3 = {
	stat = { str=function(level) return 28 + (level-1) * 2 end, cun=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_strcun_req4 = {
	stat = { str=function(level) return 36 + (level-1) * 2 end, cun=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

mnt_dexwil_req1 = {
	stat = { dex=function(level) return 12 + (level-1) * 2 end, wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
mnt_dexwil_req2 = {
	stat = { dex=function(level) return 20 + (level-1) * 2 end, wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
mnt_dexwil_req3 = {
	stat = { dex=function(level) return 28 + (level-1) * 2 end, wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
mnt_dexwil_req4 = {
	stat = { dex=function(level) return 36 + (level-1) * 2 end, wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

-- Archery range talents
-- From techinques.
archery_range = function(self, t)
	local weapon = self:hasArcheryWeapon()
	if not weapon or not weapon.combat then return 1 end
	return weapon.combat.range or 6
end




--Calling /bestial/ mounts

--[[function mountSetupSummon(self, m, x, y, level, no_control)
	m.faction = self.faction
	m.summoner = self
	m.summoner_gain_exp = true
	m.necrotic_minion = true
	m.exp_worth = 0
	m.life_regen = 0
	m.unused_stats = 0
	m.unused_talents = 0
	m.unused_generics = 0
	m.unused_talents_types = 0
	m.silent_levelup = true
	m.no_points_on_levelup = true
	m.ai_state = m.ai_state or {}
	m.ai_state.tactic_leash = 100
	-- -- Try to use stored AI talents to preserve tweaking over multiple summons
	-- m.ai_talents = self.stored_ai_talents and self.stored_ai_talents[m.name] or {}
	m.inc_damage = table.clone(self.inc_damage, true)
	m.no_breath = 1

	if self:knowTalent(self.T_DARK_EMPATHY) then
		local t = self:getTalentFromId(self.T_DARK_EMPATHY)
		local perc = t.getPerc(self, t)
		for k, e in pairs(self.resists) do
			m.resists[k] = (m.resists[k] or 0) + e * perc / 100
		end
		m.combat_physresist = m.combat_physresist + self:combatPhysicalResist() * perc / 100
		m.combat_spellresist = m.combat_spellresist + self:combatSpellResist() * perc / 100
		m.combat_mentalresist = m.combat_mentalresist + self:combatMentalResist() * perc / 100

		m.poison_immune = (m.poison_immune or 0) + (self:attr("poison_immune") or 0) * perc / 100
		m.disease_immune = (m.disease_immune or 0) + (self:attr("disease_immune") or 0) * perc / 100
		m.cut_immune = (m.cut_immune or 0) + (self:attr("cut_immune") or 0) * perc / 100
		m.confusion_immune = (m.confusion_immune or 0) + (self:attr("confusion_immune") or 0) * perc / 100
		m.blind_immune = (m.blind_immune or 0) + (self:attr("blind_immune") or 0) * perc / 100
		m.silence_immune = (m.silence_immune or 0) + (self:attr("silence_immune") or 0) * perc / 100
		m.disarm_immune = (m.disarm_immune or 0) + (self:attr("disarm_immune") or 0) * perc / 100
		m.pin_immune = (m.pin_immune or 0) + (self:attr("pin_immune") or 0) * perc / 100
		m.stun_immune = (m.stun_immune or 0) + (self:attr("stun_immune") or 0) * perc / 100
		m.fear_immune = (m.fear_immune or 0) + (self:attr("fear_immune") or 0) * perc / 100
		m.knockback_immune = (m.knockback_immune or 0) + (self:attr("knockback_immune") or 0) * perc / 100
		m.stone_immune = (m.stone_immune or 0) + (self:attr("stone_immune") or 0) * perc / 100
		m.teleport_immune = (m.teleport_immune or 0) + (self:attr("teleport_immune") or 0) * perc / 100
	end

	if game.party:hasMember(self) then
		local can_control = not no_control

		m.remove_from_party_on_death = true
		game.party:addMember(m, {
			control=can_control and "full" or "no",
			type="minion",
			title="Bestial Mount",
			orders = {target=true},
		})
	end
	m:resolve() m:resolve(nil, true)
	m.max_level = self.level + (level or 0)
	m:forceLevelup(math.max(1, self.level + (level or 0)))
	game.zone:addEntity(game.level, m, "actor", x, y)
	game.level.map:particleEmitter(x, y, 1, "summon")

	-- Summons decay
	-- m.on_act = function(self)
		-- local src = self.summoner
		-- local p = src:isTalentActive(src.T_NECROTIC_AURA)
		-- if p and self.x and self.y and not src.dead and src.x and src.y and core.fov.distance(self.x, self.y, src.x, src.y) <= self.summoner.necrotic_aura_radius then return end

		-- self.life = self.life - self.max_life * (p and p.necrotic_aura_decay or 10) / 100
		-- self.changed = true
		-- if self.life <= 0 then
			-- game.logSeen(self, "#{bold}#%s decays into a pile of ash!#{normal}#", self.name:capitalize())
			-- local t = src:getTalentFromId(src.T_NECROTIC_AURA)
			-- t.die_speach(self, t)
			-- self:die(self)
		-- end
	-- end

	-- m.on_die = function(self, killer)
		-- local src = self.summoner
		-- local w = src:isTalentActive(src.T_WILL_O__THE_WISP)
		-- local p = src:isTalentActive(src.T_NECROTIC_AURA)
		-- if not w or not p or not self.x or not self.y or not src.x or not src.y or core.fov.distance(self.x, self.y, src.x, src.y) > self.summoner.necrotic_aura_radius then return end
		-- if not rng.percent(w.chance) then return end

		-- local t = src:getTalentFromId(src.T_WILL_O__THE_WISP)
		-- t.summon(src, t, w.dam, self, killer)
	-- end

	-- Summons never flee
	m.ai_tactic = m.ai_tactic or {}
	m.ai_tactic.escape = 0
end
-------------------------------------------]]

load("/data-outrider/talents/mounted/mounts.lua")
load("/data-outrider/talents/mounted/wolf.lua")
--load("/data-outrider/talents/mounted/spider.lua")
--load("/data-outrider/talents/mounted/drake.lua")
load("/data-outrider/talents/mounted/bestial-dominion.lua")
load("/data-outrider/talents/mounted/mounted-mobility.lua")
--load("/data-outrider/talents/mounted/teamwork.lua")
--load("/data-outrider/talents/mounted/skirmish-tactics.lua")
--load("/data-outrider/talents/mounted/shock-tactics.lua")
--load("/data-outrider/talents/mounted/beast-heart.lua")

--technique
load("/data-outrider/talents/techniques/barbarous-combat.lua")
load("/data-outrider/talents/techniques/dreadful-onset.lua")