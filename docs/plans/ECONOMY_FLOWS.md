# Where gold comes from and where it goes

*2026-09-20. The companion piece to `ECONOMY_DESIGN.md`: that one proposes a
system, this one audits the numbers the game already runs on. Written after
Olaf answered the first open question.*

---

## The decision

> **Does gold keep buying attribute points and skill levels?**
>
> Yes, but rarely so. Trainers should be limited in scope, expensive, and
> appear rarely, so the player gets this great chance once in a while. It
> should not break the overall balance. Giving a random boost to a specific
> playthrough is fine — that is fun for the player.

That is a sharper answer than the three options the design offered, because it
does not pick between them: it keeps gold buying progression (option 1's
world), but makes **scarcity** the limiter rather than price caps, and accepts
run-to-run variance as a feature rather than a leak.

Three things follow, and the rest of this document is working them out:

1. The prices have to actually be expensive, and they are not.
2. Rarity has to be structural, not a dice roll — which is a map problem.
3. Gold that cannot buy progression needs **somewhere else to go**, so the
   sink layer stops being optional.

---

## The exchange rate nobody wrote down

The skill training table and the skill XP table are the same table, priced.

| Level | XP cost | Gold price | Gold per XP |
|---|---|---|---|
| → 1 | 5 | 50 | 10.0 |
| → 2 | 10 | 150 | 15.0 |
| → 3 | 18 | 300 | 16.7 |
| → 4 | 28 | 500 | 17.9 |
| → 5 | 42 | 750 | 17.9 |

**Skills are sold at about 18 gold per XP, with a discounted first level.**
Nothing in the code says so — `SKILL_TRAINING_COSTS` is a literal array — but
the rate is there, it is stable, and it re-derives the table to within a few
per cent at every level above the first. Somebody was thinking clearly when
they wrote it.

**Attributes ignore it completely.** `ATTRIBUTE_TRAINING_COST` is a flat 200,
while the XP cost of an attribute point rises with the attribute
(`(value - 9) × 3`). So the rate does not merely fail to escalate — it
**inverts**:

| Attribute | XP cost | Gold price | Gold per XP |
|---|---|---|---|
| 10 → 11 | 3 | 200 | 66.7 |
| 15 → 16 | 18 | 200 | 11.1 |
| 20 → 21 | 33 | 200 | 6.1 |
| 25 → 26 | 48 | 200 | 4.2 |
| 30 → 31 | 63 | 200 | 3.2 |

A character at 10 pays nearly four times the skill rate. A character at 25 pays
a quarter of it. **The trainer is worst value exactly where the player has
least, and a bargain exactly where they have most** — which is the opposite of
every intention in the paragraph at the top of this document, and the reason
gold currently *is* a progression press despite only twelve shops selling
attributes.

Worse, it makes specialising strictly correct: pump one attribute to 25 and
every further point is the cheapest progression in the game.

### The fix is one constant

```gdscript
const GOLD_PER_XP: int = 18
# attribute price = CharacterSystem.calculate_attribute_cost(value, 1) * GOLD_PER_XP
```

| Attribute | Now | At 18/XP |
|---|---|---|
| 10 → 11 | 200 | **54** |
| 15 → 16 | 200 | **324** |
| 20 → 21 | 200 | **594** |
| 25 → 26 | 200 | **864** |
| 30 → 31 | 200 | **1,134** |

Cheap when you are poor and starting out, genuinely expensive later — which is
"a great chance once in a while" expressed as arithmetic. It also makes the two
trainer types agree with each other for the first time, and it gives the game a
single named exchange rate instead of two tables that disagree silently.

Whether the skill table then gets re-derived from the same constant (90 / 180 /
324 / 504 / 756) or left as the hand-tuned numbers it is, is a smaller question
— the numbers barely move above level 1, and the discounted first level is
probably deliberate.

---

## A defect found on the way

**Three shops advertise skill caps they cannot honour.** `weapon_master` offers
`max_skill_level: 7`, `wandering_sage` and `infernal_forge` offer 6. But
`SKILL_TRAINING_COSTS` has five entries, so `get_skill_training_cost` returns 0
for any level at or above 5, and `buy_skill_training` reads that 0 as "cannot
train" and refuses.

So the best weapon trainer in the game silently stops at 5 while claiming 7.
It fails closed rather than giving levels away, but it is a promise in the data
that the code cannot keep — the same class as the keys cleared in `2c05a98`.

Extending the table to level 10 at the rate above would read
90 / 180 / 324 / 504 / 756 / 1,062 / 1,440 / 1,908 / 2,466 / 3,150. Levels 6
and 7 at roughly a thousand gold each are a reasonable thing for a rare master
to charge, and they make `max_skill_level` mean something.

---

## The map of flows

### Sources

| Source | Scale | Grows with progression? |
|---|---|---|
| Combat gold | `enemy_party_xp × fraction × 0.5`, +10% per Trade level | **Yes**, directly |
| Luck jackpot | 3–10% chance of 3–5× the combat gold | Yes, as a multiplier |
| Loot overflow | 20% of over-budget item value | Yes |
| Selling gear | item value (median 200, p90 1,500, max 3,600), halved, shop modifier inverted | Yes |
| Map pickups | 5–25 and 15–50 | **No** — flat all game |
| Event rewards | authored per event | Varies |
| Starting purse | 100, plus race `starting_gold` | Once |

### Sinks

| Sink | Scale | Grows? | Shops offering |
|---|---|---|---|
| Gear | 200 median, 1,500 at p90 | **Yes** | most |
| Spells | 50 × spell level | Weakly | 44 of 91 |
| Skill training | 50 → 750 | Yes, to level 5 | 17 of 91 |
| Attribute training | flat 200 | **No** | 12 of 91 |
| Mercenaries | 500–1,150 (median 800) | No | 3 guilds |
| Wound healing, rest, repair | small | No | — |

**The structural problem, in one line: four of the seven sources scale with
party power and only one sink does.** Gold pressure therefore falls across a
run — by late game the player is rich and nothing costs more than it used to.
That is why the trainer stops feeling like a great chance: not because it is
common, but because by the time you find one you can buy it without thinking.

Fixing the attribute rate fixes about half of this on its own, because it turns
the one non-scaling sink into a steeply scaling one.

---

## What the decision requires

### Rarity should be structural, not random

The scarcity Olaf asked for is **already in the data** — 12 shops of 91 teach
attributes, and each teaches only one or two of the seven. What undermines it
is placement: the generator picks `guaranteed_shops: [1, 2]` per zone at random
from events tagged `shop`, so whether a run contains an attribute trainer at
all, and which one, is a coin flip nobody designed.

That is exactly what the settlement layer in `ECONOMY_DESIGN.md` fixes. Once
`training.max_skill_level` is a property of a **town** rather than a shop
template:

- hamlets teach nothing,
- villages teach to a low cap,
- towns teach higher, and the capital highest.

Rarity then falls out of town rarity, which the zone quota and `habitability`
already control. "Limited in scope, expensive, appears rarely" becomes a
consequence of the map rather than a wish about it.

**And the run-to-run variance Olaf wants is free here.** Which trainers exist,
and where, is drawn per run from the pool — so *this* run has a Strength master
two zones from the start and no Focus teacher anywhere, and that is a fact about
the run worth telling someone about. The luck jackpot already proves the taste
is right: a rare, large, unreliable spike is the most memorable thing in the
reward code.

### Sinks stop being optional

If gold barely buys progression and gear has a ceiling, then a trade economy
with no sinks produces a number that goes up and means nothing. The design
listed sinks as option (3), a nice-to-have. **Olaf's answer promotes them to a
requirement.** In rough order of how much they give back:

- **Investment** — already a Trade perk waiting on exactly this, and the only
  sink that makes you care about a *place*.
- **Mercenary wages** — recruitment is a one-off 500–1,150 today. An ongoing
  cost turns a big purse into a bigger party rather than a bigger number.
- **Temple donation** — gold into karma, which is the one currency the player
  cannot see and cannot farm. Thematically the strongest of the four.
- **Settlement improvement** — the long-tail sink, and the one that makes a
  town you invested in visibly different on a later pass.

### Trade income must not scale with party power

Combat gold already scales with `enemy_party_xp`. If trade profit scales with
progress too, they compound and the late game floods.

Trade should scale with **distance and risk** — player choices — not with how
strong the party is. The specials premium in the design is already the right
shape (0.15 per zone crossed, 1–2× per realm), and the staples are bounded by
the scarcity clamp. This just needs writing down as a rule so a later tuning
pass does not quietly break it: *no trade payout reads party XP, party level,
or enemy difficulty.*

---

## What to build, in order

1. **`GOLD_PER_XP` and the attribute price.** One constant, one call site.
   Fixes the inverted rate, makes trainers expensive as asked, and needs no
   other system. Extend `SKILL_TRAINING_COSTS` to level 10 in the same commit
   so the three lying shops stop lying.
2. **Settlements as entities** — layer 1, the keystone. Now also the thing that
   makes trainer rarity structural.
3. **Trade goods and the price index** — layers 2 and 3, unblocked by the
   decision above.
4. **Investment**, as the first real sink, maturing on the day tick.
5. **Drift and shocks** — layer 4.

Steps 1 is independent of everything and could land today. Steps 2 onward want
the biome economy fields settled first, since they are what the price index
reads.
