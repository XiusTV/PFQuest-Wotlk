---@class QuestieQuestLinks
local QuestieQuestLinks = QuestieLoader:CreateModule("QuestieQuestLinks")

---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
---@type QuestiePlayer
local QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer")

local compat = pfQuestCompat
local math_floor = math.floor

local function GetConfig()
  pfQuest_config = pfQuest_config or {}
  return pfQuest_config
end

local function GetQuestName(questId, fallback)
  local loc = QuestieLib:GetQuestLocaleData(questId)
  if loc then
    if loc.T and loc.T ~= "" then
      return loc.T
    end
    if loc.Name and loc.Name ~= "" then
      return loc.Name
    end
  end
  if fallback and fallback ~= "" then
    return fallback
  end
  return string.format("Quest %d", questId)
end

local function ColorHex(color)
  color = color or { r = 1, g = 1, b = 1 }
  local r = math_floor((color.r or 1) * 255 + 0.5)
  local g = math_floor((color.g or 1) * 255 + 0.5)
  local b = math_floor((color.b or 1) * 255 + 0.5)
  return string.format("|cff%02x%02x%02x", r, g, b)
end

local function BuildDisplayChunks(questId, questLevel, questName)
  local config = GetConfig()
  local chunks = {}

  if questLevel and questLevel > 0 then
    table.insert(chunks, string.format("[%d]", questLevel))
  end

  table.insert(chunks, questName)

  if config.showids == "1" then
    table.insert(chunks, string.format("(%d)", questId))
  end

  return table.concat(chunks, " ")
end

function QuestieQuestLinks:IsEnabled()
  return GetConfig().enableQuestLinks == "1"
end

function QuestieQuestLinks:IsTooltipEnabled()
  return self:IsEnabled() and GetConfig().questLinkTooltip ~= "0"
end

function QuestieQuestLinks:GetQuestLink(questId, questName)
  if not questId or questId <= 0 then return nil end
  local questLevel = QuestieDB.QueryQuestSingle(questId, "questLevel")
  questLevel = questLevel and tonumber(questLevel) or 0
  questName = GetQuestName(questId, questName)

  local displayText = BuildDisplayChunks(questId, questLevel, questName)
  local color = compat.GetDifficultyColor(questLevel > 0 and questLevel or QuestiePlayer:GetPlayerLevel())
  local hex = ColorHex(color)

  local linkLevel = questLevel and questLevel or 0
  local hyperlink = string.format("%s|Hquest:%d:%d|h[%s]|h|r", hex, questId, linkLevel, displayText)
  return hyperlink
end

local function FormatQuestText(text)
  if not text then return nil end
  return pfDatabase and pfDatabase.FormatQuestText and pfDatabase:FormatQuestText(text) or text
end

function QuestieQuestLinks:AppendTooltipLines(tooltip, questId)
  if not tooltip or not questId or questId <= 0 then return end

  tooltip:ClearLines()

  local loc = pfDB and pfDB["quests"] and pfDB["quests"]["loc"] and pfDB["quests"]["loc"][questId]
  local data = pfDB and pfDB["quests"] and pfDB["quests"]["data"] and pfDB["quests"]["data"][questId]

  local questLevel = data and tonumber(data["lvl"]) or 0
  local color = compat.GetDifficultyColor(questLevel > 0 and questLevel or QuestiePlayer:GetPlayerLevel())
  local questTitle = loc and loc.T or GetQuestName(questId)
  tooltip:AddLine(questTitle, color.r, color.g, color.b, true)

  -- quest state
  local questState = pfQuest_history and pfQuest_history[questId] and 2 or 0
  questState = pfQuest and pfQuest.questlog and pfQuest.questlog[questId] and 1 or questState

  if questState == 0 then
    tooltip:AddLine(pfQuest_Loc["You don't have this quest."] or "You don't have this quest.", 1, 0.5, 0.5, true)
  elseif questState == 1 then
    tooltip:AddLine(pfQuest_Loc["You are on this quest."] or "You are on this quest.", 1, 1, 0.5, true)
  elseif questState == 2 then
    tooltip:AddLine(pfQuest_Loc["You already did this quest."] or "You already did this quest.", 0.5, 1, 0.5, true)
  end

  -- quest objectives / description
  if loc and loc.O then
    tooltip:AddLine(" ", 0, 0, 0, false)
    tooltip:AddLine(pfQuest_Loc["Quest Objectives"] or "Objectives", 1, 0.82, 0, false)
    tooltip:AddLine(FormatQuestText(loc.O), 1, 1, 1, true)
  end

  if loc and loc.D then
    tooltip:AddLine(" ", 0, 0, 0, false)
    tooltip:AddLine(FormatQuestText(loc.D), 0.8, 0.8, 0.8, true)
  end

  if data and (data["min"] or data["lvl"]) then
    tooltip:AddLine(" ", 0, 0, 0, false)
    if data["min"] then
      local required = tonumber(data["min"])
      local reqColor = compat.GetDifficultyColor(required or QuestiePlayer:GetPlayerLevel())
      tooltip:AddLine(string.format("|cffffffff%s: |r%d", pfQuest_Loc["Required Level"] or "Required Level", required or 0), reqColor.r, reqColor.g, reqColor.b)
    end
    if data["lvl"] then
      local qlvl = tonumber(data["lvl"])
      local lvlColor = compat.GetDifficultyColor(qlvl or QuestiePlayer:GetPlayerLevel())
      tooltip:AddLine(string.format("|cffffffff%s: |r%d", pfQuest_Loc["Quest Level"] or "Quest Level", qlvl or 0), lvlColor.r, lvlColor.g, lvlColor.b)
    end
  end

  -- quest log progress
  for i = 1, GetNumQuestLogEntries() do
    local title, _, _, _, _, _, _, questLogId = compat.GetQuestLogTitle(i)
    if questLogId == questId and title then
      local numObjectives = GetNumQuestLeaderBoards(i) or 0
      if numObjectives > 0 then
        tooltip:AddLine(" ", 0, 0, 0, false)
        tooltip:AddLine(pfQuest_Loc["Your progress"] or "Your progress", 1, 0.82, 0, false)
        for objIndex = 1, numObjectives do
          local objText, _, finished = GetQuestLogLeaderBoard(objIndex, i)
          if objText then
            local prefix = finished and "|cff33ff33" or "|cffffffff"
            tooltip:AddLine(prefix .. objText .. "|r", 1, 1, 1, false)
          end
        end
      end
      break
    end
  end

  tooltip:AddLine(" ", 0, 0, 0, false)
  tooltip:AddLine(string.format("|cffaaaaaa%s %d", pfQuest_Loc["Quest ID"] or "Quest ID", questId))

  tooltip:Show()
end

local CHAT_EVENTS = {
  "CHAT_MSG_SAY",
  "CHAT_MSG_YELL",
  "CHAT_MSG_GUILD",
  "CHAT_MSG_OFFICER",
  "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER",
  "CHAT_MSG_RAID",
  "CHAT_MSG_RAID_LEADER",
  "CHAT_MSG_RAID_WARNING",
  "CHAT_MSG_INSTANCE_CHAT",
  "CHAT_MSG_INSTANCE_CHAT_LEADER",
  "CHAT_MSG_CHANNEL",
  "CHAT_MSG_WHISPER",
  "CHAT_MSG_WHISPER_INFORM",
  "CHAT_MSG_BN",
  "CHAT_MSG_BN_WHISPER",
  "CHAT_MSG_BN_WHISPER_INFORM",
}

local function EnhanceMessageText(msg)
  if not msg or msg == "" then return msg end

  local replaced = msg:gsub("(|c%x+|Hquest:(%d+):[^|]-|h)%[[^]]-%]|h|r", function(prefix, questId)
    questId = tonumber(questId)
    if not questId then return prefix .. "[?]|h|r" end
    local enhanced = QuestieQuestLinks:GetQuestLink(questId)
    if enhanced then
      return enhanced
    end
    return prefix .. "[" .. GetQuestName(questId) .. "]|h|r"
  end)

  return replaced
end

function QuestieQuestLinks:Filter(_, _, msg, ...)
  if not self:IsEnabled() then
    return false, msg, ...
  end

  return false, EnhanceMessageText(msg), ...
end

function QuestieQuestLinks:RegisterFilters()
  if self._filtersRegistered then return end
  self._filterFunc = self._filterFunc or function(...)
    return QuestieQuestLinks:Filter(...)
  end
  for _, event in ipairs(CHAT_EVENTS) do
    ChatFrame_AddMessageEventFilter(event, self._filterFunc)
  end
  self._filtersRegistered = true
end

function QuestieQuestLinks:UnregisterFilters()
  if not self._filtersRegistered then return end
  for _, event in ipairs(CHAT_EVENTS) do
    ChatFrame_RemoveMessageEventFilter(event, self._filterFunc)
  end
  self._filtersRegistered = nil
end

function QuestieQuestLinks:RefreshFromConfig()
  if not self.initialized then return end
  if self:IsEnabled() then
    self:RegisterFilters()
  else
    self:UnregisterFilters()
  end
end

function QuestieQuestLinks:Initialize()
  if self.initialized then return end
  self.initialized = true
  self:RefreshFromConfig()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
  QuestieQuestLinks:Initialize()
end)

return QuestieQuestLinks

