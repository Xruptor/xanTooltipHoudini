local ADDON_NAME, private = ...

local L = private:NewLocale("enUS", true)
if not L then return end

L.SlashAuras = "auras"
L.SlashAurasOn = "xanTooltipHoudini: Aura (Buff/Debuff) tooltips are now [|cFF99CC33ON|r]"
L.SlashAurasOff = "xanTooltipHoudini: Aura (Buff/Debuff) tooltips are now [|cFF99CC33OFF|r]"
L.SlashAurasInfo = "Allow aura tooltips to be displayed during combat."

L.SlashQuest = "quest"
L.SlashQuestOn = "xanTooltipHoudini: Quest tooltips are now [|cFF99CC33ON|r]"
L.SlashQuestOff = "xanTooltipHoudini: Quest tooltips are now [|cFF99CC33OFF|r]"
L.SlashQuestInfo = "Allow quest tooltips to be displayed during combat."
