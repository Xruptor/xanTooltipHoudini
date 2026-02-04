local ADDON_NAME, private = ...

local L = private:NewLocale("ptBR")
if not L then return end

L.SlashAuras = "auras"
L.SlashAurasOn = "xanTooltipHoudini: Os tooltips de auras (Buff/Debuff) agora estão [|cFF99CC33ATIVADOS|r]"
L.SlashAurasOff = "xanTooltipHoudini: Os tooltips de auras (Buff/Debuff) agora estão [|cFF99CC33DESATIVADOS|r]"
L.SlashAurasInfo = "Permite exibir tooltips de auras durante o combate."

L.SlashQuest = "missao"
L.SlashQuestOn = "xanTooltipHoudini: Os tooltips de missões agora estão [|cFF99CC33ATIVADOS|r]"
L.SlashQuestOff = "xanTooltipHoudini: Os tooltips de missões agora estão [|cFF99CC33DESATIVADOS|r]"
L.SlashQuestInfo = "Permite exibir tooltips de missões durante o combate."
