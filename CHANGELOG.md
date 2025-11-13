# Changelog - pfQuest Enhanced

## 0.9.0-beta · 2025-11-13

### Added
- Quest giver patrol paths rendered directly on the world map, with colorized dot trails and fallback detection for linked NPCs
- Configurable tracker fade system, including in-game enable toggle and opacity slider
- Dedicated credits category in the configuration sidebar with direct resource links
- Version badge displayed on both the main configuration window and welcome screen
- Questie-style configuration layout: reorganized sections (General, Questing, Announce, Map & Minimap, Routes, User Data)

### Improved
- Quest tracker anchoring to keep titles and objective text stable during combat updates
- Enhanced quest link insertion with 255-byte safety checks to prevent chat suppression when sharing multiple quests
- Tracker resize handle brought above overlapping text and expanded hit region for easier dragging
- Minimap/world map node management now respects updated filters and category layout

### Fixed
- Combat taint from secure quest item buttons by deferring hide actions until after combat
- Duplicate Quest Focus controls caused by legacy config migration
- Scrollbar column alignment in the quest tracker panel and off-screen fade artifacts

---

## Previous Versions

Based on pfQuest 7.0.1 by Shagu
- Original quest database and core functionality
- Database from VMaNGOS and CMaNGOS projects

