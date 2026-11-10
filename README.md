# Minimap Labels

A World of Warcraft addon for WoW Forever that puts names beside the minimap's dots: herbs and ore
(coloured by the skill they give), quest areas and objectives, quest givers, NPCs and party members.
It can also alert you, with a sound, a message and a controller pulse, when a node worth gathering
appears.

Extracted from the Minimap module of [Improved Forever](https://github.com/markgravity/ImprovedForever)
(MIT) so that it runs on its own.

## Use

- **Settings:** Options > AddOns > Minimap Labels.
- **Show / hide the labels:** `/mlabels`. Click **Make macro** in the settings to create a
  "Minimap Labels" macro, put it on an action bar and bind that slot to a key if you like.
- `/mlabels debug` prints one scan of the minimap; `/mlabels step <n>` sets the scan's spacing.

## QuestieDB (optional)

With [QuestieDB](https://github.com/Questie/QuestieDB) installed, quest givers get the quest's
title beside them and objectives get their item's icon. Without it, those dots are labelled by name.
QuestieDB's NPC name index (a few MB) is only built while the Quests or Objectives labels are on.

## Resource use

Nothing runs while the labels and alerts are both off. While on, a scan reads the minimap in
slices of at most 1 ms a frame.
