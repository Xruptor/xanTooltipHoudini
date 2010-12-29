
local f = CreateFrame("frame","xanHoudiniTooltip_frame",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	GameTooltip:HookScript("OnShow", function(self)
		if InCombatLockdown() then
			self:Hide()
			return
		end
	end)

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
