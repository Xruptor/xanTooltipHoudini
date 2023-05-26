local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

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
	return issecure() or not obj:IsForbidden();
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

local function checkPlayerQuest()
	for i=1,GameTooltip:NumLines() do
		local ttText = getglobal("GameTooltipTextLeft" .. i)
		if ttText and ttText:GetText() and playerQuests[ttText:GetText()] then
			return true
		end
	end
	return false
end

function addon:doQuestTitleGrab()
	playerQuests = {}

	if IsRetail then
		for i=1, C_QuestLog.GetNumQuestLogEntries() do
			local questInfo = C_QuestLog.GetInfo(i)
			
			if questInfo.title and not questInfo.isHeader then
				playerQuests[questInfo.title] = questInfo.title
			end
		end
	
	else
		for i=1, GetNumQuestLogEntries() do
			local questTitle, _, _, _, isHeader = GetQuestLogTitle(i)
			
			if questTitle and not isHeader then
				playerQuests[questTitle] = questTitle
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
	local a,b = IsActiveBattlefieldArena()
	if not a then
		return false
	end
	return true
end

local function CheckCombatStatus()
	return IsInBG() or IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") or (IsRetail and C_PetBattles.IsInBattle())
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
	if unit and string.find(unit, "nameplate") then
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
	
	if XTH_DB.showQuestObj and checkPlayerQuest() then return end
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
		addon:CheckTooltipStatus(objTooltip)
	end)
	
	GameTooltip:HookScript("OnUpdate", function(objTooltip, elapsed)
		addon:CheckTooltipStatus(objTooltip)
	end)
	
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	hooksecurefunc(GameTooltip,"SetUnitAura",function(objTooltip, unit, index, filter)
		processAuraTooltip(objTooltip, unit, index, filter)
		addon:CheckTooltipStatus(objTooltip, unit)
	end)

	GameTooltip:HookScript("OnHide", function(self)
		auraSwitch = false
	end)
	
	hooksecurefunc(GameTooltip, "SetUnitBuff", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", processAuraTooltip)
	
	-------
	-------NamePlateTooltip
	-------
	
	--NamePlateTooltip that shows above nameplate with the buff/debuffs
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	hooksecurefunc(NamePlateTooltip,"SetUnitAura",function(objTooltip, unit, index, filter)
		addon:CheckTooltipStatus(objTooltip, unit)
	end)
	
	--activate triggers
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	self:RegisterEvent("QUEST_WATCH_UPDATE")
	self:RegisterEvent("QUEST_FINISHED")
	self:RegisterEvent("QUEST_LOG_UPDATE")

	--call quest scan just in case
	self:doQuestTitleGrab()
	
	if addon.configFrame then addon.configFrame:EnableConfig() end
	
	local ver = GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xth", ADDON_NAME, ver or "1.0"))
end
