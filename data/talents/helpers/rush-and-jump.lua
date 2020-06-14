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

---------------------------------------------------------------
--I've decided to put these important movement functions in one place.
--The rush functionality in particular is large and full of complicated calculations,
--checks and contingencies.
--As this is used in multiple places within the Outrider code, it would be very
--easy, using the copy-and-paste design pattern, to include important movement
--checks in one place but forget to include them in another.
--So my Rush and Jump functions are going here in the name of
--1) Easier debugging and improvement of core rush-like movement functionality
--2) Prettier code in the talent files ;)
---------------------------------------------------------------

---Jump an actor to a grid, ignoring anything along the way.
-- @self The actor to move
-- @x target location x
-- @y target location y
function jumpTargetTo(self, x, y)
	if not x or not y or not self then return nil end

	local ox, oy = self.x, self.y
	local actor = game.level.map(x, y, engine.Map.ACTOR)
	local feat = game.level.map(x, y, engine.Map.TERRAIN)

	--Go to a nearby space if this one is taken.
	if actor or feat and feat:check(block_move) then 
		x, y = util.findFreeGrid(x, y, 1, true, {[engine.Map.ACTOR]=true})
		if not x then return nil end
	end 

	self:move(x, y, true)
	self:resetMoveAnim()
	local jump = .75
	--Higher jump for un-ridden mounts. It just looks better!
	if self.type == "animal" and not self:isMounted() then jump = 1 end 
	self:setMoveAnim(ox, oy, 20, 4, 8, jump)
	return true
end

	-- if core.fov.distance(self.x, self.y, x, y) > range then return nil end

---Rush an actor to a grid, checking for obstacles along the path.
-- @self The actor to move
-- @x Target location x
-- @y Target location y
-- @min_range -- Our mininum rush range, defaults to 2 i.e. 1 square of movement
-- @dismount -- Do we do a dismounting attack, like Let 'Em Have It?
function rushTargetTo(self, x, y, args)
	--Set up our needed stuff
	local min_range = args.min_range or 0
	local dismount = args.dismount
	local go_through_friends = args.go_through_friends
	local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, engine.Map.TERRAIN, "block_move", self) end
	local linestep = self:lineFOV(x, y, block_actor)

	--First, we set up some functions
	--There is a quicker way to do this, but I felt this was much more readable
	local function checkAllies(self, lx, ly)
		if not go_through_friends then return end
		local a = game.level.map(lx, ly, engine.Map.ACTOR)
		if a and self:reactionToward(a) >= 0 then return true end
	end

	local function checkEntities(self, lx, ly)
		if not checkAllies(self, lx, ly) then
			return game.level.map:checkAllEntities(lx, ly, "block_move", self)
		else return false end
	end

	--Here we do the check to see if we can charge:
	local tx, ty, lx, ly, is_corner_blocked, pass_actor
	repeat
		if not pass_actor then tx, ty = lx, ly end
		lx, ly, is_corner_blocked = linestep:step()
		if checkAllies(self, lx, ly) then pass_actor = true else pass_actor = false end
	until is_corner_blocked or not lx or not ly or checkEntities(self, lx, ly)

	--Check for min_range
	-- game.log ("DEBUG: Got tx "..tx..", ty"..ty..", self.x"..self.x..", self.y"..self.y)
	if pass_actor then
		game.logSeen(self, "%s needs space to get close!", self.name:capitalize())
		return
	elseif not tx or core.fov.distance(self.x, self.y, tx, ty) <= min_range then
		game.logSeen(self, "%s is too close to build up momentum!", self.name:capitalize())
		return
	end
	if not tx or not ty or core.fov.distance(x, y, tx, ty) > 1 then return nil end

	--Set our original coordinates before we do anything.
	local ox, oy = self.x, self.y

	--Dismount before we charge?
	local done_dismount, done_rider_dismount
	if dismount and self:isMounted() then
		self:dismount(); done_dismount = true
		if self:isMounted() then return nil end --We MUST dismount, so cancel if we cannot!
	end

	if dismount and self:hasEffect(self.EFF_OUTRIDER_RIDDEN) then
		done_rider_dismount=true
		self.owner:dismount(); done_rider_dismount = true
		if self:hasEffect(self.EFF_OUTRIDER_RIDDEN) then return nil end
	end

	-- local function do_dismount() = self.owner:dismount()

	--Then, the actual rush movement is very basic:
	local px, py = self.x, self.y
	self:move(tx, ty, true)
	if config.settings.tome.smooth_move > 0 then
		self:resetMoveAnim()
		self:setMoveAnim(px, py, 8, 5)
	end

	--If we had to dismount, then pop our character back onto the map.
	if done_dismount and self.outrider_pet then self.outrider_pet:move(ox, oy, true) end
	if done_rider_dismount then self.owner:move(ox, oy, true) end
	return true
end

function targetTramplesTo(self, x, y, do_on_squares)
	local lineFunction = self:lineFOV(x, y)
	local nextX, nextY, is_corner_blocked = lineFunction:step()
	local currentX, currentY = self.x, self.y
	local targets = {}

	local stop = false
	while nextX and nextY and not is_corner_blocked and not stop do
		currentX, currentY = nextX, nextY
		nextX, nextY, is_corner_blocked = lineFunction:step()
		
		if game.level.map:checkEntity(nextX, nextY, engine.Map.TERRAIN, "block_move", self) then stop = true end

		local a = game.level.map(currentX, currentY, engine.Map.ACTOR)
		targets[#targets+1] = a
		if do_on_squares then do_on_squares(currentX, currentY) end
	end

	--Move the mounted unit before we make our attacks.
	local ox, oy = self.x, self.y
	if currentX == ox and currentY == oy then return false end
	self:move(currentX, currentY, true)
	self:resetMoveAnim()
	self:setMoveAnim(ox, oy, 8, 8)
	return targets
end