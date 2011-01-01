
local f = CreateFrame("frame","xanHoudiniTooltip_frame",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local auraSwitch = false

----------------------
--      Enable      --
----------------------

local function processAuraTooltip(self, unitid, index, filter)
	auraSwitch = true
end

local function processCombatTooltip(self, unitid, index, filter)
	if InCombatLockdown() then
		self:Hide()
		return
	end
end

function f:PLAYER_LOGIN()

	-- GameTooltip:HookScript("OnShow", function(self)
		-- local name, unitid = self:GetUnit()
		-- local parent = self:GetParent()
		-- if InCombatLockdown() and not auraSwitch then
			-- self:Hide()
			-- return
		-- end
	-- end)
	
	GameTooltip:HookScript("OnHide", function(self)
		auraSwitch = false
	end)
	
	GameTooltip:HookScript("OnUpdate", function(self, elapsed)
		if self:IsShown() and InCombatLockdown() and not auraSwitch then
			self:Hide()
		end
	end)
	
	--decide if we want to show aura tooltips while in battle
	hooksecurefunc(GameTooltip, "SetUnitAura", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitBuff", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", processAuraTooltip)

	-- hooksecurefunc(GameTooltip, "SetUnit", processCombatTooltip)
	-- hooksecurefunc(GameTooltip, "SetAction", processCombatTooltip)
	-- hooksecurefunc(GameTooltip, "SetPetAction", processCombatTooltip)
	-- hooksecurefunc(GameTooltip, "SetShapeshift", processCombatTooltip)
	-- hooksecurefunc(GameTooltip, "SetInventoryItem", processCombatTooltip)
	
	-- hooksecurefunc(GameTooltip, "SetBagItem", processCombatTooltip)
	-- hooksecurefunc(GameTooltip, "SetHyperlink", processCombatTooltip)

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
