---@class QuestieNameplate
-- Shows quest icons on enemy nameplates for quick identification of quest targets
local QuestieNameplate = QuestieLoader:CreateModule("QuestieNameplate")

local UnitGUID = UnitGUID
local UnitCanAttack = UnitCanAttack
local UnitName = UnitName
local GetNumQuestLogEntries = GetNumQuestLogEntries
local GetQuestLogTitle = GetQuestLogTitle
local tconcat = table.concat
local wipe = wipe
local strsplit = strsplit or string.split
local compat = pfQuestCompat

-- Configuration helper
local function GetConfig()
  pfQuest_config = pfQuest_config or {}
  return pfQuest_config
end

-- Cache for quest NPCs (npcId -> quest data)
local questNPCCache = {}
local nameplateIcons = {}
local activeQuestIds = nil

-- Get NPC ID from unit GUID
local function GetNPCIDFromGUID(guid)
  if not guid then return nil end

  local guidType, npcId
  if string.find(guid, "^Creature%-") or string.find(guid, "^Vehicle%-") then
    guidType, _, _, _, _, npcId = strsplit("-", guid)
  else
    npcId = string.match(guid, "%-(%d+)$")
    if npcId then
      guidType = "Creature"
    else
      local hex = string.match(guid, "^0x(%x+)$")
      if hex then
        local length = #hex
        if length >= 10 then
          npcId = tonumber(string.sub(hex, length - 9, length - 6), 16)
          guidType = "Creature"
        end
      end
    end
  end

  if not guidType or (guidType ~= "Creature" and guidType ~= "Vehicle") then
    return nil
  end

  npcId = tonumber(npcId)
  return npcId
end

local function BuildActiveQuestSet()
  activeQuestIds = activeQuestIds or {}
  wipe(activeQuestIds)

  -- Prefer pfQuest questlog if available (already synced with active quests)
  if pfQuest and pfQuest.questlog then
    for questId, data in pairs(pfQuest.questlog) do
      local numericId = tonumber(questId) or tonumber(data and data.questid)
      if numericId then
        activeQuestIds[numericId] = true
      end
    end
  end

  -- Fallback: use Blizzard quest log if pfQuest questlog is empty (e.g., on initial load)
  if not next(activeQuestIds) and pfDatabase and pfDatabase.GetQuestIDs then
    local numEntries = GetNumQuestLogEntries()
    for questIndex = 1, numEntries do
      local title, _, _, isHeader = compat.GetQuestLogTitle(questIndex)
      if title and not isHeader then
        local questIds = pfDatabase:GetQuestIDs(questIndex)
        if questIds then
          for _, questId in pairs(questIds) do
            if questId then
              activeQuestIds[questId] = true
            end
          end
        end
      end
    end
  end

  return activeQuestIds
end

local function GetNameRegion(nameplate)
  if not nameplate then return nil end
  if nameplate.questieNameRegion then
    local objType = nameplate.questieNameRegion.GetObjectType and nameplate.questieNameRegion:GetObjectType()
    if objType == "FontString" then
      -- Verify the cached region still exists and is valid
      local text = nameplate.questieNameRegion.GetText and nameplate.questieNameRegion:GetText()
      if text and text ~= "" then
        return nameplate.questieNameRegion
      else
        -- Cache is stale, clear it
        nameplate.questieNameRegion = nil
      end
    else
      -- Cache is invalid, clear it
      nameplate.questieNameRegion = nil
    end
  end

  -- Safely iterate regions - only look for FontString regions (name text)
  -- Skip texture regions (health bars, etc.) to avoid affecting them
  local regions = { nameplate:GetRegions() }
  for _, region in ipairs(regions) do
    if region then
      local objType = region.GetObjectType and region:GetObjectType()
      -- Only process FontString regions (name text), ignore textures (bars)
      if objType == "FontString" then
        local text = region.GetText and region:GetText()
        if text and text ~= "" then
          -- Cache the name region for future use
          nameplate.questieNameRegion = region
          return region
        end
      end
    end
  end

  return nil
end

local function EnumerateNameplates()
  local plates = {}
  local frames = { WorldFrame:GetChildren() }
  for _, frame in ipairs(frames) do
    if frame and frame:IsVisible() then
      local isNameplate = false
      local frameName = frame.GetName and frame:GetName()
      if frameName then
        local lowerName = string.lower(frameName)
        if string.find(lowerName, "nameplate") then
          isNameplate = true
        end
      end

      if not isNameplate then
        local nameRegion = GetNameRegion(frame)
        if nameRegion then
          isNameplate = true
        end
      end

      if isNameplate then
        table.insert(plates, frame)
      end
    end
  end
  return plates
end

local IsQuestNPC -- forward declaration for lookup helpers
local function GetUnitNameFromDB(unitId)
  if not unitId or not pfDB or not pfDB.units then return nil end
  local locTable = pfDB.units.loc or pfDB.units["loc"]
  if not locTable then return nil end
  local entry = locTable[unitId]
  if not entry then return nil end

  if type(entry) == "table" then
    return entry.name or entry["name"] or entry[1]
  elseif type(entry) == "string" then
    return entry
  end

  return nil
end

local function FindQuestDataForActiveNPC(unitName)
  if not unitName or unitName == "" then return nil end

  local targetName = string.lower(unitName)
  local matchedNpcId = nil
  local questList = {}

  local function processUnitTable(questId, unitTable, typeLabel)
    if not unitTable then return end
    for _, unitId in pairs(unitTable) do
      local dbName = GetUnitNameFromDB(unitId)
      if dbName and string.lower(dbName) == targetName then
        matchedNpcId = matchedNpcId or unitId
        -- Determine if this is a kill or loot objective
        local objType = typeLabel
        if typeLabel == "objective" then
          -- Check if this is a loot objective
          local questInfo = pfDB and pfDB.quests and pfDB.quests.data and pfDB.quests.data[questId]
          if questInfo and questInfo.obj and questInfo.obj.I and pfDB and pfDB.items and pfDB.items.data then
            local items = pfDB.items.data
            local isLoot = false
            for _, itemId in pairs(questInfo.obj.I) do
              if items[itemId] and items[itemId].U and items[itemId].U[unitId] then
                isLoot = true
                objType = "objective_loot"
                break
              end
            end
            if not isLoot then
              objType = "objective_kill"
            end
          else
            objType = "objective_kill"
          end
        end
        table.insert(questList, {
          questId = questId,
          type = objType,
          title = pfDB.quests.loc and pfDB.quests.loc[questId] and pfDB.quests.loc[questId].T or nil
        })
      end
    end
  end

  if pfQuest and pfQuest.questlog then
    for questId, _ in pairs(pfQuest.questlog) do
      local numericId = tonumber(questId)
      if numericId then
        local questInfo = pfDB and pfDB.quests and pfDB.quests.data and pfDB.quests.data[numericId]
        if questInfo then
          processUnitTable(numericId, questInfo.start and questInfo.start.U, "start")
          processUnitTable(numericId, questInfo["end"] and questInfo["end"].U, "end")
          processUnitTable(numericId, questInfo.obj and questInfo.obj.U, "objective")
          -- Also check for loot objectives (items that drop from this NPC)
          if questInfo.obj and questInfo.obj.I and pfDB and pfDB.items and pfDB.items.data then
            local items = pfDB.items.data
            for _, itemId in pairs(questInfo.obj.I) do
              if items[itemId] and items[itemId].U then
                for unitId, _ in pairs(items[itemId].U) do
                  local dbName = GetUnitNameFromDB(unitId)
                  if dbName and string.lower(dbName) == targetName then
                    matchedNpcId = matchedNpcId or unitId
                    table.insert(questList, {
                      questId = numericId,
                      type = "objective_loot",
                      title = pfDB.quests.loc and pfDB.quests.loc[numericId] and pfDB.quests.loc[numericId].T or nil,
                      itemId = itemId
                    })
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  if not matchedNpcId then
    local numEntries = GetNumQuestLogEntries()
    for questIndex = 1, numEntries do
      local title, _, _, isHeader = compat.GetQuestLogTitle(questIndex)
      if title and not isHeader then
        local questIds = pfDatabase and pfDatabase.GetQuestIDs and pfDatabase:GetQuestIDs(questIndex)
        if questIds then
          for _, questId in pairs(questIds) do
            local questInfo = pfDB and pfDB.quests and pfDB.quests.data and pfDB.quests.data[questId]
            if questInfo then
              processUnitTable(questId, questInfo.start and questInfo.start.U, "start")
              processUnitTable(questId, questInfo["end"] and questInfo["end"].U, "end")
              processUnitTable(questId, questInfo.obj and questInfo.obj.U, "objective")
              -- Also check for loot objectives (items that drop from this NPC)
              if questInfo.obj and questInfo.obj.I and pfDB and pfDB.items and pfDB.items.data then
                local items = pfDB.items.data
                for _, itemId in pairs(questInfo.obj.I) do
                  if items[itemId] and items[itemId].U then
                    for unitId, _ in pairs(items[itemId].U) do
                      local dbName = GetUnitNameFromDB(unitId)
                      if dbName and string.lower(dbName) == targetName then
                        matchedNpcId = matchedNpcId or unitId
                        table.insert(questList, {
                          questId = questId,
                          type = "objective_loot",
                          title = pfDB.quests.loc and pfDB.quests.loc[questId] and pfDB.quests.loc[questId].T or nil,
                          itemId = itemId
                        })
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  if matchedNpcId then
    return matchedNpcId, questList
  end

  return nil
end

-- Check if NPC is a quest NPC (starter, ender, or objective)
IsQuestNPC = function(npcId)
  if not npcId or not pfDB or not pfDB.quests or not pfDB.quests.data then
    return false
  end

  -- Check cache first
  if questNPCCache[npcId] ~= nil then
    return questNPCCache[npcId]
  end

  local quests = pfDB.quests.data
  local activeSet = BuildActiveQuestSet()
  if not next(activeSet) then
    questNPCCache[npcId] = false
    return false
  end

  local questList = {}
  for questId in pairs(activeSet) do
    local questInfo = quests[questId]
    if questInfo then
      -- Check if NPC is a quest starter
      if questInfo.start and questInfo.start.U then
        for _, unitId in pairs(questInfo.start.U) do
          if unitId == npcId then
            table.insert(questList, {
              questId = questId,
              type = "start",
              title = pfDB.quests.loc[questId] and pfDB.quests.loc[questId].T or nil
            })
            break
          end
        end
      end

      -- Check if NPC is a quest ender
      if questInfo["end"] and questInfo["end"].U then
        for _, unitId in pairs(questInfo["end"].U) do
          if unitId == npcId then
            table.insert(questList, {
              questId = questId,
              type = "end",
              title = pfDB.quests.loc[questId] and pfDB.quests.loc[questId].T or nil
            })
            break
          end
        end
      end

      -- Check if NPC is a quest objective (kill)
      if questInfo.obj and questInfo.obj.U then
        for _, unitId in pairs(questInfo.obj.U) do
          if unitId == npcId then
            table.insert(questList, {
              questId = questId,
              type = "objective_kill",
              title = pfDB.quests.loc[questId] and pfDB.quests.loc[questId].T or nil
            })
            break
          end
        end
      end
      
      -- Check if NPC drops quest items (loot objective)
      if questInfo.obj and questInfo.obj.I and pfDB and pfDB.items and pfDB.items.data then
        local items = pfDB.items.data
        for _, itemId in pairs(questInfo.obj.I) do
          if items[itemId] and items[itemId].U and items[itemId].U[npcId] then
            -- This NPC drops this quest item
            table.insert(questList, {
              questId = questId,
              type = "objective_loot",
              title = pfDB.quests.loc[questId] and pfDB.quests.loc[questId].T or nil,
              itemId = itemId
            })
            break
          end
        end
      end
    end
  end

  local result = next(questList) and questList or false
  questNPCCache[npcId] = result
  return result
end

-- Get quest icon texture based on quest type
local function GetQuestIconTexture(questData)
  if not questData or not next(questData) then return nil end
  
  local quest = questData[1]
  if not quest then return nil end
  
  local path = pfQuestConfig and pfQuestConfig.path or "Interface\\AddOns\\pfQuest-wotlk"
  
  if quest.type == "start" then
    return path .. "\\img\\available_c.tga"
  elseif quest.type == "end" then
    return path .. "\\img\\complete_c.tga"
  elseif quest.type == "objective_kill" then
    -- Skull icon for kill quests - using WoW's built-in skull icon
    return "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
  elseif quest.type == "objective_loot" then
    -- Bag icon for loot quests - using WoW's bag icon
    return "Interface\\Icons\\INV_Misc_Bag_08"
  elseif quest.type == "objective" then
    -- Fallback for old format
    return path .. "\\img\\node.tga"
  end
  
  return path .. "\\img\\available_c.tga"
end

-- Create or update nameplate icon
local function UpdateNameplateIcon(nameplate, npcId, questData)
  if not nameplate then return end
  
  local config = GetConfig()
  if config["nameplateEnabled"] ~= "1" then
    -- Remove icon if disabled
    if nameplateIcons[nameplate] then
      nameplateIcons[nameplate]:Hide()
      nameplateIcons[nameplate] = nil
    end
    return
  end
  
  -- Remove icon if not a quest NPC (npcId can be nil when clearing)
  if not npcId or not questData or questData == false then
    if nameplateIcons[nameplate] then
      nameplateIcons[nameplate]:Hide()
      nameplateIcons[nameplate] = nil
    end
    return
  end
  
  -- Get icon texture
  local texture = GetQuestIconTexture(questData)
  if not texture then 
    if pfQuest_config and pfQuest_config.debug then
      Questie.Print("UpdateNameplateIcon: No texture found for quest data")
    end
    return 
  end
  
  -- Create or get icon frame
  local iconFrame = nameplateIcons[nameplate]
  if not iconFrame then
    -- Create a frame to hold the texture (better control over positioning)
    iconFrame = CreateFrame("Frame", nil, nameplate)
    iconFrame:SetFrameStrata("TOOLTIP")
    iconFrame:SetFrameLevel(nameplate:GetFrameLevel() and (nameplate:GetFrameLevel() + 20) or 1000)
    iconFrame:SetParent(nameplate)
    
    -- Create the texture as a child of the frame
    local iconTexture = iconFrame:CreateTexture(nil, "OVERLAY")
    iconTexture:SetAllPoints(iconFrame)
    iconFrame.texture = iconTexture
    
    nameplateIcons[nameplate] = iconFrame
  end
  
  -- Ensure icon frame is parented to nameplate
  if iconFrame:GetParent() ~= nameplate then
    iconFrame:SetParent(nameplate)
  end
  
  -- Configure icon
  local scale = tonumber(config["nameplateIconScale"]) or 1.0
  local iconSize = math.floor(16 * scale)
  
  -- Set texture and size
  iconFrame.texture:SetTexture(texture)
  iconFrame:SetWidth(iconSize)
  iconFrame:SetHeight(iconSize)
  iconFrame.texture:SetAllPoints(iconFrame)
  
  -- Try to find the name region for anchoring
  local anchor = GetNameRegion(nameplate)
  if not anchor then
    -- Fallback: try to find any FontString in the nameplate
    local regions = { nameplate:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.GetObjectType and region:GetObjectType() == "FontString" then
        local text = region.GetText and region:GetText()
        if text and text ~= "" then
          anchor = region
          break
        end
      end
    end
  end
  
  -- If still no anchor, use the nameplate itself
  if not anchor then
    anchor = nameplate
  end
  
  -- Position icon to the left of the name text
  iconFrame:ClearAllPoints()
  local success, err = pcall(function()
    -- Try anchoring to the left of the name region
    iconFrame:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
  end)
  
  if not success then
    -- Fallback positioning if the anchor point fails
    pcall(function()
      iconFrame:SetPoint("CENTER", nameplate, "LEFT", -iconSize - 8, 0)
    end)
  end
  
  iconFrame:SetAlpha(1)
  iconFrame:Show()
  iconFrame.texture:Show()
  
  -- Ensure icon is visible
  if nameplate:IsVisible() then
    iconFrame:Show()
    iconFrame.texture:Show()
  end
  
  if pfQuest_config and pfQuest_config.debug then
    local anchorName = anchor and (anchor:GetName() or tostring(anchor)) or "nil"
    local anchorText = anchor and anchor.GetText and anchor:GetText() or "no text"
    Questie.Print(string.format("UpdateNameplateIcon: Created icon for NPC %d, texture=%s, size=%d, anchor=%s (text=%s), frameLevel=%d", 
      npcId or 0, texture, iconSize, anchorName, anchorText, iconFrame:GetFrameLevel() or 0))
  end
end

-- Handle nameplate unit added/updated
local function OnNamePlateAdded(nameplate, unitToken, guidOverride, nameTextOverride)
  if not QuestieNameplate.enabled or not nameplate then return end

  local guid = guidOverride
  local npcId = nil
  local questData = nil
  
  -- Try to get GUID from unitToken first
  if unitToken then
    -- Only skip if we can't attack AND we have no other way to identify this NPC
    -- (name-based matching can still work even if not attackable)
    local canAttack = UnitCanAttack("player", unitToken)
    if canAttack then
      guid = guid or UnitGUID(unitToken)
    end
    -- Continue processing even if not attackable - might be a quest NPC that needs interaction
  end

  -- If we have a GUID, try to extract NPC ID from it
  if guid then
    nameplate.questieGuid = guid
    npcId = GetNPCIDFromGUID(guid)
    if npcId then
      questData = IsQuestNPC(npcId)
    end
  end

  -- If we don't have quest data yet, try name-based matching
  if (not questData or questData == false) then
    local npcName = nameTextOverride
    if not npcName and unitToken then
      npcName = UnitName(unitToken)
    end
    if not npcName then
      local nameRegion = GetNameRegion(nameplate)
      npcName = nameRegion and nameRegion:GetText()
    end
    
    if npcName and npcName ~= "" then
      local resolvedId, resolvedData = FindQuestDataForActiveNPC(npcName)
      if resolvedId and resolvedData then
        npcId = resolvedId
        questData = resolvedData
        -- Cache the GUID if we found one, or store the name for future reference
        if guid then
          nameplate.questieGuid = guid
        else
          nameplate.questieName = npcName
        end
      end
    end
  end

  -- Only update icon if we have both npcId and questData
  if npcId and questData and questData ~= false then
    if pfQuest_config and pfQuest_config.debug then
      Questie.Print(string.format("OnNamePlateAdded: Updating icon for NPC %d (nameplate=%s)", 
        npcId, nameplate:GetName() or "unnamed"))
    end
    UpdateNameplateIcon(nameplate, npcId, questData)
  else
    -- Clear icon if this NPC is not a quest NPC
    UpdateNameplateIcon(nameplate, nil, false)
  end
end

-- Handle nameplate unit removed
local function OnNamePlateRemoved(nameplate)
  if nameplateIcons[nameplate] then
    local iconFrame = nameplateIcons[nameplate]
    if iconFrame and iconFrame.Hide then
      iconFrame:Hide()
    end
    nameplateIcons[nameplate] = nil
  end
end

-- Assign GUID to visible nameplate by matching unit name
local function AssignGuidToVisiblePlate(unitToken)
  if not unitToken then return end
  local guid = UnitGUID(unitToken)
  if not guid then return end
  local name = UnitName(unitToken)
  if not name then return end

  local plates = EnumerateNameplates()
  for _, frame in ipairs(plates) do
    local nameRegion = GetNameRegion(frame)
    if nameRegion and nameRegion:GetText() == name then
      frame.questieGuid = guid
      frame.questieNameRegion = nameRegion
      OnNamePlateAdded(frame, unitToken, guid)
      break
    end
  end
end

-- Refresh all visible nameplates (Wrath-compatible)
function QuestieNameplate:RefreshAll()
  local config = GetConfig()
  if config["nameplateEnabled"] ~= "1" then
    return
  end

  AssignGuidToVisiblePlate("target")
  AssignGuidToVisiblePlate("mouseover")

  local seen = {}
  local plates = EnumerateNameplates()
  for _, frame in ipairs(plates) do
    local unitToken = nil

    if frame.unitFrame and frame.unitFrame.unit then
      unitToken = frame.unitFrame.unit
    elseif frame.unit then
      unitToken = frame.unit
    end

    if unitToken then
      seen[frame] = true
      OnNamePlateAdded(frame, unitToken)
    elseif frame.questieGuid then
      seen[frame] = true
      OnNamePlateAdded(frame, nil, frame.questieGuid)
    else
      local nameRegion = GetNameRegion(frame)
      if nameRegion then
        local nameText = nameRegion:GetText()
        if nameText then
          seen[frame] = true
          OnNamePlateAdded(frame, nil, nil, nameText)
        end
      end
    end
  end

  for plate, iconFrame in pairs(nameplateIcons) do
    if not seen[plate] then
      if iconFrame and iconFrame.Hide then
        iconFrame:Hide()
      end
      nameplateIcons[plate] = nil
    end
  end
end

-- Clear quest NPC cache (call when quest log updates)
function QuestieNameplate:ClearCache()
  questNPCCache = {}
  activeQuestIds = nil
  self:RefreshAll()
end

-- Refresh from config
function QuestieNameplate:RefreshFromConfig()
  if not self.initialized then
    return
  end

  local config = GetConfig()
  local enabled = config["nameplateEnabled"] == "1"
  self.enabled = enabled

  if not enabled then
    -- Hide existing icons
    for plate, iconFrame in pairs(nameplateIcons) do
      if iconFrame and iconFrame.Hide then
        iconFrame:Hide()
      end
      nameplateIcons[plate] = nil
    end
    if self.updateFrame then
      self.updateFrame:Hide()
    end
  else
    questNPCCache = {}
    activeQuestIds = nil
    if self.updateFrame then
      self.updateFrame:Show()
    end
    self:RefreshAll()
  end
end

-- Initialize nameplate tracking
function QuestieNameplate:Initialize()
  if self.initialized then return end

  -- Hook into nameplate events (Wrath-compatible)
  if not self.eventFrame then
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    
    self.eventFrame:SetScript("OnEvent", function(self, event)
      if event == "QUEST_LOG_UPDATE" then
        QuestieNameplate:ClearCache()
      elseif event == "PLAYER_TARGET_CHANGED" then
        AssignGuidToVisiblePlate("target")
        QuestieNameplate:RefreshAll()
      elseif event == "UPDATE_MOUSEOVER_UNIT" then
        AssignGuidToVisiblePlate("mouseover")
        QuestieNameplate:RefreshAll()
      end
    end)
  end
  
  -- Use OnUpdate to periodically check nameplates (Wrath doesn't have NAME_PLATE_UNIT_ADDED)
  if not self.updateFrame then
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function(self, elapsed)
      self.timer = (self.timer or 0) + elapsed
      if self.timer >= 0.2 then -- Check every 0.2 seconds
        self.timer = 0
        QuestieNameplate:RefreshAll()
      end
    end)
  end
  self.updateFrame:Hide()
  
  self.initialized = true
  self:RefreshFromConfig()
end

-- Debug helpers ---------------------------------------------------------------

function QuestieNameplate:DebugNPC(unitToken)
  if not unitToken then
    Questie.Print("QuestieNameplate.DebugNPC: no unit token provided")
    return
  end

  local guid = UnitGUID(unitToken)
  if not guid then
    Questie.Print("QuestieNameplate.DebugNPC: no GUID for", unitToken)
    return
  end

  local npcId = GetNPCIDFromGUID(guid)
  if not npcId then
    Questie.Print("QuestieNameplate.DebugNPC: unable to parse NPC ID for", unitToken, guid)
    return
  end

  local questData = IsQuestNPC(npcId)
  if questData and questData ~= false then
    local entries = {}
    for _, data in ipairs(questData) do
      table.insert(entries, string.format("%s:%s", data.type or "?", tostring(data.questId)))
    end
    Questie.Print(string.format("NPC %d linked quests: %s", npcId, tconcat(entries, ", ")))
  else
    Questie.Print(string.format("NPC %d is not in active quest list", npcId))
  end

  return questData
end

function QuestieNameplate:DebugScan()
  local plates = EnumerateNameplates()
  Questie.Print(string.format("QuestieNameplate.DebugScan: detected %d nameplates.", #plates))
  for _, frame in ipairs(plates) do
    local name = frame:GetName() or "<unnamed>"
    local nameRegion = GetNameRegion(frame)
    local text = nameRegion and nameRegion:GetText() or "<no text>"
    Questie.Print(string.format("  %s -> %s", name, text))
  end
end

function QuestieNameplate:DebugNameplateNames()
  local plates = EnumerateNameplates()
  Questie.Print("QuestieNameplate.DebugNameplateNames: listing visible nameplates")
  for idx, frame in ipairs(plates) do
    local nameRegion = GetNameRegion(frame)
    local text = nameRegion and nameRegion:GetText() or "<no text>"
    local frameName = frame:GetName() or "<unnamed>"
    Questie.Print(string.format("  [%d] %s text=%s", idx, frameName, text))
  end
end

-- Initialize on PLAYER_LOGIN
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    QuestieNameplate:Initialize()
    self:UnregisterEvent("PLAYER_LOGIN")
  end
end)

return QuestieNameplate

