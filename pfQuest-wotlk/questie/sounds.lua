---@class QuestieSounds
-- Plays quest-related audio cues (accept/completion) using pfQuest config values.
local QuestieSounds = QuestieLoader:CreateModule("QuestieSounds")

local DEFAULT_ACCEPT_SOUND = "igQuestListOpen"
local DEFAULT_COMPLETE_SOUND = "igQuestListComplete"

local function GetConfig()
  pfQuest_config = pfQuest_config or {}
  return pfQuest_config
end

local function normalizeDescriptor(descriptor, fallback)
  if type(descriptor) ~= "string" or descriptor == "" then
    return fallback
  end
  return descriptor
end

local function playDescriptor(descriptor)
  if not descriptor or descriptor == "" then
    return false
  end

  -- Try as sound ID first
  local soundId = tonumber(descriptor)
  if soundId then
    local success, err = pcall(function()
      PlaySound(soundId)
    end)
    if success then return true end
  end

  -- Try as file path
  if descriptor:find("\\") or descriptor:find("/") or descriptor:find("%.") then
    local success, err = pcall(function()
      PlaySoundFile(descriptor)
    end)
    if success then return true end
  end

  -- Try as sound name (string)
  local success, err = pcall(function()
    PlaySound(descriptor)
  end)
  if success then return true end

  -- Fallback: try with "Master" channel
  local success2, err2 = pcall(function()
    if PlaySoundFile then
      PlaySoundFile(descriptor, "Master")
    else
      PlaySound(descriptor, "Master")
    end
  end)
  
  return success2
end

function QuestieSounds:RefreshFromConfig()
  local config = GetConfig()

  self.enabled = config["enableQuestSounds"] == "1"

  local acceptDescriptor = normalizeDescriptor(config["questAcceptedSound"], DEFAULT_ACCEPT_SOUND)
  local completeDescriptor = normalizeDescriptor(config["questCompleteSound"], DEFAULT_COMPLETE_SOUND)

  if config["questAcceptedSound"] ~= acceptDescriptor then
    config["questAcceptedSound"] = acceptDescriptor
  end

  if config["questCompleteSound"] ~= completeDescriptor then
    config["questCompleteSound"] = completeDescriptor
  end

  self.acceptSound = acceptDescriptor
  self.completeSound = completeDescriptor
end

function QuestieSounds:PlayDescriptor(descriptor, fallback)
  local resolved = normalizeDescriptor(descriptor, fallback)
  playDescriptor(resolved)
end

function QuestieSounds:PreviewSound(descriptor, fallback)
  -- Ensure module is initialized
  if not self.initialized then
    self:Initialize()
  end
  
  -- Use descriptor if provided, otherwise fallback
  local soundToPlay = descriptor
  if not soundToPlay or soundToPlay == "" then
    soundToPlay = fallback
  end
  
  -- If still no sound, use defaults based on config key
  if not soundToPlay or soundToPlay == "" then
    if self.acceptSound then
      soundToPlay = self.acceptSound
    elseif self.completeSound then
      soundToPlay = self.completeSound
    else
      soundToPlay = fallback or DEFAULT_ACCEPT_SOUND
    end
  end
  
  -- Play the sound
  local success = playDescriptor(soundToPlay)
  
  -- If that failed and we have a fallback, try the fallback
  if not success and fallback and fallback ~= soundToPlay then
    playDescriptor(fallback)
  end
end

function QuestieSounds:IsEnabled()
  if self.enabled == nil then
    self:RefreshFromConfig()
  end
  return self.enabled
end

function QuestieSounds:OnQuestAccepted(questTitle, questId)
  if not self:IsEnabled() then
    return
  end
  self:PlayDescriptor(self.acceptSound, DEFAULT_ACCEPT_SOUND)
end

function QuestieSounds:OnQuestCompleted(questTitle, questId)
  if not self:IsEnabled() then
    return
  end
  self:PlayDescriptor(self.completeSound, DEFAULT_COMPLETE_SOUND)
end

function QuestieSounds:Initialize()
  if self.initialized then
    return
  end
  self:RefreshFromConfig()
  self.initialized = true
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    QuestieSounds:Initialize()
    self:UnregisterEvent("PLAYER_LOGIN")
  end
end)

return QuestieSounds

