-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2020 Nicolas Casalini
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

newTalent{
	name = "Set-up Shot", short_name = "OUTRIDER_SET_UP_SHOT", image = "talents/set_up_shot.png",
	type = {"mounted/skirmish-tactics", 2},
	points = 5,
	cooldown = function(self, t) return math.max(6, self:combatTalentScale(t, 8, 6)) end,
	require = techs_dex_req2,
	range = archery_range,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 } },
	on_pre_use = function(self, t, silent, fake) if not self:hasArcheryWeapon() then if not silent then game.logPlayer(self, "You require a bow or sling for this talent.") end return false end return true end,
	action = function(self, t)
		local targets = self:archeryAcquireTargets(nil, {one_shot=true})
		if not targets then return end
		self:archeryShoot(targets, t, nil, {})
		local target = targets[1]
		if not target then return true end
		local allies = {}
		for i = 0, 8 do
			local x = currentX + (i % 3) - 1
			local y = currentY + math.floor((i % 9) / 3) - 1
			local a = game.level.map(x, y, Map.ACTOR)
			if a and self:reactionToward(a) > 0  then
				local dam = t.getDam(self, t)
				a:attackTarget(target, nil, dam, true)

				game:playSoundNear(a, "actions/melee")
			end
		end
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100

		return ([[You shoot your enemy for 100%% damage, granting any adjacent alllies a free attack for %d%% damage. This shot consumes no stamina. Extra talent levels increase the ally damage and reduce the cooldown.]]):
		format(dam)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.7) end,
}

newTalent{
	name = "Animal Affinity", short_name = "OUTRIDER_FERAL_AFFINITY", image="talents/feral_affinity.png",
	type = {"mounted/teamwork", 2},
	require = mnt_wilcun_req2,
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
	shared_talent = "T_OUTRIDER_FERAL_AFFINITY_MOUNT",
	on_learn = function (self, t)
		local pet = self.outrider_pet
		if not pet then return end
		shareTalentWithPet(self, pet, t)
	end,
	on_unlearn = function(self, t)
		local pet = self.outrider_pet
		if not pet then return end
		if self:getTalentLevelRaw(t) == 0 then
			unshareTalentWithPet(self, pet, t)
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
	getMaxDist = function(self, t) return math.round(self:combatTalentScale(t, 2, 4.2, .85)) end,
}

newTalent{
	name = "Animal Affinity (Mount)", short_name = "OUTRIDER_FERAL_AFFINITY_MOUNT", image = "talents/feral_affinity.png",
	type = {"technique/other", 1},
	mode = "passive",
	points = 1,
	passives = function(self, t, p)
		--TODO: These need to be updated frequently
		local owner = self.summoner
		if owner then
			local save_pct = owner:callTalent(owner.T_OUTRIDER_FERAL_AFFINITY, "getSavePct")/100
			local resist_pct = owner:callTalent(owner.T_OUTRIDER_FERAL_AFFINITY, "getResistPct")/100
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

newTalent{
	name = "Brazen Lunge", short_name = "OUTRIDER_BRAZEN_LUNGE", image = "talents/brazen_lunge.png",
	type = {"mounted/barbarous-combat", 1},
	require = mnt_strcun_req1,
	points = 5,
	random_ego = "attack",
	stamina = function(self, t)
		return math.max(0.5, 7.5 - self:getTalentLevelRaw(t)*1.5)
	end,
	cooldown = 6,
	tactical = { ATTACK = 2 },
	requires_target = true,
	range = 2,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.5, 2.1) end,
	getStamina = function(self, t) return self:combatTalentScale(t, 3.8, 5.7) end,
	getDuration = function(self, t) return self:combatTalentScale(t, 2.7, 4) end,
	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return end
		self:attackTarget(target, nil, t.getDamage(self, t), true)
		self:setEffect(self.EFF_OUTRIDER_REGAIN_POISE, 2, {regen=t.getStamina(self, t)})
		return true
	end,
	info = function(self, t)
		return ([[Take a bold lunge at your foes, dealing %d%% melee weapon damage in a range of 2. Your over-extension incites your unwary targets to focus their attacks you for %d turns, all the while ignoring your allies.

			Toying with your opponents like that leaves you to re-assert control of the battlefield; if you can avoid weapon attacks for 2 turns, regain %.1f stamina per turn that you do so.]]):
		format(
		t.getDamage(self, t)*100,
		t.getDuration(self, t),
		t.getStamina(self, t)
		)
	end,
}


newTalent{
	name = "Rearing Assault", short_name = "READING_ASSAULT", image = "talents/rearing_assault.png",
	type = {"mounted/teamwork", 3},
	hide="always", --DEBUG: Hiding untested talents 
	points = 5,
	random_ego = "defensive",
	cooldown = 6,
	stamina = 6,
	loyalty= 3,
	require = mnt_wilcun_req3,
	requires_target = true,
	tactical = { ATTACK = 2 },
	on_pre_use = function(self, t, silent, fake)
		if self:isMounted() then
			if self:attr("never_move") then return false end
		else
			local mount = self:hasMount()
			if mount and mount:attr("never_move") then return false end
		end
		return preCheckHasMountPresent(self, t, silent, fake)
	end,
	target = function(self, t)
		local pet = self.outrider_pet
		local ret = {type="hit", range=self:getTalentRange(t), friendlyfire=false, selffire=false}
		if not self:isMounted() then
			ret = table.merge(ret, {start_x=pet.x, start_y=pet.y, default_target=pet, immediate_keys=false})
		end
		return ret
	end,
	action = function(self, t)
		local mount = self:hasMount()
		local mover = self:isMounted() and self or mount
		local tg = self:getTalentTarget(t)
		local x, y, target
		if mover==self then
			x, y, target = self:getTarget(tg)
		else
			game.target.target.x = mount.x
			game.target.target.y = mount.y
			x, y, target = autoPetTarget(self, mount)
			if not target then x, y, target = game:targetGetForPlayer(tg) end
		end
		if not x or not y or not target then return nil end
		if core.fov.distance(mount.x, mount.y, x, y) > 1 then return nil end

		local tx, ty, sx, sy = target.x, target.y, mount.x, mount.y
		local hitted = mount:attackTarget(target, nil, 0, true)
		if hitted and not mount.dead and tx == target.x and ty == target.y then
			if not mover:canMove(tx,ty,true) or not target:canMove(sx,sy,true) then
				mount:logCombat(target, "Terrain prevents #Source# from switching places with #Target#.")
				return true
			end
			mover:move(tx, ty, true)
			if not target.dead then
				target:move(sx, sy, true)
			end
			if core.fov.distance(self.x, self.y, target.x, target.y)==1 then
				local buff = t.getCrit(self, t)
				self.combat_physcrit = self.combat_physcrit+buff
				if self:hasArcheryWeapon() then
					tg = self:archeryAcquireTargets(tg, {x=target.x, y=target.y})
					self:archeryShoot(tg, t, nil, {})
				else
					self:attackTarget(target, nil, 1, true)
				end
				self.combat_physcrit = self.combat_physcrit-buff
			end
		end
		mover:resetMoveAnim()
		mover:setMoveAnim(sx, sy, 8, 5, 8, 3)
		return true
	end,
	info = function(self, t)
		local dam = t.getDam(self, t)*100
		local crit = t.getCrit(self, t)
		return ([[Your mount rears up and attacks your target for %d%% damage, while moving into its space; your mount and your foe will exchange places. If you are mounted, or adjacent to the target when the movement completes, then you follow up with a crushing strike or a focused shot with a %d%% increased critical modifier. You may also call upon your mount to use this while dismounted; this does not cost stamina.]]):
			format(dam, crit)
	end,
	getDam = function(self, t) return self:combatTalentScale(t, 1.2, 1.8) end,
	getCrit = function(self, t) return self:combatTalentScale(t, 6, 25) end,
}