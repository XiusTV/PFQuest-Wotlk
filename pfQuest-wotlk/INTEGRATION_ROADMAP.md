# pfQuest × Questie Integration Roadmap

## Integration Philosophy

We are **integrating Questie features INTO pfQuest**, not making them coexist. All Questie functionality should be adapted to work with pfQuest's existing systems, configuration, and data structures.

## Completed Features ✅

1. ✅ **Auto Questing** - Auto accept/turn-in quests
2. ✅ **Quest Tracker** - Questie-style tracker UI with quest item buttons
3. ✅ **Tooltip System** - Enhanced tooltips with party progress
4. ✅ **Quest Focus** - Focus quests to dim non-focused icons
5. ✅ **Party Progress Sync** - Share quest progress with party members
6. ✅ **Level-Based Quest Coloring** - Color quest titles by level (gray/green/yellow/red)
7. ✅ **QuestieSounds** - Quest accept/complete audio cues
8. ✅ **QuestieNameplate** - Quest icons on enemy nameplates
9. ✅ **QuestieQuestLinks** - Enhanced quest link handling in chat
10. ✅ **QuestieMenu** - Context menu system for townsfolk tracking

---

## Remaining Features to Integrate

### Phase 1: High-Value QoL Features (Quick Wins)

**Goal:** Add features that provide immediate value with minimal complexity.

#### 1.1 QuestieCoordinates (Deferred)

This feature is intentionally out of scope. Coordinate displays on the world map and minimap
will remain as-is; no QuestieCoordinates module will be ported. Future phases can revisit this
decision if requirements change.

---

#### 1.2 QuestieAnnounce

**What:** Announce quest completion/accepted in chat  
**Why:** Provides feedback for quest actions  
**Complexity:** Low  
**Dependencies:** None  
**Integration Steps:**

1. Copy `QuestieAnnounce.lua` to `questie/announce.lua`
2. Adapt to use `pfQuest_config` instead of `Questie.db.profile`
3. Hook into `quest.lua` quest accept/complete events
4. Add config toggles: `announceQuestAccepted`, `announceQuestCompleted`
5. Wire into config panel under "Questing" section
6. Test: Accept/complete quests, verify announcements

**Test Checklist:**

- [ ] Quest accepted announcements appear when enabled
- [ ] Quest completed announcements appear when enabled
- [ ] Announcements respect config toggles
- [ ] Announcements work without reload

---

### Phase 2: Medium-Value Features (Moderate Complexity)

**Goal:** Add features that provide significant value but require more integration work.

#### 2.1 QuestieNameplate

**What:** Show quest icons on enemy nameplates  
**Why:** Quick visual identification of quest targets  
**Complexity:** Medium  
**Dependencies:** QuestieTooltips (already integrated)  
**Integration Steps:**

1. Copy `QuestieNameplate.lua` to `questie/nameplate.lua`
2. Adapt to use `pfQuest_config` instead of `Questie.db.profile`
3. Integrate with `pfQuestTooltipBridge` to get quest data
4. Hook into nameplate creation/destruction events
5. Add config toggles: `nameplateEnabled`, `nameplateIconScale`
6. Wire into config panel under "Map" section
7. Test: Enable nameplates, verify icons appear on quest NPCs

**Test Checklist:**

- [x] Quest icons appear on nameplates when enabled
- [x] Icons update when quest progress changes
- [x] Icons disappear when quest is completed
- [x] Config toggles work without reload
- [x] Performance is acceptable with many nameplates

---

#### 2.2 QuestieQuestLinks

**What:** Enhanced quest link handling in chat  
**Why:** Better quest link display and interaction  
**Complexity:** Medium  
**Dependencies:** None  
**Integration Steps:**

1. Copy `QuestLinks/` directory to `questie/questlinks/`
2. Adapt to use `pfQuest_config` instead of `Questie.db.profile`
3. Hook into chat frame events
4. Add config toggles: `enableQuestLinks`, `questLinkTooltip`
5. Wire into config panel under "Questing" section
6. Test: Click quest links in chat, verify tooltips/info

**Test Checklist:**

- [x] Quest links in chat are enhanced when enabled
- [x] Quest link tooltips show quest info
- [x] Quest link interactions work correctly
- [x] Config toggles work without reload

---

#### 2.3 QuestieMenu

**What:** Context menu system for NPCs (trainers, mailboxes, etc.)  
**Why:** Quick access to NPC interactions  
**Complexity:** Medium-High  
**Dependencies:** None  
**Integration Steps:**

1. Copy `QuestieMenu/` directory to `questie/menu/`
2. Adapt to use `pfQuest_config` instead of `Questie.db.profile`
3. Integrate with pfQuest's NPC detection system
4. Add config toggles: `enableQuestieMenu`, `menuShowTrainers`, etc.
5. Wire into config panel under "Questing" section
6. Test: Right-click NPCs, verify menu appears

**Test Checklist:**

- [x] Questie menu accessible via slash command (`/db menu`)
- [x] Menu options work correctly (toggles townsfolk tracking)
- [x] Config toggles work without reload
- [x] Menu integrates with pfQuest's tracking system
- [ ] Right-click NPC context menu (future enhancement)

---

### Phase 3: High-Value Complex Features (Major Features)

**Goal:** Add major features that provide significant value but require substantial integration work.

#### 3.1 QuestieJourney

**What:** Quest browser/journal UI showing quest history, search, and details  
**Why:** Major feature for quest management and browsing  
**Complexity:** High  
**Dependencies:** QuestieDB (database), QuestieSearch  
**Integration Steps:**

1. Copy `Journey/` directory to `questie/journey/`
2. Adapt to use `pfQuest_config` instead of `Questie.db.profile`
3. Integrate with pfQuest's quest data system
4. Create bridge between pfQuest quest data and QuestieJourney format
5. Add config toggles: `enableJourney`, `journeyShowCompleted`, etc.
6. Wire into config panel under new "Journey" section
7. Add slash command: `/pfq journey` or `/pfquest journey`
8. Test: Open journey window, browse quests, search, view details

**Test Checklist:**

- [ ] Journey window opens/closes correctly
- [ ] Quest list displays correctly
- [ ] Quest search works
- [ ] Quest details show correct information
- [ ] Completed quests tracked correctly
- [ ] Config toggles work without reload
- [ ] Performance is acceptable with large quest lists

---

#### 3.2 QuestieSlash Commands

**What:** Slash command system for pfQuest  
**Why:** Quick access to features via commands  
**Complexity:** Medium  
**Dependencies:** None  
**Integration Steps:**

1. Review existing pfQuest slash commands
2. Copy `QuestieSlash.lua` to `questie/slash.lua`
3. Adapt commands to pfQuest naming (`/pfq` or `/pfquest`)
4. Integrate with existing pfQuest commands
5. Add commands for new features (journey, nameplate, etc.)
6. Test: All slash commands work correctly

**Test Checklist:**

- [ ] `/pfq` or `/pfquest` shows help menu
- [ ] All commands work correctly
- [ ] Command aliases work
- [ ] Commands match pfQuest naming conventions

---

## Integration Guidelines

### Configuration Integration

- **Always use `pfQuest_config`** as the source of truth
- **Never reference `Questie.db.profile`** directly
- **Add config entries** to `pfQuest_defconfig` in `config.lua`
- **Wire `onupdate` callbacks** to sync config changes to Questie modules

### Module Loading

- **Use `QuestieLoader`** for module management
- **Follow existing module structure** in `questie/` directory
- **Register modules** in `init/addon.xml` if needed

### Data Integration

- **Bridge pfQuest data** to Questie format where needed
- **Use `pfQuestTooltipBridge`** as reference for data mapping
- **Avoid duplicating data** - reuse pfQuest's quest data structures

### Testing Strategy

- **Test each feature independently** before moving to next
- **Test with existing features** to ensure no conflicts
- **Test config changes** without reload when possible
- **Test performance** with typical usage scenarios

---

## Implementation Order

### Recommended Order:

1. **Phase 1.1** - QuestieCoordinates (Quick win, low risk)
2. **Phase 1.2** - QuestieAnnounce (Quick win, low risk)
3. **Phase 1.3** - QuestieSounds (Quick win, low risk)
4. **Phase 2.1** - QuestieNameplate (Moderate complexity, high value)
5. **Phase 2.2** - QuestieQuestLinks (Moderate complexity, medium value)
6. **Phase 2.3** - QuestieMenu (Moderate-high complexity, medium value)
7. **Phase 3.2** - QuestieSlash (Medium complexity, foundation for others)
8. **Phase 3.1** - QuestieJourney (High complexity, major feature)

### Why This Order?

- **Phase 1** builds momentum with quick wins
- **Phase 2** adds valuable features before tackling the complex Journey
- **Phase 3.2** (Slash) should come before Journey to provide command access
- **Phase 3.1** (Journey) is saved for last as it's the most complex and benefits from all previous integrations

---

## Notes

- Each phase should be completed and tested before moving to the next
- Update `INTEGRATION_PROGRESS.txt` after each feature is completed
- Remove Questie-specific code that assumes Questie is loaded alongside pfQuest
- All features should work standalone with pfQuest only

