---@class QuestieMenu
-- QuestieMenu module - provides context menu system for NPCs and townsfolk
local QuestieMenu = QuestieLoader:CreateModule("QuestieMenu")

-- Configuration helper
local function GetConfig()
  return pfQuest_config or {}
end

-- Townsfolk texture map
local _, playerClass = UnitClass("player")
local _townsfolk_texturemap = {
  ["Flight Master"] = "Interface\\Minimap\\tracking\\flightmaster",
  ["Meeting Stones"] = "Interface\\Minimap\\tracking\\meetingstone",
  ["Class Trainer"] = "Interface\\Minimap\\tracking\\class",
  ["Stable Master"] = "Interface\\Minimap\\tracking\\stablemaster",
  ["Spirit Healer"] = "Interface\\raidframe\\raid-icon-rez",
  ["Weapon Master"] = "Interface\\Minimap\\tracking\\weaponmaster",
  ["Profession Trainer"] = "Interface\\Minimap\\tracking\\profession",
  ["Auctioneer"] = "Interface\\Minimap\\tracking\\auctioneer",
  ["Banker"] = "Interface\\Minimap\\tracking\\banker",
  ["Innkeeper"] = "Interface\\Minimap\\tracking\\innkeeper",
  ["Repair"] = "Interface\\Minimap\\tracking\\repair",
  ["Mailbox"] = "Interface\\Minimap\\tracking\\mailbox",
}

-- Initialize townsfolk config if needed
local function InitTownsfolkConfig()
  local config = GetConfig()
  if not config["townsfolkConfig"] then
    config["townsfolkConfig"] = {
      ["Flight Master"] = true,
      ["Mailbox"] = true,
      ["Meeting Stones"] = true,
    }
  end
end

-- Toggle townsfolk tracking
local function ToggleTownsfolk(key)
  local config = GetConfig()
  InitTownsfolkConfig()
  
  if not config["townsfolkConfig"][key] then
    config["townsfolkConfig"][key] = false
  end
  
  config["townsfolkConfig"][key] = not config["townsfolkConfig"][key]
  
  -- Use pfQuest's existing tracking system
  if pfDatabase and pfDatabase.TrackMeta then
    -- Map QuestieMenu keys to pfQuest tracking keys
    local trackingKeyMap = {
      ["Flight Master"] = "flight",
      ["Mailbox"] = "mailbox",
      ["Meeting Stones"] = "meetingstone",
      ["Class Trainer"] = "classtrainer",
      ["Stable Master"] = "stablemaster",
      ["Spirit Healer"] = "spirithealer",
      ["Auctioneer"] = "auctioneer",
      ["Banker"] = "banker",
      ["Innkeeper"] = "innkeeper",
      ["Repair"] = "repair",
    }
    
    local pfQuestKey = trackingKeyMap[key]
    if pfQuestKey and pfQuest_track and type(pfQuest_track) == "table" then
      -- Toggle via pfQuest's tracking system
      pfQuest_track[pfQuestKey] = config["townsfolkConfig"][key] and "1" or "0"
      pfDatabase.TrackMeta(nil, pfQuestKey, config["townsfolkConfig"][key])
    end
  end
end

-- Build menu entry for townsfolk
local function BuildTownsfolkEntry(key, localizedText)
  local config = GetConfig()
  InitTownsfolkConfig()
  
  local icon = _townsfolk_texturemap[key] or ("Interface\\Minimap\\tracking\\" .. string.lower(key))
  local checked = config["townsfolkConfig"][key] == true
  
  return {
    text = localizedText or key,
    func = function() ToggleTownsfolk(key) end,
    icon = icon,
    notCheckable = false,
    checked = checked,
    isNotRadio = true,
    keepShownOnClick = true,
  }
end

-- Build townsfolk menu
function QuestieMenu:BuildTownsfolkMenu()
  local menu = {}
  local config = GetConfig()
  InitTownsfolkConfig()
  
  -- Add standard townsfolk entries
  local townsfolkList = {
    "Flight Master",
    "Mailbox",
    "Meeting Stones",
    "Class Trainer",
    "Stable Master",
    "Spirit Healer",
    "Auctioneer",
    "Banker",
    "Innkeeper",
    "Repair",
  }
  
  for _, key in ipairs(townsfolkList) do
    table.insert(menu, BuildTownsfolkEntry(key))
  end
  
  return menu
end

-- Show main menu
function QuestieMenu:Show(hideDelay)
  InitTownsfolkConfig()

  local menuTable = self:BuildTownsfolkMenu()
  
  -- Add separator
  table.insert(menuTable, {
    text = "",
    isTitle = true,
    notCheckable = true,
    isSeparator = true,
  })
  
  -- Add settings option
  table.insert(menuTable, {
    text = "Settings",
    func = function()
      if pfQuestConfig and pfQuestConfig.IsShown then
        if pfQuestConfig:IsShown() then
          pfQuestConfig:Hide()
        else
          pfQuestConfig:Show()
        end
      end
    end,
    notCheckable = true,
  })
  
  -- Add cancel option
  table.insert(menuTable, {
    text = "Cancel",
    func = function() end,
    notCheckable = true,
  })
  
  if not QuestieMenu.menu then
    QuestieMenu.menu = CreateFrame("Frame", "QuestieMenuFrame", UIParent, "UIDropDownMenuTemplate")
  end

  EasyMenu(menuTable, QuestieMenu.menu, "cursor", -80, -15, "MENU", hideDelay or 2)
end

-- Show townsfolk-only menu
function QuestieMenu:ShowTownsfolk(hideDelay)
  InitTownsfolkConfig()

  local menuTable = self:BuildTownsfolkMenu()
  
  table.insert(menuTable, {
    text = "Cancel",
    func = function() end,
    notCheckable = true,
  })
  
  if not QuestieMenu.menuTowns then
    QuestieMenu.menuTowns = CreateFrame("Frame", "QuestieMenuTownsfolkFrame", UIParent, "UIDropDownMenuTemplate")
  end

  EasyMenu(menuTable, QuestieMenu.menuTowns, "cursor", -80, -15, "MENU", hideDelay)
end

-- Initialize on login
function QuestieMenu:Initialize()
  InitTownsfolkConfig()
  
  -- Sync existing pfQuest tracking state to townsfolk config
  local config = GetConfig()
  if pfQuest_track and type(pfQuest_track) == "table" then
    local trackingKeyMap = {
      flight = "Flight Master",
      mailbox = "Mailbox",
      meetingstone = "Meeting Stones",
      classtrainer = "Class Trainer",
      stablemaster = "Stable Master",
      spirithealer = "Spirit Healer",
      auctioneer = "Auctioneer",
      banker = "Banker",
      innkeeper = "Innkeeper",
      repair = "Repair",
    }
    
    for pfQuestKey, questieKey in pairs(trackingKeyMap) do
      if pfQuest_track[pfQuestKey] then
        config["townsfolkConfig"][questieKey] = pfQuest_track[pfQuestKey] == "1"
      end
    end
  end
end

-- Register initialization
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
  QuestieMenu:Initialize()
end)

