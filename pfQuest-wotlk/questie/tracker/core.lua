---@class QuestieTracker
local QuestieTracker = QuestieLoader:CreateModule("QuestieTracker")
QuestieTracker.started = QuestieTracker.started or false

---@class TrackerBaseFrame
local TrackerBaseFrame = QuestieLoader:CreateModule("TrackerBaseFrame")

---@class TrackerHeaderFrame
local TrackerHeaderFrame = QuestieLoader:CreateModule("TrackerHeaderFrame")

---@class TrackerQuestFrame
local TrackerQuestFrame = QuestieLoader:CreateModule("TrackerQuestFrame")

---@class TrackerLinePool
local TrackerLinePool = QuestieLoader:CreateModule("TrackerLinePool")

---@class TrackerFadeTicker
local TrackerFadeTicker = QuestieLoader:CreateModule("TrackerFadeTicker")

---@class TrackerUtils
local TrackerUtils = QuestieLoader:CreateModule("TrackerUtils")

local compat = pfQuestCompat
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")

local durabilityInitialPosition
local voiceOverInitialPosition
local anchorEventFrame
local fadeHoverCount = 0

local function GetPfConfig()
  pfQuest_config = pfQuest_config or {}
  return pfQuest_config
end

local function IsPfConfigEnabled(key)
  local cfg = GetPfConfig()
  return cfg[key] == "1"
end

local function GetDurabilityAlertCount()
  if not INVENTORY_ALERT_STATUS_SLOTS then return 0 end
  local count = 0
  for i = 1, #INVENTORY_ALERT_STATUS_SLOTS do
    if GetInventoryAlertStatus(i) > 0 then
      count = count + 1
    end
  end
  return count
end

local function IsVoiceOverAvailable()
  return VoiceOverFrame and VoiceOver and VoiceOver.SoundQueueUI and VoiceOver.Addon and VoiceOver.Addon.db and VoiceOver.Addon.db.profile
end

local function EnsureAnchorEventFrame()
  if anchorEventFrame then return end
  anchorEventFrame = CreateFrame("Frame")
  anchorEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  anchorEventFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
  anchorEventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
      QuestieTracker:CaptureAnchorDefaults()
    end
    QuestieTracker:UpdateAnchoredFrames()
  end)
end
local QuestieFocusModule
local function GetFocusModule()
  if not QuestieFocusModule and QuestieLoader and QuestieLoader.ImportModule then
    QuestieFocusModule = QuestieLoader:ImportModule("QuestieFocus")
  end
  return QuestieFocusModule
end

local panelheight = 16
local function GetTrackerDimensions()
  local width = Questie.db.profile.trackerWidth or 280
  local height = Questie.db.profile.trackerHeight or 400
  return width, height
end

local defaults = {
  trackerEnabled = true,
}

local function EnsureConfig()
  Questie.db.profile = Questie.db.profile or {}
  for key, value in pairs(defaults) do
    if Questie.db.profile[key] == nil then
      Questie.db.profile[key] = value
    end
  end
end

function QuestieTracker:SyncProfileFromConfig()
  EnsureConfig()
  local cfg = GetPfConfig()
  -- Sync trackerEnabled from pfQuest config
  Questie.db.profile.trackerEnabled = IsPfConfigEnabled("showtracker")
  Questie.db.profile.stickyDurabilityFrame = IsPfConfigEnabled("stickydurability")
  Questie.db.profile.stickyVoiceOverFrame = IsPfConfigEnabled("stickyvoiceover")
  Questie.db.profile.trackerFadeEnabled = IsPfConfigEnabled("trackerfade")
end

function QuestieTracker:CaptureAnchorDefaults()
  if DurabilityFrame and not durabilityInitialPosition then
    durabilityInitialPosition = { DurabilityFrame:GetPoint() }
  end
  if IsVoiceOverAvailable() and not voiceOverInitialPosition then
    voiceOverInitialPosition = { VoiceOverFrame:GetPoint() }
  end
end

function QuestieTracker:ResetDurabilityFrame()
  if not DurabilityFrame or not durabilityInitialPosition then return end
  DurabilityFrame:ClearAllPoints()
  DurabilityFrame:SetPoint(unpack(durabilityInitialPosition))
  if GetDurabilityAlertCount() == 0 then
    DurabilityFrame:Hide()
  end
end

function QuestieTracker:UpdateDurabilityFrame()
  if not DurabilityFrame then return end
  self:CaptureAnchorDefaults()

  if not IsPfConfigEnabled("stickydurability") or not self.baseFrame or not self.baseFrame:IsShown() or not self:HasQuest() then
    self:ResetDurabilityFrame()
    return
  end

  if GetDurabilityAlertCount() == 0 then
    DurabilityFrame:Hide()
    return
  end

  local trackerCenterX = self.baseFrame:GetCenter()
  if not trackerCenterX then return end

  local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
  DurabilityFrame:ClearAllPoints()
  DurabilityFrame:SetClampedToScreen(true)
  DurabilityFrame:SetFrameStrata("MEDIUM")

  if trackerCenterX <= (screenWidth / 2) then
    DurabilityFrame:SetPoint("LEFT", self.baseFrame, "TOPRIGHT", 0, -40)
  else
    DurabilityFrame:SetPoint("RIGHT", self.baseFrame, "TOPLEFT", 0, -40)
  end

  DurabilityFrame:Show()
end

function QuestieTracker:ResetVoiceOverFrame()
  if not IsVoiceOverAvailable() or not voiceOverInitialPosition then return end
  VoiceOverFrame:ClearAllPoints()
  VoiceOverFrame:SetPoint(unpack(voiceOverInitialPosition))
  VoiceOverFrame:SetClampedToScreen(true)
  if VoiceOver.Addon and VoiceOver.Addon.db and VoiceOver.Addon.db.profile and VoiceOver.Addon.db.profile.SoundQueueUI then
    VoiceOver.Addon.db.profile.SoundQueueUI.LockFrame = false
    if VoiceOver.SoundQueueUI and VoiceOver.SoundQueueUI.RefreshConfig then
      VoiceOver.SoundQueueUI:RefreshConfig()
    end
  end
end

function QuestieTracker:UpdateVoiceOverFrame()
  if not IsVoiceOverAvailable() then return end
  self:CaptureAnchorDefaults()

  if not IsPfConfigEnabled("stickyvoiceover") or not self.baseFrame or not self.baseFrame:IsShown() or not self:HasQuest() then
    self:ResetVoiceOverFrame()
    return
  end

  local trackerCenterX = self.baseFrame:GetCenter()
  if not trackerCenterX then return end

  local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
  VoiceOverFrame:ClearAllPoints()
  VoiceOverFrame:SetClampedToScreen(true)
  VoiceOverFrame:SetFrameStrata("MEDIUM")

  local verticalOffset = -7
  if IsPfConfigEnabled("stickydurability") and DurabilityFrame and DurabilityFrame:IsShown() then
    verticalOffset = -125
  end

  if trackerCenterX <= (screenWidth / 2) then
    VoiceOverFrame:SetPoint("TOPLEFT", self.baseFrame, "TOPRIGHT", 15, verticalOffset)
  else
    VoiceOverFrame:SetPoint("TOPRIGHT", self.baseFrame, "TOPLEFT", -15, verticalOffset)
  end

  VoiceOverFrame:SetWidth(460)
  VoiceOverFrame:SetHeight(110)

  if VoiceOver.Addon and VoiceOver.Addon.db and VoiceOver.Addon.db.profile and VoiceOver.Addon.db.profile.SoundQueueUI then
    VoiceOver.Addon.db.profile.SoundQueueUI.LockFrame = true
    if VoiceOver.SoundQueueUI and VoiceOver.SoundQueueUI.RefreshConfig then
      VoiceOver.SoundQueueUI:RefreshConfig()
      if VoiceOver.SoundQueueUI.UpdateSoundQueueDisplay then
        VoiceOver.SoundQueueUI:UpdateSoundQueueDisplay()
      end
    end
  end
end

function QuestieTracker:UpdateAnchoredFrames()
  self:SyncProfileFromConfig()
  self:UpdateDurabilityFrame()
  self:UpdateVoiceOverFrame()
end

function QuestieTracker:RefreshFade()
  if TrackerFadeTicker and TrackerFadeTicker.Refresh then
    TrackerFadeTicker:Refresh()
  end
end

function QuestieTracker:RegisterFadeTarget(frame, options)
  if TrackerFadeTicker and TrackerFadeTicker.RegisterFrame then
    TrackerFadeTicker:RegisterFrame(frame, options)
  end
end

function QuestieTracker:UnregisterFadeTarget(frame)
  if TrackerFadeTicker and TrackerFadeTicker.UnregisterFrame then
    TrackerFadeTicker:UnregisterFrame(frame)
  end
end

function QuestieTracker:HasQuest()
  return self.hasActiveQuests or false
end

function TrackerBaseFrame.Initialize()
  EnsureConfig()

  if TrackerBaseFrame.frame then
    return TrackerBaseFrame.frame
  end

  local frame = CreateFrame("Frame", "QuestieTrackerBaseFrame", UIParent)
  local width, height = GetTrackerDimensions()
  frame:SetSize(width, height)
  
  -- Restore saved position if available
  local cfg = GetPfConfig()
  if cfg.trackerpos and type(cfg.trackerpos) == "table" and #cfg.trackerpos >= 4 then
    local point, relativeToName, relativePoint, xOfs, yOfs = cfg.trackerpos[1], cfg.trackerpos[2], cfg.trackerpos[3], cfg.trackerpos[4], cfg.trackerpos[5]
    local relativeTo = relativeToName == "UIParent" and UIParent or _G[relativeToName] or UIParent
    frame:SetPoint(point or "TOPLEFT", relativeTo, relativePoint or "TOPLEFT", xOfs or 20, yOfs or -150)
  else
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -150)
  end
  
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetFrameStrata("LOW")
  frame:SetResizable(true)
  frame:SetMinResize(220, 160)

  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.bg:SetColorTexture(0, 0, 0, 1)
  frame.bg:SetAlpha(0.35)

  frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
      self:StartMoving()
      self.isMoving = true
    end
  end)

  frame:SetScript("OnMouseUp", function(self)
    if self.isMoving then
      self:StopMovingOrSizing()
      self.isMoving = false
      -- Save tracker position
      local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
      if point and relativeTo then
        local cfg = GetPfConfig()
        cfg.trackerpos = { point, relativeTo:GetName() or "UIParent", relativePoint, xOfs, yOfs }
      end
    end
  end)

  local resizer = CreateFrame("Button", nil, frame)
  -- Position resizer to avoid overlap with scrollbar (scrollbar is ~20px wide)
  resizer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 5)
  resizer:SetSize(14, 14)
  resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  resizer:SetScript("OnMouseDown", function(self)
    local parent = self:GetParent()
    parent.resizing = true
    parent:StartSizing("BOTTOMRIGHT")
  end)
  resizer:SetScript("OnMouseUp", function(self)
    local parent = self:GetParent()
    parent:StopMovingOrSizing()
    parent.resizing = nil
    QuestieTracker:OnSizeApplied(parent:GetWidth(), parent:GetHeight())
  end)
  frame.resizer = resizer

  TrackerBaseFrame.frame = frame
  return frame
end

local function CreateHeaderButton(parent, anchor, texturePath)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(20, 20)  -- Increased from panelheight - 2 (14px) to 20px for better visibility
  button:SetNormalTexture(texturePath)
  button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
  button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
  button:SetPoint(anchor, -4, -1)
  return button
end

function TrackerHeaderFrame.Initialize(parent)
  if TrackerHeaderFrame.frame then
    return TrackerHeaderFrame.frame
  end

  local frame = CreateFrame("Frame", "QuestieTrackerHeaderFrame", parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  frame:SetHeight(24)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("LEFT", frame, "LEFT", 8, 0)
  title:SetText("|cff33ffccPFQuestie Tracker|r")

  frame.collapseButton = CreateHeaderButton(frame, "RIGHT", "Interface\\Buttons\\UI-Panel-CollapseButton-Up")
  
  -- Add click handler for collapse/minimize functionality
  frame.collapseButton:SetScript("OnClick", function(self)
    local cfg = GetPfConfig()
    local isCollapsed = cfg["trackercollapsed"] == "1"
    
    -- Toggle collapsed state
    cfg["trackercollapsed"] = isCollapsed and "0" or "1"
    
    -- Get base frame and current dimensions
    local baseFrame = QuestieTracker.baseFrame
    if not baseFrame then return end
    
    -- Get the collapse button's position relative to UIParent (screen coordinates)
    -- This is the anchor point we want to keep fixed
    local buttonX, buttonY = self:GetRight(), self:GetTop()
    local uiParentX, uiParentY = UIParent:GetRight(), UIParent:GetTop()
    local relativeX = buttonX - uiParentX
    local relativeY = buttonY - uiParentY
    
    if cfg["trackercollapsed"] == "1" then
      -- Collapse: Hide quest frame and resize base frame to header height only
      if QuestieTracker.questFrame then
        QuestieTracker.questFrame:Hide()
      end
      -- Store original height before collapsing
      if not baseFrame._originalHeight then
        baseFrame._originalHeight = baseFrame:GetHeight()
      end
      -- Store the button's screen position
      if not baseFrame._originalButtonPos then
        baseFrame._originalButtonPos = { relativeX, relativeY }
      end
      -- Clear all points and resize, then re-anchor at TOPRIGHT using button position
      baseFrame:ClearAllPoints()
      -- Set height first (before anchoring)
      baseFrame:SetHeight(24)
      -- Re-anchor at TOPRIGHT using button's screen position (button stays in place)
      baseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", relativeX, relativeY)
      -- Hide resizer when collapsed
      if baseFrame.resizer then
        baseFrame.resizer:Hide()
      end
      self:SetNormalTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
    else
      -- Expand: Show quest frame and restore base frame height
      if QuestieTracker.questFrame then
        QuestieTracker.questFrame:Show()
      end
      -- Use stored button position if available, otherwise use current
      local anchorX, anchorY
      if baseFrame._originalButtonPos then
        anchorX, anchorY = baseFrame._originalButtonPos[1], baseFrame._originalButtonPos[2]
        baseFrame._originalButtonPos = nil
      else
        anchorX, anchorY = relativeX, relativeY
      end
      -- Clear all points, restore height, then re-anchor at TOPRIGHT (button stays in place)
      baseFrame:ClearAllPoints()
      -- Restore original height
      if baseFrame._originalHeight then
        baseFrame:SetHeight(baseFrame._originalHeight)
        baseFrame._originalHeight = nil
      end
      -- Re-anchor at TOPRIGHT using button's screen position
      baseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", anchorX, anchorY)
      -- Show resizer when expanded
      if baseFrame.resizer then
        baseFrame.resizer:Show()
      end
      self:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
    end
  end)

  frame.title = title
  TrackerHeaderFrame.frame = frame
  return frame
end

function TrackerQuestFrame.Initialize(parent, header)
  if TrackerQuestFrame.frame then
    return TrackerQuestFrame.frame
  end

  local frame = CreateFrame("Frame", "QuestieTrackerQuestFrame", parent)
  frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

  local scroll = CreateFrame("ScrollFrame", "QuestieTrackerScrollFrame", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 0)

  local content = CreateFrame("Frame", "QuestieTrackerScrollChild", scroll)
  local baseWidth = parent:GetWidth()
  content:SetSize(math.max(200, baseWidth - 30), 200)
  scroll:SetScrollChild(content)

  frame.scroll = scroll
  frame.content = content

  TrackerQuestFrame.frame = frame
  return frame
end

function TrackerLinePool.Initialize(container)
  TrackerLinePool.container = container
  TrackerLinePool.lines = TrackerLinePool.lines or {}
  TrackerLinePool.inUse = TrackerLinePool.inUse or {}
  TrackerLinePool.itemButtons = TrackerLinePool.itemButtons or {}
  TrackerLinePool.itemButtonsInUse = TrackerLinePool.itemButtonsInUse or {}
end

function QuestieTracker:HandleLineClick(line, button)
  if not line or not line.data or not line.data.questId then
    return
  end

  local focus = GetFocusModule()
  if not focus or not focus.ToggleQuest or not focus.Clear then
    return
  end

  if button == "LeftButton" then
    focus:ToggleQuest(line.data.questId)
  elseif button == "RightButton" then
    focus:Clear()
  end
end

function QuestieTracker:HandleLineEnter(line)
  if not line then return end
  TrackerFadeTicker:HandleEnter()
  if line.highlight then
    line.highlight:Show()
  end

  if not line.data or not line.data.questId then
    return
  end

  local focus = GetFocusModule()

  GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
  GameTooltip:SetText(line.data.questTitle or line.text:GetText() or "")

  if focus and focus.IsEnabled and focus:IsEnabled() then
    GameTooltip:AddLine(string.format("%s: %s",
      pfQuest_Loc["Left-Click"] or "Left-Click",
      "Focus quest"), .8, .8, .8)
    GameTooltip:AddLine(string.format("%s: %s",
      pfQuest_Loc["Right-Click"] or "Right-Click",
      "Clear focus"), .8, .8, .8)
  else
    GameTooltip:AddLine("Enable Quest Focus in the pfQuest configuration to activate focus controls.", .8, .8, .8, true)
  end

  GameTooltip:Show()
end

function QuestieTracker:HandleLineLeave(line)
  TrackerFadeTicker:HandleLeave()
  if line and line.highlight then
    line.highlight:Hide()
  end
  GameTooltip:Hide()
end

function TrackerLinePool:GetLine()
  local line = table.remove(self.lines)
  if not line then
    line = CreateFrame("Frame", nil, self.container.content)
    line:SetHeight(16)
    line.text = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    line.text:SetPoint("TOPLEFT", line, "TOPLEFT", 0, 0)
    line.text:SetPoint("TOPRIGHT", line, "TOPRIGHT", 0, 0)
    line.text:SetJustifyH("LEFT")
    line:EnableMouse(true)
    line.highlight = line:CreateTexture(nil, "BACKGROUND")
    line.highlight:SetAllPoints(line)
    line.highlight:SetColorTexture(1, 1, 1, 0.08)
    line.highlight:Hide()
    line:SetScript("OnMouseUp", function(frame, button)
      QuestieTracker:HandleLineClick(frame, button)
    end)
    line:SetScript("OnEnter", function(frame)
      QuestieTracker:HandleLineEnter(frame)
    end)
    line:SetScript("OnLeave", function(frame)
      QuestieTracker:HandleLineLeave(frame)
    end)
  end
  line.text:SetTextColor(1, 1, 1, 1)
  line.text:SetText("")
  line.data = nil
  line:Show()
  table.insert(self.inUse, line)
  return line
end

function TrackerLinePool:ReleaseAll()
  for _, line in ipairs(self.inUse) do
    line:Hide()
    if line.highlight then
      line.highlight:Hide()
    end
    if line.focusText then
      line.focusText:Hide()
    end
    line.data = nil
    table.insert(self.lines, line)
  end
  wipe(self.inUse)
  
  -- Release all item buttons
  for _, button in ipairs(self.itemButtonsInUse) do
    button:Hide()
    button.itemId = nil
    button.line = nil
    QuestieTracker:UnregisterFadeTarget(button)
    table.insert(self.itemButtons, button)
  end
  wipe(self.itemButtonsInUse)
end

local function GetQuestItemButtons(questId, qlogid)
  if not qlogid then return {} end
  
  local items = {}
  local numObjectives = GetNumQuestLeaderBoards(qlogid) or 0
  
  -- Check objectives for item requirements
  for i = 1, numObjectives do
    local objectiveText, objectiveType = GetQuestLogLeaderBoard(i, qlogid)
    if objectiveText and objectiveType == "item" then
      -- Parse item name from objective text (format: "Item Name: 5/10")
      local itemName = string.match(objectiveText, "^([^:]+)")
      if itemName then
        itemName = string.gsub(itemName, "^%s+", "")
        itemName = string.gsub(itemName, "%s+$", "")
        
        -- Try to find this item in bags by comparing names from links
        for bag = 0, 4 do
          for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
              -- Extract item name from link: |cff9d9d9d|Hitem:12345:0:0:0|h[Item Name]|h|r
              local linkItemName = string.match(link, "%[([^%]]+)%]")
              if linkItemName and linkItemName == itemName then
                local _, _, itemIdStr = string.find(link, "item:(%d+)")
                if itemIdStr then
                  local itemId = tonumber(itemIdStr)
                  -- Only add if item is usable
                  if IsUsableItem(itemId) then
                    -- Check if we already added it
                    local found = false
                    for _, existing in ipairs(items) do
                      if existing.itemId == itemId then
                        found = true
                        break
                      end
                    end
                    if not found then
                      table.insert(items, {
                        itemId = itemId,
                        itemName = itemName,
                        count = GetItemCount(itemId, nil, true) or 0,
                      })
                    end
                  end
                end
              end
            end
          end
        end
        
        -- Also check equipped items
        for slot = 1, 19 do
          local link = GetInventoryItemLink("player", slot)
          if link then
            local linkItemName = string.match(link, "%[([^%]]+)%]")
            if linkItemName and linkItemName == itemName then
              local _, _, itemIdStr = string.find(link, "item:(%d+)")
              if itemIdStr then
                local itemId = tonumber(itemIdStr)
                -- Only add if item is usable
                if IsUsableItem(itemId) then
                  local found = false
                  for _, existing in ipairs(items) do
                    if existing.itemId == itemId then
                      found = true
                      break
                    end
                  end
                  if not found then
                    table.insert(items, {
                      itemId = itemId,
                      itemName = itemName,
                      count = GetItemCount(itemId, nil, true) or 0,
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
  
  return items
end

function TrackerLinePool:GetItemButton()
  local button = table.remove(self.itemButtons)
  if not button then
    button = CreateFrame("Button", nil, self.container.content, "SecureActionButtonTemplate")
    -- Secure frames cannot have SetSize called during combat, use pcall to suppress errors
    pcall(function()
      if not InCombatLockdown or not InCombatLockdown() then
        button:SetSize(16, 16)
      end
    end)
    button:SetFrameStrata("MEDIUM")
    
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 2)
    button.count:SetJustifyH("RIGHT")
    
    button:SetScript("OnEnter", function(self)
      TrackerFadeTicker:HandleEnter()
      if self.itemId then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.itemId)
        GameTooltip:Show()
      end
    end)
    button:SetScript("OnLeave", function(self)
      TrackerFadeTicker:HandleLeave()
      GameTooltip:Hide()
    end)
    
    -- Register with fade system
    QuestieTracker:RegisterFadeTarget(button, { minAlpha = 0.35 })
  end
  
  button:Show()
  table.insert(self.itemButtonsInUse, button)
  return button
end

local function AttachFadeHooks(frame)
  if not frame or frame._questieTrackerFadeHooked then return end
  frame._questieTrackerFadeHooked = true
  frame:HookScript("OnEnter", function()
    TrackerFadeTicker:HandleEnter()
  end)
  frame:HookScript("OnLeave", function()
    TrackerFadeTicker:HandleLeave()
  end)
end

function TrackerFadeTicker:IsFadeEnabled()
  return IsPfConfigEnabled("trackerfade")
end

function TrackerFadeTicker:RegisterFrame(frame, options)
  if not frame then return end
  self.extraFrames = self.extraFrames or setmetatable({}, { __mode = "k" })
  self.extraFrames[frame] = options or {}
  AttachFadeHooks(frame)
  self:Apply(fadeHoverCount > 0)
end

function TrackerFadeTicker:UnregisterFrame(frame)
  if not self.extraFrames or not frame then return end
  self.extraFrames[frame] = nil
  self:Apply(fadeHoverCount > 0)
end

local function ApplyExtraFrameAlpha(extraFrames, visible)
  if not extraFrames then return end
  for frame, opts in pairs(extraFrames) do
    if frame and frame.SetAlpha then
      local minAlpha = opts.minAlpha or 0.35
      local alpha = visible and 1 or minAlpha
      frame:SetAlpha(alpha)
    end
  end
end

function TrackerFadeTicker:Apply(forceVisible)
  if not self.frame or not self.frame.bg then return end

  local fadeEnabled = self:IsFadeEnabled() and QuestieTracker:HasQuest()
  local show = forceVisible or not fadeEnabled

  self.frame.bg:SetAlpha(show and 0.35 or 0.12)

  if self.frame.resizer then
    self.frame.resizer:SetAlpha(show and 1 or 0.25)
  end

  if self.header and self.header.collapseButton then
    self.header.collapseButton:SetAlpha(show and 1 or 0.4)
  end

  ApplyExtraFrameAlpha(self.extraFrames, show)
end

function TrackerFadeTicker:HandleEnter()
  fadeHoverCount = fadeHoverCount + 1
  self:Apply(true)
end

function TrackerFadeTicker:HandleLeave()
  if fadeHoverCount > 0 then
    fadeHoverCount = fadeHoverCount - 1
  end
  if fadeHoverCount <= 0 then
    fadeHoverCount = 0
    self:Apply(false)
  end
end

function TrackerFadeTicker:Refresh()
  self:Apply(fadeHoverCount > 0)
end

function TrackerFadeTicker.Initialize(frame, header, questFrame)
  TrackerFadeTicker.frame = frame
  TrackerFadeTicker.header = header
  TrackerFadeTicker.questFrame = questFrame
  TrackerFadeTicker.extraFrames = setmetatable({}, { __mode = "k" })
  fadeHoverCount = 0

  AttachFadeHooks(frame)
  AttachFadeHooks(header)
  if frame and frame.resizer then
    AttachFadeHooks(frame.resizer)
  end
  if questFrame then
    AttachFadeHooks(questFrame)
    if questFrame.scroll then
      AttachFadeHooks(questFrame.scroll)
    end
    if questFrame.content then
      AttachFadeHooks(questFrame.content)
    end
  end

  TrackerFadeTicker:Refresh()
end

function TrackerBaseFrame:SetSafePoint()
  -- placeholder for future reposition logic
end

local function DisableDefaultTracker()
  local frame = compat.QuestWatchFrame or WatchFrame
  if not frame then return end

  -- Check if init.lua already set this up
  if QuestieTracker._defaultTracker and QuestieTracker._defaultTracker.frame then
    -- Already initialized, just ensure it's hidden
    frame:SetParent(QuestieTracker._defaultTracker.hiddenParent)
    frame:Hide()
    return
  end

  QuestieTracker._defaultTracker = QuestieTracker._defaultTracker or {}
  if not QuestieTracker._defaultTracker.frame then
    QuestieTracker._defaultTracker.frame = frame
    QuestieTracker._defaultTracker.onShow = frame:GetScript("OnShow")
    QuestieTracker._defaultTracker.parent = frame:GetParent()
    QuestieTracker._defaultTracker.hiddenParent = QuestieTracker._defaultTracker.hiddenParent or CreateFrame("Frame")
    QuestieTracker._defaultTracker.hiddenParent:Hide()
  end

  frame:SetParent(QuestieTracker._defaultTracker.hiddenParent)
  frame:Hide()
  frame:SetScript("OnShow", frame.Hide)
  frame:HookScript("OnShow", frame.Hide)
end

local function RestoreDefaultTracker()
  local info = QuestieTracker._defaultTracker
  if not info or not info.frame then return end

  info.frame:SetScript("OnShow", info.onShow)
  info.frame:SetParent(info.parent or UIParent)
  info.frame:Show()
  QuestieTracker._defaultTracker = nil
end

function QuestieTracker.Initialize()
  EnsureConfig()
  
  -- Sync config first to ensure trackerEnabled is up to date
  QuestieTracker:SyncProfileFromConfig()

  -- Double-check pfQuest config as well
  local cfg = GetPfConfig()
  if cfg["showtracker"] == "0" then
    -- Explicitly disabled in pfQuest config, don't initialize
    return
  end

  if QuestieTracker.started or not Questie.db.profile.trackerEnabled then
    return
  end
  local base = TrackerBaseFrame.Initialize()
  local header = TrackerHeaderFrame.Initialize(base)
  local quests = TrackerQuestFrame.Initialize(base, header)

  EnsureAnchorEventFrame()
  QuestieTracker:CaptureAnchorDefaults()
  QuestieTracker.hasActiveQuests = false

  TrackerLinePool.Initialize(quests)
  TrackerFadeTicker.Initialize(base, header, quests)

  QuestieTracker.started = true
  QuestieTracker.baseFrame = base
  QuestieTracker.headerFrame = header
  QuestieTracker.questFrame = quests

  -- Restore collapsed state if it was saved
  local cfg = GetPfConfig()
  if cfg["trackercollapsed"] == "1" and header.collapseButton then
    quests:Hide()
    -- Get the collapse button's position relative to UIParent (screen coordinates)
    local buttonX, buttonY = header.collapseButton:GetRight(), header.collapseButton:GetTop()
    local uiParentX, uiParentY = UIParent:GetRight(), UIParent:GetTop()
    local relativeX = buttonX - uiParentX
    local relativeY = buttonY - uiParentY
    
    -- Clear all points, resize, then re-anchor at TOPRIGHT using button position
    base:ClearAllPoints()
    base:SetHeight(24)
    base:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", relativeX, relativeY)
    -- Hide resizer when collapsed
    if base.resizer then
      base.resizer:Hide()
    end
    header.collapseButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
  end

  if not QuestieTracker.eventFrame then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:SetScript("OnEvent", function()
      if QuestieTracker.started then
        QuestieTracker:Update()
      end
    end)
    QuestieTracker.eventFrame = frame
  end

  base:SetScript("OnSizeChanged", function(_, width, height)
    if base.resizing then return end
    QuestieTracker:OnSizeApplied(width, height, true)
  end)

  DisableDefaultTracker()

  QuestieTracker:OnSizeApplied(base:GetWidth(), base:GetHeight(), true)
  QuestieTracker:Update()
end

local function BuildQuestEntries()
  local entries = {}

  if pfQuest and pfQuest.questlog then
    for questId, info in pairs(pfQuest.questlog) do
      local title = info.title
      if not title and type(questId) == "number" then
        local loc = QuestieLib:GetQuestLocaleData(questId)
        if loc and loc.T then
          title = loc.T
        end
      end
      title = title or tostring(questId)

      local level
      if type(questId) == "number" then
        level = QuestieDB.QueryQuestSingle(questId, "questLevel")
      end

      entries[#entries + 1] = {
        id = questId,
        qlogid = info.qlogid,
        title = title,
        level = level or 0,
      }
    end
  end

  table.sort(entries, function(a, b)
    if a.level == b.level then
      return a.title < b.title
    end
    return a.level < b.level
  end)

  return entries
end

function QuestieTracker:Update()
  if not self.started then return end

  TrackerLinePool:ReleaseAll()

  local linesDrawn = 0
  local yOffset = -4

  local function addLine(text, indent, data)
    indent = indent or 0
    local line = TrackerLinePool:GetLine()
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", self.questFrame.content, "TOPLEFT", indent, yOffset)
    line:SetPoint("TOPRIGHT", self.questFrame.content, "TOPRIGHT", 0, yOffset)
    line.text:SetText(text)
    line.data = data
    line:SetHitRectInsets(-indent, 0, 0, 0)
    if line.highlight then
      line.highlight:Hide()
    end
    yOffset = yOffset - 16
    linesDrawn = linesDrawn + 1
    return line
  end

  local function addPlaceholder()
    addLine("|cffccccccNo tracked quests.|r")
    addLine("|cffaaaaaaAccept quests to populate this tracker.|r", 12)
  end

  local questEntries = BuildQuestEntries()
  local hasEntries = #questEntries > 0

  if not hasEntries then
    addPlaceholder()
  else
    for _, entry in ipairs(questEntries) do
      local titleColor = "ffffff"
      local questComplete
      local questLevel = entry.level or 0
      
      -- Try to get level from quest log first (more accurate)
      if entry.qlogid then
        local _, level, _, _, _, complete = compat.GetQuestLogTitle(entry.qlogid)
        questComplete = complete
        if complete then
          titleColor = "33ff33"
        end
        -- Use quest log level if available, otherwise fall back to database level
        if level and level > 0 then
          questLevel = tonumber(level) or questLevel
        end
      end

      -- Level-based color coding for quest titles only (not objectives)
      if not questComplete and questLevel and questLevel > 0 then
        local playerLevel = UnitLevel("player") or 1
        local levelDiff = questLevel - playerLevel
        
        -- Color coding based on level difference
        if levelDiff <= -7 then
          -- Gray: 7+ levels below player
          titleColor = "808080"
        elseif levelDiff >= -6 and levelDiff <= -4 then
          -- Green: 4-6 levels below player
          titleColor = "00ff00"
        elseif levelDiff >= -3 and levelDiff <= 3 then
          -- Yellow: 3 levels below to 3 levels above player (includes same level)
          titleColor = "ffff00"
        elseif levelDiff == 4 then
          -- Orange/Red: 4 levels above player
          titleColor = "ff8000"
        elseif levelDiff >= 5 then
          -- Darker Red: 5+ levels above player
          titleColor = "cc0000"
        end
      end

      -- Build level text as plain text (no color codes)
      local levelText = ""
      if questLevel and questLevel > 0 then
        levelText = string.format("[%d] ", questLevel)
      end

      local focusPrefix = ""
      local focus = GetFocusModule()
      if focus and focus.IsQuestFocused and focus:IsQuestFocused(entry.id) then
        focusPrefix = "|cff33ffcc▶|r "
        if not questComplete then
          titleColor = "33ffcc"
        end
      end

      -- Get quest items before creating the line (for inline positioning)
      local questItems = {}
      if entry.qlogid then
        questItems = GetQuestItemButtons(entry.id, entry.qlogid)
      end

      -- Calculate button area width (for spacing text properly)
      local buttonAreaWidth = 0
      if #questItems > 0 then
        local buttonCount = math.min(#questItems, 3)
        buttonAreaWidth = buttonCount * 18 -- 16px button + 2px spacing each
      end

      -- Calculate focus prefix width (approximately 10 pixels for "▶ ")
      local focusPrefixWidth = (focusPrefix and focusPrefix ~= "") and 10 or 0

      -- Apply color to both level number and title together
      -- Format: [focus] [items] [level] Quest Name
      local questLine = string.format("%s|cff%s%s%s|r", focusPrefix, titleColor, levelText, entry.title)
      local titleLine = addLine(questLine, 0, {
        questId = entry.id,
        questTitle = entry.title,
      })

      -- Add quest item buttons inline with quest name (before level text)
      if #questItems > 0 then
        -- Position buttons after focus prefix (if present)
        local buttonX = focusPrefixWidth
        
        -- Position buttons to the left of the quest level text
        for i, itemData in ipairs(questItems) do
          if i <= 3 then -- Limit to 3 buttons per quest
            local button = TrackerLinePool:GetItemButton()
            button.itemId = itemData.itemId
            button.line = titleLine
            
            -- Get item texture (GetItemInfo may return nil if item not cached)
            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemData.itemId)
            if not texture and link then
              -- Try to get texture from link if direct call failed
              local _, _, itemIdStr = string.find(link, "item:(%d+)")
              if itemIdStr then
                name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(tonumber(itemIdStr))
              end
            end
            if texture then
              button.icon:SetTexture(texture)
            else
              -- Fallback: use a placeholder texture
              button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Hide item count (not needed since tracker shows progress)
            button.count:Hide()
            
            -- Position button inline with quest name, before level text
            button:ClearAllPoints()
            button:SetPoint("LEFT", titleLine, "LEFT", buttonX, 0)
            buttonX = buttonX + 18 -- 16px button + 2px spacing
            
            -- Set up secure action for clicking
            button:SetAttribute("type1", "item")
            button:SetAttribute("item1", "item:" .. itemData.itemId)
            button:RegisterForClicks("AnyUp")
          end
        end
        
        -- Adjust quest line text position to start after buttons
        -- Rebuild text without focus prefix and position it after buttons
        titleLine.text:ClearAllPoints()
        local levelAndTitle = string.format("|cff%s%s%s|r", titleColor, levelText, entry.title)
        titleLine.text:SetText(levelAndTitle)
        titleLine.text:SetPoint("LEFT", titleLine, "LEFT", focusPrefixWidth + buttonAreaWidth, 0)
        
        -- If there's a focus prefix, create it as a separate text element at the start
        if focusPrefixWidth > 0 then
          if not titleLine.focusText then
            titleLine.focusText = titleLine:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
          end
          titleLine.focusText:SetText(focusPrefix)
          titleLine.focusText:SetPoint("LEFT", titleLine, "LEFT", 0, 0)
          titleLine.focusText:Show()
        end
      else
        -- No items: hide focusText if it exists (use normal text display)
        if titleLine.focusText then
          titleLine.focusText:Hide()
        end
      end
      
      -- Add quest objectives
      if entry.qlogid then
        local numObjectives = GetNumQuestLeaderBoards(entry.qlogid) or 0
        if numObjectives > 0 then
          for objectiveIndex = 1, numObjectives do
            local objectiveText, _, finished = GetQuestLogLeaderBoard(objectiveIndex, entry.qlogid)
            if objectiveText then
              -- Objectives are always white (or gray if completed)
              local objColor = finished and "808080" or "ffffff"
              addLine(string.format("|cff%s- %s|r", objColor, objectiveText), 12)
            end
          end
        elseif questComplete then
          addLine("|cff808080- Ready to turn in|r", 12)
        end
      end
    end
  end

  local contentHeight = math.max(20, linesDrawn * 16 + 20)
  self.questFrame.content:SetHeight(contentHeight)

  self.hasActiveQuests = hasEntries
  self:UpdateAnchoredFrames()
  TrackerFadeTicker:Refresh()
end

function QuestieTracker:Disable()
  -- Save position before disabling
  if self.baseFrame then
    local point, relativeTo, relativePoint, xOfs, yOfs = self.baseFrame:GetPoint(1)
    if point and relativeTo then
      local cfg = GetPfConfig()
      cfg.trackerpos = { point, relativeTo:GetName() or "UIParent", relativePoint, xOfs, yOfs }
    end
    self.baseFrame:Hide()
  end
  self:ResetDurabilityFrame()
  self:ResetVoiceOverFrame()
  self.started = false
  RestoreDefaultTracker()
end

function QuestieTracker:OnSizeApplied(width, height, silent)
  width = math.max(220, width or 0)
  height = math.max(160, height or 0)

  Questie.db.profile.trackerWidth = width
  Questie.db.profile.trackerHeight = height

  if self.questFrame and self.questFrame.content then
    self.questFrame.content:SetWidth(math.max(200, width - 30))
  end

  self:UpdateAnchoredFrames()
  self:RefreshFade()

  if not silent then
    self:Update()
  end
end

function QuestieTracker:Enable()
  Questie.db.profile.trackerEnabled = true
  -- Disable default tracker when enabling
  DisableDefaultTracker()
  -- If tracker was already initialized, just show it
  if self.started and self.baseFrame then
    self.baseFrame:Show()
    self:Update()
  else
    -- Otherwise initialize it
    self.started = false
    self:Initialize()
    if self.baseFrame then
      self.baseFrame:Show()
    end
    self:Update()
  end
end

function QuestieTracker:Toggle(force)
  local enabled = force
  if enabled == nil then
    enabled = not Questie.db.profile.trackerEnabled
  end

  Questie.db.profile.trackerEnabled = enabled
  if enabled then
    self:Enable()
  else
    self:Disable()
  end
end

return QuestieTracker

