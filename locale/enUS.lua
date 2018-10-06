local ADDON_NAME, addon = ...

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)
if not L then return end

L.SlashAuras = "auras"
L.SlashAurasOn = "xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33ON|r]"
L.SlashAurasOff = "xanTooltipHoudini: Aura (Buff/Debuff) toolips are now [|cFF99CC33OFF|r]"
L.SlashAurasInfo = "Allow aura tooltips to be displayed during combat."

L.SlashQuest = "quest"
L.SlashQuestOn = "xanTooltipHoudini: Quest toolips are now [|cFF99CC33ON|r]"
L.SlashQuestOff = "xanTooltipHoudini: Quest toolips are now [|cFF99CC33OFF|r]"
L.SlashQuestInfo = "Allow quest tooltips to be displayed during combat."