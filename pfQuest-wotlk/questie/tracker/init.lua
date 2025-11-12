local Tracker = QuestieLoader:ImportModule("QuestieTracker")

-- Helper function to disable Blizzard tracker
local compat = pfQuestCompat
local defaultTrackerInfo = {} -- Store tracker info locally instead of on QuestieTracker

local function DisableDefaultTracker()
  local frame = compat.QuestWatchFrame or WatchFrame
  if not frame then return false end

  if not defaultTrackerInfo.frame then
    defaultTrackerInfo.frame = frame
    defaultTrackerInfo.onShow = frame:GetScript("OnShow")
    defaultTrackerInfo.parent = frame:GetParent()
    defaultTrackerInfo.hiddenParent = defaultTrackerInfo.hiddenParent or CreateFrame("Frame")
    defaultTrackerInfo.hiddenParent:Hide()
  end

  frame:SetParent(defaultTrackerInfo.hiddenParent)
  frame:Hide()
  frame:SetScript("OnShow", frame.Hide)
  frame:HookScript("OnShow", frame.Hide)
  
  -- Also store in Tracker module so core.lua can access it
  if Tracker then
    Tracker._defaultTracker = defaultTrackerInfo
  end
  
  -- Also try to store in QuestieTracker if it exists (for core.lua compatibility)
  if QuestieTracker then
    QuestieTracker._defaultTracker = defaultTrackerInfo
  end
  
  return true
end

-- Check pfQuest config directly to determine if tracker should be enabled
local function ShouldTrackerBeEnabled()
  -- Ensure config exists
  if not pfQuest_config then
    pfQuest_config = {}
  end
  -- Check if showtracker is explicitly set, default to "1" if not set
  local showtracker = pfQuest_config["showtracker"]
  if showtracker == nil then
    -- Not set, default to enabled
    return true
  end
  return showtracker == "1"
end

-- Sync config and initialize tracker
local function InitializeTracker()
  if not Tracker then return end
  
  -- Sync config before checking if tracker should be enabled
  if Tracker.SyncProfileFromConfig then
    Tracker:SyncProfileFromConfig()
  end
  
  -- Check if tracker should be enabled (from pfQuest config)
  local shouldEnable = ShouldTrackerBeEnabled()
  
  -- Also check Questie.db.profile.trackerEnabled as fallback
  local questieEnabled = Questie and Questie.db and Questie.db.profile and Questie.db.profile.trackerEnabled
  
  if shouldEnable or questieEnabled then
    -- Disable Blizzard tracker immediately
    local disabled = DisableDefaultTracker()
    
    -- Set up delayed check if frame doesn't exist yet
    if not disabled then
      local checkFrame = CreateFrame("Frame")
      local attempts = 0
      checkFrame:RegisterEvent("PLAYER_LOGIN")
      checkFrame:RegisterEvent("ADDON_LOADED")
      checkFrame:SetScript("OnEvent", function(self, event)
        DisableDefaultTracker()
        if DisableDefaultTracker() then
          self:UnregisterAllEvents()
          self:SetScript("OnUpdate", nil)
        end
      end)
      -- Also try periodically with OnUpdate (WotLK compatible)
      checkFrame:SetScript("OnUpdate", function(self, elapsed)
        attempts = attempts + 1
        DisableDefaultTracker()
        if attempts > 500 then -- Stop after ~5 seconds at 60fps
          self:UnregisterAllEvents()
          self:SetScript("OnUpdate", nil)
        end
      end)
    end
    
    -- Initialize our tracker
    Tracker:Initialize()
  end
end

-- Set up initialization that waits for both Questie and config to be ready
local initFrame = CreateFrame("Frame")
local attempts = 0
local configLoaded = false

-- Wait for ADDON_LOADED to ensure config is loaded
local configCheckFrame = CreateFrame("Frame")
configCheckFrame:RegisterEvent("ADDON_LOADED")
configCheckFrame:SetScript("OnEvent", function(self, event, addonName)
  -- Wait for pfQuest addon to load its config
  if addonName == "pfQuest-wotlk" or addonName == "pfQuest-tbc" or addonName == "pfQuest" then
    configLoaded = true
    -- Config should be loaded now, check if tracker should be enabled
    if ShouldTrackerBeEnabled() then
      DisableDefaultTracker()
      -- Set up persistent monitoring to keep Blizzard tracker disabled
      local blizzCheckFrame = CreateFrame("Frame")
      blizzCheckFrame:RegisterEvent("PLAYER_LOGIN")
      blizzCheckFrame:SetScript("OnEvent", function(self, event)
        if ShouldTrackerBeEnabled() then
          DisableDefaultTracker()
        end
      end)
      -- Periodic check (with timeout to avoid infinite loop)
      local attempts = 0
      blizzCheckFrame:SetScript("OnUpdate", function(self, elapsed)
        attempts = attempts + 1
        if ShouldTrackerBeEnabled() then
          DisableDefaultTracker()
        end
        -- Stop after reasonable time (OnShow hooks will handle it after that)
        if attempts > 300 then -- ~5 seconds
          self:SetScript("OnUpdate", nil)
        end
      end)
    end
    -- Try to initialize tracker now that config is loaded
    if Questie and Questie.db and Questie.db.profile then
      InitializeTracker()
    end
  end
end)

-- Also check if config is already loaded
if pfQuest_config and pfQuest_config["showtracker"] ~= nil then
  configLoaded = true
end

initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event)
  -- Check if both Questie and config are ready
  if Questie and Questie.db and Questie.db.profile and configLoaded then
    InitializeTracker()
    self:UnregisterAllEvents()
    self:SetScript("OnUpdate", nil)
  end
end)
-- Also check periodically
initFrame:SetScript("OnUpdate", function(self, elapsed)
  attempts = attempts + 1
  -- Update configLoaded status
  if pfQuest_config and pfQuest_config["showtracker"] ~= nil then
    configLoaded = true
  end
  if Questie and Questie.db and Questie.db.profile and configLoaded then
    InitializeTracker()
    self:UnregisterAllEvents()
    self:SetScript("OnUpdate", nil)
  elseif attempts > 1000 then -- Stop after ~16 seconds
    self:UnregisterAllEvents()
    self:SetScript("OnUpdate", nil)
  end
end)

