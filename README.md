### Support: [Buy Me A Coffee](https://buymeacoffee.com/xius)

**Other WotLK 3.3.5 Addons by XiusTV:**

* [ElvUI VibeUI](https://github.com/XiusTV/Elvui-VibeUI) - Modern ElvUI configuration
* [Modern TSM](https://github.com/XiusTV/Modern-TSM-335) - Performance-optimized TradeSkillMaster
* [PFQuestie](https://github.com/XiusTV/PFQuestie) - Rework of Pfquest and Questie integrated together!

Interact with me on discord @ https://discord.gg/neEqeFFUsE for help related to all my addons!

# pfQuest Enhanced (WotLK 3.3.5)

pfQuest Enhanced is a modernized fork of Shagu's legendary quest database addon, rebuilt for Wrath of the Lich King 3.3.5 and tightly integrated with Questie-style UI components. It blends pfQuest's comprehensive database tooling with Questie's tracker, tooltip, and party sync experience to deliver an all-in-one questing suite for modern private servers.

> **Heads up**
>
> This repository focuses on the WotLK branch (`pfQuest-wotlk`) and its Ascension Bronzebeard extension (`pfQuest-bronzebeard`). All code starts with Shagu's original pfQuest foundation, then layers in the Questie integrations, and UX upgrades authored by XiusTV and contributors.[^pfquestie]

[^pfquestie]: Modernization project home: [XiusTV/PFQuestie](https://github.com/XiusTV/PFQuestie)

## Key Features

- **Questie-style tracker** with resize handle, inline quest items, quest focus controls, and configurable idle fade strength
- **Enhanced quest links** that add difficulty colors, tooltips, and safe chat truncation to prevent dropped messages
- **Quest giver patrol paths** rendered directly on the world map when supported by the database
- **Sticky durability & VoiceOver frames** that auto-anchor to the tracker when desired
- **Configurable auto questing** (accept/turn-in, daily-only mode, exclusion list) and quest log utilities
- **Party progress synchronization** in tooltips when partnered with the Questie-sync module
- **Quest capture pipeline** (optional) for generating new database entries with an external merger tool
- **Fully reorganized configuration UI** with dedicated sidebar categories, credits pane, and live-updating options

## Installation

1. Download/cloned the repository or packaged release
2. Copy these folders into `World of Warcraft\Interface\AddOns\` (retain names):
   - `pfQuest-wotlk`
   - `pfQuest-bronzebeard` *(optional realm-specific data for Ascension Bronzebeard)*
3. Launch WoW 3.3.5a and enable the addon(s) on the character select screen
4. Optional: set "Addon Memory" to `0` (no limit) if the client warns about the database size

## Configuration Overview

Open `/pfq config` (or `/pfquest config`) to access the redesigned control panel:

- **General** – high-level toggles such as minimap button, database IDs, favorite auto-draw, and global drop chance cutoff
- **Credits** – acknowledgement of Shagu, XiusTV, and community contributors with quick-access links
- **Questing** – tracker appearance, Quest Focus, auto questing, tooltip enhancements, quest link controls, nameplate icons, and quest giver path display
- **Announce** – chat notifications and quest completion sounds
- **Map & Minimap** – quest objective filters, quest giver visibility, node styling, transparency sliders, and continent map options
- **Routes** – pfRoute integration switches (cluster behaviour, minimap rendering, path arrows)
- **User Data** – one-click resets for configuration, cache, and captured quest history

Many options apply instantly; tracker fade controls and Quest Focus utilities notify the corresponding modules without requiring a reload.

## Credits

- **Shagu** – Original pfQuest author and database tooling
- **XiusTV** – Modernization lead, Questie integration, and WotLK/Bronzebeard maintenance
- **Bennylavaa** – Contributor for data, functionality, and tooling
- **Questie Team** – Inspiration for tracker, tooltip, and party sync systems adopted here

## Support & Links

- Modern project hub: [XiusTV/PFQuestie](https://github.com/XiusTV/PFQuestie)
- Upstream pfQuest (Shagu): <https://github.com/shagu/pfQuest>
- Discord support (XiusTV community): `https://discord.gg/neEqeFFUsE`

Enjoy the enhanced questing experience, and feel free to open issues or pull requests for bugs, data corrections, or feature ideas.
