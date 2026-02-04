local ADDON_NAME, private = ...

local L = private:NewLocale("koKR")
if not L then return end

L.SlashAuras = "오라"
L.SlashAurasOn = "xanTooltipHoudini: 오라(버프/디버프) 툴팁이 [|cFF99CC33켜짐|r] 상태입니다"
L.SlashAurasOff = "xanTooltipHoudini: 오라(버프/디버프) 툴팁이 [|cFF99CC33꺼짐|r] 상태입니다"
L.SlashAurasInfo = "전투 중 오라 툴팁 표시를 허용합니다."

L.SlashQuest = "퀘스트"
L.SlashQuestOn = "xanTooltipHoudini: 퀘스트 툴팁이 [|cFF99CC33켜짐|r] 상태입니다"
L.SlashQuestOff = "xanTooltipHoudini: 퀘스트 툴팁이 [|cFF99CC33꺼짐|r] 상태입니다"
L.SlashQuestInfo = "전투 중 퀘스트 툴팁 표시를 허용합니다."
