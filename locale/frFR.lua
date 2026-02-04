local ADDON_NAME, private = ...

local L = private:NewLocale("frFR")
if not L then return end

L.SlashAuras = "auras"
L.SlashAurasOn = "xanTooltipHoudini: Les info-bulles d'aura (Buff/Debuff) sont maintenant [|cFF99CC33ACTIVÉES|r]"
L.SlashAurasOff = "xanTooltipHoudini: Les info-bulles d'aura (Buff/Debuff) sont maintenant [|cFF99CC33DÉSACTIVÉES|r]"
L.SlashAurasInfo = "Autorise l'affichage des info-bulles d'aura en combat."

L.SlashQuest = "quete"
L.SlashQuestOn = "xanTooltipHoudini: Les info-bulles de quêtes sont maintenant [|cFF99CC33ACTIVÉES|r]"
L.SlashQuestOff = "xanTooltipHoudini: Les info-bulles de quêtes sont maintenant [|cFF99CC33DÉSACTIVÉES|r]"
L.SlashQuestInfo = "Autorise l'affichage des info-bulles de quêtes en combat."
