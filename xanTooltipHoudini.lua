local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end

local addon = _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local L = private.L or {}
local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local C_AddOns = _G.C_AddOns
local C_QuestLog = _G.C_QuestLog
local C_PetBattles = _G.C_PetBattles
local GetNumQuestLogEntries = _G.GetNumQuestLogEntries
local GetQuestLogTitle = _G.GetQuestLogTitle
local GetNumBattlefieldScores = _G.GetNumBattlefieldScores
local IsActiveBattlefieldArena = _G.IsActiveBattlefieldArena
local IsShiftKeyDown = _G.IsShiftKeyDown
local InCombatLockdown = _G.InCombatLockdown
local UnitAffectingCombat = _G.UnitAffectingCombat
local IsLoggedIn = _G.IsLoggedIn
local GameTooltip = _G.GameTooltip
local NamePlateTooltip = _G.NamePlateTooltip
local hooksecurefunc = _G.hooksecurefunc
local wipe = _G.wipe
local DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME

local questEvents = {
	QUEST_COMPLETE = true,
	UNIT_QUEST_LOG_CHANGED = true,
	QUEST_WATCH_UPDATE = true,
	QUEST_FINISHED = true,
	QUEST_LOG_UPDATE = true,
}

local playerQuests = {}
local auraSwitch = false

local ignoreFrames = {
	TemporaryEnchantFrame = true,
	QuestInfoRewardsFrame = true,
	MinimapCluster = true,
}

for i = 1, (_G.NUM_GROUP_LOOT_FRAMES or 4) do
	ignoreFrames["GroupLootFrame" .. i] = true
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

	local method = target[methodName]
	if type(method) ~= "function" then return false end

	local ok = pcall(hooksecurefunc, target, methodName, hookFunc)
	return ok
end

local function processAuraTooltip(_, unitid, ...)
	auraSwitch = unitid == "player"
end

local function checkPlayerQuest(tooltip)
	tooltip = tooltip or GameTooltip
	if not tooltip or not tooltip.NumLines then return false end
	local tooltipName = tooltip.GetName and tooltip:GetName()
	if not tooltipName then return false end

	for i = 1, tooltip:NumLines() do
		local ttText = _G[tooltipName .. "TextLeft" .. i]
		if ttText and CanAccessObject(ttText) then
			local text = ttText:GetText()
			if text and playerQuests[text] then
				return true
			end
		end
	end
	return false
end

function addon:doQuestTitleGrab()
	if wipe then
		wipe(playerQuests)
	else
		for k in pairs(playerQuests) do
			playerQuests[k] = nil
		end
	end

	if IsRetail then
		if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return end

		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local questInfo = C_QuestLog.GetInfo(i)
			if questInfo and questInfo.title and not questInfo.isHeader then
				playerQuests[questInfo.title] = true
			end
		end
	else
		if type(GetNumQuestLogEntries) ~= "function" or type(GetQuestLogTitle) ~= "function" then return end

		for i = 1, GetNumQuestLogEntries() do
			local questTitle, _, _, _, isHeader = GetQuestLogTitle(i)
			if questTitle and not isHeader then
				playerQuests[questTitle] = true
			end
		end
	end
end

local function IsInBG()
	return type(GetNumBattlefieldScores) == "function" and GetNumBattlefieldScores() > 0
end

local function IsInArena()
	if not IsRetail or type(IsActiveBattlefieldArena) ~= "function" then return false end
	return IsActiveBattlefieldArena() and true or false
end

local function CheckCombatStatus()
	if InCombatLockdown() or UnitAffectingCombat("player") then return true end
	if IsRetail and C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then return true end
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
	if tooltip == NamePlateTooltip then return end --we really don't want to do anything else with nameplate

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

function addon:InitDB()
	if type(XTH_DB) ~= "table" then XTH_DB = {} end
	if XTH_DB.showAuras == nil then XTH_DB.showAuras = true end
	if XTH_DB.showQuestObj == nil then XTH_DB.showQuestObj = true end
end

function addon:ToggleSetting(key, onMsg, offMsg)
	self:InitDB()
	local newValue = not XTH_DB[key]
	XTH_DB[key] = newValue

	if DEFAULT_CHAT_FRAME and (onMsg or offMsg) then
		DEFAULT_CHAT_FRAME:AddMessage(newValue and onMsg or offMsg)
	end

	return newValue
end

function addon:EnableAddon()
	if self._enabled then return end
	self._enabled = true

	self:InitDB()

	local tooltipUpdateThrottle = 0
	local TOOLTIP_UPDATE_INTERVAL = 0.10
	local slashAuras = (L.SlashAuras or "auras"):lower()
	local slashQuest = (L.SlashQuest or "quest"):lower()

	SLASH_XANTOOLTIPHOUDINI1 = "/xth"
	SlashCmdList["XANTOOLTIPHOUDINI"] = function(msg)
		msg = type(msg) == "string" and msg or ""
		local cmd = msg:match("^(%S+)")
		if cmd then
			cmd = cmd:lower()
			if cmd == slashAuras then
				if addon.aboutPanel and addon.aboutPanel.btnAuras and addon.aboutPanel.btnAuras.Toggle then
					addon.aboutPanel.btnAuras.Toggle()
				else
					addon:ToggleSetting("showAuras", L.SlashAurasOn, L.SlashAurasOff)
				end
				return
			elseif cmd == slashQuest then
				if addon.aboutPanel and addon.aboutPanel.btnQuest and addon.aboutPanel.btnQuest.Toggle then
					addon.aboutPanel.btnQuest.Toggle()
				else
					addon:ToggleSetting("showQuestObj", L.SlashQuestOn, L.SlashQuestOff)
				end
				return
			end
		end

		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64 / 255, 224 / 255, 208 / 255)
			DEFAULT_CHAT_FRAME:AddMessage("/xth " .. slashAuras .. " - " .. (L.SlashAurasInfo or ""))
			DEFAULT_CHAT_FRAME:AddMessage("/xth " .. slashQuest .. " - " .. (L.SlashQuestInfo or ""))
		end
	end

	if GameTooltip then
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

		GameTooltip:HookScript("OnHide", function()
			tooltipUpdateThrottle = 0
			auraSwitch = false
		end)

		SafeHookTooltipMethod(GameTooltip, "SetUnitBuff", processAuraTooltip)
		SafeHookTooltipMethod(GameTooltip, "SetUnitDebuff", processAuraTooltip)
	end

	--NamePlateTooltip that shows above nameplate with the buff/debuffs
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	if NamePlateTooltip then
		SafeHookTooltipMethod(NamePlateTooltip, "SetUnitAura", function(objTooltip, unit, index, filter)
			addon:CheckTooltipStatus(objTooltip, unit)
		end)
	end

	--activate triggers
	for eventName in pairs(questEvents) do
		self:RegisterEvent(eventName)
	end

	--call quest scan just in case
	self:doQuestTitleGrab()

	if addon.configFrame then addon.configFrame:EnableConfig() end

	local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
	local ver = (GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0"
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xth", ADDON_NAME, ver))
	end
end

function addon:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= ADDON_NAME then return end
		self:UnregisterEvent("ADDON_LOADED")
		if IsLoggedIn and IsLoggedIn() then
			self:EnableAddon()
		else
			self:RegisterEvent("PLAYER_LOGIN")
		end
		return
	elseif event == "PLAYER_LOGIN" then
		self:EnableAddon()
		self:UnregisterEvent("PLAYER_LOGIN")
		return
	end

	if questEvents[event] then
		self:doQuestTitleGrab()
	end
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", addon.OnEvent)
