
local L = LibStub("AceLocale-3.0"):NewLocale("xanTooltipHoudini", "enUS", true)
if not L then return end

--for non-english fonts
--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/Fonts.xml

--Get the best possible font for the localization langugage.
--Some fonts are better than others to display special character sets.
L.GetFontType = "Fonts\\FRIZQT__.TTF"

L.SlashAuras = "auras"
L.SlashAurasOn = "xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33ON|r]"
L.SlashAurasOff = "xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33OFF|r]"
L.SlashAurasInfo = "Allow aura tooltips to be displayed during combat."

L.SlashQuest = "quest"
L.SlashQuestOn = "xanTooltipHoudini: Quest toolips are now [|cFF99CC33ON|r]"
L.SlashQuestOff = "xanTooltipHoudini: Quest toolips are now [|cFF99CC33OFF|r]"
L.SlashQuestInfo = "Allow quest tooltips to be displayed during combat."