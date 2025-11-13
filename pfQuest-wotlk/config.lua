-- multi api compat
local compat = pfQuestCompat
local L = pfQuest_Loc
local wipe = _G.wipe or function(tbl)
  for key in pairs(tbl) do
    tbl[key] = nil
  end
end
local math_max = math.max
local math_min = math.min
local math_floor = math.floor

pfQuest_history = {}
pfQuest_colors = {}
pfQuest_config = {}

local function MigrateLegacyBronzebeardConfig()
  if not pfQuest_config then return end

  local migrations = {
    bronzebeardContinentPins = "continentPins",
    bronzebeardHideChickenQuests = "hideChickenQuests",
    bronzebeardHideFelwoodFlowers = "hideFelwoodFlowers",
    bronzebeardHidePvPQuests = "hidePvPQuests",
    bronzebeardHideCommissionQuests = "hideCommissionQuests",
    bronzebeardHideItemDrops = "hideItemDrops",
  }

  for legacyKey, newKey in pairs(migrations) do
    if pfQuest_config[newKey] == nil and pfQuest_config[legacyKey] ~= nil then
      pfQuest_config[newKey] = pfQuest_config[legacyKey]
    end
  end
end

MigrateLegacyBronzebeardConfig()

local function GetQuestLinksModule()
  if QuestieLoader and QuestieLoader.ImportModule then
    local ok, module = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieQuestLinks")
    if ok then
      return module
    end
  end
  return nil
end

local reset = {
  config = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the configuration?"]
    dialog.OnAccept = function()
      pfQuest_config = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  history = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the quest history?"]
    dialog.OnAccept = function()
      pfQuest_history = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  cache = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the caches?"]
    dialog.OnAccept = function()
      pfQuest_questcache = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  everything = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset everything?"]
    dialog.OnAccept = function()
      pfQuest_config, pfBrowser_fav, pfQuest_history, pfQuest_colors, pfQuest_server, pfQuest_questcache = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
}

-- default config
pfQuest_defconfig = {
  { -- 1: All Quests; 2: Tracked; 3: Manual; 4: Hide
    config = "trackingmethod",
    text = nil, default = 1, type = nil
  },

{ text = L["General"],
  default = nil, type = "header" },
  { text = L["Enable World Map Menu"],
    default = "1", type = "checkbox", config = "worldmapmenu" },
  { text = L["Enable Minimap Button"],
    default = "1", type = "checkbox", config = "minimapbutton" },
  { text = L["Enable Questie Menu"] or "Enable Questie Menu",
    default = "1", type = "checkbox", config = "enableQuestieMenu" },
  { text = L["Show Database IDs"],
    default = "0", type = "checkbox", config = "showids" },
  { text = L["Draw Favorites On Login"],
    default = "0", type = "checkbox", config = "favonlogin" },
  { text = L["Minimum Item Drop Chance"],
    default = "1", type = "text", config = "mindropchance" },

{ text = L["Credits"] or "Credits",
  default = nil, type = "header" },
  { text = (L["Original Creator"] or "Original Creator") .. ": |cff33ffccShagu|r",
    default = "", type = "info", url = "https://github.com/shagu/pfQuest" },
  { text = (L["Modernization, Integrations, and More"] or "Modernization, Integrations, and More") .. ": |cff33ffccXiusTV|r",
    default = "", type = "info", url = "https://github.com/XiusTV" },
  { text = L["XiusTV on Twitch"] or "XiusTV on Twitch",
    default = "", type = "info", url = "https://www.twitch.tv/xiustv" },
  { text = (L["Contributors"] or "Contributors") .. ": |cff33ffccBennylavaa|r",
    default = "", type = "info", url = "https://github.com/Bennylavaa/pfQuest-epoch" },

{ text = L["Questing"],
  default = nil, type = "header" },
  { text = L["Enable Quest Tracker"],
    default = "1", type = "checkbox", config = "showtracker", onupdate = function()
      if Questie and Questie.LoaderInitialized then
        if pfQuest_config["showtracker"] == "1" then
          Questie.db.profile.trackerEnabled = true
          QuestieLoader:ImportModule("QuestieTracker"):Enable()
        else
          Questie.db.profile.trackerEnabled = false
          local tracker = QuestieLoader:ImportModule("QuestieTracker")
          if tracker and tracker.Disable then
            tracker:Disable()
          end
        end
      end
    end },
  { text = L["Quest Tracker Visibility"],
    default = "0", type = "text", config = "trackeralpha" },
  { text = L["Quest Tracker Font Size"],
    default = "12", type = "text", config = "trackerfontsize", },
  { text = L["Quest Tracker Unfold Objectives"],
    default = "0", type = "checkbox", config = "trackerexpand" },
  { text = L["Fade Tracker When Idle"] or "Fade Tracker When Idle",
    default = "0", type = "checkbox", config = "trackerfade", onupdate = function()
      local tracker = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieTracker")
      if tracker and tracker.SyncProfileFromConfig then
        tracker:SyncProfileFromConfig()
      end
      if tracker and tracker.RefreshFade then
        tracker:RefreshFade()
      end
      if pfQuestConfig and pfQuestConfig.SetSliderEnabled then
        pfQuestConfig:SetSliderEnabled("trackerfadealpha", pfQuest_config["trackerfade"] == "1")
      end
    end },
  { text = L["Tracker Fade Opacity"] or "Tracker Fade Opacity",
    default = "0.12", type = "slider", config = "trackerfadealpha", min = 0.0, max = 0.35, step = 0.01,
    format = "%.2f", displayFormatter = function(value)
      return string.format("%d%%", math_floor((value or 0) * 100 + 0.5))
    end,
    onupdate = function()
      local tracker = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieTracker")
      if tracker and tracker.RefreshFade then
        tracker:RefreshFade()
      end
    end },
  { text = L["Stick Durability Frame"] or "Stick Durability Frame",
    default = "0", type = "checkbox", config = "stickydurability", onupdate = function()
      local tracker = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieTracker")
      if tracker and tracker.SyncProfileFromConfig then
        tracker:SyncProfileFromConfig()
      end
      if tracker and tracker.UpdateAnchoredFrames then
        tracker:UpdateAnchoredFrames()
      end
    end },
  { text = L["Stick VoiceOver Frame"] or "Stick VoiceOver Frame",
    default = "0", type = "checkbox", config = "stickyvoiceover", onupdate = function()
      local tracker = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieTracker")
      if tracker and tracker.SyncProfileFromConfig then
        tracker:SyncProfileFromConfig()
      end
      if tracker and tracker.UpdateAnchoredFrames then
        tracker:UpdateAnchoredFrames()
      end
    end },
  { text = L["Enable Quest Focus"] or "Enable Quest Focus",
    default = "0", type = "checkbox", config = "focusenable", onupdate = function()
      local focus = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieFocus")
      if focus and focus.RefreshFromConfig then
        focus:RefreshFromConfig()
      end
    end },
  { text = L["Fade Non-Focused Quest Icons"] or "Fade Non-Focused Quest Icons",
    default = "1", type = "checkbox", config = "focusfade", onupdate = function()
      local focus = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieFocus")
      if focus and focus.Apply then
        focus:Apply()
      end
    end },
  { text = L["Dim Cluster Nodes While Focused"] or "Dim Cluster Nodes While Focused",
    default = "1", type = "checkbox", config = "focusclusterdim", onupdate = function()
      local focus = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieFocus")
      if focus and focus.RefreshFromConfig then
        focus:RefreshFromConfig()
      elseif focus and focus.Apply then
        focus:Apply()
      end
    end },
  { text = L["Highlight Focused Quest Icons"] or "Highlight Focused Quest Icons",
    default = "1", type = "checkbox", config = "focushighlight", onupdate = function()
      local focus = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieFocus")
      if focus and focus.RefreshFromConfig then
        focus:RefreshFromConfig()
      elseif focus and focus.Apply then
        focus:Apply()
      end
    end },
  { text = L["Share Quest Focus With Party"] or "Share Quest Focus With Party",
    default = "0", type = "checkbox", config = "focuspartyshare", onupdate = function()
      local focus = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieFocus")
      if focus and focus.RefreshFromConfig then
        focus:RefreshFromConfig()
      end
    end },
  { text = L["Show Party Focus Highlights"] or "Show Party Focus Highlights",
    default = "0", type = "checkbox", config = "focuspartyreceive", onupdate = function()
      local focus = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieFocus")
      if focus and focus.RefreshFromConfig then
        focus:RefreshFromConfig()
      end
    end },
  { text = L["Enable Quest Auto Accept"],
    default = "0", type = "checkbox", config = "autoaccept", onupdate = function()
      if Questie and Questie.db and Questie.db.profile then
        Questie.db.profile.autoaccept = pfQuest_config["autoaccept"] == "1"
      end
    end },
  { text = L["Enable Quest Auto Turn-In"],
    default = "0", type = "checkbox", config = "autocomplete", onupdate = function()
      if Questie and Questie.db and Questie.db.profile then
        Questie.db.profile.autocomplete = pfQuest_config["autocomplete"] == "1"
      end
    end },
  { text = L["Auto Accept Daily Quests"],
    default = "0", type = "checkbox", config = "autoacceptdailyonly", onupdate = function()
      if QuestieAuto and QuestieAuto.settings then
        QuestieAuto.settings.dailyOnly = pfQuest_config["autoacceptdailyonly"] == "1"
      end
    end },
  { text = L["Auto Quest Exclusions (comma or newline separated)"],
    default = "", type = "text", config = "autoexclusions", onupdate = function()
      if QuestieAuto and QuestieAuto.SetCustomExclusions then
        QuestieAuto:SetCustomExclusions(pfQuest_config["autoexclusions"] or "")
      end
    end },
  { text = L["Enable Quest Log Buttons"],
    default = "1", type = "checkbox", config = "questlogbuttons" },
  { text = L["Enable Quest Link Support"],
    default = "1", type = "checkbox", config = "questlinks" },
  { text = L["Enable Enhanced Quest Links"] or "Enable Enhanced Quest Links",
    default = "0", type = "checkbox", config = "enableQuestLinks", onupdate = function()
      local questLinks = GetQuestLinksModule()
      if questLinks and questLinks.RefreshFromConfig then
        questLinks:RefreshFromConfig()
      end
    end },
  { text = L["Show Enhanced Link Tooltips"] or "Show Enhanced Link Tooltips",
    default = "1", type = "checkbox", config = "questLinkTooltip", onupdate = function()
      local questLinks = GetQuestLinksModule()
      if questLinks and questLinks.RefreshFromConfig then
        questLinks:RefreshFromConfig()
      end
    end },
  { text = L["Show Quest Giver Paths"] or "Show Quest Giver Paths",
    default = "1", type = "checkbox", config = "showgiverpaths" },
  { text = L["Show Tooltips"],
    default = "1", type = "checkbox", config = "showtooltips" },
  { text = L["Show Party Progress On Tooltips"] or "Show Party Progress On Tooltips",
    default = "1", type = "checkbox", config = "tooltippartyprogress", onupdate = function()
      local partySync = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestiePartySync")
      if partySync and partySync.RefreshFromConfig then
        partySync:RefreshFromConfig()
      end
    end },
  { text = L["Show Help On Tooltips"],
    default = "1", type = "checkbox", config = "tooltiphelp" },
  { text = L["Show Level On Quest Tracker"],
    default = "1", type = "checkbox", config = "trackerlevel" },
  { text = L["Show Level On Quest Log"],
    default = "0", type = "checkbox", config = "questloglevel" },
  { text = L["Enable Quest Icons On Nameplates"] or "Enable Quest Icons On Nameplates",
    default = "0", type = "checkbox", config = "nameplateEnabled", onupdate = function()
      local nameplate = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieNameplate")
      if nameplate and nameplate.RefreshFromConfig then
        nameplate:RefreshFromConfig()
      end
    end },
  { text = L["Nameplate Icon Scale"] or "Nameplate Icon Scale",
    default = "1.0", type = "text", config = "nameplateIconScale", onupdate = function()
      local nameplate = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieNameplate")
      if nameplate and nameplate.RefreshFromConfig then
        nameplate:RefreshFromConfig()
      end
    end },

{ text = L["Announce"],
  default = nil, type = "header" },
  { text = L["Announce Quest Accepted"] or "Announce Quest Accepted",
    default = "0", type = "checkbox", config = "announceQuestAccepted" },
  { text = L["Announce Finished Quest Objectives"] or "Announce Finished Quest Objectives",
    default = "1", type = "checkbox", config = "announceFinishedObjectives" },
  { text = L["Announce Remaining Quest Objectives"] or "Announce Remaining Quest Objectives",
    default = "0", type = "checkbox", config = "announceRemainingObjectives" },
  { text = L["Enable Quest Sounds"] or "Enable Quest Sounds",
    default = "0", type = "checkbox", config = "enableQuestSounds", onupdate = function()
      local sounds = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieSounds")
      if sounds and sounds.RefreshFromConfig then
        sounds:RefreshFromConfig()
      end
    end },
  { text = L["Quest Accepted Sound"] or "Quest Accepted Sound",
    default = "igQuestListOpen", type = "select", config = "questAcceptedSound",
    values = {
      { value = "igQuestListOpen", label = "Quest List Open" },
      { value = "igQuestLogAbandonQuest", label = "Abandon Quest" },
      { value = "igMainMenuOptionCheckBoxOn", label = "Checkbox On" },
      { value = "igMainMenuOption", label = "Main Menu Option" },
      { value = "TellMessage", label = "Tell Message" },
      { value = "MapPing", label = "Map Ping" },
      { value = "QUESTADDED", label = "Quest Added" },
    },
    onupdate = function()
      local sounds = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieSounds")
      if sounds and sounds.RefreshFromConfig then
        sounds:RefreshFromConfig()
      end
    end },
  { text = L["Quest Completed Sound"] or "Quest Completed Sound",
    default = "igQuestListComplete", type = "select", config = "questCompleteSound",
    values = {
      { value = "igQuestListComplete", label = "Quest List Complete" },
      { value = "QUESTCOMPLETE", label = "Quest Complete" },
      { value = "LEVELUP", label = "Level Up" },
      { value = "MapPing", label = "Map Ping" },
      { value = "TellMessage", label = "Tell Message" },
      { value = "igMainMenuOptionCheckBoxOn", label = "Checkbox On" },
    },
    onupdate = function()
      local sounds = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieSounds")
      if sounds and sounds.RefreshFromConfig then
        sounds:RefreshFromConfig()
      end
    end },

{ text = L["Map & Minimap"],
    default = nil, type = "header" },
  { text = L["Quest Objective Spawn Points (World Map)"],
    default = "1", type = "checkbox", config = "showspawn" },
  { text = L["Quest Objective Spawn Points (Mini Map)"],
    default = "1", type = "checkbox", config = "showspawnmini" },
  { text = L["Quest Objective Icons (World Map)"],
    default = "1", type = "checkbox", config = "showcluster" },
  { text = L["Quest Objective Icons (Mini Map)"],
    default = "0", type = "checkbox", config = "showclustermini" },
  { text = L["Display Available Quest Givers"],
    default = "1", type = "checkbox", config = "allquestgivers" },
  { text = L["Display Current Quest Givers"],
    default = "1", type = "checkbox", config = "currentquestgivers" },
  { text = L["Display Low Level Quest Givers"],
    default = "0", type = "checkbox", config = "showlowlevel" },
  { text = L["Display Level+3 Quest Givers"],
    default = "0", type = "checkbox", config = "showhighlevel" },
  { text = L["Display Event & Daily Quests"],
    default = "0", type = "checkbox", config = "showfestival" },
  { text = L["Hide PvP/Battleground Quests"] or "Hide PvP/Battleground Quests",
    default = "1", type = "checkbox", config = "hidePvPQuests" },
  { text = L["Hide Commission Quests"] or "Hide Commission Quests",
    default = "0", type = "checkbox", config = "hideCommissionQuests" },
  { text = L["Hide Chicken Quests (CLUCK!)"] or "Hide Chicken Quests (CLUCK!)",
    default = "1", type = "checkbox", config = "hideChickenQuests" },
  { text = L["Hide Felwood Corrupted Flowers"] or "Hide Felwood Corrupted Flowers",
    default = "1", type = "checkbox", config = "hideFelwoodFlowers" },
  { text = L["Hide Item Drop Quest Starters"] or "Hide Item Drop Quest Starters",
    default = "0", type = "checkbox", config = "hideItemDrops" },
  { text = L["Enable Minimap Nodes"],
    default = "1", type = "checkbox", config = "minimapnodes" },
  { text = L["Use Icons For Tracking Nodes"],
    default = "1", type = "checkbox", config = "trackingicons" },
  { text = L["Use Monochrome Cluster Icons"],
    default = "0", type = "checkbox", config = "clustermono" },
  { text = L["Use Cut-Out Minimap Node Icons"],
    default = "1", type = "checkbox", config = "cutoutminimap" },
  { text = L["Use Cut-Out World Map Node Icons"],
    default = "0", type = "checkbox", config = "cutoutworldmap" },
  { text = L["Color Map Nodes By Spawn"],
    default = "0", type = "checkbox", config = "spawncolors" },
  { text = L["World Map Node Transparency"],
    default = "1.0", type = "text", config = "worldmaptransp" },
  { text = L["Minimap Node Transparency"],
    default = "1.0", type = "text", config = "minimaptransp" },
  { text = L["Node Fade Transparency"],
    default = "0.3", type = "text", config = "nodefade" },
  { text = L["Highlight Nodes On Mouseover"],
    default = "1", type = "checkbox", config = "mouseover" },
  { text = L["Display Continent Pins"] or "Display Continent Pins",
    default = "1", type = "checkbox", config = "continentPins" },
  { text = L["Require Ctrl+Click for Pin Interaction"] or "Require Ctrl+Click for Pin Interaction",
    default = "0", type = "checkbox", config = "continentClickThrough" },
  { text = L["Continent Node Size"] or "Continent Node Size",
    default = "12", type = "text", config = "continentNodeSize" },
  { text = L["Continent Utility Node Size"] or "Continent Utility Node Size",
    default = "14", type = "text", config = "continentUtilityNodeSize" },

  { text = L["Routes"],
    default = nil, type = "header" },
  { text = L["Show Route Between Objects"],
    default = "1", type = "checkbox", config = "routes" },
  { text = L["Include Unified Quest Locations"],
    default = "1", type = "checkbox", config = "routecluster" },
  { text = L["Include Quest Enders"],
    default = "1", type = "checkbox", config = "routeender" },
  { text = L["Include Quest Starters"],
    default = "0", type = "checkbox", config = "routestarter" },
  { text = L["Show Route On Minimap"],
    default = "0", type = "checkbox", config = "routeminimap" },
  { text = L["Show Arrow Along Routes"],
    default = "1", type = "checkbox", config = "arrow" },

  { text = L["User Data"],
    default = nil, type = "header" },
  { text = L["Reset Configuration"],
    default = "1", type = "button", func = reset.config },
  { text = L["Reset Quest History"],
    default = "1", type = "button", func = reset.history },
  { text = L["Reset Cache"],
    default = "1", type = "button", func = reset.cache },
  { text = L["Reset Everything"],
    default = "1", type = "button", func = reset.everything },
}

StaticPopupDialogs["PFQUEST_RESET"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

pfQuestConfig = CreateFrame("Frame", "pfQuestConfig", UIParent)
pfQuestConfig:Hide()
pfQuestConfig:SetWidth(760)
pfQuestConfig:SetHeight(560)
pfQuestConfig:SetPoint("CENTER", 0, 0)
pfQuestConfig:SetFrameStrata("HIGH")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:SetClampedToScreen(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")
pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()
    pfQuestConfig:CreateConfigEntries(pfQuest_defconfig)

    pfQuest_questcache = pfQuest_questcache or {}
    pfQuest_history = pfQuest_history or {}
    pfQuest_colors = pfQuest_colors or {}
    pfQuest_config = pfQuest_config or {}
    pfQuest_track = pfQuest_track or {}
    pfBrowser_fav = pfBrowser_fav or {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

    -- clear quest history on new characters
    if UnitXP("player") == 0 and UnitLevel("player") == 1 then
      pfQuest_history = {}
    end

    if pfBrowserIcon and pfQuest_config["minimapbutton"] == "0" then
      pfBrowserIcon:Hide()
    end
  end
end)

pfQuestConfig:SetScript("OnMouseDown", function()
  this:StartMoving()
end)

pfQuestConfig:SetScript("OnMouseUp", function()
  this:StopMovingOrSizing()
end)

pfQuestConfig:SetScript("OnShow", function()
  this:UpdateConfigEntries()
end)

pfQuestConfig.vpos = 40

pfUI.api.CreateBackdrop(pfQuestConfig, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestConfig")

-- detect current addon path
local tocs = { "", "-master", "-tbc", "-wotlk" }
for _, name in pairs(tocs) do
  local current = string.format("pfQuest%s", name)
  local _, title = GetAddOnInfo(current)
  if title then
    pfQuestConfig.path = "Interface\\AddOns\\" .. current
    pfQuestConfig.version = tostring(GetAddOnMetadata(current, "Version"))
    break
  end
end

pfQuestConfig.title = pfQuestConfig:CreateFontString("Status", "LOW", "GameFontNormal")
pfQuestConfig.title:SetFontObject(GameFontWhite)
pfQuestConfig.title:SetPoint("TOP", pfQuestConfig, "TOP", 0, -8)
pfQuestConfig.title:SetJustifyH("LEFT")
pfQuestConfig.title:SetFont(pfUI.font_default, 14)
pfQuestConfig.title:SetText("|cff33ffccpf|rQuest " .. L["Config"])

pfQuestConfig.close = CreateFrame("Button", "pfQuestConfigClose", pfQuestConfig)
pfQuestConfig.close:SetPoint("TOPRIGHT", -5, -5)
pfQuestConfig.close:SetHeight(20)
pfQuestConfig.close:SetWidth(20)
pfQuestConfig.close.texture = pfQuestConfig.close:CreateTexture("pfQuestionDialogCloseTex")
pfQuestConfig.close.texture:SetTexture(pfQuestConfig.path.."\\compat\\close")
pfQuestConfig.close.texture:ClearAllPoints()
pfQuestConfig.close.texture:SetPoint("TOPLEFT", pfQuestConfig.close, "TOPLEFT", 4, -4)
pfQuestConfig.close.texture:SetPoint("BOTTOMRIGHT", pfQuestConfig.close, "BOTTOMRIGHT", -4, 4)

pfQuestConfig.close.texture:SetVertexColor(1,.25,.25,1)
pfUI.api.SkinButton(pfQuestConfig.close, 1, .5, .5)
pfQuestConfig.close:SetScript("OnClick", function()
  this:GetParent():Hide()
end)

pfQuestConfig.welcome = CreateFrame("Button", "pfQuestConfigWelcome", pfQuestConfig)
pfQuestConfig.welcome:SetWidth(160)
pfQuestConfig.welcome:SetHeight(28)
pfQuestConfig.welcome:SetPoint("BOTTOMLEFT", 10, 10)
pfQuestConfig.welcome:SetScript("OnClick", function() pfQuestConfig:Hide(); pfQuestInit:Show() end)
pfQuestConfig.welcome.text = pfQuestConfig.welcome:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.welcome.text:SetAllPoints(pfQuestConfig.welcome)
pfQuestConfig.welcome.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.welcome.text:SetText(L["Welcome Screen"])
pfUI.api.SkinButton(pfQuestConfig.welcome)

pfQuestConfig.save = CreateFrame("Button", "pfQuestConfigReload", pfQuestConfig)
pfQuestConfig.save:SetWidth(160)
pfQuestConfig.save:SetHeight(28)
pfQuestConfig.save:SetPoint("BOTTOMRIGHT", -10, 10)
pfQuestConfig.save:SetScript("OnClick", ReloadUI)
pfQuestConfig.save.text = pfQuestConfig.save:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.save.text:SetAllPoints(pfQuestConfig.save)
pfQuestConfig.save.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.save.text:SetText(L["Save & Close"])
pfUI.api.SkinButton(pfQuestConfig.save)

pfQuestConfig.versionLabel = pfQuestConfig:CreateFontString(nil, "LOW", "GameFontHighlight")
pfQuestConfig.versionLabel:SetPoint("BOTTOM", pfQuestConfig, "BOTTOM", 0, 24)
pfQuestConfig.versionLabel:SetText("|cff33ffccVersion 0.9 (Beta)|r")

function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end
  for id, data in pairs(pfQuest_defconfig) do
    if data.config and not pfQuest_config[data.config] then
      pfQuest_config[data.config] = data.default
    end
  end
end

function pfQuestConfig:MigrateHistory()
  if not pfQuest_history then return end

  local match = false

  for entry, data in pairs(pfQuest_history) do
    if type(entry) == "string" then
      for id in pairs(pfDatabase:GetIDByName(entry, "quests")) do
        pfQuest_history[id] = { 0, 0 }
        pfQuest_history[entry] = nil
        match = true
      end
    elseif data == true then
      pfQuest_history[entry] = { 0, 0 }
    elseif type(data) == "table" and not data[1] then
      pfQuest_history[entry] = { 0, 0 }
    end
  end

  if match == true then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: " .. L["Quest history migration completed."])
  end
end

local configframes = {}

local function StyleDropdownControl(dropdown, dropdownName)
  if not dropdown then return end
  dropdownName = dropdownName or (dropdown.GetName and dropdown:GetName())
  if not dropdownName then return end

  dropdown:SetHeight(22)

  local left = _G[dropdownName .. "Left"]
  local middle = _G[dropdownName .. "Middle"]
  local right = _G[dropdownName .. "Right"]
  if left then left:Hide() end
  if middle then middle:Hide() end
  if right then right:Hide() end

  if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
    pfUI.api.CreateBackdrop(dropdown, nil, true)
    if dropdown.backdrop then
      dropdown.backdrop:SetPoint("TOPLEFT", dropdown, "TOPLEFT", -3, 3)
      dropdown.backdrop:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 3, -3)
    end
  end

  local text = _G[dropdownName .. "Text"]
  if text then
    text:ClearAllPoints()
    text:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    text:SetPoint("RIGHT", dropdown, "RIGHT", -20, 0)
    text:SetJustifyH("LEFT")
    text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  end

  local button = _G[dropdownName .. "Button"]
  if button then
    button:ClearAllPoints()
    button:SetPoint("RIGHT", dropdown, "RIGHT", -2, 0)
    button:SetSize(16, 16)
    button:SetNormalTexture(nil)
    button:SetPushedTexture(nil)
    button:SetHighlightTexture(nil)

    if not button.icon then
      button.icon = button:CreateTexture(nil, "ARTWORK")
      button.icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
      button.icon:SetSize(12, 12)
      button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    button.icon:SetVertexColor(.2, 1, .8, 1)
  end
end

function pfQuestConfig:CreateConfigEntries(config)
  if self.categories then
    for _, cat in pairs(self.categories) do
      if cat.button then
        cat.button:Hide()
      end
      if cat.frame then
        cat.frame:Hide()
      end
    end
  end

  if self.categoryButtons then
    for _, button in pairs(self.categoryButtons) do
      button:Hide()
    end
  end

  wipe(configframes)

  self.categories = {}
  self.categoryOrder = {}
  self.categoryButtons = {}
  self.sliderRegistry = {}

  local sidebarWidth = 190

  if not self.sidebar then
    self.sidebar = CreateFrame("Frame", nil, self)
    self.sidebar:SetPoint("TOPLEFT", 10, -40)
    self.sidebar:SetPoint("BOTTOMLEFT", 10, 50)
    self.sidebar:SetWidth(sidebarWidth)
    pfUI.api.CreateBackdrop(self.sidebar, nil, true, 0.5)
  end

  if not self.content then
    self.content = CreateFrame("Frame", nil, self)
    self.content:SetPoint("TOPLEFT", self.sidebar, "TOPRIGHT", 10, 0)
    self.content:SetPoint("BOTTOMRIGHT", -10, 50)
    pfUI.api.CreateBackdrop(self.content, nil, true, 0.5)

    self.scroll = CreateFrame("ScrollFrame", "pfQuestConfigScroll", self.content, "UIPanelScrollFrameTemplate")
    self.scroll:SetPoint("TOPLEFT", 6, -6)
    self.scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    if self.scroll.SetClipsChildren then
      self.scroll:SetClipsChildren(true)
    end

    self.scrollContent = CreateFrame("Frame", nil, self.scroll)
    self.scrollContent:SetPoint("TOPLEFT", 0, 0)
    self.scrollContent:SetWidth(math_max(self.content:GetWidth() - 32, 0))
    self.scrollContent:SetHeight(1)
    self.scroll:SetScrollChild(self.scrollContent)

    self.content:SetScript("OnSizeChanged", function(_, width)
      if not pfQuestConfig.scrollContent then return end
      pfQuestConfig.scrollContent:SetWidth(math_max(width - 32, 0))
    end)
  end

  local DEFAULT_CATEGORY = L["General"] or "General"
  local currentCategory = nil

  for _, data in ipairs(config) do
    if data.type == "header" then
      currentCategory = data.text or DEFAULT_CATEGORY
      if not self.categories[currentCategory] then
        table.insert(self.categoryOrder, currentCategory)
        self.categories[currentCategory] = { entries = {} }
      end
    elseif data.type then
      if not currentCategory then
        currentCategory = DEFAULT_CATEGORY
        if not self.categories[currentCategory] then
          table.insert(self.categoryOrder, currentCategory)
          self.categories[currentCategory] = { entries = {} }
        end
      end
      table.insert(self.categories[currentCategory].entries, data)
    end
  end

  local previousButton = nil
  for _, name in ipairs(self.categoryOrder) do
    local category = self.categories[name]

    local button = CreateFrame("Button", nil, self.sidebar)
    button:SetWidth(sidebarWidth - 20)
    button:SetHeight(26)
    if previousButton then
      button:SetPoint("TOP", previousButton, "BOTTOM", 0, -6)
    else
      button:SetPoint("TOP", self.sidebar, "TOP", 0, -12)
    end
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    button.text:SetAllPoints(button)
    button.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
    button.text:SetText(name)
    pfUI.api.SkinButton(button)
    button:SetScript("OnClick", function()
      pfQuestConfig:ShowCategory(name)
    end)

    category.button = button
    self.categoryButtons[name] = button
    previousButton = button

    local container = CreateFrame("Frame", nil, self.scrollContent)
    container:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 12, -12)
    container:SetPoint("RIGHT", self.scrollContent, "RIGHT", -12, 0)
    container:Hide()

    category.frame = container
    category.totalHeight = 20

    container.title = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    container.title:SetFont(pfUI.font_default, pfUI_config.global.font_size + 2, "OUTLINE")
    container.title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    container.title:SetText(name)
    container.title:SetJustifyH("LEFT")

    local anchor = container.title
    local spacing = 10
    local rowHeight = 26

    for _, data in ipairs(category.entries) do
      local entryData = data
      local frame = CreateFrame("Frame", nil, container)
      frame:SetHeight(rowHeight)
      frame:SetPoint("LEFT", container, "LEFT", 0, 0)
      frame:SetPoint("RIGHT", container, "RIGHT", 0, 0)
      frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -spacing)
      anchor = frame

      frame.caption = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
      frame.caption:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
      frame.caption:SetPoint("LEFT", frame, "LEFT", 0, 0)
      frame.caption:SetPoint("RIGHT", frame, "RIGHT", -180, 0)
      frame.caption:SetJustifyH("LEFT")
      frame.caption:SetText(entryData.text or "")

      if entryData.type == "checkbox" then
        frame.input = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.input:SetNormalTexture("")
        frame.input:SetPushedTexture("")
        frame.input:SetHighlightTexture("")
        pfUI.api.CreateBackdrop(frame.input, nil, true)
        frame.input:SetWidth(18)
        frame.input:SetHeight(18)
        frame.input:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        frame.input.config = entryData.config
        if pfQuest_config[entryData.config] == "1" then
          frame.input:SetChecked()
        end
        frame.input:SetScript("OnClick", function()
          if this:GetChecked() then
            pfQuest_config[this.config] = "1"
          else
            pfQuest_config[this.config] = "0"
          end

          if entryData.onupdate then
            entryData.onupdate()
          end

          pfQuest:ResetAll()
        end)
      elseif entryData.type == "text" then
        frame.input = CreateFrame("EditBox", nil, frame)
        frame.input:SetTextColor(.2,1,.8,1)
        frame.input:SetJustifyH("RIGHT")
        frame.input:SetTextInsets(6,6,4,4)
        frame.input:SetWidth(140)
        frame.input:SetHeight(20)
        frame.input:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        frame.input:SetFontObject(GameFontNormal)
        frame.input:SetAutoFocus(false)
        frame.input:SetScript("OnEscapePressed", function()
          this:ClearFocus()
        end)
        frame.input:SetScript("OnEnterPressed", function()
          this:ClearFocus()
        end)
        frame.input.config = entryData.config
        frame.input:SetText(pfQuest_config[entryData.config])
        frame.input:SetScript("OnTextChanged", function()
          pfQuest_config[this.config] = this:GetText()
          if entryData.onupdate then
            entryData.onupdate()
          end
        end)
        pfUI.api.CreateBackdrop(frame.input, nil, true)
      elseif entryData.type == "slider" then
        local sliderName = "pfQuestConfigSlider" .. (entryData.config or tostring(entryData))
        if _G[sliderName] then
          local index = 1
          while _G[sliderName .. index] do
            index = index + 1
          end
          sliderName = sliderName .. index
        end

        frame.input = CreateFrame("Slider", sliderName, frame, "OptionsSliderTemplate")
        local slider = frame.input
        slider:SetWidth(150)
        slider:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
        slider:SetMinMaxValues(entryData.min or 0, entryData.max or 1)
        slider:SetValueStep(entryData.step or 0.05)
        if slider.SetObeyStepOnDrag then
          slider:SetObeyStepOnDrag(true)
        end
        slider.config = entryData.config
        slider.format = entryData.format or "%.2f"
        slider.displayFormatter = entryData.displayFormatter
        slider.minValue = entryData.min or 0
        slider.maxValue = entryData.max or 1
        slider.step = entryData.step or 0.05

        local lowText = _G[sliderName .. "Low"]
        if lowText then
          local lowDisplay = slider.displayFormatter and slider.displayFormatter(slider.minValue) or string.format(slider.format, slider.minValue)
          lowText:SetText(lowDisplay)
        end
        local highText = _G[sliderName .. "High"]
        if highText then
          local highDisplay = slider.displayFormatter and slider.displayFormatter(slider.maxValue) or string.format(slider.format, slider.maxValue)
          highText:SetText(highDisplay)
        end
        local centerText = _G[sliderName .. "Text"]
        if centerText then
          centerText:SetText("")
        end

        slider.valueText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        slider.valueText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
        slider.valueText:SetFont(pfUI.font_default, pfUI_config.global.font_size - 1, "OUTLINE")
        slider.valueText:SetJustifyH("LEFT")

        local currentValue = tonumber(pfQuest_config[entryData.config])
        if not currentValue then
          currentValue = tonumber(entryData.default)
        end
        if not currentValue then
          currentValue = slider.minValue
        end
        currentValue = math_max(slider.minValue, math_min(slider.maxValue, currentValue))
        slider._updating = true
        slider:SetValue(currentValue)
        slider._updating = nil

        local displayText
        if slider.displayFormatter then
          displayText = slider.displayFormatter(currentValue)
        else
          displayText = string.format(slider.format, currentValue)
        end
        slider.valueText:SetText(displayText)
        pfQuest_config[entryData.config] = string.format(slider.format, currentValue)

        slider:SetScript("OnValueChanged", function(self, value)
          if self._updating then return end
          local minValue = self.minValue or 0
          local maxValue = self.maxValue or 1
          local step = self.step or 0.05
          local precision = step > 0 and (1 / step) or 100
          value = math_max(minValue, math_min(maxValue, math_floor(value * precision + 0.5) / precision))

          pfQuest_config[self.config] = string.format(self.format or "%.2f", value)

          if self.valueText then
            if self.displayFormatter then
              self.valueText:SetText(self.displayFormatter(value))
            else
              self.valueText:SetText(string.format(self.format or "%.2f", value))
            end
          end

          if entryData.onupdate then
            entryData.onupdate(value)
          end
        end)

        if pfQuestConfig and pfQuestConfig.sliderRegistry then
          pfQuestConfig.sliderRegistry[entryData.config] = slider
        end
      elseif entryData.type == "info" then
        frame.caption:ClearAllPoints()
        frame.caption:SetPoint("LEFT", frame, "LEFT", 0, 0)
        frame.caption:SetPoint("RIGHT", frame, "RIGHT", (entryData.url and -90 or 0), 0)
        frame.caption:SetText(entryData.text or "")
        frame.caption:SetJustifyH("LEFT")
        frame.caption:SetTextColor(0.8, 0.8, 0.8, 1)

        if entryData.url then
          frame.linkButton = CreateFrame("Button", nil, frame)
          frame.linkButton:SetSize(80, 20)
          frame.linkButton:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
          frame.linkButton:SetText(L["Open Link"] or "Open Link")
          if pfUI and pfUI.api and pfUI.api.SkinButton then
            pfUI.api.SkinButton(frame.linkButton)
          end
          frame.linkButton:SetScript("OnClick", function()
            local link = entryData.url
            if not link then return end
            if ChatFrame_OpenURL then
              ChatFrame_OpenURL(link)
            else
              DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: " .. link)
            end
          end)
        end
      elseif entryData.type == "select" and entryData.values then
        local dropdownName = "pfQuestConfigDropdown" .. (entryData.config or tostring(entryData))
        if _G[dropdownName] then
          local index = 1
          while _G[dropdownName .. index] do
            index = index + 1
          end
          dropdownName = dropdownName .. index
        end

        frame.input = CreateFrame("Frame", dropdownName, frame, "UIDropDownMenuTemplate")
        frame.input:SetWidth(150)
        frame.input:SetHeight(22)
        frame.input:SetPoint("RIGHT", frame, "RIGHT", -26, 0)
        frame.input.config = entryData.config
        frame.input.values = entryData.values
        frame.input.dropdownName = dropdownName

        frame.previewButton = CreateFrame("Button", nil, frame)
        frame.previewButton:SetPoint("LEFT", frame.input, "RIGHT", 4, 0)
        frame.previewButton:SetSize(20, 20)
        frame.previewButton.config = entryData.config
        frame.previewButton.defaultValue = entryData.default
        frame.previewButton:SetNormalTexture(nil)
        frame.previewButton:SetHighlightTexture(nil)
        frame.previewButton:SetPushedTexture(nil)
        frame.previewButton:SetDisabledTexture(nil)
        frame.previewButton.icon = frame.previewButton:CreateTexture(nil, "ARTWORK")
        frame.previewButton.icon:SetTexture("Interface\\Buttons\\UI-VoiceChat-Speaker")
        frame.previewButton.icon:SetPoint("CENTER", frame.previewButton, "CENTER", 0, 0)
        frame.previewButton.icon:SetSize(16, 16)
        frame.previewButton.icon:SetVertexColor(.2, 1, .8, 1)
        if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
          pfUI.api.CreateBackdrop(frame.previewButton, nil, true)
        end

        frame.previewButton:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText("Preview Sound", 0.2, 1, 0.8)
          GameTooltip:AddLine("Click to play the currently selected sound.", 1, 1, 1, true)
          GameTooltip:Show()
        end)
        frame.previewButton:SetScript("OnLeave", function()
          GameTooltip:Hide()
        end)
        frame.previewButton:SetScript("OnClick", function(self)
          local selection = pfQuest_config[self.config] or self.defaultValue
          if not selection or selection == "" then
            selection = self.defaultValue
          end
          
          local sounds = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieSounds")
          if sounds and sounds.PreviewSound then
            sounds:PreviewSound(selection, self.defaultValue)
          else
            -- Fallback: try to play directly if module not available
            if selection then
              local success, err = pcall(function()
                PlaySound(selection)
              end)
              if not success and self.defaultValue then
                pcall(function()
                  PlaySound(self.defaultValue)
                end)
              end
            end
          end
        end)

        frame.input.getDisplayText = function(value)
          if not value or value == "" then return "" end
          if type(entryData.values[1]) == "table" then
            for _, option in ipairs(entryData.values) do
              if option.value == value then
                return option.label or option.text or tostring(option.value)
              end
            end
          else
            return entryData.values[value] or tostring(value)
          end
          return tostring(value)
        end

        frame.input.iterateOptions = function(callback)
          if type(entryData.values[1]) == "table" then
            for _, option in ipairs(entryData.values) do
              callback(option.value, option.label or option.text or tostring(option.value))
            end
          else
            local keys = {}
            for value in pairs(entryData.values) do
              table.insert(keys, value)
            end
            table.sort(keys)
            for _, value in ipairs(keys) do
              callback(value, entryData.values[value])
            end
          end
        end

        local currentValue = pfQuest_config[entryData.config] or entryData.default or ""
        if (not currentValue or currentValue == "") and entryData.default and entryData.default ~= "" then
          pfQuest_config[entryData.config] = entryData.default
          currentValue = entryData.default
        end
        local displayText = frame.input.getDisplayText(currentValue)
        UIDropDownMenu_SetText(frame.input, displayText)
        UIDropDownMenu_SetSelectedValue(frame.input, currentValue)
        StyleDropdownControl(frame.input, dropdownName)

        UIDropDownMenu_Initialize(frame.input, function(_, level)
          if not level then return end
          local info = UIDropDownMenu_CreateInfo()
          frame.input.iterateOptions(function(value, text)
            info.text = text
            info.value = value
            info.func = function()
              pfQuest_config[frame.input.config] = value
              UIDropDownMenu_SetSelectedValue(frame.input, value)
              UIDropDownMenu_SetText(frame.input, text)
              if entryData.onupdate then
                entryData.onupdate()
              end
              local sounds = QuestieLoader and QuestieLoader.ImportModule and QuestieLoader:ImportModule("QuestieSounds")
              if sounds then
                if sounds.RefreshFromConfig then
                  sounds:RefreshFromConfig()
                end
                if sounds.PreviewSound then
                  sounds:PreviewSound(value, entryData.default)
                else
                  -- Fallback: try to play directly
                  if value then
                    pcall(function() PlaySound(value) end)
                  end
                end
              else
                -- Fallback: try to play directly if module not available
                if value then
                  pcall(function() PlaySound(value) end)
                end
              end
              StyleDropdownControl(frame.input, dropdownName)
            end
            info.checked = (pfQuest_config[frame.input.config] == value) and true or false
            UIDropDownMenu_AddButton(info, level)
          end)
        end)

        UIDropDownMenu_SetWidth(frame.input, 130)
        StyleDropdownControl(frame.input, dropdownName)

        local dropdownButton = _G[dropdownName .. "Button"]
        if dropdownButton then
          dropdownButton:SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            ToggleDropDownMenu(1, nil, frame.input, self, 0, 0)
          end)
        end

        frame.input:SetScript("OnMouseDown", function(_, button)
          if button == "LeftButton" then
            PlaySound("igMainMenuOptionCheckBoxOn")
            ToggleDropDownMenu(1, nil, frame.input, frame.input, 0, 0)
          end
        end)
        frame.input:SetScript("OnEnter", function()
          StyleDropdownControl(frame.input, dropdownName)
        end)
        frame.input:SetScript("OnLeave", function()
          StyleDropdownControl(frame.input, dropdownName)
        end)

      elseif entryData.type == "button" and entryData.func then
        frame.input = CreateFrame("Button", nil, frame)
        frame.input:SetWidth(120)
        frame.input:SetHeight(20)
        frame.input:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        frame.input:SetScript("OnClick", entryData.func)
        frame.input.text = frame.input:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        frame.input.text:SetAllPoints(frame.input)
        frame.input.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        frame.input.text:SetText("OK")
        pfUI.api.SkinButton(frame.input)
      end

      if frame.input and pfUI.api.emulated then
        frame.input:SetWidth(frame.input:GetWidth()/.6)
        frame.input:SetHeight(frame.input:GetHeight()/.6)
        frame.input:SetScale(.8)
        if frame.input.SetTextInsets then
          frame.input:SetTextInsets(8,8,8,8)
        end
      end

      configframes[entryData] = frame
      spacing = 8
      category.totalHeight = category.totalHeight + rowHeight + spacing
    end

    category.totalHeight = category.totalHeight + 10
    category.totalHeight = math_max(category.totalHeight, (self.content and self.content:GetHeight() or 0) - 40)
    container:SetHeight(category.totalHeight)
  end

  if self.categoryOrder[1] then
    self:ShowCategory(self.categoryOrder[1])
  end

  if self.SetSliderEnabled then
    self:SetSliderEnabled("trackerfadealpha", pfQuest_config["trackerfade"] == "1")
  end
end

function pfQuestConfig:UpdateConfigEntries()
  for _, data in ipairs(pfQuest_defconfig) do
    if data.type and configframes[data] and configframes[data].input then
      if data.type == "checkbox" then
        configframes[data].input:SetChecked((pfQuest_config[data.config] == "1" and true or nil))
      elseif data.type == "text" then
        configframes[data].input:SetText(pfQuest_config[data.config])
      elseif data.type == "slider" then
        local slider = configframes[data].input
        if slider then
          local value = tonumber(pfQuest_config[data.config]) or tonumber(data.default) or slider.minValue or 0
          value = math_max(slider.minValue or value, math_min(slider.maxValue or value, value))
          slider._updating = true
          slider:SetValue(value)
          slider._updating = nil
          if slider.valueText then
            if slider.displayFormatter then
              slider.valueText:SetText(slider.displayFormatter(value))
            else
              slider.valueText:SetText(string.format(slider.format or "%.2f", value))
            end
          end
        end
      elseif data.type == "select" and data.values then
        local currentValue = pfQuest_config[data.config] or data.default or ""
        if currentValue == "" and data.default and data.default ~= "" then
          pfQuest_config[data.config] = data.default
          currentValue = data.default
        end
        local displayText
        if configframes[data].input and configframes[data].input.getDisplayText then
          displayText = configframes[data].input.getDisplayText(currentValue)
        elseif type(data.values[1]) == "table" then
          for _, option in ipairs(data.values) do
            if option.value == currentValue then
              displayText = option.label or option.text or tostring(option.value)
              break
            end
          end
        else
          displayText = data.values[currentValue]
        end
        displayText = displayText or tostring(currentValue or "")
        if configframes[data].input then
          UIDropDownMenu_SetSelectedValue(configframes[data].input, currentValue)
          UIDropDownMenu_SetText(configframes[data].input, displayText)
          StyleDropdownControl(configframes[data].input, configframes[data].input.dropdownName)
        end
        if configframes[data].previewButton then
          configframes[data].previewButton.defaultValue = data.default
        end
      end
    end
  end

  if self.SetSliderEnabled then
    self:SetSliderEnabled("trackerfadealpha", pfQuest_config["trackerfade"] == "1")
  end
end

function pfQuestConfig:SetSliderEnabled(configKey, enabled)
  if not self.sliderRegistry then return end
  local slider = self.sliderRegistry[configKey]
  if not slider then return end

  enabled = not not enabled
  if enabled then
    slider:Enable()
    slider:SetAlpha(1)
    if slider.valueText then
      slider.valueText:SetTextColor(1, 1, 1)
    end
  else
    slider:Disable()
    slider:SetAlpha(0.5)
    if slider.valueText then
      slider.valueText:SetTextColor(0.6, 0.6, 0.6)
    end
  end
end

function pfQuestConfig:ShowCategory(name)
  if not self.categories or not self.categories[name] then return end
  if not self.scroll or not self.scrollContent then return end

  for _, categoryName in ipairs(self.categoryOrder) do
    local category = self.categories[categoryName]
    if category and category.frame then
      if categoryName == name then
        category.frame:Show()
        self.scrollContent:SetHeight(category.totalHeight)
        if ScrollFrame_UpdateScrollChildRect then
          ScrollFrame_UpdateScrollChildRect(self.scroll)
        end
        self.scroll:SetVerticalScroll(0)
      else
        category.frame:Hide()
      end
    end

    local button = category and category.button
    if button and button.text then
      if categoryName == name then
        button.text:SetTextColor(.3, 1, .8)
      else
        button.text:SetTextColor(1, 1, 1)
      end
    end
  end

  self.activeCategory = name
end

do -- welcome/init popup dialog
  local config_stage = {
    arrow = 1,
    mode = 2
  }

  local desaturate = function(texture, state)
    local supported = texture:SetDesaturated(state)
    if not supported then
      if state then
        texture:SetVertexColor(0.5, 0.5, 0.5)
      else
        texture:SetVertexColor(1.0, 1.0, 1.0)
      end
    end
  end

  -- create welcome/init window
  pfQuestInit = CreateFrame("Frame", "pfQuestInit", UIParent)
  pfQuestInit:Hide()
  pfQuestInit:SetWidth(400)
  pfQuestInit:SetHeight(270)
  pfQuestInit:SetMovable(true)
  pfQuestInit:EnableMouse(true)
  pfQuestInit:SetPoint("CENTER", 0, 0)
  pfQuestInit:RegisterEvent("PLAYER_ENTERING_WORLD")
  pfQuestInit:SetScript("OnMouseDown", function()
    this:StartMoving()
  end)

  pfQuestInit:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
  end)

  pfQuestInit:SetScript("OnEvent", function()
    if pfQuest_config.welcome ~= "1" then
      -- parse current config
      if pfQuest_config["showspawn"] == "0" and pfQuest_config["showcluster"] == "1" then
        config_stage.mode = 1
      elseif pfQuest_config["showspawn"] == "1" and pfQuest_config["showcluster"] == "0" then
        config_stage.mode = 3
      end

      if pfQuest_config["arrow"] == "0" then
        config_stage.arrow = nil
      end

      pfQuestInit:Show()
    end
    this:UnregisterAllEvents()
  end)

  pfQuestInit:SetScript("OnShow", function()
    -- reload ui elements
    desaturate(pfQuestInit[1].bg, true)
    desaturate(pfQuestInit[2].bg, true)
    desaturate(pfQuestInit[3].bg, true)
    desaturate(pfQuestInit[config_stage.mode].bg, false)
    pfQuestInit.checkbox:SetChecked(config_stage.arrow)
  end)

  pfUI.api.CreateBackdrop(pfQuestInit, nil, true, 0.85)

  pfQuestInit.versionText = pfQuestInit:CreateFontString(nil, "LOW", "GameFontHighlight")
  pfQuestInit.versionText:SetPoint("CENTER", pfQuestInit, "CENTER", 0, -10)
  pfQuestInit.versionText:SetText("|cff33ffccVersion 0.9 (Beta)|r")

  -- welcome title
  pfQuestInit.title = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
  pfQuestInit.title:SetPoint("TOP", pfQuestInit, "TOP", 0, -17)
  pfQuestInit.title:SetJustifyH("LEFT")
  pfQuestInit.title:SetText(L["Please select your preferred |cff33ffccpf|cffffffffQuest|r mode:"])

  -- questing mode
  local buttons = {
    { caption = L["Simple Markers"], texture = "\\img\\init\\simple", position = { "TOPLEFT", 10, -40 },
      tooltip = L["Only show cluster icons with summarized objective locations based on spawn points"] },
    { caption = L["Combined"], texture = "\\img\\init\\combined", position = { "TOP", 0, -40 },
      tooltip = L["Show cluster icons with summarized locations and also display all spawn points of each quest objective"] },
    { caption = L["Spawn Points"], texture = "\\img\\init\\spawns", position = { "TOPRIGHT", -10, -40 },
      tooltip = L["Display all spawn points of each quest objective and hide summarized cluster icons."] },
  }

  for i, button in pairs(buttons) do
    pfQuestInit[i] = CreateFrame("Button", "pfQuestInitLeft", pfQuestInit)
    pfQuestInit[i]:SetWidth(120)
    pfQuestInit[i]:SetHeight(160)
    pfQuestInit[i]:SetPoint(unpack(button.position))
    pfQuestInit[i]:SetID(i)

    pfQuestInit[i].bg = pfQuestInit[i]:CreateTexture(nil, "NORMAL")
    pfQuestInit[i].bg:SetWidth(200)
    pfQuestInit[i].bg:SetHeight(200)
    pfQuestInit[i].bg:SetPoint("CENTER", 0, 0)
    pfQuestInit[i].bg:SetTexture(pfQuestConfig.path..button.texture)

    pfQuestInit[i].caption = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
    pfQuestInit[i].caption:SetPoint("TOP", pfQuestInit[i], "BOTTOM", 0, -5)
    pfQuestInit[i].caption:SetJustifyH("LEFT")
    pfQuestInit[i].caption:SetText(button.caption)

    pfUI.api.SkinButton(pfQuestInit[i])

    pfQuestInit[i]:SetScript("OnClick", function()
      desaturate(pfQuestInit[1].bg, true)
      desaturate(pfQuestInit[2].bg, true)
      desaturate(pfQuestInit[3].bg, true)
      desaturate(pfQuestInit[this:GetID()].bg, false)
      config_stage.mode = this:GetID()
    end)

    local OnEnter = pfQuestInit[i]:GetScript("OnEnter")
    pfQuestInit[i]:SetScript("OnEnter", function()
      if OnEnter then OnEnter() end
      GameTooltip_SetDefaultAnchor(GameTooltip, this)

      GameTooltip:SetText(this.caption:GetText())
      GameTooltip:AddLine(buttons[this:GetID()].tooltip, 1, 1, 1, true)
      GameTooltip:SetWidth(100)
      GameTooltip:Show()
    end)

    local OnLeave = pfQuestInit[i]:GetScript("OnLeave")
    pfQuestInit[i]:SetScript("OnLeave", function()
      if OnLeave then OnLeave() end
      GameTooltip:Hide()
    end)
  end

  -- show arrows
  pfQuestInit.checkbox = CreateFrame("CheckButton", nil, pfQuestInit, "UICheckButtonTemplate")
  pfQuestInit.checkbox:SetPoint("BOTTOMLEFT", 10, 10)
  pfQuestInit.checkbox:SetNormalTexture("")
  pfQuestInit.checkbox:SetPushedTexture("")
  pfQuestInit.checkbox:SetHighlightTexture("")
  pfQuestInit.checkbox:SetWidth(22)
  pfQuestInit.checkbox:SetHeight(22)
  pfUI.api.CreateBackdrop(pfQuestInit.checkbox, nil, true)

  pfQuestInit.checkbox.caption = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
  pfQuestInit.checkbox.caption:SetPoint("LEFT", pfQuestInit.checkbox, "RIGHT", 5, 0)
  pfQuestInit.checkbox.caption:SetJustifyH("LEFT")
  pfQuestInit.checkbox.caption:SetText(L["Show Navigation Arrow"])
  pfQuestInit.checkbox:SetScript("OnClick", function()
    config_stage.arrow = this:GetChecked()
  end)

  pfQuestInit.checkbox:SetScript("OnEnter", function()
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:SetText(L["Navigation Arrow"])
    GameTooltip:AddLine(L["Show navigation arrow that points you to the nearest quest location."], 1, 1, 1, true)
    GameTooltip:SetWidth(100)
    GameTooltip:Show()
  end)

  pfQuestInit.checkbox:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- save button
  pfQuestInit.save = CreateFrame("Button", nil, pfQuestInit)
  pfQuestInit.save:SetWidth(100)
  pfQuestInit.save:SetHeight(24)
  pfQuestInit.save:SetPoint("BOTTOMRIGHT", -10, 10)
  pfQuestInit.save.text = pfQuestInit.save:CreateFontString("Caption", "LOW", "GameFontWhite")
  pfQuestInit.save.text:SetAllPoints(pfQuestInit.save)
  pfQuestInit.save.text:SetText(L["Save & Close"])

  pfUI.api.SkinButton(pfQuestInit.save)

  pfQuestInit.save:SetScript("OnClick", function()
    -- write current config
    if config_stage.mode == 1 then
      pfQuest_config["showspawn"] = "0"
      pfQuest_config["showspawnmini"] = "0"
      pfQuest_config["showcluster"] = "1"
      pfQuest_config["showclustermini"] = "1"
    elseif config_stage.mode == 2 then
      pfQuest_config["showspawn"] = "1"
      pfQuest_config["showspawnmini"] = "1"
      pfQuest_config["showcluster"] = "1"
      pfQuest_config["showclustermini"] = "0"
    elseif config_stage.mode == 3 then
      pfQuest_config["showspawn"] = "1"
      pfQuest_config["showspawnmini"] = "1"
      pfQuest_config["showcluster"] = "0"
      pfQuest_config["showclustermini"] = "0"
    end

    if config_stage.arrow then
      pfQuest_config["arrow"] = "1"
    else
      pfQuest_config["arrow"] = "0"
    end

    -- save welcome flag and reload
    pfQuest_config["welcome"] = "1"
    pfQuest:ResetAll()
    pfQuestInit:Hide()
  end)
end
