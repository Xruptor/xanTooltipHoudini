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

local f = CreateFrame("frame","xanTooltipHoudini_frame",UIParent)
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
	if not f:InCombatLockdown() then return end
	if not XTH_DB then return end
	
	local name = tooltip:GetName() and string.lower(tooltip:GetName()) or ""

	--this is for the special buffs/debuffs icons above the nameplates, units are nameplate1, nameplate2, etc...
	if unit and string.find(unit, "nameplate") then
		tooltip:Hide()
		return
	elseif tooltip == NamePlateTooltip or string.find(name, "nameplate") then
		--we really don't want to do anything else with nameplate
		return
	end
	
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
			if c and c:lower() == "auras" then
				if XTH_DB.showAuras then
					XTH_DB.showAuras = false
					DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33OFF|r]")
				else
					XTH_DB.showAuras = true
					DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33ON|r]")
				end
				return true
			elseif c and c:lower() == "quest" then
				if XTH_DB.showQuestObj then
					XTH_DB.showQuestObj = false
					DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini: Quest toolips are now [|cFF99CC33OFF|r]")
				else
					XTH_DB.showQuestObj = true
					DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini: Quest toolips are now [|cFF99CC33ON|r]")
				end
				return true
			end
		end
	
		DEFAULT_CHAT_FRAME:AddMessage("xanTooltipHoudini")
		DEFAULT_CHAT_FRAME:AddMessage("/xth auras - toggles Aura (Buff/Debuff) tooltips (ON/OFF)")
		DEFAULT_CHAT_FRAME:AddMessage("/xth quest - toggles Quest objective tooltips (ON/OFF)")
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
	NamePlateTooltip:HookScript("OnShow", function(objTooltip)
		f:CheckTooltipStatus(objTooltip)
	end)
	
	NamePlateTooltip:HookScript("OnUpdate", function(objTooltip, elapsed)
		f:CheckTooltipStatus(objTooltip)
	end)
	
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
