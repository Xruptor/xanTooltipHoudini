local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local GetNumQuestLogEntries = _G.GetNumQuestLogEntries
local GetQuestLogTitle = _G.GetQuestLogTitle

--trigger quest scans
local triggers = {
	["QUEST_COMPLETE"] = true,
	["UNIT_QUEST_LOG_CHANGED"] = true,
	["QUEST_WATCH_UPDATE"] = true,
	["QUEST_FINISHED"] = true,
	["QUEST_LOG_UPDATE"] = true,
}

local playerQuests = {}
local auraSwitch = false

local ignoreFrames = {
	["TemporaryEnchantFrame"] = true,
	["QuestInfoRewardsFrame"] = true,
	["MinimapCluster"] = true,
}

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		if event == "ADDON_LOADED" then
			local arg1 = ...
			if arg1 and arg1 == ADDON_NAME then
				self:UnregisterEvent("ADDON_LOADED")
				self:RegisterEvent("PLAYER_LOGIN")
			end
			return
		end
		if IsLoggedIn() then
			self:EnableAddon(event, ...)
			self:UnregisterEvent("PLAYER_LOGIN")
		end
		return
	end
	if self[event] then 
		return self[event](self, event, ...)
	elseif triggers[event] and self["doQuestTitleGrab"] then
		return self["doQuestTitleGrab"]()
	end 
end)

--add the loot frames
for i=1, NUM_GROUP_LOOT_FRAMES or 4 do
	ignoreFrames["GroupLootFrame" .. i] = true
end

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local function CanAccessObject(obj)
	if issecure() then return true end
	if not obj then return false end
	if obj.IsForbidden then
		return not obj:IsForbidden()
	end
	return true
end

local function SafeHookTooltipMethod(target, methodName, hookFunc)
	if not target or type(methodName) ~= "string" or type(hookFunc) ~= "function" then return false end

	if type(target) == "string" then
		target = _G[target]
		if not target then return false end
	end

	local ok, method = pcall(function()
		return target[methodName]
	end)
	if not ok or type(method) ~= "function" then return false end

	ok = pcall(hooksecurefunc, target, methodName, hookFunc)
	return ok
end

----------------------
--      Enable      --
----------------------

local function processAuraTooltip(self, unitid, index, filter)
	if unitid == "player" then
		auraSwitch = true
		return
	end
	auraSwitch = false
end

local function checkPlayerQuest(tooltip)
	tooltip = tooltip or GameTooltip
	if not tooltip or not tooltip.NumLines then return false end
	local tooltipName = tooltip.GetName and tooltip:GetName()
	if not tooltipName then return false end

	for i=1, tooltip:NumLines() do
		local ttText = _G[tooltipName .. "TextLeft" .. i]
		if ttText and CanAccessObject(ttText) then
			local text = ttText:GetText()
			if text then
				local ok, hasQuest = pcall(rawget, playerQuests, text)
				if ok and hasQuest then return true end
			end
		end
	end
	return false
end

function addon:doQuestTitleGrab()
	playerQuests = {}

	if IsRetail then
		if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return end

		for i=1, C_QuestLog.GetNumQuestLogEntries() do
			local questInfo = C_QuestLog.GetInfo(i)
			
			if questInfo and questInfo.title and not questInfo.isHeader then
				playerQuests[questInfo.title] = true
			end
		end
	
	else
		if type(GetNumQuestLogEntries) ~= "function" or type(GetQuestLogTitle) ~= "function" then return end

		for i=1, GetNumQuestLogEntries() do
			local questTitle, _, _, _, isHeader = GetQuestLogTitle(i)
			
			if questTitle and not isHeader then
				playerQuests[questTitle] = true
			end
		end
	end
	
end

local function IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	return false
end

local function IsInArena()
	if not IsRetail then return false end
	local a = IsActiveBattlefieldArena()
	if not a then
		return false
	end
	return true
end

local function CheckCombatStatus()
	if InCombatLockdown() or UnitAffectingCombat("player") then return true end
	if IsRetail and C_PetBattles.IsInBattle() then return true end
	return IsInBG() or IsInArena()
end

function addon:CheckTooltipStatus(tooltip, unit)
	if not tooltip then return end
	if not CheckCombatStatus() then return end
	if not XTH_DB then return end
	
	--there are lots of taints involved with GameTooltip and NameplateTooltip since 7.2
	--https://us.battle.net/forums/en/wow/topic/20759156905
	--https://eu.battle.net/forums/en/wow/topic/17620312302
	if not CanAccessObject(tooltip) then return end
	
	--this is for the special buffs/debuffs icons above the nameplates, units are nameplate1, nameplate2, etc...
	if unit and unit:sub(1, 9) == "nameplate" then
		tooltip:Hide()
		return
	end
	if tooltip == NamePlateTooltip then return end  --we really don't want to do anything else with nameplate

	local owner = tooltip:GetOwner()
	local ownerName = owner and owner:GetParent() and owner:GetParent():GetName()

	if XTH_DB.showAuras then
		if auraSwitch then return end
		if ownerName and ownerName == "BuffFrame" then return end
	end
	
	if XTH_DB.showQuestObj and checkPlayerQuest(tooltip) then return end
	if ownerName and ignoreFrames[ownerName] then return end
	
	if not IsShiftKeyDown() then
		tooltip:Hide()
	end
end

function addon:EnableAddon()

	--do DB stuff
	if not XTH_DB then XTH_DB = {} end
	if XTH_DB.showAuras == nil then XTH_DB.showAuras = true end
	if XTH_DB.showQuestObj == nil then XTH_DB.showQuestObj = true end

	local tooltipUpdateThrottle = 0
	local TOOLTIP_UPDATE_INTERVAL = 0.10

	SLASH_XANTOOLTIPHOUDINI1 = "/xth"
	SlashCmdList["XANTOOLTIPHOUDINI"] = function(msg)
	
		local a,b,c = strfind(msg, "(%S+)") --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == L.SlashAuras then
				addon.aboutPanel.btnAuras.func(true)
				return true
			elseif c and c:lower() == L.SlashQuest then
				addon.aboutPanel.btnQuest.func(true)
				return true
			end
		end
	
		DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64/255, 224/255, 208/255)
		DEFAULT_CHAT_FRAME:AddMessage("/xth "..L.SlashAuras.." - "..L.SlashAurasInfo)
		DEFAULT_CHAT_FRAME:AddMessage("/xth "..L.SlashQuest.." - "..L.SlashQuestInfo)
	end

	-------
	-------GameTooltip
	-------
	
	GameTooltip:HookScript("OnShow", function(objTooltip)
		tooltipUpdateThrottle = 0
		addon:CheckTooltipStatus(objTooltip)
	end)
	
	GameTooltip:HookScript("OnUpdate", function(objTooltip, elapsed)
		tooltipUpdateThrottle = tooltipUpdateThrottle + (elapsed or 0)
		if tooltipUpdateThrottle < TOOLTIP_UPDATE_INTERVAL then return end
		tooltipUpdateThrottle = 0
		addon:CheckTooltipStatus(objTooltip)
	end)
	
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	SafeHookTooltipMethod(GameTooltip, "SetUnitAura", function(objTooltip, unit, index, filter)
		processAuraTooltip(objTooltip, unit, index, filter)
		addon:CheckTooltipStatus(objTooltip, unit)
	end)

	GameTooltip:HookScript("OnHide", function(self)
		tooltipUpdateThrottle = 0
		auraSwitch = false
	end)
	
	SafeHookTooltipMethod(GameTooltip, "SetUnitBuff", processAuraTooltip)
	SafeHookTooltipMethod(GameTooltip, "SetUnitDebuff", processAuraTooltip)
	
	-------
	-------NamePlateTooltip
	-------
	
	--NamePlateTooltip that shows above nameplate with the buff/debuffs
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	if NamePlateTooltip then
		SafeHookTooltipMethod(NamePlateTooltip, "SetUnitAura", function(objTooltip, unit, index, filter)
			addon:CheckTooltipStatus(objTooltip, unit)
		end)
	end
	
	--activate triggers
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	self:RegisterEvent("QUEST_WATCH_UPDATE")
	self:RegisterEvent("QUEST_FINISHED")
	self:RegisterEvent("QUEST_LOG_UPDATE")

	--call quest scan just in case
	self:doQuestTitleGrab()
	
	if addon.configFrame then addon.configFrame:EnableConfig() end
	
	local ver = C_AddOns.GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xth", ADDON_NAME, ver or "1.0"))
end
