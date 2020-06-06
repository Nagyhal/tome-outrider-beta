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

local archerPreUse = Talents.main_env.archerPreUse
local use_stamina = Talents.main_env.use_stamina
local archery_range = Talents.main_env.archery_range

newTalent{
	name = "Mounted Archery Mastery", 
	short_name = "OUTRIDER_MOUNTED_ARCHERY_MASTERY", image="talents/mounted_archery_mastery.png",
	type = {"technique/combat-training", 1},
	points = 5,
	require = { stat = { dex=function(level) return 12 + level * 6 end }, },
	mode = "passive",
	hide = true, --Only show this in Combat Training for Outriders
	on_learn = function(self, t)
		if not self:knowTalent(self.T_OUTRIDER_MOUNTED_ARCHERY) then self:learnTalent(self.T_OUTRIDER_MOUNTED_ARCHERY, true) end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 and self:knowTalent(self.T_OUTRIDER_MOUNTED_ARCHERY) then self:unlearnTalentFull(self.T_OUTRIDER_MOUNTED_ARCHERY) end
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'ammo_mastery_reload', t.getReload(self, t))
	end,
	getChance = function(self,t) 
		local chance = 15
		return chance
	end,
	info = function(self, t)
		local inc = t.getPercentInc(self, t)
		local reload = t.getReload(self,t)
		local stamina = t.getStamina(self,t)
		-- local damage = t.getDamage(self, t)
		-- local dur = t.getDur(self,t)
		-- local cooldown = t.getCooldown(self,t)

		--You are a master of brutal ranged harrying techniques, both mounted and on foot, increasing your weapon damage by %d%% and physical power by 30 when using bows.
		return ([[Increases weapon damage by %d%% and physical power by 30 when using bows or slings, as well as your reload rate by %d.

			Also teaches you the Mounted Archery combat manoeuvre. When riding, you can sustain to loose arrows at your target as you move. Each turn, if you move or rest with a bow equipped, you stand tall and let soar an arrow at your hapless target, just as if you had used the Shoot talent. This costs %.1f stamina per shot and will deactivate if you move out of range, dismount or use another weapon to attack.]]):
		format(inc*100, reload, stamina)
	end,
	getDamage = function(self, t) return 30 end,
	getPercentInc = function(self, t) return math.sqrt(self:getTalentLevel(t) / 5) / 1.5 end,
	getReload = function(self, t)
		return math.floor(self:combatTalentScale(t, 0, 2.7, "log"))
	end,
	getStamina = function(self, t) return self:combatTalentLimit(t, 3, 10, 5) end,
}

newTalent{
	name = "Mounted Archery",
	short_name = "OUTRIDER_MOUNTED_ARCHERY", image="talents/mounted_archery.png",
	type = {"technique/archery-base", 1},
	points = 1,
	mode = "sustained",
	deactivate_on = {no_combat=true, rest=true},
	tactical = { BUFF = 1 },
	cooldown = 5,
	no_energy = true,
	remove_on_zero = true,
	requires_target = true,
	target = function(self, t)
		local tg = self:getTalentTarget(self:getTalentFromId(self.T_SHOOT))
		tg.friendlyfire=false
		tg.selffire=false
		tg.friendlyblock=false
	end,
	on_pre_use = function(self, t, silent, fake) 
		return preCheckIsMounted(self, t, silent, fake) and preCheckArcheryInAnySlot(self, t, silent, fake)
	end,
	----Helper functions---------------------------------------
	doShot = function(self, t)
		local tgt = self:isTalentActive(t.id)["target"]

		local did_shot
		if self:hasArcheryWeapon() then
			did_shot = self:forceUseTalent(self.T_SHOOT, {
				ignore_energy=true, ignore_cd=true, force_target=tgt, ignore_ressources=true, silent=true
			})
		end
		if did_shot and not use_stamina(self, t.getStamina(self, t)) then
			local spend = math.min(t.getStamina(self, t), self:getStamina())
			self:incStamina(-spend) --Never free!
			t.forceDisactivate(self, t)
			return
		end

		local p = self:isTalentActive(t.id); p.dont_shoot = nil
	end,
	checkTarget = function(self, t)
		local target = table.get(self:isTalentActive(t.id), "target")
		if not target or target.dead or not game.level:hasEntity(target) then
			t.forceDisactivate(self, t)
		elseif not self:canProject(self:getTalentTarget(t), target.x, target.y) then
			t.forceDisactivate(self, t)
		else return true end
	end,
	checkCanShoot = function(self, t)
		if not self:hasArcheryWeapon() then 
			t.forceDisactivate(self, t)
			return nil
		end
		if not table.get(self:isTalentActive(t.id), "dont_shoot") then return true end
	end,
	dontShootThisTurn = function(self, t)
		local p = self:isTalentActive(t.id); p["dont_shoot"] = true
	end,
	forceDisactivate = function(self, t)
		--This is a function, because it might need to be expanded
		--upon at some point.
		self:forceUseTalent(t.id, {ignore_energy=true})
	end,
	----Callbacks----------------------------------------------
	-----------------------------------------------------------
	--We shoot once per turn on ActBase.
	--If we attack, though - don't shoot.
	--If we use any talent, except for an instant talent, then
	--  we don't shoot.
	--If we dismount, then we can't use Mounted Archery any more.
	--Likewise, if we remove our archery weapon, we can't use
	--  Mounted Archery any more.
	callbackOnActBase = function(self, t)
		if t.checkTarget(self, t) and t.checkCanShoot(self, t) then
			t.doShot(self, t)
		end
	end,
	callbackOnCombatAttack = function(self, t, weapon, ammo)
		t.dontShootThisTurn(self, t)
	end,
	callbackOnPostTalent = function(self, t, ab, ret, silent)
		if not ab.no_energy then t.dontShootThisTurn(self, t) end
	end,
	callbackOnQuickSwitchWeapons = function(self, t)
		if not self:hasArcheryWeapon() then
			t.forceDisactivate(self, t)
		end
	end,
	callbackOnDismount = function(self, t) t.forceDisactivate(self, t) end,
	-----------------------------------------------------------
	activate = function(self, t)
		local done_swap = swapToArchery(self)
		if not self:hasArcheryWeapon() then
			game.logPlayer(self, "You can't swap to your ranged weapon to use this talent!")
			return nil
		end

		local tg = {type = "bolt", range = archery_range(self),	talent = t}
		local x, y, target = self:getTarget(tg)
		if not target then
			if done_swap then self:quickSwitchWeapons(true, nil, true) end
			return nil
		end

		local mount = self:getMount()
		game.logSeen(self, "%s looses arrows at %s from atop %s!", self.name:capitalize(), target.name, mount.name)
		return {target=target, ct=5}
	end,
	deactivate = function(self, t, p) 
		return true
	end,
	info = function(self, t)
		return ([[]]):
		format(t.getStamina(self, t))
	end,
	getStamina = function(self, t)
		return self:callTalent(self.T_OUTRIDER_MOUNTED_ARCHERY_MASTERY, "getStamina")
	end,
	info = function(self, t)
		local stamina = t.getStamina(self,t)
		-- local damage = t.getDamage(self, t)
		-- local dur = t.getDur(self,t)
		-- local cooldown = t.getCooldown(self,t)

		--You are a master of brutal ranged harrying techniques, both mounted and on foot, increasing your weapon damage by %d%% and physical power by 30 when using bows.
		return ([[When riding, you can sustain to loose arrows at your target as you move. Each turn, if you move or rest with a bow equipped, you stand tall and let soar an arrow at your hapless target, just as if you had used the Shoot talent. This costs %.1f stamina per shot and will deactivate if you move out of range, dismount or use another weapon to attack.]]):
		format(stamina)
	end,

}
