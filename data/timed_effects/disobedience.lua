-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2019 Nicolas Casalini
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

local Particles = require "engine.Particles"

newEffect{
	name = "OUTRIDER_RILED_UP", image = "talents/panic.png",
	desc = "Riled Up",
	long_desc = function(self, eff) return ("The beast has become riled up and has a %d%% chance to rage against its target instead of obeying any commands."):format(eff.chance) end,
	type = "mental",
	subtype = { tactic=true, disobedience=true },
	status = "detrimental",
	parameters = {chance=50},
	callbackOnActBase = function(self, eff)
		if eff.target then
			if eff.target.dead or not game.level:hasEntity(eff.target) then
				eff.target = nil
				self:runAI("target_mount")
				eff.target = table.get(self.ai_target, "actor")
			end
		end
	end,
	on_gain = function(self, err) return "#F53CBE##Target# becomes riled up!", "+Riled Up" end,
	on_lose = function(self, err) return "#Target# is no longer riled up", "-Riled Up" end,
	--Logic is handled in the AI
	activate = function(self, eff)
		self:addShaderAura("riled_up", "awesomeaura", {time_factor=4000, alpha=0.65,  flame_scale=1.1}, "particles_images/bloodwings.png")
	end,
	deactivate = function(self, eff)
		self:removeShaderAura("riled_up")
	end,
}

newEffect{
	name = "OUTRIDER_SKITTISH", image = "talents/panic.png",
	desc = "Skittish",
	long_desc = function(self, eff) return ("The beast has become skittish and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	subtype = { fear=true, disobedience=true },
	status = "detrimental",
	parameters = {chance=33},
	on_gain = function(self, err) return "#F53CBE##Target# becomes skittish!", "+Skittish" end,
	on_lose = function(self, err) return "#Target# is no longer skittish", "-Skittish" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "terrified", eff.chance)
		self:addShaderAura("skittish", "awesomeaura", {time_factor=4000, alpha=0.6,  flame_scale=0.9}, "particles_images/coldwings.png")
	end,
	deactivate = function(self, eff)
		self:removeShaderAura("skittish")
	end,
}

newEffect{
	name = "OUTRIDER_OBSTINATE", image = "talents/panic.png",
	desc = "Obstinate",
	long_desc = function(self, eff) return ("The beast has become obstinate and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	lists = "outrider_disobedience",
	subtype = { fear=true },
	status = "detrimental",
	parameters = {chance=20},
	on_gain = function(self, err) return "#F53CBE##Target# becomes obstinate!", "+Obstinate" end,
	on_lose = function(self, err) return "#Target# is no longer obstinate", "-Obstinate" end,
	activate = function(self, eff)
		eff.particlesId = self:addParticles(Particles.new("fear_violet", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particlesId)
	end,
}

newEffect{
	name = "OUTRIDER_FRENZIED", image = "talents/panic.png",
	desc = "Frenzied",
	long_desc = function(self, eff) return ("The beast has become frenzied and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	lists = "outrider_disobedience",
	subtype = { fear=true },
	status = "detrimental",
	parameters = {chance=20},
	on_gain = function(self, err) return "#F53CBE##Target# becomes frenzied!", "+Frenzied" end,
	on_lose = function(self, err) return "#Target# is no longer frenzied", "-Frenzied" end,
	activate = function(self, eff)
		eff.particlesId = self:addParticles(Particles.new("fear_violet", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particlesId)
	end,
}

newEffect{
	name = "OUTRIDER_TERROR-STRICKEN", image = "talents/panic.png",
	desc = "Terror-Stricken",
	long_desc = function(self, eff) return ("The beast has become terror-stricken and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	lists = "outrider_disobedience",
	subtype = { fear=true },
	status = "detrimental",
	parameters = {chance=20},
	on_gain = function(self, err) return "#F53CBE##Target# becomes terror-Stricken!", "+Terror-Stricken" end,
	on_lose = function(self, err) return "#Target# is no longer terror-Stricken", "-Terror-Stricken" end,
	activate = function(self, eff)
		eff.particlesId = self:addParticles(Particles.new("fear_violet", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particlesId)
	end,
}

newEffect{
	name = "OUTRIDER_DEFIANT", image = "talents/panic.png",
	desc = "Defiant",
	long_desc = function(self, eff) return ("The beast has become defiant and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	lists = "outrider_disobedience",
	subtype = { fear=true },
	status = "detrimental",
	parameters = {chance=20},
	on_gain = function(self, err) return "#F53CBE##Target# becomes defiant!", "+Defiant" end,
	on_lose = function(self, err) return "#Target# is no longer defiant", "-Defiant" end,
	activate = function(self, eff)
		eff.particlesId = self:addParticles(Particles.new("fear_violet", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particlesId)
	end,
}