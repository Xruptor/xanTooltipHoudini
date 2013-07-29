--trigger quest scans
local triggers = {
	["QUEST_COMPLETE"] = true,
	["UNIT_QUEST_LOG_UPDATE"] = true,
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
	auraSwitch = true
end

local function checkPlayerQuest()
	for i=1,GameTooltip:NumLines() do
		local ttText = getglobal("GameTooltipTextLeft" .. i)
		if ttText:GetText() and playerQuests[ttText:GetText()] ~= nil then
			return true
		end
	end
	return false
end

function f:doQuestTitleGrab()
	--we have to expand and then collaspe headers because GetQuestLogTitle won't return anything if it's closed
	local saved_position = GetQuestLogSelection()
	for i=1,GetNumQuestLogEntries() do
	   local _,_,_,_,_,isCollapsed,isComplete = GetQuestLogTitle(i)
	   if isCollapsed then
		  local count = GetNumQuestLogEntries()
		  ExpandQuestHeader(i)
		  count = GetNumQuestLogEntries() - count
		  for j=i+1,i+count do
			 local title,_,_,_,_,_,isComplete = GetQuestLogTitle(j)
				--store the player quest
				playerQuests[title] = title
		  end
		  CollapseQuestHeader(i)
	   end
	end
	SelectQuestLogEntry(saved_position)
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

	GameTooltip:HookScript("OnShow", function(self)
		local canPass = false
		if XTH_DB and not XTH_DB.showAuras then canPass = true end
		if XTH_DB and XTH_DB.showQuestObj and checkPlayerQuest() then canPass = true end
		
		if XTH_DB and canPass then
			if InCombatLockdown() then
				local owner = self:GetOwner()
				if not XTH_DB.showAuras and owner and owner:GetParent() and owner:GetParent():GetName() and ignoreFrames[owner:GetParent():GetName()] then
					--do nothing
					return
				end
				if XTH_DB.showQuestObj and checkPlayerQuest() then
					--do nothing
					return
				end
				if not XTH_DB.showAuras or not XTH_DB.showQuestObj then
					self:Hide()
				end
				return
			end
		end
	end)
	
	GameTooltip:HookScript("OnUpdate", function(self, elapsed)
		local canPass = false
		if XTH_DB and XTH_DB.showAuras then canPass = true end
		if XTH_DB and XTH_DB.showQuestObj and checkPlayerQuest() then canPass = true end
			
		if XTH_DB and canPass and self:IsShown() then
			local owner = self:GetOwner()
			if InCombatLockdown() then
				--check for temporary enchant frame
				if XTH_DB.showAuras and not auraSwitch and owner and owner:GetParent() and owner:GetParent():GetName() and ignoreFrames[owner:GetParent():GetName()] then
					--do nothing
					return
				end
				if XTH_DB.showQuestObj and checkPlayerQuest() then
					--do nothing
					return
				end				
				--otherwise hide it
				if not auraSwitch or not XTH_DB.showQuestObj then
					self:Hide()
				end
			end
		end
	end)
	
	-- GameTooltip:SetScript("OnTooltipSetQuest", function(self, ...)
		-- if XTH_DB.showQuestObj then
			-- checkPlayerQuest()
		-- end
    -- end)
	
	-- GameTooltip:SetScript("OnTooltipSetUnit", function(self, ...)
		-- if XTH_DB.showQuestObj then
			-- checkPlayerQuest()
		-- end
    -- end)
	
	-- GameTooltip:SetScript("OnTooltipSetItem", function(self, ...)
		-- if XTH_DB.showQuestObj then
			-- checkPlayerQuest()
		-- end
    -- end)
	
	GameTooltip:HookScript("OnHide", function(self)
		auraSwitch = false
	end)

	
	--decide if we want to show aura tooltips while in battle
	hooksecurefunc(GameTooltip, "SetUnitAura", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitBuff", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", processAuraTooltip)

	--activate triggers
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("UNIT_QUEST_LOG_UPDATE")
	self:RegisterEvent("QUEST_WATCH_UPDATE")
	self:RegisterEvent("QUEST_FINISHED")
	self:RegisterEvent("QUEST_LOG_UPDATE")

	--call quest scan just in case
	self:doQuestTitleGrab()
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
