# HealersMate

HealersMate is a comprehensive healing addon designed for Vanilla World of Warcraft version 1.12. It aims to provide an easy-to-use and functional out-of-box healing experience while also providing many customization options akin to modern WoW's VuhDo or Healbot, but without being too overbearing. It supports healing parties, raids, pets, and targets.
<p align="center">
  <img src="Screenshots/Party-Example.PNG" alt="Party Example" width=20%>
  <img src="Screenshots/Raid-Example.PNG" alt="Raid Example" width=75%>
</p>

### Customizable Key Bindings
Bind key+button combinations to specific spells, allowing you to cast on any player with one click.<br>
Use the command `/hm` in-game to open the configurator.

<img src="Screenshots/Spell-Config-Example.PNG" alt="Spell Config Example" width=40%>

#### Special Binds
Assign these keywords as some of your free spell binds to perform special actions:
| Bind | Function |
| - | - |
| Target | Sets the unit as your target |
| Follow | Follow a player |
| Assist | Set the unit's target as your target |
| Role | Choose to set a player as Tank/Healer/Damage |

### View Spells at a Glance

When hovering over a player, a tooltip is displayed showing you what spells you have bound, their power cost, and how many times you can cast them.

<img src="Screenshots/Tooltip-Example.PNG" alt="Tooltip Example">

### Buff/Debuff/Dispel Tracking

HealersMate will display buffs and debuffs relevant to you, as well as color heath bars when a player has a debuff you can dispel.

<p align="center">
  <img src="Screenshots/Debuff-Example.PNG" alt="Debuff Example">
  <img src="Screenshots/Low-Health-Example.PNG" alt="Low Health Example">
</p>

### Still In Development

Currently, 2.0.0 is in Alpha, which means there may be bugs and there are certain features lacking. Namely, a way to customize the UI. Under the hood, a lot of things are in place, but a user-friendly configuration is in the works. If you're feeling bold and know how to mess around with Lua, you can edit Profile.lua and ProfileManager.lua to finely customize your UI.

### Client Mods That Enhance HealersMate

While not required, the mods listed below will massively improve your experience with HealersMate, and likely the game in general. Note that some vanilla servers may not allow these mods and you should check with your server to see if they do. Turtle WoW does not seem to have a problem with any of these.

| Mod | Enhancement |
| - | - |
| SuperWoW ([GitHub](https://github.com/balakethelock/SuperWoW)) | - Shows incoming healing without you or others needing to use HealComm<br>- Allows casting on players without needing to resort to target-switching tricks<br>- Lets you see distance to players(less accurate than UnitXP SP3)<br>- Lets you set units you're hovering over as your mouseover target |
| UnitXP SP3 ([GitHub](https://github.com/allfoxwy/UnitXP_SP3)) | Allows HealersMate to show more accurate distance to players and show whether they're in line of sight |
| Nampower ([Original](https://github.com/namreeb/nampower) / [Pepopo's Improved Fork](https://github.com/pepopo978/nampower)) | Drastically decreases the amount of time in between casting consecutive spells  |

See [this page](https://turtle-wow.fandom.com/wiki/Client_Fixes_and_Tweaks) for information about how to install mods.

### Planned Features

For 2.0.0 Release:
- [ ] Customizable player frames
- [ ] Support MMO mouse buttons
- [ ] Custom mouse button names and ordering
- [X] ~~Bind spells to hostile targets~~
- [X] ~~Basic heal predictions without you or others needing to use HealComm (SuperWoW required)~~
- [X] ~~Assign roles to players~~

In future releases:
- Track Buff and HoT times

---
Feel free to contribute, report issues, or suggest improvements. Your feedback is valuable in making HealersMate a powerful and user-friendly healing solution for the Vanilla WoW community.

## Installation
1. [Download the latest release zip](https://github.com/i2ichardt/HealersMate/releases/).
2. Extract the files into your WoW addons folder.
3. Launch World of Warcraft and enjoy a smoother healing experience with HealersMate.

---

**Reminder:** This addon is designed for use in Vanilla World of Warcraft version 1.12 and is NOT compatible with Classic(1.13+) versions of WoW.
