"""Perks: skill -> "Level N" -> perk, then a final "Cross-skill" group split by
category. Name, description and flavor are writing; the requirements and the
mantra flag are context. base_bonuses is plain numbers, so it is skipped."""
from ..model import Entry, Field, Group
from ._common import clean

TITLE = "Perks"
FILE = "resources/data/perks.json"
SKILLS_FILE = "resources/data/skills.json"


def _attrs(d) -> str:
    if isinstance(d, dict):
        return ", ".join(f"{k} {v}" for k, v in d.items())
    return str(d)


def _context(p: dict, cross: bool) -> str:
    parts = []
    if cross:
        req = p.get("requirements")
        if isinstance(req, dict) and req:
            parts.append("needs " + _attrs(req))
        if p.get("special_requirement"):
            parts.append(f"also: {p['special_requirement']}")
    if p.get("requires_perks"):
        parts.append("after " + ", ".join(map(str, p["requires_perks"])))
    if p.get("required_attributes"):
        parts.append("needs " + _attrs(p["required_attributes"]))
    if p.get("is_mantra"):
        parts.append("mantra")
    return clean(" · ".join(parts))


def _entry(pid: str, p: dict, section: str, cross: bool) -> Entry:
    return Entry(
        key=f"perks:{section}:{pid}", title=p.get("name", pid), ident=pid,
        title_path=(FILE, section, pid, "name"), context=_context(p, cross),
        fields=[Field("desc", p.get("description", ""), "text",
                      (FILE, section, pid, "description")),
                Field("flavor", p.get("flavor", ""), "text",
                      (FILE, section, pid, "flavor"))])


def build(ds) -> Group:
    data = ds.get(FILE)
    skill_names = {k: v.get("name", k)
                   for k, v in ds.get(SKILLS_FILE).get("skills", {}).items()
                   if isinstance(v, dict)}
    # skill id -> level -> [(id, perk)]. Some perks carry no skill at all
    # (they are gated on attributes instead); they go in a "No skill" group.
    by_skill: dict = {}
    for pid, p in data.get("skill_perks", {}).items():
        if pid.startswith("_") or not isinstance(p, dict):
            continue
        by_skill.setdefault(p.get("skill", "") or "none", {}).setdefault(
            p.get("required_level", 0), []).append((pid, p))
    top = Group(TITLE, 1)
    for sid, levels in by_skill.items():
        g = Group(skill_names.get(sid, "No skill" if sid == "none" else sid), 2, sid)
        for lvl in sorted(levels):
            lg = Group(f"Level {lvl}", 3, str(lvl))
            lg.entries = [_entry(pid, p, "skill_perks", False) for pid, p in levels[lvl]]
            g.groups.append(lg)
        top.groups.append(g)
    by_cat: dict = {}
    for pid, p in data.get("cross_perks", {}).items():
        if pid.startswith("_") or not isinstance(p, dict):
            continue
        by_cat.setdefault(p.get("category", "other"), []).append((pid, p))
    cross = Group("Cross-skill", 2, "cross")
    for cat, items in by_cat.items():
        cg = Group(cat.replace("_", " ").capitalize(), 3, cat)
        cg.entries = [_entry(pid, p, "cross_perks", True) for pid, p in items]
        cross.groups.append(cg)
    top.groups.append(cross)
    return top
