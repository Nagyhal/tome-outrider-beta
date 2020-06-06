local outrider_block_move = function(_, bx, by)
	return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self)
end