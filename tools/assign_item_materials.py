#!/usr/bin/env python3
"""Give every authored non-consumable item a material and a quality.

Items.json carried two incompatible models. Procedurally generated items derive
their stats from `base x material x quality`, keep the provenance in a
`generated` block, and wear out in use. The 486 authored non-consumables had
fixed stats, no material or quality at all, and — because weapon degradation
reads `generated.fragility`, which defaults to 0.0 — never degraded, while 358
of them carried durability fields nothing ever decremented.

This DESCRIBES rather than re-derives: every item keeps the stats it was
hand-tuned with. The material and quality are chosen to match what the item
already is, so nothing changes in play today and everything that keys off the
vocabulary works tomorrow.

Run:
    python3 tools/assign_item_materials.py            # dry run
    python3 tools/assign_item_materials.py --write
"""

import argparse
import json
import pathlib
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
ITEMS = ROOT / "resources" / "data" / "items.json"
TABLES = ROOT / "resources" / "data" / "equipment_tables.json"

# Slots that hold no equipment — consumables and quest oddments.
CONSUMABLE_SLOTS = {"inventory", ""}

# Enchantment is the term the value model was missing: material and quality
# describe what an item IS, enchantment what has been done to it. Tiers are
# assigned by where an item's actual value sits against base x material x
# quality — descriptive, like everything else here, so nothing is re-priced.
ENCHANTMENT_BANDS = [
    (2.0,  "none"),
    (6.0,  "touched"),
    (18.0, "blessed"),
    (45.0, "empowered"),
    (1e9,  "perfected"),
]

# Declared by hand before this tool existed. Their author chose deliberately,
# so they are never recomputed — everything else is, on every run, which keeps
# the tool idempotent and lets the inference improve.
AUTHORED_MATERIALS = {
    "bone_club", "bone_dagger", "bone_spear", "bone_sword", "bronze_axe",
    "bronze_dagger", "bronze_mace", "bronze_spear", "composite_bow",
    "hunting_bow", "longbow", "oak_staff", "obsidian_blade", "obsidian_dagger",
    "obsidian_spear", "short_bow", "wooden_staff",
}

# Trade tools name their own material in the noun.
TOOL_MATERIAL = {
    "lute": "wood", "thieving_tools": "steel", "alchemists_kit": "copper",
    "merchants_scales": "bronze", "quartermasters_ledger": "cloth",
    "war_standard": "cloth", "throwing_knife": "iron",
}

# Those same tools encode their grade in their id, using a ladder that does not
# match quality_levels: plain / fine / masterwork / storied / legendary against
# poor / common / good / fine / masterwork. Two overlapping vocabularies for one
# concept. Read the id where it names a real quality and fall back to rarity
# otherwise; reconciling the two ladders is a design decision, recorded in TODO.
# The trade tools encoded grade in their ids on a parallel ladder — plain /
# fine / masterwork / storied / legendary. There is one quality vocabulary now,
# the one in quality_levels, and the two grades above masterwork are not quality
# at all: a storied lute is a masterwork lute with a story on it, which is
# enchantment. They map to masterwork here and earn their extra value through
# the enchantment tier instead.
ID_QUALITY = {"plain": "common", "fine": "fine", "masterwork": "masterwork",
              "storied": "masterwork", "legendary": "masterwork"}

# When the name says nothing, the base type usually does.
TYPE_MATERIAL = {
    "staff": "wood", "bow": "wood", "club": "wood",
    "robe": "cloth", "hat": "cloth",
    "armor": "leather", "helmet": "leather", "gloves": "leather",
    "boots": "leather", "pants": "leather", "shield": "wood",
}
TYPE_MATERIAL_DEFAULTS = {"focus": "bronze", "charm": "bronze"}
SLOT_MATERIAL = {
    "head": "leather", "chest": "leather", "legs": "leather", "feet": "leather",
    "hand_l": "leather", "hand_r": "leather", "back": "cloth",
    "talisman": "bone", "ring1": "silver", "ring2": "silver",
    "trinket1": "bone", "trinket2": "bone",
}
# Rarity implies quality. Deterministic — the modal quality for that band, not a
# roll, because an item's quality should not change between runs of this script.
RARITY_QUALITY = {
    "common": "common", "uncommon": "good", "rare": "fine",
    "epic": "masterwork", "legendary": "masterwork",
}


def infer_material(item_id, item, materials):
    blob = " ".join([item_id, item.get("name", ""), item.get("description", "")]).lower()
    # Longest name first, so "sky_iron" is not read as "iron".
    for name in sorted(materials, key=len, reverse=True):
        if name.replace("_", " ") in blob.replace("_", " "):
            return name, "named"
    for noun, material in TOOL_MATERIAL.items():
        if noun in item_id:
            return material, "tool noun"
    by_type = TYPE_MATERIAL.get(item.get("type", "")) \
        or TYPE_MATERIAL_DEFAULTS.get(item.get("type", ""))
    if by_type:
        return by_type, "type"
    by_slot = SLOT_MATERIAL.get(item.get("slot", ""))
    if by_slot:
        return by_slot, "slot"
    return "iron", "default"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    # A material named in an item's name is not always what it is made OF.
    # "Gold Dorje" is gilt bronze, not bullion — a ritual implement plated in
    # gold, priced accordingly. Where the named material implies a value far
    # above what the item actually costs, the name is decoration and the
    # structure has to be inferred from the type instead. The item's own price
    # is the better witness.
    DECORATIVE_THRESHOLD = 2.0

    data = json.loads(ITEMS.read_text(encoding="utf-8"))
    tables = json.loads(TABLES.read_text(encoding="utf-8"))
    materials = tables["materials"]
    bases = {}
    for table in ("weapon_bases", "armor_bases", "accessory_bases"):
        bases.update(tables.get(table, {}))
    qualities = tables["quality_levels"]

    how = Counter()
    how_set = {}
    chosen = Counter()
    enchant = Counter()
    touched = 0
    for item_id, item in data["items"].items():
        if item_id.startswith("_") or not isinstance(item, dict):
            continue
        if item.get("slot", "") in CONSUMABLE_SLOTS:
            continue
        item.pop("enchantment", None)
        item.pop("gilding", None)
        if item_id in AUTHORED_MATERIALS:
            how["authored by hand"] += 1
        else:
            item.pop("material", None)
            material, source = infer_material(item_id, item, materials)
            item["material"] = material
            how_set[item_id] = source
            how["material from " + source] += 1
        item.pop("quality", None)
        if True:
            grade = next((ID_QUALITY[w] for w in item_id.split("_") if w in ID_QUALITY), None)
            item["quality"] = grade or RARITY_QUALITY.get(item.get("rarity", "common"), "common")
        # If the named material would price the item far above what it costs,
        # the metal is plating: re-infer from the type or slot.
        base = bases.get(item.get("type", ""), {})
        if how_set.get(item_id) == "named" and base:
            named_value = (base.get("value", 50)
                           * materials.get(item["material"], {}).get("value_mult", 1.0)
                           * qualities.get(item["quality"], {}).get("value_mult", 1.0))
            actual = item.get("value", 0)
            if actual > 0 and named_value / actual >= DECORATIVE_THRESHOLD:
                fallback = (TYPE_MATERIAL.get(item.get("type", ""))
                            or SLOT_MATERIAL.get(item.get("slot", "")) or "bronze")
                item["gilding"] = item["material"]
                item["material"] = fallback
                how["material re-read as gilding"] += 1
                how["material from named"] -= 1
                chosen[fallback] = chosen.get(fallback, 0)

        # Enchantment, from where the authored value actually sits.
        mat = materials.get(item["material"], {})
        qual = qualities.get(item["quality"], {})
        expected = (base.get("value", 50) * mat.get("value_mult", 1.0)
                    * qual.get("value_mult", 1.0))
        ratio = (item.get("value", 0) / expected) if expected else 1.0
        item["enchantment"] = next(name for limit, name in ENCHANTMENT_BANDS if ratio < limit)
        enchant[item["enchantment"]] += 1

        chosen[item["material"]] += 1
        touched += 1

    print(f"non-consumable items: {touched}")
    for source, n in how.most_common():
        print(f"  {source:32s} {n}")
    print("\nmaterials assigned:", dict(chosen.most_common()))
    print("enchantment tiers:", dict(enchant.most_common()))

    unknown = {m for m in chosen if m not in materials}
    if unknown:
        print("\nERROR: assigned materials that do not exist:", unknown, file=sys.stderr)
        return 1

    if not args.write:
        print("\ndry run — pass --write to apply")
        return 0
    ITEMS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nwrote {ITEMS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
