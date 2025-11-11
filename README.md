# PFQuestie - Enhanced Quest Suite for WotLK 3.3.5

**Unified quest database suite for World of Warcraft 3.3.5 with Questie integration, automated quest capture, and party synchronization.**

## About This Repository

This repository contains **two complementary quest addons** maintained exclusively by XiusTV:

1. **pfQuest-wotlk** - Core quest database for WotLK 3.3.5 with Questie integration
2. **pfQuest-bronzebeard** - Ascension Bronzebeard realm-specific extension

Both addons feature advanced quest capture systems, Questie-style tracker and tooltips, party progress synchronization, and automated database building.

**⚠️ This is an independent project.** The original pfQuest developer (Shagu) is not involved with these enhanced versions.

---

## 🚀 Key Features

### Questie Integration

* **Questie Tracker** - Modern quest tracker UI with resize handle and quest level display
* **Questie Tooltips** - Enhanced tooltips showing quest objectives, progress, and party member progress
* **Quest Focus** - Click tracker quests to focus them, dimming non-focused map icons
* **Auto Questing** - Auto-accept and auto-turn-in quests with daily-only mode and exclusion lists
* **Party Progress Sync** - See party members' quest progress in tooltips (real-time synchronization)

### Quest Capture System

* **Automatic quest detection** - Captures quest data when you accept new quests
* **Live database injection** - Captured quests immediately available in-game
* **Per-character history tracking** - See your capture contributions
* **Smart NPC detection** - Identifies quest givers and enders with accurate locations
* **Objective parsing** - Extracts kill/collect/explore objectives
* **Quest chain detection** - Tracks prerequisites and sequences
* **Reward tracking** - Captures all rewards and choice rewards
* **Export functionality** - Generate Lua database files from captured quests

### Performance Optimizations

* **Lazy loading** - Only loads needed data
* **Efficient caching** - Reduces repeated lookups
* **Optimized rendering** - Smoother map updates

### Database & Map Features

* **Quest tracking** - Automatic objective tracking on world map and minimap
* **Spawn points** - NPCs, objects, herbs, mines, chests, and more
* **Database browser** - Browse through all quests, items, NPCs, and objects
* **Quest links** - Shift-click quests to link in chat
* **Arrow navigation** - HUD arrow pointing to active objectives
* **Minimap integration** - Quest nodes on minimap
* **ElvUI-style config panel** - Two-pane configuration interface with sidebar navigation

---

## 📦 Installation

### Installing Both Addons

1. Download or clone this repository
2. Extract both addon folders to:
   ```
   World of Warcraft\Interface\AddOns\
   ```
   You should have:
   - `AddOns\pfQuest-wotlk\`
   - `AddOns\pfQuest-bronzebeard\`
3. Restart WoW
4. Type `/db show` to start using

### Which Addon Do I Need?

**pfQuest-wotlk**: 
- Universal quest database for WotLK 3.3.5
- Works on any WotLK server
- Contains Vanilla + TBC quest data
- **Install this if you play on any WotLK server**

**pfQuest-bronzebeard**:
- Extension specifically for Ascension's Bronzebeard realm
- Server-specific quest data and overrides
- Requires pfQuest-wotlk to be installed
- **Only install this if you play on Bronzebeard**

---

## 🎮 Commands

### Basic Commands

* `/db show` - Open database browser
* `/db object [name]` - Search for NPCs/objects
* `/db quest [name]` - Search for quests
* `/db item [name]` - Search for items
* `/way <x> <y>` - Set waypoint
* `/db mines` - Show all mines on map
* `/db herbs` - Show all herbs on map
* `/db rares` - Show all rare spawns
* `/db chests` - Show all chests

### Quest Capture Commands

* `/pfquest capture` - Open quest capture monitor UI
* `/pfquest capture scan` - Scan quest log for new quests
* `/pfquest capture export` - Export captured quests as Lua
* `/pfquest capture clear` - Clear all captured quest data
* `/pfquest capture status` - Show capture system status

### Party Sync Commands

* `/pfqps status` - Show party sync status
* `/pfqps debug` - Toggle debug mode
* `/pfqps sync` - Manually trigger full sync with party members

---

## 🎯 How Quest Capture Works

### In-Game Capture

1. Accept a quest (capture system automatically detects it)
2. Complete objectives (system tracks where you killed/collected)
3. Turn in quest (system records completion)
4. Data is saved to SavedVariables

### Making Captures Permanent

Captured data is saved per-character but can be shared:

**Option 1: Export & Share**
1. Run `/pfquest capture export`
2. Data is copied to your clipboard as Lua code
3. Share with community or save for backup

**Option 2: External Merger Tool** (Recommended)
1. Navigate to `Interface\pfQuest-Tools\dist\`
2. Run `pfQuest Merger Tool.exe`
3. Click "Start Monitoring"
4. When you close WoW, captured quests are automatically merged into the addon database
5. Next launch, all characters have access to captured quests!

---

## 🎨 Interface & Controls

### Map Controls

* **Click** a node on the world map to change its color
* **Shift-click** a quest giver to remove completed quests from map
* **Ctrl-hold** to temporarily hide clusters on world map
* **Ctrl-hold** while hovering minimap node to temporarily hide it

### Questlog Integration

* **Show** button - Add quest objectives to map
* **Hide** button - Remove quest from map
* **Clean** button - Remove all pfQuest nodes from map
* **Reset** button - Restore default visibility settings

### Questie Tracker

* **Left-click** quest - Focus quest (dim other map icons)
* **Right-click** quest - Clear focus
* **Resize handle** - Drag bottom-right corner to resize tracker
* **Quest level display** - Shows quest level next to quest name

### Minimap Button

* **Click** - Open database browser
* **Shift-drag** - Move minimap button position

### HUD Arrow

* **Shift-drag** - Move arrow position
* Automatically points to active quest objectives

### Configuration Panel

* **Sidebar navigation** - Click category names on the left
* **Scrollable content** - Options appear on the right
* **Real-time updates** - Changes apply immediately (no reload needed for most settings)

---

## 📊 Database Browser

The database GUI allows you to:

* Browse all quests, items, NPCs, and objects
* Bookmark favorite entries
* Search by name or filter by type
* View spawn locations on map
* See quest chains and prerequisites
* Display up to 100 entries at once

Access it via:
* Click minimap icon
* `/db show`

---

## 🔧 Auto-Tracking Modes

Configure how quests appear on your map:

### All Quests (Default)
Every quest is automatically shown and updated on the map

### Tracked Quests
Only shift-clicked tracked quests show on the map

### Manual Selection
Only manually shown quests (via "Show" button) appear
Completed objectives auto-remove

### Hide Quests
Manual mode + quest givers won't auto-show
Completed objectives remain on map

Change mode via dropdown in top-right of world map.

---

## 🎯 Party Progress Synchronization

See your party members' quest progress in real-time:

* **Automatic sync** - Progress updates sent within 1 second of changes
* **Tooltip display** - Hover over quest NPCs to see party progress
* **Quest ID matching** - Works even when NPC IDs differ between clients
* **3-minute TTL** - Remote progress expires after 3 minutes
* **Yell fallback** - Works outside groups using `/yell` channel

**Configuration:**
* Enable "Party Progress in Tooltips" in Questing section
* Optionally disable `/yell` fallback for solo players

---

## 🌍 Supported Content

### pfQuest-wotlk Database

* **Vanilla (1-60)** - Full quest database
* **The Burning Crusade (60-70)** - Complete TBC quests
* **Wrath of the Lich King (70-80)** - WotLK content (expanding via captures)
* **Multi-language support** - enUS, deDE, frFR, esES, ruRU, zhCN, zhTW, koKR, ptBR

### pfQuest-bronzebeard Database

* **Ascension-specific quests** - Custom Bronzebeard realm quests
* **Server overrides** - Corrected spawn locations for Ascension
* **Custom NPCs** - Realm-specific NPCs and locations
* **Automated capture** - Continuously expanding database

---

## 💡 Usage Tips

### Finding Resources

```
/db mines 150 225    - Show ores requiring skill 150-225
/db herbs 200 250    - Show herbs requiring skill 200-250
/db object Copper    - Show all Copper Vein spawns
/db quest Onyxia     - Find all quests with "Onyxia"
```

### Efficient Questing

1. Enable "All Quests" mode for automatic tracking
2. Use database browser to find quest starts
3. Shift-click quest givers on map to mark as done
4. Use `/db clean` to clear map when needed
5. Focus quests in tracker to highlight objectives
6. Enable party progress to see group members' advancement

### Contributing Quest Data

1. Complete quests normally (capture runs automatically)
2. Run `/pfquest capture status` to see what you've captured
3. Export or use merger tool to make permanent
4. Share exports with the community!

---

## 🏆 Credits

### This Branch

* **Developed and maintained exclusively by XiusTV**
* Quest capture system implementation
* Questie integration (tracker, tooltips, auto-questing, focus, party sync)
* Performance optimizations
* WotLK 3.3.5 and Bronzebeard-specific enhancements
* Database expansion through community captures
* ElvUI-style configuration panel

### Original pfQuest Framework

* **Created by Shagu** - [Original Repository](https://github.com/shagu/pfQuest)
* Core database and rendering engine
* VMaNGOS and CMaNGOS database projects for quest data

### Questie Integration

* Based on Questie addon concepts and UI patterns
* Party synchronization inspired by Questie's party sync system
* Tooltip system adapted from Questie's tooltip modules

This project builds on the pfQuest framework by Shagu. All capture systems, Questie integrations, optimizations, and WotLK/Bronzebeard-specific features are original work by XiusTV.

---

## 📜 License

This addon follows the same license as the original pfQuest project.

---

## ✅ Compatibility

* **WoW Version**: 3.3.5a (WotLK) - Tested on Warmane, Ascension
* **Servers**: Universal (pfQuest-wotlk), Bronzebeard-specific (pfQuest-bronzebeard)
* **Memory**: ~80MB database (all locales) - persistent memory usage
* **Addons**: Compatible with pfUI, ElvUI, and all standard UI mods
* **Language**: Full multi-language support

---

## 🐛 Troubleshooting

### "AddOn using too much memory" Warning

Set Script Memory to `0` (no limit) in character selection screen
This is normal - pfQuest loads entire database on startup but doesn't grow over time

### Quest Not Showing on Map

1. Check auto-tracking mode (should be "All Quests" for automatic)
2. Click "Reset" button in questlog
3. Try `/db clean` then `/db show` to refresh

### Captured Quests Not Appearing

1. Run `/pfquest capture status` to verify data was captured
2. Use merger tool to integrate captures into database
3. Reload UI (`/reload`) after merger completes

### Party Progress Not Showing

1. Enable "Party Progress in Tooltips" in Questing section
2. Ensure both clients have the feature enabled
3. Check `/pfqps status` to verify sync is working
4. Try `/pfqps sync` to manually trigger sync

### Performance Issues

1. Use slim language downloads instead of full packages
2. Disable unused addons
3. Clear WoW cache folder

---

## 🚀 What's Next

* **Northrend Quest Expansion** - Capturing all WotLK 70-80 quests
* **Community Database** - Sharing captured quest data
* **Enhanced Capture UI** - More detailed statistics and filtering
* **Automatic Updates** - Cloud-sync for quest captures
* **Integration Tools** - Better export/import functionality
* **Questie Comms Compatibility** - Seamless sync with Questie addon users

---

## 📝 Contributing

Found missing quest data? The capture system makes it easy!

1. Accept and complete the quest
2. System automatically captures the data
3. Use merger tool or export to share
4. Submit exports via GitHub issues

Every quest you complete helps expand the database for everyone!

---

**For issues or feature requests, please open an issue on this repository.**

---

*Last Updated: December 2024*  
*Maintainer: XiusTV*  
*Based on pfQuest by Shagu*
