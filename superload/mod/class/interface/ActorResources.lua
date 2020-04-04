local _M = loadPrevious(...)

local base_incLoyalty = _M.incLoyalty
function _M:incLoyalty(loyalty)
	local eff = self:hasEffect(self.EFF_OUTRIDER_BOND_BEYOND_BLOOD)
	if eff and loyalty < 0 then
		loyalty = loyalty - loyalty*eff.loyalty_discount/100
	end

	return base_incLoyalty(self, loyalty)
end

return _M