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
>
> Every such attribute and skill advancement is capped at three points max,
> with each subsequent purchase from the same shop for the same character
> costing x, 2.5x, 5x.

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

### A trainer is an occasion, not a service

The cap is what actually delivers "a great chance once in a while", and it does
something the price alone cannot: it makes the trainer a **finite encounter**.
Three lessons from this teacher for this character, at 1x, 2.5x and 5x, and
then they have taught you what they can.

Two consequences worth naming:

- **It ends the grind before it starts.** Without a cap, a rich party parks at
  the best trainer and buys until the gold runs out, which is exactly the
  progression press the whole question was about. With one, the ceiling is
  structural — the most gold can ever buy at one trainer is three points, and
  the third costs five times the first.
- **It makes finding a *second* trainer matter.** Once a teacher is exhausted,
  the next one is worth travelling for, which is the behaviour the settlement
  and road layers exist to reward.

**The allowance is shared between attributes and skills.** All twelve shops
that teach attributes also teach skills, so this is the common case, not an
edge case: three lessons *total* from one trainer, of whichever kind. A
separate three-and-three would double every trainer's output and make the dual
shops strictly better in a way nothing in the design asks for. If the intent
was per-kind, it is one line — the ledger key gains the training type.

**It is per character.** One party member exhausting a teacher leaves the
others their own three, which is what makes a good trainer worth bringing the
whole party to.

### The rate is one constant

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

## One rule, four refresh rates

The trainer rework answers a question wider than trainers: **what is a price
responding to?** The answer that makes the whole economy one system rather than
four is that *every vendor holds stock, and price responds to stock*. What
differs between kinds of vendor is only **how fast the stock comes back**.

| Vendor | Stock | Refresh | Price curve |
|---|---|---|---|
| **Trainer** | 3 lessons | never | steep — 1x, 2.5x, 5x |
| **Caravan** | what it is carrying | never | medium |
| **Town market**, staples | toward equilibrium | daily drift | gentle — `clamp(eq / stock, 0.5, 2.0)` |
| **Smith's rack**, gear | one of each item | every 7 days | selection rather than price |

The trainer feels unlike a shop because it sits at the extreme of that axis: a
person is a finite, non-renewing stock of three. Nothing else about it is
special, which is the point — the cap and the 1x/2.5x/5x steps are just a very
short stock on a very steep curve, and the same two numbers describe a market
that recovers overnight.

**The smith's rack was the opposite of restocking.** `get_shop` hands back a
deep copy of the template and `open_shop` rolled a fresh procedural rack into
it, so walking out and back in rerolled the weapons and a purchase depleted
nothing that survived the visit. The rack was infinite and free — and that
quietly voids the material-selection design below, because a player who can
reroll until the smith offers what they wanted is not shopping in a region,
they are pulling a lever. Now fixed: the rack belongs to the map object, is
saved, depletes when you buy, and tops back up to its slot count every seven
days with unsold stock left where it is.

**This is worth building once.** A `stock` and a `refresh` on a vendor record,
and one price function that reads them, covers trainers, staples, caravan
cargo and consumables. Writing four pricing systems that happen to resemble
each other is how the buy and sell prices eventually cross.

---

## Gear, and the goods it is made of

`ECONOMY_DESIGN.md` prices eight trade goods and says nothing about the 1,492
items that already have a `value`. They are not a separate problem, because of
something already in the data:

**Trade goods are the raw form of materials.** `equipment_tables.json` carries
42 materials, each with a `value_mult`, and `realm_material_weights` already
makes availability depend on where you are — hell rolls bone / obsidian /
bronze, the god realm rolls sky-iron and vajra. That is the coarse, per-realm
version of exactly what a biome should do per region.

| Trade good | Materials it becomes |
|---|---|
| **ore** | copper, bronze, iron, steel, silver, damascene, sky_iron |
| **timber** | wood, sandalwood, rosewood, composite |
| **hides** | leather, hide, scale, chitin |
| **salvage** | bone, obsidian, devils_bone |
| **herbs, fish, grain, salt** | consumables, not gear |

So `produces: {"ore": 3}` on the Cinder Hills does **two jobs from one
number**: it sets the price of ore, and it makes iron gear common and cheap
there. No new biome data is required for the common case.

### Two effects, and the second matters more

- **Price** — one more term, the same clamp shape as the staples:
  `× material_scarcity(region, material)`.
- **Selection** — `realm_material_weights` tilted by the biome. A blacksmith in
  the Cinder Hills racks iron and steel; one in the Deep Wood racks wood and
  leather; one on the Reef Flats racks conch, coral and scale.

Selection is the bigger change, because it decides what you *can* buy rather
than what it costs. It is also nearly free: the weighted pick already exists in
`_generate_procedural_stock`, and it already takes a realm.

### The implementation constraint that will bite

**An item's value is baked in at generation.** `final_value = base.value ×
material.value_mult × quality.value_mult`, computed once in `item_system.gd`
and stored on the item. The only local term today is `shop.price_modifier`,
applied at the till.

So regional pricing **must live in `get_buy_price` / `get_sell_price`, never in
`final_value`** — otherwise an item mutates when carried across a border, which
destroys the one behaviour the whole design is for: buying where a thing is
cheap and selling where it is dear. The item's worth is intrinsic; the market's
opinion of it is local. Those have to stay separate fields.

### A number to be careful with

`vajra` has `value_mult: 15.0` and the god realm weights it at 45. A vajra
blade is already worth fifteen times its base. If a regional multiplier stacks
on top unclamped, carrying one from the god realm to hell is an arbitrage that
ends the economy in a single trip. The `[0.5, 2.0]` clamp is not decoration —
it is what keeps the top of the material ladder from being a money printer, and
it wants asserting in a verifier against the **highest** `value_mult` in the
table rather than against a typical one.

---

## What a caravan does after it spawns

The friendly NPCs already exist — every mob pool carries `attitude: 0` entries,
and `_place_zone_mobs` already generates patrol routes for `mode == 1`. A
caravan is therefore not a new spawn system; it is a patrol mob with cargo and
a shop hook.

**Its state:**

```
origin        the settlement it left, and whose prices it quotes
cargo         {good: count} — a manifest, finite
route         settlement ids along the road network
disposition   how it feels about the party
```

**Its behaviour, in the order the party experiences it:**

1. **Spawns at a settlement**, picks a destination, and takes the road.
2. **Walks.** The road network is the schedule — a caravan that left the ore
   town three days ago is somewhere on the road to the grain town, and a player
   who has learned the roads can work out where.
3. **On meeting, it is a shop quoting its origin's prices.** That is the whole
   point of it: buying a distant market's cheap side without going there. Its
   `price_modifier` is the origin's, not the local one.
4. **Its cargo depletes and never refills.** Buy it out and it has nothing —
   the non-refreshing row in the table above. This is what stops a caravan from
   being an infinite arbitrage machine parked on a road.
5. **On arrival it despawns.** The destination's prices move by the daily
   drift, not by this caravan's delivery.
6. **Rob it** and you get the cargo, a karma hit, and a flag. Traders in that
   realm price you up, and some flee on sight rather than trade.

**Step 5 is a deliberate cheap choice.** The expensive version has the caravan
actually deposit its cargo into the destination's stock, so the network
equalises through simulated trade rather than through drift. That is a better
world model and it is not worth building until the drift is visibly boring —
the player cannot tell the difference until they are watching two markets at
once, which is a late-game behaviour that may never arrive.

**Where they are is already answered.** `mob_bias: {"traveller": 2.5}` on the
Old Roads is a caravan corridor; `{"traveller": 0.1}` on the Deep Swamp is why
you do not meet merchants chest-deep in a bog. The field designed for NPC kind
turns out to be the caravan density field too.

---

## The one new biome field

Everything above needed exactly one thing the biome tables do not already
carry, and even that is optional:

```jsonc
"reef_flats": {
  "produces": { "fish": 2, "salt": 2 },
  "materials": { "conch": 2.0, "coral": 1.8, "scale": 1.4, "iron": 0.4 }
}
```

**Derive by default, declare to override** — the same rule `produces` already
follows against terrain. The good-to-material table above derives a sensible
tilt from `produces` for nearly every biome, so `materials` is only written
where the derivation cannot know something: that a reef yields conch and coral,
that the charnel grounds yield devils_bone, that the Frozen Wood has no metal
at all whatever its hills suggest.

Most biomes will leave it empty, which is the sign it is the right shape.

---

## Four decisions, 2026-09-20

### Death regenerates the world

> The whole world should be regenerated on player character death, with only
> the karmic tendencies influencing the new character and sometimes, rarely,
> some specific effect that lasts for the next lifetime. The specific map
> should be regenerated each time — the zones, regions and biomes are there to
> keep a general structure, but the specifics should change randomly.

This settles what gold is: **a life's resource, not a ratchet.** A trade
fortune buys gear and training in the life that earned it and goes in the
ground with the body, which removes the compounding worry from every layer
below — trade cannot snowball across runs because there is no across.

It also turned up a defect. `start_new_run` reset five things; the new-game
path reset fifteen; and the two had drifted. Gold, supplies other than food,
seen events, map buffs and both shop caches all survived a death. The caches
matter most: `shop_stock` and `guild_spell_lists` are keyed by **map object
id**, and a regenerated map never issues those ids again — so it was not a
visible bug but an unbounded leak of racks belonging to worlds that no longer
exist. Both paths now call one `reset_for_new_life`, so a new variable cannot
be reset in one and forgotten in the other.

What survives is unchanged and correct: `unlocked_worlds`, the run counter,
and on the character the `affinities` and `persistent_upgrades` that
`CharacterSystem` already copies across. **That last field is where the "rare
specific effect" belongs** — it exists, it persists, and nothing writes to it
yet.

### A shop pays what it has, and barter is the way round it

> Shops should not have infinite gold, the amount based on the wealth of the
> region and the specific venue (town > caravan > settlement). Also, barter
> should be possible.

A purse per shop, seeded by venue type and refilled on the rack's cadence —
the same stock-and-refresh rule, applied to money. A town holds 4,000; a
teahouse 400. Selling drains it, buying from the shop puts money back.

Wealth reads `price_modifier` for now, the only per-place richness signal that
exists. When biome `wealth` and settlement tiers land, it reads those instead.
That is the seam, and it is one function.

**Barter is what stops the purse being a wall.** "Sell the sword, buy the
armour" is one exchange that needs no cash at all, but a purse makes it
impossible at a poor shop if it has to happen as two transactions. So goods
settle against goods first and gold only covers the difference. Where the shop
cannot cover it, the player is told what they will lose — *you will not get 17
gold of change* — and may take the deal anyway. Refused silently by default;
`accept_shortfall` is the player answering.

### Supply and demand stays invisible

> They should just work in the background so the player sees when arriving in
> a city "oh, fish is really cheap here, but incense is very expensive,
> interesting, maybe it would pay to return to the spice town from before".

**No indicator, no dear/fair/cheap marker.** The earlier suggestion to add one
is withdrawn. The discovery *is* the content, and a badge saying CHEAP does
the noticing for the player, which is the one thing they should be doing
themselves.

Two consequences worth holding to:

- **The numbers have to carry it alone**, so the spread must be wide enough to
  notice unaided. A 10% difference is invisible without a marker; the
  `[0.5, 2.0]` scarcity clamp gives up to fourfold, which is plainly visible
  in a price list.
- **`supply_and_demand` (Trade 5) becomes more valuable, not less.** The
  baseline is that you notice and remember; the perk is that you are *told* —
  the spread across settlements you have visited, without the bookkeeping.
  That is a much better perk when the default is genuinely unaided.

### Shocks are not an economy feature

Recorded in `TODO.md` §11 rather than here. A market shock is one instance of
something the game lacks entirely — the world changing without the player
touching it — and the same hook serves territory, factions and karma. Building
it as a price mechanic now would mean rewriting it the first time a mob group
should take a road while you are two zones away.

---

## What to build, in order

1. ~~**`GOLD_PER_XP` and the attribute price.**~~ **Built.** The rate is named,
   attributes are priced off their own XP cost, `SKILL_TRAINING_COSTS` reaches
   level 10 so the three lying shops stop lying, and the three-lesson cap with
   its 1x / 2.5x / 5x escalation is enforced and saved per character per
   trainer. Seven checks in `verify_economy_bonuses`.
2. **Settlements as entities** — layer 1, the keystone. Now also the thing that
   makes trainer rarity structural.
3. **Trade goods and the price index** — layers 2 and 3, unblocked by the
   decision above.
4. **Investment**, as the first real sink, maturing on the day tick.
5. **Drift and shocks** — layer 4.

And from the sections above, slotted where they belong rather than as a second
list:

- **One stock-and-refresh vendor record** goes in with step 2, not after it.
  The price function that reads it is the same one the staples need, and
  retrofitting the trainer onto it later means touching pricing twice.
- **Biome-tilted material selection** goes in with step 2 as well. It is the
  cheapest large change in this document — `_generate_procedural_stock` already
  does a weighted pick and already takes a realm, so tilting the weights by
  subregion is a small edit that changes what every shop in the game racks.
- **Regional gear pricing** goes in the till (`get_buy_price` / `get_sell_price`),
  never in `final_value`, and wants the clamp verified against `vajra` at
  `value_mult: 15.0` rather than a typical material.
- **Caravans** come after step 3, because a caravan with no trade goods to
  carry is just a peddler with extra steps.

Steps 1 is independent of everything and could land today. Steps 2 onward want
the biome economy fields settled first, since they are what the price index
reads.
