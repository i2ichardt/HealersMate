# HealersMate

HealersMate is a unit frames addon for World of Warcraft Vanilla 1.12 tailored for healers, striving to be an alternative to modern WoW's VuhDo, Cell, or Healbot.
<p align="center">
  <img src="Screenshots/Party-Example.PNG" alt="Party Example" width=20%>
  <img src="Screenshots/Raid-Example.PNG" alt="Raid Example" width=75%>
</p>

### Quick List of Features
- Shows the status of party/raid/pets/targets health, power, marks, and relevant buffs and debuffs
- Colors the bars of players you can dispel
- Bind click-casting spells for both friendly and hostile targets
- See your bound spells, their cost, and available mana while hovering over frames
- Shows incoming healing (Improved by SuperWoW)
- Shows when members have aggro on mobs
- Assign roles to players
- Choose from a variety of preset frame styles, eventually to be fully customizable
- See the distance between you and other players (**[SuperWoW or UnitXP SP3 Required](https://github.com/OldManAlpha/HealersMate?tab=readme-ov-file#client-mods-that-enhance-healersmate)**, otherwise only can check 28 yds)
- See when players/enemies are out of your line-of-sight (**[UnitXP SP3 Required](https://github.com/OldManAlpha/HealersMate?tab=readme-ov-file#client-mods-that-enhance-healersmate)**)
- See the remaining duration of buffs and HoTs on other players (**[SuperWoW Required](https://github.com/OldManAlpha/HealersMate?tab=readme-ov-file#client-mods-that-enhance-healersmate)**)
- Add players/enemies to a separate Focus group, even if they're not in your party or raid (**[SuperWoW Required](https://github.com/OldManAlpha/HealersMate?tab=readme-ov-file#client-mods-that-enhance-healersmate)**)

### Customizable Key Bindings
Bind key+mouse button combinations to specific spells, allowing you to cast on any player with one click.<br>
Use the command `/hm` in-game to open the configurator.

<img src="Screenshots/Spell-Config-Example.PNG" alt="Spell Config Example" width=40%>

#### Special Binds
Assign these keywords as some of your free spell binds to perform special actions:
| Bind | Function |
| - | - |
| Target | Sets the unit as your target |
| Context | Open the right-click context menu |
| Role | Choose to set a player as Tank/Healer/Damage |
| Follow | Follow a player |
| Assist | Set the unit's target as your target |
| Focus (SuperWoW Required) | Add/remove a unit to your focus |
| Promote Focus (SuperWoW Required) | Moves a focus to the top |

### View Spells at a Glance

When hovering over a player, a tooltip is displayed showing you what spells you have bound, their power cost, and how many times you can cast them.

<img src="Screenshots/Tooltip-Example.PNG" alt="Tooltip Example">

### Buff/Debuff/Dispel Tracking

HealersMate will display buffs and debuffs relevant to you, as well as color heath bars when a player has a debuff you can dispel.

<p align="center">
  <img src="Screenshots/Debuff-Example.PNG" alt="Debuff Example">
</p>

### Not Just For Healers

While HealersMate is made with a healers-first mentality, HealersMate can be a viable option for raid frames for non-healers or dispellers.

### Still In Development

Currently, 2.0.0 is in Alpha, which means there may be bugs and there are certain features lacking. Namely, a way to customize the UI. Under the hood, a lot of things are in place, but a user-friendly configuration is in the works. If you're feeling bold and know how to mess around with Lua, you can edit Profile.lua and ProfileManager.lua to finely customize your UI or define your own scripts under Customize>Advanced Options.

### Client Mods That Enhance HealersMate

While not required, the mods listed below will massively improve your experience with HealersMate, and likely the game in general. Note that some vanilla servers may not allow these mods and you should check with your server to see if they do. Turtle WoW does not seem to have a problem with any of these. See [this page](https://turtle-wow.fandom.com/wiki/Client_Fixes_and_Tweaks) for information about how to install mods.

| Mod | Enhancement |
| - | - |
| SuperWoW ([GitHub](https://github.com/balakethelock/SuperWoW)) | - Shows more accurate incoming healing, and shows incoming healing from players that do not have HealComm<br>- Allows casting on players without doing split-second target switching<br>- Lets you see accurate distance to friendly players/NPCs<br>- Lets you set units you're hovering over as your mouseover target |
| UnitXP SP3 ([GitHub](https://github.com/allfoxwy/UnitXP_SP3)) | Allows HealersMate to show very accurate distance to both friendly players and enemies, and show if they're out of line-of-sight |
| Nampower ([Original](https://github.com/namreeb/nampower) / [Pepopo's Improved Fork](https://github.com/pepopo978/nampower)) | Drastically decreases the amount of time in between casting consecutive spells  |

### Planned Features

For 2.0.0 Release:
- [ ] Customizable player frames
- [ ] Support MMO mouse buttons
- [ ] Custom mouse button names and ordering
- [X] ~~Bind spells to hostile targets~~
- [X] ~~Basic heal predictions without you or others needing to use HealComm (SuperWoW required)~~
- [X] ~~Assign roles to players~~
- [X] ~~Track Buff and HoT times~~ (SuperWoW Required)

---
Feel free to contribute, report issues, or suggest improvements. Your feedback is valuable in making HealersMate a powerful and user-friendly healing solution for the Vanilla WoW community.

## Installation
1. [Download the latest release zip](https://github.com/i2ichardt/HealersMate/releases/).
2. Extract the contents into your WoW addons folder.
3. Launch World of Warcraft and enjoy a smoother healing experience with HealersMate.

---

**Reminder:** This addon is designed for use in Vanilla World of Warcraft version 1.12 and is NOT compatible with Classic(1.13+) versions of WoW.
