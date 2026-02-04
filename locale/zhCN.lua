local ADDON_NAME, private = ...

local L = private:NewLocale("zhCN")
if not L then return end

L.SlashAuras = "光环"
L.SlashAurasOn = "xanTooltipHoudini: 光环 (Buff/Debuff) 提示为 [|cFF99CC33开|r]"
L.SlashAurasOff = "xanTooltipHoudini: 光环 (Buff/Debuff) 提示为 [|cFF99CC33关|r]"
L.SlashAurasInfo = "战斗中显示光环提示。"

L.SlashQuest = "任务"
L.SlashQuestOn = "xanTooltipHoudini: 任务提示为 [|cFF99CC33开|r]"
L.SlashQuestOff = "xanTooltipHoudini: 任务提示为 [|cFF99CC33关|r]"
L.SlashQuestInfo = "战斗中显示任务提示。"
