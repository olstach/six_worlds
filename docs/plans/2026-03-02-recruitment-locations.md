# Recruitment Locations Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 5 new map location types (Teahouse, Mercenary Guild, Veterans' Camp, Yogini Circle, Town) each with a companion recruitment tab and distinct services.

**Architecture:** All locations extend the existing shop system — data in shops.json, events in hell_events.json, spawns in hell.json. The only new UI element is a Rest tab added to shop_ui.tscn/shop_ui.gd. The Veterans' Camp skill randomisation happens in map_generator.gd at placement time; claimed state is persisted in MapManager's object data via a new `update_object_data()` method. Location-specific runtime data flows from the triggered map object through overworld.gd into shop_ui via a new optional `location_data` parameter.

**Tech Stack:** Godot 4.3, GDScript, JSON data files.

---

### Task 1: Add Rest tab node to shop_ui.tscn

**Files:**
- Modify: `scenes/ui/shop_ui.tscn`

The tab container currently has: Items, Spells, Training, Companions. Add a Rest tab after Training and before Companions, following the exact same node structure.

**Step 1: Open shop_ui.tscn and locate the Companions tab block**

It starts at line ~154:
```
[node name="Companions" type="Control" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer"]
```

**Step 2: Insert the Rest tab block immediately before Companions**

Add these nodes (insert before the Companions block):
```
[node name="Rest" type="Control" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer"]
layout_mode = 2

[node name="ScrollContainer" type="ScrollContainer" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer/Rest"]
layout_mode = 2
size_flags_vertical = 3

[node name="RestContainer" type="VBoxContainer" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer/Rest/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 10
```

**Step 3: Commit**
```bash
git add scenes/ui/shop_ui.tscn
git commit -m "feat: add Rest tab node to shop_ui.tscn"
```

---

### Task 2: Wire Rest tab in shop_ui.gd

**Files:**
- Modify: `scripts/ui/shop_ui.gd`

**Step 1: Add @onready for rest_container after the companions_container line (~line 18)**
```gdscript
@onready var rest_container: VBoxContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Rest/ScrollContainer/RestContainer
```

**Step 2: Add `_location_data` variable after `selected_barter_items`**
```gdscript
var _location_data: Dictionary = {}
```

**Step 3: Update `open_shop_by_id()` to accept and store location_data**

Replace:
```gdscript
func open_shop_by_id(shop_id: String) -> bool:
	var shop_data = ShopSystem.get_shop(shop_id)
	if shop_data.is_empty():
		return false
	open_shop(shop_data)
	return true
```
With:
```gdscript
func open_shop_by_id(shop_id: String, location_data: Dictionary = {}) -> bool:
	var shop_data = ShopSystem.get_shop(shop_id)
	if shop_data.is_empty():
		return false
	_location_data = location_data
	open_shop(shop_data)
	return true
```

**Step 4: Add `_populate_rest_tab()` call inside `open_shop()` alongside the other populate calls**

After `_populate_companions_tab()`, add:
```gdscript
_populate_rest_tab()
```

**Step 5: Add the rest tab populate and helper methods** (add after `_populate_companions_tab`)

```gdscript
# ============================================
# REST TAB
# ============================================

func _populate_rest_tab() -> void:
	for child in rest_container.get_children():
		child.queue_free()

	var rest_data: Dictionary = current_shop.get("rest", {})
	if rest_data.is_empty():
		return

	var price_mod: float = current_shop.get("price_modifier", 1.0)
	var teapot_cost: int = int(rest_data.get("teapot_cost", 30) * price_mod)
	var night_cost: int = int(rest_data.get("night_cost", 80) * price_mod)
	var teapot_pct: int = rest_data.get("teapot_restore_pct", 50)
	var night_pct: int = rest_data.get("night_restore_pct", 100)

	# Party status summary
	for character in CharacterSystem.get_party():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var name_lbl := Label.new()
		name_lbl.text = character.get("name", "?")
		name_lbl.custom_minimum_size.x = 90
		row.add_child(name_lbl)

		var derived: Dictionary = character.get("derived", {})
		var max_hp: int = derived.get("max_hp", 0)
		var max_mp: int = derived.get("max_mana", 0)
		var max_st: int = derived.get("max_stamina", 0)
		var cur_hp: int = derived.get("current_hp", max_hp)
		var cur_mp: int = derived.get("current_mana", max_mp)
		var cur_st: int = derived.get("current_stamina", max_st)

		var status_lbl := Label.new()
		status_lbl.text = "HP %d/%d   MP %d/%d   ST %d/%d" % [cur_hp, max_hp, cur_mp, max_mp, cur_st, max_st]
		status_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(status_lbl)
		rest_container.add_child(row)

	rest_container.add_child(HSeparator.new())

	# Gossip placeholder — will be populated from shop data in a future pass
	# var gossip_lbl = Label.new(); gossip_lbl.text = current_shop.get("gossip", "")

	_add_rest_option("Order a teapot", teapot_pct, teapot_cost)
	_add_rest_option("Stay for the night", night_pct, night_cost)


func _add_rest_option(label: String, restore_pct: int, cost: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	rest_container.add_child(row)

	var lbl := Label.new()
	lbl.text = "%s  (%d%% restore)" % [label, restore_pct]
	lbl.custom_minimum_size.x = 220
	row.add_child(lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d gold" % cost
	var can_afford := GameState.can_afford(cost)
	cost_lbl.add_theme_color_override("font_color", AFFORDABLE_COLOR if can_afford else UNAFFORDABLE_COLOR)
	cost_lbl.custom_minimum_size.x = 70
	row.add_child(cost_lbl)

	var btn := Button.new()
	btn.text = "Rest"
	btn.disabled = not can_afford
	btn.pressed.connect(func(): _on_rest_pressed(restore_pct, cost))
	row.add_child(btn)


func _on_rest_pressed(restore_pct: int, cost: int) -> void:
	if not GameState.can_afford(cost):
		return
	GameState.spend_gold(cost)

	for character in CharacterSystem.get_party():
		var derived: Dictionary = character.get("derived", {})
		var max_hp: int = derived.get("max_hp", 0)
		var max_mp: int = derived.get("max_mana", 0)
		var max_st: int = derived.get("max_stamina", 0)
		var cur_hp: int = derived.get("current_hp", max_hp)
		var cur_mp: int = derived.get("current_mana", max_mp)
		var cur_st: int = derived.get("current_stamina", max_st)

		character.derived["current_hp"] = mini(cur_hp + int(float(max_hp - cur_hp) * restore_pct / 100.0), max_hp)
		character.derived["current_mana"] = mini(cur_mp + int(float(max_mp - cur_mp) * restore_pct / 100.0), max_mp)
		character.derived["current_stamina"] = mini(cur_st + int(float(max_st - cur_st) * restore_pct / 100.0), max_st)

	_update_gold_display()
	_populate_rest_tab()
```

**Step 6: Commit**
```bash
git add scripts/ui/shop_ui.gd
git commit -m "feat: rest tab UI and logic in shop_ui"
```

---

### Task 3: Thread location_data from overworld into the shop

**Files:**
- Modify: `scripts/overworld/overworld.gd` (~line 341)

When a shop event fires, `_current_event_object` holds the full map object dict including its `data` (which may contain `selected_skills`, `claimed`, etc. for veteran's camp). We need to pass this into the shop UI.

**Step 1: Update `_on_event_shop_requested` to pass location context**

Locate:
```gdscript
	if not _shop_instance.open_shop_by_id(shop_id):
```
Replace with:
```gdscript
	var loc_data: Dictionary = _current_event_object.get("data", {}).duplicate()
	loc_data["_object_id"] = _current_event_object.get("id", "")
	if not _shop_instance.open_shop_by_id(shop_id, loc_data):
```

**Step 2: Commit**
```bash
git add scripts/overworld/overworld.gd
git commit -m "feat: pass map object data into shop as location_data"
```

---

### Task 4: Veterans' Camp — claimed training slots

**Files:**
- Modify: `scripts/autoload/map_manager.gd`
- Modify: `scripts/ui/shop_ui.gd`

#### 4a — MapManager.update_object_data()

**Step 1: Add the method to map_manager.gd** (after `get_visible_objects()`, ~line 893)

```gdscript
## Update a field in a specific map object's data dict.
## Used by shop_ui to persist veteran's camp claimed training slots.
func update_object_data(obj_id: String, key: String, value) -> void:
	for pos in objects:
		if objects[pos].get("id", "") == obj_id:
			objects[pos]["data"][key] = value
			return
	push_warning("MapManager.update_object_data: object not found: " + obj_id)
```

#### 4b — shop_ui.gd: veteran mode in training tab

**Step 2: Update `_populate_training_tab()` to detect veteran camp mode**

At the top of `_populate_training_tab()`, after clearing children, add:
```gdscript
	# Veteran's Camp mode: skills are chosen at map-gen time, each slot one-use
	var selected_skills: Array = _location_data.get("selected_skills", [])
	if not selected_skills.is_empty():
		_populate_veteran_training(selected_skills, _location_data.get("claimed", []))
		return
```

**Step 3: Add `_populate_veteran_training()` after `_create_skill_training_option()`**

```gdscript
func _populate_veteran_training(selected_skills: Array, claimed: Array) -> void:
	var header := Label.new()
	header.text = "Combat Training  (one character per slot)"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", GOLD_COLOR)
	training_container.add_child(header)
	training_container.add_child(HSeparator.new())

	for i in range(selected_skills.size()):
		var skill: String = selected_skills[i]
		var is_claimed: bool = i < claimed.size() and claimed[i]

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var lbl := Label.new()
		lbl.text = skill.replace("_", " ").capitalize()
		lbl.custom_minimum_size.x = 110
		hbox.add_child(lbl)

		if is_claimed:
			var taken := Label.new()
			taken.text = "[ Taken ]"
			taken.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			hbox.add_child(taken)
		else:
			for character in CharacterSystem.get_party():
				var current_level: int = character.get("skills", {}).get(skill, 0)
				var price: int = ShopSystem.get_skill_training_cost(current_level)
				var can_afford := GameState.can_afford(price) and price > 0

				var btn := Button.new()
				btn.text = "%s (Lv.%d) — %dg" % [character.get("name", "?"), current_level, price]
				btn.add_theme_font_size_override("font_size", 11)
				btn.disabled = not can_afford
				btn.pressed.connect(func(): _on_veteran_train_pressed(i, character, skill))
				hbox.add_child(btn)

		training_container.add_child(hbox)


func _on_veteran_train_pressed(slot_index: int, character: Dictionary, skill: String) -> void:
	var current_level: int = character.get("skills", {}).get(skill, 0)
	var price: int = ShopSystem.get_skill_training_cost(current_level)
	if not GameState.can_afford(price):
		return

	ShopSystem.purchase_skill_training(character, skill)

	# Persist claimed state in the map object
	var obj_id: String = _location_data.get("_object_id", "")
	if obj_id != "":
		var new_claimed: Array = _location_data.get("claimed", [false, false]).duplicate()
		new_claimed[slot_index] = true
		_location_data["claimed"] = new_claimed
		MapManager.update_object_data(obj_id, "claimed", new_claimed)

	_populate_training_tab()
```

**Step 4: Commit**
```bash
git add scripts/ui/shop_ui.gd scripts/autoload/map_manager.gd
git commit -m "feat: veterans camp claimed training slots"
```

---

### Task 5: Map generator — Veterans' Camp skill injection

**Files:**
- Modify: `scripts/map_gen/map_generator.gd` (~line 643 `_place_event_object`)

When a pool template has a `training_pool` field, the generator picks 2 random skills and adds them to the object's data dict.

**Step 1: Add skill injection at the end of `_place_event_object()`, before `_occupied[pos] = true`**

The current `data` dict is built inline. Locate the `_objects.append({...})` call and find the `"data"` dict inside it. After the existing `"data": { ... }` is built, add the following lines immediately before `_occupied[pos] = true`:

```gdscript
	# Veteran's Camp: inject random skills from training_pool
	if "training_pool" in template:
		var pool: Array = template["training_pool"].duplicate()
		pool.shuffle()
		_objects[-1]["data"]["selected_skills"] = [pool[0], pool[1]]
		_objects[-1]["data"]["claimed"] = [false, false]
```

**Step 2: Commit**
```bash
git add scripts/map_gen/map_generator.gd
git commit -m "feat: inject random training skills into veterans camp map objects"
```

---

### Task 6: shops.json — new types and hell variant entries

**Files:**
- Modify: `resources/data/shops.json`

#### 6a — New shop_types

Add to the `"shop_types"` object:
```json
"teahouse": {
    "description": "Rest and recruit companions",
    "tabs": ["rest", "companions"]
},
"mercenary_guild": {
    "description": "Weapons, armour, and fighters for hire",
    "tabs": ["items", "companions"]
},
"veteran_camp": {
    "description": "Combat skill training and veterans for hire",
    "tabs": ["training", "companions"]
},
"yogini_circle": {
    "description": "Spells, magic supplies, and spiritual companions",
    "tabs": ["spells", "items", "companions"]
},
"town": {
    "description": "General goods and companions",
    "tabs": ["items", "companions"]
}
```

#### 6b — Hell variant shop entries

Add to the `"shops"` object (alongside existing entries):

```json
"hell_teahouse_cold": {
    "name": "Teahouse",
    "type": "teahouse",
    "description": "A dim waystation where the desperate catch their breath. The barkeeper keeps a pot of Lapsang Souchong going — its smoke is the closest thing to warmth in the frozen wastes.",
    "price_modifier": 1.2,
    "buys_items": false,
    "items": {},
    "spells": [],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"],
    "rest": {
        "teapot_cost": 30,
        "teapot_restore_pct": 50,
        "night_cost": 80,
        "night_restore_pct": 100
    }
},
"hell_teahouse_fire": {
    "name": "Teahouse",
    "type": "teahouse",
    "description": "The tea here is brewed in volcanic water. It tastes like char and smoke and something almost familiar. The barkeeper doesn't ask where you've been.",
    "price_modifier": 1.2,
    "buys_items": false,
    "items": {},
    "spells": [],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"],
    "rest": {
        "teapot_cost": 30,
        "teapot_restore_pct": 50,
        "night_cost": 80,
        "night_restore_pct": 100
    }
},
"hell_mercenary_guild": {
    "name": "Mercenary Guild",
    "type": "mercenary_guild",
    "description": "A fortified post where demonic soldiers hire out between assignments. Their equipment is functional, their prices are fair, their loyalty is negotiable.",
    "price_modifier": 1.1,
    "buys_items": true,
    "accepted_item_types": ["weapon", "armor", "shield"],
    "items": {
        "iron_sword": 2,
        "steel_longsword": 1,
        "iron_axe": 2,
        "iron_mace": 1,
        "iron_dagger": 2,
        "wooden_spear": 2,
        "hunting_bow": 1,
        "chainmail": 1,
        "leather_vest": 2,
        "iron_shield": 1,
        "leather_boots": 2,
        "leather_gloves": 2
    },
    "spells": [],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"]
},
"hell_veterans_camp": {
    "name": "Veterans' Camp",
    "type": "veteran_camp",
    "description": "A camp of soldiers who survived long enough to have something to teach. They charge for lessons — nothing is free in hell.",
    "price_modifier": 1.0,
    "buys_items": false,
    "items": {},
    "spells": [],
    "training": {
        "attributes": [],
        "skills": ["swords", "martial_arts", "ranged", "daggers", "axes", "unarmed", "spears", "maces", "armor"]
    },
    "available_companions": ["karnak"]
},
"hell_yogini_circle": {
    "name": "Yogini Circle",
    "type": "yogini_circle",
    "description": "A circle of Dakinis — fierce, half-wild tantric practitioners. They trade knowledge for gold and ask no questions about what you plan to do with it.",
    "price_modifier": 1.15,
    "buys_items": false,
    "items": {
        "raw_reagents": 8,
        "alchemists_pouch": 3,
        "prayer_beads": 2,
        "oak_staff": 1,
        "cloth_robe": 1,
        "cloth_hood": 1
    },
    "spells": [
        "lesser_heal", "greater_heal", "bless", "regeneration",
        "magic_missile", "blink",
        "voidbolt", "gloom", "curse"
    ],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"]
},
"hell_town_weapons": {
    "name": "Town",
    "type": "town",
    "description": "A cluster of hovels that qualifies as a settlement. The main trade here is war.",
    "price_modifier": 1.1,
    "buys_items": true,
    "items": {
        "iron_sword": 2, "steel_longsword": 1, "iron_axe": 2,
        "iron_mace": 2, "iron_dagger": 3, "wooden_spear": 2,
        "hunting_bow": 1, "chainmail": 1, "leather_vest": 2,
        "iron_shield": 2, "leather_boots": 2, "leather_gloves": 2,
        "rations": 5, "herb_bundle": 3, "scrap_metal": 5
    },
    "spells": [],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"]
},
"hell_town_magic": {
    "name": "Town",
    "type": "town",
    "description": "A settlement that has drawn more than its share of sorcerers and wandering scholars. The apothecary is always busy.",
    "price_modifier": 1.15,
    "buys_items": true,
    "items": {
        "raw_reagents": 8, "alchemists_pouch": 3, "prayer_beads": 2,
        "oak_staff": 1, "cloth_robe": 2, "cloth_hood": 2,
        "iron_dagger": 2, "rations": 5, "herb_bundle": 5
    },
    "spells": [
        "firebolt", "lesser_heal", "magic_missile", "gloom", "curse", "blink"
    ],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"]
},
"hell_town_supplies": {
    "name": "Town",
    "type": "town",
    "description": "A trading post that survives by stocking what travellers actually need. No questions, reasonable prices.",
    "price_modifier": 1.05,
    "buys_items": true,
    "items": {
        "rations": 12, "travel_provisions": 5, "herb_bundle": 8,
        "raw_reagents": 5, "alchemists_pouch": 2,
        "iron_dagger": 2, "leather_vest": 2, "leather_boots": 3,
        "leather_gloves": 3, "health_potion": 3, "mana_potion": 2,
        "scrap_metal": 8, "salvage_kit": 3
    },
    "spells": [],
    "training": { "attributes": [], "skills": [] },
    "available_companions": ["karnak"]
}
```

**Step: Commit**
```bash
git add resources/data/shops.json
git commit -m "feat: add new shop types and hell variant entries to shops.json"
```

---

### Task 7: hell_events.json — new location events

**Files:**
- Modify: `resources/data/events/hell_events.json`

Add inside the `"events"` object:

```json
"hell_teahouse_cold": {
    "id": "hell_teahouse_cold",
    "title": "Teahouse",
    "realm": "hell",
    "text": "A low building crouches at the edge of the frozen waste, smoke leaking from the roof. Inside, a few silent figures nurse cups of something warm. The barkeeper glances up without expression.",
    "choices": [
        {
            "text": "Sit down",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_teahouse_cold",
                "text": "You take a seat. Nobody bothers you."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You keep walking. The smell of smoke follows you longer than it should."
            }
        }
    ]
},
"hell_teahouse_fire": {
    "id": "hell_teahouse_fire",
    "title": "Teahouse",
    "realm": "hell",
    "text": "A squat building half-buried in ash. The sign is burned off but the smell of tea — strong, smoky, almost pleasant — cuts through the sulphur. The door is open.",
    "choices": [
        {
            "text": "Step inside",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_teahouse_fire",
                "text": "The heat inside is almost comfortable compared to outside."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You leave the warmth behind."
            }
        }
    ]
},
"hell_mercenary_guild": {
    "id": "hell_mercenary_guild",
    "title": "Mercenary Guild",
    "realm": "hell",
    "text": "A fortified outpost flying a plain black banner. A board outside lists rates for services rendered. Inside, armoured figures sharpen weapons or sleep. They look up when you enter.",
    "choices": [
        {
            "text": "Browse their wares",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_mercenary_guild",
                "text": "The quartermaster unlocks a case and waits."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You leave the mercenaries to their sharpening."
            }
        }
    ]
},
"hell_veterans_camp": {
    "id": "hell_veterans_camp",
    "title": "Veterans' Camp",
    "realm": "hell",
    "text": "A sparse camp around a fire. The people here are old — old for hell, which means they have survived something most haven't. One of them watches you approach with calculating eyes.",
    "choices": [
        {
            "text": "Ask about training",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_veterans_camp",
                "text": "\"We can teach two things. Once each. Make your choices.\""
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "The veteran returns to staring into the fire."
            }
        }
    ]
},
"hell_yogini_circle": {
    "id": "hell_yogini_circle",
    "title": "Yogini Circle",
    "realm": "hell",
    "text": "A ring of figures seated in the dirt, chanting in a language that makes your teeth itch. One of them opens her eyes and looks directly at you before you've made a sound.",
    "choices": [
        {
            "text": "Approach the circle",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_yogini_circle",
                "text": "She gestures for you to sit. The chanting doesn't stop."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You back away slowly. The chanting follows you for a while."
            }
        }
    ]
},
"hell_town_weapons": {
    "id": "hell_town_weapons",
    "title": "Town",
    "realm": "hell",
    "text": "A settlement built from salvaged iron and spite. The biggest building is the armoury. Someone is always selling something in the street, and half of it is sharp.",
    "choices": [
        {
            "text": "Enter the town",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_town_weapons",
                "text": "You push through the crowd."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You skirt the settlement and keep moving."
            }
        }
    ]
},
"hell_town_magic": {
    "id": "hell_town_magic",
    "title": "Town",
    "realm": "hell",
    "text": "A settlement where more windows glow than can be explained by candlelight. Strange smells drift from the apothecary. A scholar argues with a demon outside the library.",
    "choices": [
        {
            "text": "Enter the town",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_town_magic",
                "text": "You find the market square."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You leave the scholars to their arguments."
            }
        }
    ]
},
"hell_town_supplies": {
    "id": "hell_town_supplies",
    "title": "Town",
    "realm": "hell",
    "text": "A trading post that survives on practicality. The sign reads: FOOD. TOOLS. NO CREDIT. It is the most honest thing you have seen in hell.",
    "choices": [
        {
            "text": "Enter the town",
            "type": "default",
            "outcome": {
                "type": "shop",
                "shop_id": "hell_town_supplies",
                "text": "The shopkeeper nods without looking up."
            }
        },
        {
            "text": "Move on",
            "type": "default",
            "outcome": {
                "type": "text",
                "text": "You keep walking."
            }
        }
    ]
}
```

**Step: Commit**
```bash
git add resources/data/events/hell_events.json
git commit -m "feat: add events for teahouse, guild, camp, circle, and town"
```

---

### Task 8: hell.json — add new object pool entries

**Files:**
- Modify: `resources/data/map_configs/hell.json`

Add to both `cold_hell` and `fire_hell` event arrays inside `"object_pools"`.

**cold_hell additions:**
```json
{"event_id": "hell_teahouse_cold", "name": "Teahouse", "icon": "rest", "blocking": false, "one_time": false, "weight": 2, "tag": "rest"},
{"event_id": "hell_mercenary_guild", "name": "Mercenary Guild", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"},
{"event_id": "hell_veterans_camp", "name": "Veterans' Camp", "icon": "npc", "blocking": false, "one_time": false, "weight": 2, "training_pool": ["swords", "martial_arts", "ranged", "daggers", "axes", "unarmed", "spears", "maces", "armor"]},
{"event_id": "hell_yogini_circle", "name": "Yogini Circle", "icon": "shrine", "blocking": false, "one_time": false, "weight": 1},
{"event_id": "hell_town_weapons", "name": "Town", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"},
{"event_id": "hell_town_magic", "name": "Town", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"},
{"event_id": "hell_town_supplies", "name": "Town", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"}
```

**fire_hell additions** (same except teahouse uses fire variant):
```json
{"event_id": "hell_teahouse_fire", "name": "Teahouse", "icon": "rest", "blocking": false, "one_time": false, "weight": 2, "tag": "rest"},
{"event_id": "hell_mercenary_guild", "name": "Mercenary Guild", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"},
{"event_id": "hell_veterans_camp", "name": "Veterans' Camp", "icon": "npc", "blocking": false, "one_time": false, "weight": 2, "training_pool": ["swords", "martial_arts", "ranged", "daggers", "axes", "unarmed", "spears", "maces", "armor"]},
{"event_id": "hell_yogini_circle", "name": "Yogini Circle", "icon": "shrine", "blocking": false, "one_time": false, "weight": 1},
{"event_id": "hell_town_weapons", "name": "Town", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"},
{"event_id": "hell_town_magic", "name": "Town", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"},
{"event_id": "hell_town_supplies", "name": "Town", "icon": "shop", "blocking": false, "one_time": false, "weight": 1, "tag": "shop"}
```

**Step: Commit**
```bash
git add resources/data/map_configs/hell.json
git commit -m "feat: add new location types to hell map object pools"
```

---

### Task 9: Manual verification

Launch the game and verify each location. Note: the map is procedurally generated at 192×144 so locations spawn across the map — use the debug XP button to add gold for testing rest/training costs.

**Checklist:**
- [ ] Teahouse opens with Rest tab as default; "Order a teapot" costs ~36 gold, heals ~50% missing; "Stay for the night" costs ~96 gold, full heal; gold deducted correctly; stats display updates after rest
- [ ] Mercenary Guild shows Items tab and Companions tab; karnak appears in Companions
- [ ] Veterans' Camp shows exactly 2 named combat skills; recruiting one character marks slot "Taken"; second character can train the other slot; reopening the shop shows persisted claimed state
- [ ] Yogini Circle shows Spells tab, Items tab (reagents/scrolls), Companions tab
- [ ] Town (any variant) shows Items tab with appropriate stock and Companions tab
- [ ] All 5 locations show "Enter the town" / "Sit down" etc. event text before shop opens
- [ ] Companions tab on all locations shows Karnak with Recruit button
