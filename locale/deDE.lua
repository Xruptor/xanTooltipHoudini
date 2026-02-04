local ADDON_NAME, private = ...

local L = private:NewLocale("deDE")
if not L then return end

L.SlashAuras = "auren"
L.SlashAurasOn = "xanTooltipHoudini: Aura (Buff/Debuff)-Tooltips sind jetzt [|cFF99CC33AN|r]"
L.SlashAurasOff = "xanTooltipHoudini: Aura (Buff/Debuff)-Tooltips sind jetzt [|cFF99CC33AUS|r]"
L.SlashAurasInfo = "Erlaubt, Aura-Tooltips im Kampf anzuzeigen."

L.SlashQuest = "auftrag"
L.SlashQuestOn = "xanTooltipHoudini: Quest-Tooltips sind jetzt [|cFF99CC33AN|r]"
L.SlashQuestOff = "xanTooltipHoudini: Quest-Tooltips sind jetzt [|cFF99CC33AUS|r]"
L.SlashQuestInfo = "Erlaubt, Quest-Tooltips im Kampf anzuzeigen."
