# Alfred the butler
#### V1.5.0
## DISCLAIMER
Alfred is a plugin that CAN read and write files. In this repo, I have specifically only write to data/export folder and only read from data/import folder. It will ONLY read and write files if you press the import/export function on the menu. This is an open-source repo and you are free to check the code on what files alfred will read/write.

Alfred also does near-instant sell and near-instant salvage, it will likely sell/salvage before you even see the inventory page open. It will still obey your filter settings (both GA count and affix/unique/mythic filters)

## Description
Alfred is your personal butler in Cerrigar. He is capable of stashing, salvaging and selling items based on your settings. He is also capable of restock boss summon materials as well as infernal horde compasses. Additionally, he will also display status of your inventory on top left of your screen and you can see how many items alfred will stash/keep, salvage or sell as well as count/max boss summon materials and infernal horde compasses that you instruct alfred to restock.

there are 4 trigger conditions that can get alfred to do tasks:
- called by an external plugin
- inventory is full and you went back to cerrigar
- a manual trigger via keybind
- restock mode is set to active and you have less than the hardcoded minimum (for boss item, it is set to the minimum required to summon boss, for compass it is 1)

## Configurations
### general
- Enable checkbox -- to enable alfred plugin
- Keybinds
  - toggle keybind -- for quick enable/disable
  - dump tracker info -- debug usage
  - manual trigger -- make alfred do task now (will teleport to cerrigar if not there)
### Display settings
- Draw Status -- to enable the status on top left of screen
- Draw Keep Items -- draw blue box around items that is set to keep in inventory
- Draw Sell Items -- draw pink box around items that is set to sell in inventory
- Draw Salvage Items -- draw orange box around items that is set to salvage in inventory
- Various box sizing and offset settings to adjust depending on screen size similar to affix filter

### General settings
- use evade -- whether to use evade or not in town (default false)
- explorer path angle (lower is better)
- max inventory items -- No. of items to count as inventory full. usefull for bossing when you dont pick all items up
- failed action -- In event that alfred is unable to complete all task, alfred can stand there and dump tracker info to log, or alfred can just force retry and may be stuck in a loop (but atleast inactivity timer wont kick in)
- skip stashing cache -- dont stash caches

### Non-ancestral
select what to do with non-ancestral items by types and marked as junk

### Ancestral
- Drop down to select what to do with items that do not meet the threshold by types and marked as junk
- Greater affix threshold to keep for mythic, uniques and legendaries. Setting all of them to 1 will tell alfred to keep/stash all items with 1 greater affix or more (basically keep/stash everything)
- Keep max aspect checkbox -- if checked, will ignore the GA threshold and keep the item if the aspect roll is max
- use unique/mythic filter -- enable more specific filters by selecting which unique/mythic u want to keep
- use affix filter -- enable more specific filters via affix for legendaries
- Additional slider for matching affix threshold
- Both GA threshold and min affix threshold must be met
- export/import functionality -- you can use this to export/import affix filter and unique/mythic configuration. There is a preset for spiritborn for most common spiritborn build items
#### Unique/Mythic
- search and add uniques/mythics that you want to keep
#### Helm/Chest/Gloves/Pants/Boots/Amulet/Ring/Weapon/Offhand
- search and add affixes that you want to keep
- you can search by name, description or id
### Socketables
- stash socketables
  - never -- never stash socketables
  - when full -- only stash socketables when socketables inventory is full
  - always -- always stash socketables whenever alfred is triggered
### Consumables
- stash consumeables
  - never -- never stash boss materials
  - when full -- only stash boss materials when boss materials inventory is full
  - always -- always stash boss materials whenever alfred is triggered
- sliders for maximum amount of item to restock up to
    - set to 0 if u do not want to restock that item
### Dungeon Keys
- stash dungeon keys
  - never -- never stash compasses and tributes
  - when full -- only stash compasses and tributes when compasses and tributes inventory is full
  - always -- always stash compasses and tributes whenever alfred is triggered
- sliders for maximum amount of item to restock up to
    - set to 0 if u do not want to restock that item

## For devs
Alfred exposes an external collection of functions via global variable `PLUGIN_alfred_the_butler`.
Also in the task folder, there is an `external-template.lua` as a sample on how to call alfred from other plugins.

## Known issues
- some aspects are giving false positive, mainly those that have multiple data (e.g. frost stride). for now, alfred is treating them as real max aspect to not accidentally sell/salvage a max one

## Credits
- Letrico - general help, bouncing ideas, my faq XD
- Zewx - explorerlite is written by Zewx in the piteer plugin and is being used in alfred
- Lanvi - pre-release general testing and feedback
- Pinguu - drawing boxes based on filters
