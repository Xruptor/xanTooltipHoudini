local ADDON_NAME, private = ...

local L = private:NewLocale("zhTW")
if not L then return end

--special thanks to BNS333 from CurseForge
--https://www.curseforge.com/members/bns333

L.SlashAuras = "光環"
L.SlashAurasOn = "xanTooltipHoudini: 光環(Buff/Debuff)提示現在為  [|cFF99CC33ON|r]"
L.SlashAurasOff = "xanTooltipHoudini: 光環(Buff/Debuff)提示現在為  [|cFF99CC33OFF|r]"
L.SlashAurasInfo = "允許在戰鬥中顯示光環提示。"

L.SlashQuest = "任務"
L.SlashQuestOn = "xanTooltipHoudini: 任務提示現在為  [|cFF99CC33ON|r]"
L.SlashQuestOff = "xanTooltipHoudini: 任務提示現在為  [|cFF99CC33OFF|r]"
L.SlashQuestInfo = "允許在戰鬥中顯示任務提示。"
