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
	long_desc = function(self, eff) return ("The beast has become riled up and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	-- lists = "outrider_disobedience",
	subtype = { fear=true, disobedience=true },
	status = "detrimental",
	parameters = {chance=20},
	on_gain = function(self, err) return "#F53CBE##Target# becomes riled up!", "+Riled Up" end,
	on_lose = function(self, err) return "#Target# is no longer riled up", "-Riled Up" end,
	callbackOnActBase = function(self, eff)

	end,
	activate = function(self, eff)
		eff.particlesId = self:addParticles(Particles.new("fear_violet", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particlesId)
	end,
}

newEffect{
	name = "OUTRIDER_FLITFUL", image = "talents/panic.png",
	desc = "Flitful",
	long_desc = function(self, eff) return ("The beast has become flitful and has a %d%% chance to flee in terror instead of acting."):format(eff.chance) end,
	type = "mental",
	lists = "outrider_disobedience",
	subtype = { fear=true },
	status = "detrimental",
	parameters = {chance=20},
	on_gain = function(self, err) return "#F53CBE##Target# becomes flitful!", "+Flitful" end,
	on_lose = function(self, err) return "#Target# is no longer flitful", "-Flitful" end,
	activate = function(self, eff)
		eff.particlesId = self:addParticles(Particles.new("fear_violet", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particlesId)
	end,
	do_act = function(self, eff)
		if not self:enoughEnergy() then return nil end
		if eff.src.dead then return true end

		if rng.percent(eff.chance) then
			local distance = core.fov.distance(self.x, self.y, eff.src.x, eff.src.y)
			if distance <= eff.range then
				-- in range
				if not self:attr("never_move") then
					local sourceX, sourceY = eff.src.x, eff.src.y

					local bestX, bestY
					local bestDistance = 0
					local start = rng.range(0, 8)
					for i = start, start + 8 do
						local x = self.x + (i % 3) - 1
						local y = self.y + math.floor((i % 9) / 3) - 1

						if x ~= self.x or y ~= self.y then
							local distance = core.fov.distance(x, y, sourceX, sourceY)
							if distance > bestDistance
									and game.level.map:isBound(x, y)
									and not game.level.map:checkAllEntities(x, y, "block_move", self)
									and not game.level.map(x, y, Map.ACTOR) then
								bestDistance = distance
								bestX = x
								bestY = y
							end
						end
					end

					if bestX then
						self:move(bestX, bestY, false)
						game.logPlayer(self, "#F53CBE#You panic and flee from %s.", eff.src.name)
					else
						self:logCombat(eff.src, "#F53CBE##Source# panics but fails to flee from #Target#.")
						self:useEnergy(game.energy_to_act * self:combatMovementSpeed(bestX, bestY))
					end
				end
			end
		end
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