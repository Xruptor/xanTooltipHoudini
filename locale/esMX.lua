local ADDON_NAME, private = ...

local L = private:NewLocale("esMX")
if not L then return end

L.SlashAuras = "auras"
L.SlashAurasOn = "xanTooltipHoudini: Los tooltips de auras (Buff/Debuff) ahora están [|cFF99CC33ACTIVADOS|r]"
L.SlashAurasOff = "xanTooltipHoudini: Los tooltips de auras (Buff/Debuff) ahora están [|cFF99CC33DESACTIVADOS|r]"
L.SlashAurasInfo = "Permite mostrar tooltips de auras durante el combate."

L.SlashQuest = "mision"
L.SlashQuestOn = "xanTooltipHoudini: Los tooltips de misiones ahora están [|cFF99CC33ACTIVADOS|r]"
L.SlashQuestOff = "xanTooltipHoudini: Los tooltips de misiones ahora están [|cFF99CC33DESACTIVADOS|r]"
L.SlashQuestInfo = "Permite mostrar tooltips de misiones durante el combate."
