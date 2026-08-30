#!/usr/bin/env python3
"""Export the writable content as Markdown for Olaf to read and edit.

Every editable string sits between HTML-comment anchors that name its exact
JSON path:

    <!--@ hell_events.json | hell_bone_arena | text -->
    A frozen pit ringed with bones …
    <!--@end-->

The anchors do not render, so the documents read as prose. `import_review_docs.py`
reads them back and writes the edits into the JSON, so nothing has to be
re-keyed by hand.

Rules for editing:
  - Change anything between an anchor and its `@end`. Blank lines are fine.
  - Do not edit the anchor lines themselves, or the ids in headings.
  - Anything outside the anchors (headings, mechanical notes, tables) is
    generated and will be regenerated — edits there are lost.

Content added during the 2026-07-27 sessions is marked **NEW**, so a file that
has already had a pass only needs its new parts read.
"""
import json
import os
import re

ROOT = "/home/user/six_worlds"
OUT = os.path.join(ROOT, "docs/review")
BASE_SNAPSHOT = "/tmp/claude-0/-home-user-six-worlds/5d12bda8-475f-5abc-8862-e29e3063f3bc/scratchpad/base"

REALMS = [
    ("hell_events.json", "EVENTS_HELL.md", "Hell"),
    ("hungry_ghost_events.json", "EVENTS_HUNGRY_GHOST.md", "Hungry Ghost"),
    ("animal_events.json", "EVENTS_ANIMAL.md", "Animal"),
    ("domain_events.json", "EVENTS_DOMAIN.md", "Cross-realm (domain, camp, trait, relationship)"),
]

CHOICE_LABEL = {"default": "grey", "requirement": "blue", "roll": "yellow"}


def anchor(path_parts, text):
    """Wrap an editable string in its path anchor."""
    key = " | ".join(str(p) for p in path_parts)
    body = (text or "").rstrip()
    return f"<!--@ {key} -->\n{body}\n<!--@end-->\n"


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def load_base(name):
    p = os.path.join(BASE_SNAPSHOT, name)
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def reward_line(rewards):
    """One-line mechanical summary, so the writer can see what a choice pays."""
    if not rewards:
        return ""
    bits = []
    for k in ("xp", "gold", "items", "supplies", "restore", "hp_loss",
              "learn_spell", "skill_up", "buffs", "flags", "wound",
              "add_trait", "remove_trait", "add_traits", "remove_traits",
              "pressure", "gamble", "attribute_loss", "gold_returned"):
        if k in rewards:
            v = rewards[k]
            if k == "pressure":
                v = ", ".join(f"{p.get('element')}{p.get('amount'):+g}"
                              for p in (v if isinstance(v, list) else [v])
                              if isinstance(p, dict))
            bits.append(f"{k}: {v}")
    return "  ·  ".join(bits)


def req_line(reqs):
    if not reqs:
        return ""
    bits = []
    if "trait" in reqs:
        bits.append(f"**trait: {reqs['trait']}**")
    if "not_trait" in reqs:
        bits.append(f"**not_trait: {reqs['not_trait']}**")
    for s, lv in reqs.get("skills", {}).items():
        bits.append(f"{s} {lv}")
    for a, lv in reqs.get("attributes", {}).items():
        bits.append(f"{a} {lv}")
    if "roll" in reqs:
        r = reqs["roll"]
        bits.append(f"roll {r.get('attribute') or r.get('skill')} vs {r.get('difficulty')}")
    return ", ".join(bits)


def export_events(src, outfile, title):
    data = load("resources/data/events/" + src)
    events = data["events"]
    base = load_base(src.replace("_events.json", "") + ".json")
    base_events = (base or {}).get("events", {})

    new_events = [e for e in events if e not in base_events]
    lines = [f"# {title} — Events\n",
             f"*{len(events)} events. {len(new_events)} added in the 2026-07-27 sessions, "
             f"marked **NEW EVENT**. Individual choices added later to an older event are "
             f"marked **NEW**.*\n",
             "*Edit the prose between the anchors. Headings, ids and the mechanical "
             "lines under each choice are generated — edits there are lost.*\n",
             "---\n"]

    for eid, e in events.items():
        if not isinstance(e, dict):
            continue
        is_new_event = eid not in base_events
        old_choice_ids = set()
        if not is_new_event:
            old_choice_ids = {c.get("id") for c in base_events[eid].get("choices", [])
                              if isinstance(c, dict)}

        flag = "  **NEW EVENT**" if is_new_event else ""
        lines.append(f"## {eid}{flag}\n")
        meta = [f"realm: {e.get('realm', '?')}"]
        for k in ("zone", "trigger", "requires_trait", "requires_band", "rarity"):
            if e.get(k):
                meta.append(f"{k}: {e[k]}")
        lines.append("`" + "  ·  ".join(meta) + "`\n")

        lines.append("**Title**\n")
        lines.append(anchor([src, eid, "title"], e.get("title", "")))

        body_key = "text" if "text" in e else "description"
        lines.append("\n**Body**\n")
        lines.append(anchor([src, eid, body_key], e.get(body_key, "")))

        choices = [c for c in e.get("choices", []) if isinstance(c, dict)]
        if choices:
            lines.append("\n### Choices\n")
        for i, c in enumerate(choices):
            # 72 choices in the location events carry no id. Anchor those by
            # index so their prose is still editable and importable.
            cid = c.get("id") or f"[{i}]"
            new = "  **NEW**" if (not is_new_event and cid not in old_choice_ids) else ""
            colour = CHOICE_LABEL.get(c.get("type", "default"), c.get("type", ""))
            req = req_line(c.get("requirements", {}))
            head = f"**{cid}** — *{colour}*"
            if req:
                head += f" — requires {req}"
            lines.append(f"\n#### {head}{new}\n")
            lines.append(anchor([src, eid, f"choices.{cid}.text"], c.get("text", "")))

            for branch, label in (("outcome", "Outcome"),
                                  ("outcome_success", "Outcome — success"),
                                  ("outcome_failure", "Outcome — failure")):
                o = c.get(branch)
                if not isinstance(o, dict):
                    continue
                lines.append(f"\n*{label}*")
                mech = []
                if o.get("type") and o["type"] != "text":
                    mech.append(f"type: {o['type']}")
                for k in ("enemy_group", "difficulty", "shop_id", "companion_id",
                          "follow_up_event", "defeat_boss"):
                    if o.get(k):
                        mech.append(f"{k}: {o[k]}")
                if o.get("karma"):
                    mech.append("karma: " + ", ".join(f"{r}{v:+g}" for r, v in o["karma"].items()))
                rl = reward_line(o.get("rewards", {}))
                if rl:
                    mech.append(rl)
                if mech:
                    lines.append(f"\n`{'  ·  '.join(mech)}`\n")
                else:
                    lines.append("\n")
                lines.append(anchor([src, eid, f"choices.{cid}.{branch}.text"], o.get("text", "")))
        lines.append("\n---\n")

    write(outfile, "\n".join(lines))
    return len(events), len(new_events)


def export_animal_companions():
    data = load("resources/data/companions.json")["companions"]
    comps = data if isinstance(data, dict) else {c["id"]: c for c in data}
    base = load_base("companions.json")
    base_comps = {}
    if base:
        bc = base["companions"]
        base_comps = bc if isinstance(bc, dict) else {c["id"]: c for c in bc}

    animal = {k: v for k, v in comps.items()
              if isinstance(v, dict) and v.get("realm") == "animal"}
    lines = ["# Animal Realm — Companions\n",
             f"*{len(animal)} companions. All written by Claude and never edited — "
             "this whole file wants a pass.*\n",
             "*Edit the prose between the anchors. The stat block under each name is "
             "generated; change it in `companions.json` instead.*\n", "---\n"]

    by_zone = {}
    for cid, c in animal.items():
        by_zone.setdefault(c.get("zone", "unzoned"), []).append((cid, c))

    for zone in sorted(by_zone):
        lines.append(f"\n# Zone: {zone}\n")
        for cid, c in sorted(by_zone[zone]):
            new = "  **NEW**" if cid not in base_comps else ""
            lines.append(f"\n## {c.get('name', cid)}  `{cid}`{new}\n")
            stat = [f"birth: {c.get('birth', '?')}",
                    f"background: {c.get('background', '?')}"]
            if c.get("traits"):
                stat.append("traits: " + ", ".join(c["traits"]))
            if c.get("recruitment_cost") is not None:
                stat.append(f"cost: {c['recruitment_cost']}")
            for k in ("fixed_items", "known_spells"):
                if c.get(k):
                    stat.append(f"{k}: {c[k]}")
            lines.append("`" + "  ·  ".join(str(s) for s in stat) + "`\n")

            # Skills the companion develops into, strongest first. Editable:
            # the importer rewrites build_weights from this list, weighting
            # 5/4/3/2 down the order, and leaves it alone if the list is unchanged.
            bw = c.get("build_weights", {})
            ordered = [k for k, _ in sorted(bw.items(), key=lambda kv: -kv[1])]
            lines.append("\n**Skills** *(strongest first)*\n")
            lines.append(anchor(["companions.json", cid, "build_weights"],
                                ", ".join(ordered)))
            for field in ("flavor_text", "description", "recruitment_text"):
                if field in c:
                    lines.append(f"\n**{field.replace('_', ' ').title()}**\n")
                    lines.append(anchor(["companions.json", cid, field], c[field]))
        lines.append("\n---\n")

    write("ANIMAL_COMPANIONS.md", "\n".join(lines))
    return len(animal)


def export_traits():
    tr = load("resources/data/traits.json")
    traits = {k: v for k, v in tr.items() if isinstance(v, dict) and not k.startswith("_")}
    comps = load("resources/data/companions.json")["companions"]
    comps = list(comps.values()) if isinstance(comps, dict) else comps
    freq = {}
    for c in comps:
        if isinstance(c, dict):
            for t in c.get("traits", []):
                freq[t] = freq.get(t, 0) + 1

    order = ["physical", "personality", "behavioral", "acquired", "racial"]
    lines = ["# Traits\n",
             f"*{len(traits)} traits. The player rolls one inborn **physical**, one "
             "**personality** and one **behavioral** at creation; **acquired** ones are "
             "earned during a run; **racial** ones come with the birth.*\n",
             "*`pressure` shifts the emotional baseline that decay pulls toward: negative "
             "is toward that element's klesha, positive toward its wisdom. `bond` tags are "
             "what RelationshipSystem scores party rapport on.*\n",
             "*Edit names and descriptions between the anchors. The mechanical line is "
             "generated — change it in `traits.json`.*\n", "---\n"]

    for cat in order:
        group = {k: v for k, v in traits.items() if v.get("category") == cat}
        if not group:
            continue
        lines.append(f"\n# {cat.title()}  ({len(group)})\n")
        for tid, t in sorted(group.items()):
            on_comps = freq.get(tid, 0)
            lines.append(f"\n## {tid}\n")
            mech = []
            if t.get("stat_modifiers"):
                mech.append("stats: " + ", ".join(f"{k}{v:+d}" for k, v in t["stat_modifiers"].items()))
            if t.get("skill_modifiers"):
                mech.append("skills: " + ", ".join(f"{k}{v:+d}" for k, v in t["skill_modifiers"].items()))
            if t.get("pressure_modifiers"):
                mech.append("pressure: " + ", ".join(f"{k}{v:+g}" for k, v in t["pressure_modifiers"].items()))
            if t.get("bond_tags"):
                mech.append("bond: " + ", ".join(t["bond_tags"]))
            if t.get("opposed_traits"):
                mech.append("opposed: " + ", ".join(t["opposed_traits"]))
            if t.get("purgeable_by"):
                mech.append(f"purged by {', '.join(t['purgeable_by'])} {t.get('purge_difficulty', 0)}")
            mech.append(f"on {on_comps} companions")
            lines.append("`" + "  ·  ".join(mech) + "`\n")
            lines.append("**Name**\n")
            lines.append(anchor(["traits.json", tid, "name"], t.get("name", "")))
            lines.append("\n**Description**\n")
            lines.append(anchor(["traits.json", tid, "description"], t.get("description", "")))
        lines.append("\n---\n")

    write("TRAITS.md", "\n".join(lines))
    return len(traits)


def write(name, text):
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        f.write(text)
    print(f"  wrote docs/review/{name}  ({len(text.splitlines())} lines)")


if __name__ == "__main__":
    print("exporting review documents:")
    n = export_animal_companions()
    print(f"     {n} animal companions")
    n = export_traits()
    print(f"     {n} traits")
    for src, out, title in REALMS:
        total, new = export_events(src, out, title)
        print(f"     {title}: {total} events, {new} new")
