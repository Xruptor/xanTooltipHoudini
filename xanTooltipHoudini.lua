local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then _G[ADDON_NAME] = addon end

addon.addonFrame = CreateFrame("frame","xanTooltipHoudini_frame",UIParent)
local f = addon.addonFrame

local L = LibStub("AceLocale-3.0"):GetLocale("xanTooltipHoudini")

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

f:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then 
		return self[event](self, event, ...)
	elseif triggers[event] and self["doQuestTitleGrab"] then
		return self["doQuestTitleGrab"]()
	end 
end)

--add the loot frames
for i=1, NUM_GROUP_LOOT_FRAMES do
	ignoreFrames["GroupLootFrame" .. i] = true
end

local debugf = tekDebug and tekDebug:GetFrame("xanTooltipHoudini")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
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

function f:doQuestTitleGrab()
	playerQuests = {}
	for i=1,GetNumQuestLogEntries() do
		local questTitle, _, _, _, isHeader = GetQuestLogTitle(i)
		
		if questTitle and not isHeader then
			playerQuests[questTitle] = questTitle
		end
	end
end

function f:InCombatLockdown()
	return InCombatLockdown() or UnitAffectingCombat("player")
end

function f:CheckTooltipStatus(tooltip, unit)
	if not tooltip then return end
	if not f:InCombatLockdown() then return end
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

function f:PLAYER_LOGIN()

	--do DB stuff
	if not XTH_DB then XTH_DB = {} end
	if XTH_DB.showAuras == nil then XTH_DB.showAuras = true end
	if XTH_DB.showQuestObj == nil then XTH_DB.showQuestObj = true end

	SLASH_XANTOOLTIPHOUDINI1 = "/xth"
	SlashCmdList["XANTOOLTIPHOUDINI"] = function(msg)
	
		local a,b,c = strfind(msg, "(%S+)") --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == L.SlashAuras then
				addon.aboutPanel.btnAuras.func()
				return true
			elseif c and c:lower() == L.SlashQuest then
				addon.aboutPanel.btnQuest.func()
				return true
			end
		end
	
		DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini")
		DEFAULT_CHAT_FRAME:AddMessage("/xth "..L.SlashAuras.." - "..L.SlashAurasInfo)
		DEFAULT_CHAT_FRAME:AddMessage("/xth "..L.SlashQuest.." - "..L.SlashQuestInfo)
	end

	-------
	-------GameTooltip
	-------
	
	GameTooltip:HookScript("OnShow", function(objTooltip)
		f:CheckTooltipStatus(objTooltip)
	end)
	
	GameTooltip:HookScript("OnUpdate", function(objTooltip, elapsed)
		f:CheckTooltipStatus(objTooltip)
	end)
	
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	hooksecurefunc(GameTooltip,"SetUnitAura",function(objTooltip, unit, index, filter)
		processAuraTooltip(objTooltip, unit, index, filter)
		f:CheckTooltipStatus(objTooltip, unit)
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
		f:CheckTooltipStatus(objTooltip, unit)
	end)
	
	--activate triggers
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	self:RegisterEvent("QUEST_WATCH_UPDATE")
	self:RegisterEvent("QUEST_FINISHED")
	self:RegisterEvent("QUEST_LOG_UPDATE")

	--call quest scan just in case
	self:doQuestTitleGrab()
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
