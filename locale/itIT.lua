local ADDON_NAME, private = ...

local L = private:NewLocale("itIT")
if not L then return end

L.SlashAuras = "aure"
L.SlashAurasOn = "xanTooltipHoudini: I tooltip delle aure (Buff/Debuff) ora sono [|cFF99CC33ATTIVI|r]"
L.SlashAurasOff = "xanTooltipHoudini: I tooltip delle aure (Buff/Debuff) ora sono [|cFF99CC33DISATTIVI|r]"
L.SlashAurasInfo = "Consente di mostrare i tooltip delle aure durante il combattimento."

L.SlashQuest = "missione"
L.SlashQuestOn = "xanTooltipHoudini: I tooltip delle missioni ora sono [|cFF99CC33ATTIVI|r]"
L.SlashQuestOff = "xanTooltipHoudini: I tooltip delle missioni ora sono [|cFF99CC33DISATTIVI|r]"
L.SlashQuestInfo = "Consente di mostrare i tooltip delle missioni durante il combattimento."
