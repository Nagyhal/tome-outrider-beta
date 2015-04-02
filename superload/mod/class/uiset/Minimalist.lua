local _M = loadPrevious(...)

local Dialog = require "engine.ui.Dialog"
local move_handle = {core.display.loadImage("/data/gfx/ui/move_handle.png"):glTexture()}

function _M:showResourceTooltip(x, y, w, h, id, desc, is_first)
	if not game.mouse:updateZone(id, x, y, w, h, nil, self.places.resources.scale) then
		game.mouse:registerZone(x, y, w, h, function(button, mx, my, xrel, yrel, bx, by, event)
			if is_first then
				if event == "out" then self.mhandle.resources = nil return
				else self.mhandle.resources = true end

				-- Move handle
				if not self.locked and bx >= self.mhandle_pos.resources.x and bx <= self.mhandle_pos.resources.x + move_handle[6] and by >= self.mhandle_pos.resources.y and by <= self.mhandle_pos.resources.y + move_handle[7] then
					if event == "button" and button == "right" then
						local player = game.player
						local list = {}
						if player:knowTalent(player.T_STAMINA_POOL) then list[#list+1] = {name="Stamina", id="stamina"} end
						if player:knowTalent(player.T_MANA_POOL) then list[#list+1] = {name="Mana", id="mana"} end
						if player:knowTalent(player.T_SOUL_POOL) then list[#list+1] = {name="Necrotic", id="soul"} end
						if player:knowTalent(player.T_EQUILIBRIUM_POOL) then list[#list+1] = {name="Equilibrium", id="equilibrium"} end
						if player:knowTalent(player.T_POSITIVE_POOL) then list[#list+1] = {name="Positive", id="positive"} end
						if player:knowTalent(player.T_NEGATIVE_POOL) then list[#list+1] = {name="Negative", id="negative"} end
						if player:knowTalent(player.T_PARADOX_POOL) then list[#list+1] = {name="Paradox", id="paradox"} end
						if player:knowTalent(player.T_VIM_POOL) then list[#list+1] = {name="Vim", id="vim"} end
						if player:knowTalent(player.T_HATE_POOL) then list[#list+1] = {name="Hate", id="hate"} end
						if player:knowTalent(player.T_PSI_POOL) then list[#list+1] = {name="Psi", id="psi"} end
						if player:knowTalent(player.T_FEEDBACK_POOL) then list[#list+1] = {name="Feedback", id="feedback"} end
						if player:knowTalent(player.T_LOYALTY_POOL) then list[#list+1] = {name="Loyalty", id="loyalty"} end
						Dialog:listPopup("Display/Hide resources", "Toggle:", list, 300, 300, function(sel)
							if not sel or not sel.id then return end
							game.player["_hide_resource_"..sel.id] = not game.player["_hide_resource_"..sel.id]
						end)
						return
					end
					self:uiMoveResize("resources", button, mx, my, xrel, yrel, bx, by, event, nil, nil, "\nRight click to toggle resources bars visibility")
					return
				end
			end

			local extra = {log_str=desc}
			game.mouse:delegate(button, mx, my, xrel, yrel, nil, nil, event, "playmap", extra)
		end, nil, id, true, self.places.resources.scale)
	end
end

return _M