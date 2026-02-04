local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end

local addon = _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

addon.configFrame = CreateFrame("frame", ADDON_NAME .. "_config_eventFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local configFrame = addon.configFrame

local C_AddOns = _G.C_AddOns
local L = private.L or {}

local lastObject
local function addConfigEntry(objEntry, adjustX, adjustY)
	objEntry:ClearAllPoints()

	if not lastObject then
		objEntry:SetPoint("TOPLEFT", 20, -150)
	else
		objEntry:SetPoint("LEFT", lastObject, "BOTTOMLEFT", adjustX or 0, adjustY or -30)
	end

	lastObject = objEntry
end

local chkBoxIndex = 0
local function createCheckbutton(parentFrame, displayText)
	chkBoxIndex = chkBoxIndex + 1

	local checkbutton = CreateFrame("CheckButton", ADDON_NAME .. "_config_chkbtn_" .. chkBoxIndex, parentFrame, "ChatConfigCheckButtonTemplate")
	_G[checkbutton:GetName() .. "Text"]:SetText(" " .. displayText)

	return checkbutton
end

local function createToggle(panel, label, key, onMsg, offMsg)
	local checkbutton = createCheckbutton(panel, label)

	checkbutton:SetScript("OnShow", function()
		checkbutton:SetChecked(XTH_DB and XTH_DB[key])
	end)

	checkbutton.Toggle = function()
		local newValue = addon:ToggleSetting(key, onMsg, offMsg)
		checkbutton:SetChecked(newValue)
		return newValue
	end

	checkbutton:SetScript("OnClick", checkbutton.Toggle)

	return checkbutton
end

local function LoadAboutFrame()
	--Code inspired from tekKonfigAboutPanel
	local parent = InterfaceOptionsFramePanelContainer or UIParent
	local about = CreateFrame("Frame", ADDON_NAME .. "AboutPanel", parent, BackdropTemplateMixin and "BackdropTemplate")
	about.name = ADDON_NAME
	about:Hide()

	local fields = { "Version", "Author" }
	local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
	local notes = GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Notes")

	local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(ADDON_NAME)

	local subtitle = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", about, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(notes)

	local anchor
	for _, field in pairs(fields) do
		local val = GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, field)
		if val then
			local titleText = about:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			titleText:SetWidth(75)
			if not anchor then
				titleText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
			else
				titleText:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
			end
			titleText:SetJustifyH("RIGHT")
			titleText:SetText(field:gsub("X%-", ""))

			local detail = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detail:SetPoint("LEFT", titleText, "RIGHT", 4, 0)
			detail:SetPoint("RIGHT", -16, 0)
			detail:SetJustifyH("LEFT")
			detail:SetText(val)

			anchor = titleText
		end
	end

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(about)
	else
		local category, layout = _G.Settings.RegisterCanvasLayoutCategory(about, about.name)
		_G.Settings.RegisterAddOnCategory(category)
		addon.settingsCategory = category
	end

	return about
end

function configFrame:EnableConfig()
	addon.aboutPanel = LoadAboutFrame()

	local btnAuras = createToggle(addon.aboutPanel, L.SlashAurasInfo or "", "showAuras", L.SlashAurasOn, L.SlashAurasOff)
	addConfigEntry(btnAuras, 0, -20)
	addon.aboutPanel.btnAuras = btnAuras

	local btnQuest = createToggle(addon.aboutPanel, L.SlashQuestInfo or "", "showQuestObj", L.SlashQuestOn, L.SlashQuestOff)
	addConfigEntry(btnQuest, 0, -20)
	addon.aboutPanel.btnQuest = btnQuest
end
