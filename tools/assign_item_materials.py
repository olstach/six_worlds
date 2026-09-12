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
ID_QUALITY = {"plain": "common", "fine": "fine", "masterwork": "masterwork",
              "storied": "masterwork", "legendary": "masterwork"}

# When the name says nothing, the base type usually does.
TYPE_MATERIAL = {
    "staff": "wood", "bow": "wood", "club": "wood",
    "robe": "cloth", "hat": "cloth",
    "armor": "leather", "helmet": "leather", "gloves": "leather",
    "boots": "leather", "pants": "leather", "shield": "wood",
}
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
    by_type = TYPE_MATERIAL.get(item.get("type", ""))
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

    data = json.loads(ITEMS.read_text(encoding="utf-8"))
    materials = json.loads(TABLES.read_text(encoding="utf-8"))["materials"]

    how = Counter()
    chosen = Counter()
    touched = 0
    for item_id, item in data["items"].items():
        if item_id.startswith("_") or not isinstance(item, dict):
            continue
        if item.get("slot", "") in CONSUMABLE_SLOTS:
            continue
        if "material" not in item:
            material, source = infer_material(item_id, item, materials)
            item["material"] = material
            how[source] += 1
        else:
            how["already set"] += 1
        if "quality" not in item:
            grade = next((ID_QUALITY[w] for w in item_id.split("_") if w in ID_QUALITY), None)
            item["quality"] = grade or RARITY_QUALITY.get(item.get("rarity", "common"), "common")
        chosen[item["material"]] += 1
        touched += 1

    print(f"non-consumable items: {touched}")
    for source, n in how.most_common():
        print(f"  material from {source:12s} {n}")
    print("\nmaterials assigned:", dict(chosen.most_common()))

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
