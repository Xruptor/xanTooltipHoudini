
local f = CreateFrame("frame","xanTooltipHoudini_frame",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local auraSwitch = false

local ignoreFrames = {
	["TemporaryEnchantFrame"] = true,
	["QuestInfoRewardsFrame"] = true,
	["MinimapCluster"] = true,
}
--add the loot frames
for i=1, NUM_GROUP_LOOT_FRAMES do
	ignoreFrames["GroupLootFrame" .. i] = true
end
	
----------------------
--      Enable      --
----------------------

local function processAuraTooltip(self, unitid, index, filter)
	auraSwitch = true
end

function f:PLAYER_LOGIN()

	--do DB stuff
	if not XTH_DB then XTH_DB = {} end
	if XTH_DB.showAuras == nil then XTH_DB.showAuras = true end

	SLASH_XANTOOLTIPHOUDINI1 = "/xth"
	SlashCmdList["XANTOOLTIPHOUDINI"] = function(msg)
	
		local a,b,c = strfind(msg, "(%S+)") --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == "auras" then
				if XTH_DB.showAuras then
					XTH_DB.showAuras = false
					DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33OFF|r]")
				else
					XTH_DB.showAuras = true
					DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33ON|r]")
				end
				return true
			end
		end
	
		DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini")
		DEFAULT_CHAT_FRAME:AddMessage("/xth auras - toggles Aura (Buff/Debuff) tooltips (ON/OFF)")
	end
	
	GameTooltip:HookScript("OnShow", function(self)
		--only use this if showAuras is false
		if XTH_DB and not XTH_DB.showAuras then
			if InCombatLockdown() then
				local owner = self:GetOwner()
				if owner and owner:GetParent() and owner:GetParent():GetName() and ignoreFrames[owner:GetParent():GetName()] then
					--do nothing
					return
				end
				self:Hide()
				return
			end
		end
	end)
	
	GameTooltip:HookScript("OnHide", function(self)
		auraSwitch = false
	end)
	
	GameTooltip:HookScript("OnUpdate", function(self, elapsed)
		--check if showauras is on
		if XTH_DB and XTH_DB.showAuras and self:IsShown() then
			--hide everything BUT auras, and temporary weapon enchants ;P
			local owner = self:GetOwner()
			if InCombatLockdown() and not auraSwitch then
				--check for temporary enchant frame
				if owner and owner:GetParent() and owner:GetParent():GetName() and ignoreFrames[owner:GetParent():GetName()] then
					--do nothing
					return
				end
				--otherwise hide it
				self:Hide()
			end
		end
	end)
	
	--decide if we want to show aura tooltips while in battle
	hooksecurefunc(GameTooltip, "SetUnitAura", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitBuff", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", processAuraTooltip)

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
