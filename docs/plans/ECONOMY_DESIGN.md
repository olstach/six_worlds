# The economy: a design

*2026-09-17. Asked for after the two Trade perks — `investment` and
`supply_and_demand` — turned out to want a system rather than a wiring.*

---

## What exists today

- **One price per item, everywhere.** `item.value`, multiplied by
  `shop.price_modifier` (a single scalar, 0.9–1.3) and the party's Trade and
  Charm discounts. Selling inverts the modifier and halves the result.
- **91 shops, none of which has a position.** A shop is a definition reached
  through an event outcome (`type: shop, shop_id: X`). Nine are typed `town`.
  Nothing on the map is a *place with an identity*: the generator places
  `guaranteed_shops: [1, 2]` per zone from events tagged `shop`, and what it
  places is a template, not a settlement.
- **Maps already have regions.** Each map config has `zones` — bands of rows
  with their own `terrain_weights`, `road_chance`, object pools and mob pools.
  Animal has ocean / coastal wall / forest / meadow. This is the region unit a
  regional economy needs, and it already exists.
- **Names already exist.** `location_names` per map config, with a comment
  explaining the Tibetan and Sanskrit compounds it builds settlement names
  from.
- **Time already advances.** Days pass, the lunar calendar listens to them.
- **Distance already costs money.** Travel consumes food per step, reduced by
  Logistics. A long trade route is already a paid-for route.

So the pieces for a trade economy are nearly all present *except* the one it
actually needs: **a price that depends on where you are.**

---

## The constraint that shapes everything

**Gold buys progression.** Trainers sell attribute points at 200 gold and skill
levels at 50/150/300/500/750. The design's headline is that XP is the only
progression currency and there are no levels — but in practice gold buys
attributes and skills through a shop.

That means *any* reliable money press is a progression press, and a trade
economy is the most reliable money press a game can have. This is not a reason
not to build one; it is the reason to decide, first, which of these is true:

1. **Trade profits stay bounded** — by stock depletion, carrying capacity, food
   spent on the road, and a cap on the spread. Gold stays a gear-and-training
   currency and trade is a way to afford better gear sooner, not infinitely.
2. **Trainers stop selling levels for gold** — they charge XP, or gold *and*
   XP. Gold becomes purely a gear currency and the press matters much less.
3. **Gold grows sinks to absorb it** — investment, temple donation, mercenary
   wages, settlement improvement. A rich party spends on the world rather than
   on itself.

I would build (1) into the mechanism from the start regardless, because a
self-limiting market is better design than a capped one, and pair it with (3)
because investment is already one of the two perks asking for this. (2) is a
bigger decision about what gold *is*, and it is yours.

---

## The spine

**A price is a function of good, place and time.**

One mechanism gives all three, and it is small:

> **Every settlement holds a stock of every trade good, and its prices are read
> off that stock. Stock regenerates each day toward an equilibrium derived from
> the terrain around it.**

From that single rule:

- **Place.** A forest zone's settlements equilibrate high on timber and low on
  grain, so timber is cheap there and grain dear. The terrain already says
  which — `terrain.json` says what a ground yields to a forager, and the same
  vocabulary says what a region produces. No second table.
- **Time.** Stock drifts toward equilibrium, so a market recovers from being
  bought out, and prices move while you travel. Events can shock it: a caravan
  arrives, a mine floods, a siege begins.
- **Diminishing returns.** Buying lowers stock and raises the price you pay for
  the next unit; selling raises stock and lowers what you are paid. A route
  cannot be farmed, only worked — and it recovers if you leave it alone, which
  is exactly the behaviour that makes routes worth *learning*.

Concretely, for settlement S and good g:

```
price(S, g) = base_value(g)
            × scarcity(S, g)          # clamp(equilibrium / max(stock, 1), 0.5, 2.0)
            × tier_multiplier(S)      # a hamlet pays worse than a city
            × shop_modifier           # what already exists, now one term of several
```

`scarcity` clamped to [0.5, 2.0] gives at most a fourfold spread between the
cheapest and dearest market for one good, before the sell ratio takes its cut.
That is enough to be worth a journey and not enough to break the game.

---

## Five layers, each shippable alone

**1. Settlements as entities.** A record with an id, a generated name, a
position, a zone, and a tier, created by the generator where it already places
shops, and hosting the shop definition it already picks. Nothing changes in
play — but the map now has *places*, and everything below needs them. This is
the keystone and it is cheap.

It also makes the portal question concrete: portals are two-way, and a living
hero who has crossed between worlds can cross back, so **a settlement you have
met is a settlement you can return to.** Investments left in a realm mature
whether you are standing in it or not, which turns backtracking from a
curiosity into a reason.

**2. A regional price index.** Stock and equilibrium per settlement per good
category, equilibrium derived from the zone's terrain weights. Buying and
selling read the index. Immediately: prices differ by place, `supply_and_demand`
has something to compare, and the existing `price_modifier` becomes one term
rather than the whole story.

**3. Trade goods.** Eight to twelve goods in `trade_goods.json` — grain, salt,
timber, ore, hides, incense, reagents, relics — each with a base value, a
weight, and a production affinity by terrain. They exist to be carried, and
weight is what makes carrying them a decision: the party's capacity is already
Strength-derived, so a cargo run costs you the gear you did not bring.

**4. Drift and shocks.** The day tick moves stock toward equilibrium. Events
shock it. This is where `investment` matures, and where a market remembers
what you did to it last week.

**5. Towns with depth.** With settlements as entities, the things you want fall
out: prosperity as a function of stock and wealth, which changes what the shop
stocks and what the trainers there will teach; investment raising prosperity;
reputation per settlement; quests that belong to a place. The existing
`guild_max_tier` and `training.max_skill_level` stop being properties of a shop
template and become properties of a *town* — which is what they always meant.

---

## The goods

Two kinds, doing two different jobs.

### Staples — bulk, cheap, needed everywhere

These drive the stock-and-price mechanism. Every settlement consumes some and
produces others, so the web is what makes one region need another.

| Good | Produced by | Consumed by |
|---|---|---|
| **Grain** | plains, meadow | everywhere; more per tier |
| **Fish** | water, ocean, ice | everywhere inland |
| **Salt** | desert, sand, water | everywhere |
| **Timber** | forest | everywhere that builds |
| **Ore** | mountains, hills, ruins | everywhere that makes |
| **Hides** | meadow, forest, snow | everywhere that wears |
| **Herbs** | swamp, forest, hills | everywhere that heals |
| **Salvage** | ruins, charnel grounds | smiths and alchemists |

Eight, which is enough for a web and few enough to hold in your head. Read the
table the other way and the routes appear: mountains grow nothing and need
grain; plains make no tools and need ore; the ocean has fish and salt and wants
timber; the swamp has herbs and wants everything.

The terrain column is not a new table — it is `terrain.json`, the same file
that says what a ground yields to a forager and what it becomes on a
battlefield. A zone that generated 30% mountains equilibrates high on ore
because the map generator decided that.

### Specials — one place makes them, and they are worth more the further you carry them

This is your risk-and-reward layer, and it is where the planar gates become
economic. A special good has a low local price and a premium that grows with
distance from where it was produced:

```
sale_price = base × (1 + distance_premium) × scarcity_at_market
distance_premium = 0.15 per zone crossed          (same realm, capped ~0.6)
                 + 1.0 to 2.0 per realm crossed   (the gates pay for themselves)
```

A naga pearl sold at the reef is worth what a pearl is worth. Carried to the
cold hells it is worth four times that — and everything between here and there
knows you are carrying it.

| Realm | Special | Produced in | What it is |
|---|---|---|---|
| Hell | **Ash-iron** (*thal-lchags*) | fire hells | metal quenched in suffering; smiths pay anything |
| Hell | **Bitter salt** | cold hells | preserves what should not be preserved |
| Hungry Ghost | **Grave incense** | charnel grounds | burned to be heard by the dead |
| Hungry Ghost | **Bog amber** | fetid swamps | resin with something inside it |
| Animal | **Naga pearl** | ocean | the sea courts' coin, and they remember it leaving |
| Animal | **Garuda plume** | ridge | taken, not gathered |
| Human *(unbuilt)* | tea, paper, ink, silk | — | the realm that makes things for other realms |
| Asura *(unbuilt)* | war-steel, trophies | — | |
| God *(unbuilt)* | amrita, celestial silk, lotus | — | worth most in the realms that cannot make them |

**The risk is the premium.** One rule: the total premium riding in the party's
packs raises the chance of a hostile encounter, and a lost fight costs a
fraction of the cargo. Carry a pearl across three zones and something will come
for it — which is the difference between a trade route and a delivery.

That also gives the unbuilt realms a reason to exist economically before they
have content: the Human realm is the one that *makes things*, and the God realm
sells what nowhere else can grow.

## How this ties to the terrain work

The terrain audit left one vocabulary (`Ground`, `terrain.json`) shared by the
overworld and the battle grid, and yesterday it gained a `forage` block: what a
ground yields to somebody searching it. A region's *production* is the same
question asked at a larger scale, so it reads the same data:

```
equilibrium(S, g) = Σ over the zone's terrain weights of produces(terrain, g)
                  × tier_factor(S)
```

A zone that is 30% mountains and 15% forest equilibrates high on ore and
middling on timber, and the map that generated it decided that. **Map
generation becomes the thing that lays out the economy** — which is the tie-in
you named, and the reason to do the two together rather than in either order.

---

## Subregions: the same fix the battlefield got, one level up

A zone today fills its whole rectangle with weighted-random terrain and then
smooths it three times. So a zone keeps the PROPORTIONS of its terrain and
throws away the ARRANGEMENT — which is word for word the flaw the terrain audit
found in the battlefield generator and fixed with blocks and greeble. The world
map still has the statistical version.

**Subregions are that fix at map scale.** A zone is divided into a handful of
contiguous areas, each with its own biome, and the terrain is generated per
subregion rather than per zone.

**How they are cut.** Seeds on a jittered lattice — a grid, with each point
pushed off centre — and every tile joins its nearest seed. A plain lattice
looks like a chessboard and pure random seeds clump; jittering a lattice gives
organic shapes with a KNOWN COUNT AND SIZE, which is what "regular and
logically placed, but not overwhelming" needs. Six to nine subregions per zone,
each roughly 40×20 on a 192-wide map.

**What a subregion is.** An id, a name, a biome, a centre. The biome is drawn
from the zone's pool, so a zone becomes "mostly pine slopes with two salt flats
and a burned-over stretch" rather than an even scatter of everything it
contains.

**A biome belongs to the WORLD, not to a zone.** Each map config carries a
`biomes` library — a kind of place, defined once — and a zone names the ones it
may grow in `biome_pool` (id to weight). Two zones that could both hold a
frozen wood say so, rather than each carrying a copy of one.

**And a biome decides more than its terrain.** Every field is read:

| Field | What it decides |
|---|---|
| `terrain_weights` | what the ground is made of |
| `cluster_min` / `cluster_max` | how large its patches are — a deep wood is one canopy, a reef is broken up |
| `mob_weight` | how much of the zone's danger is placed here |
| `event_weight` | how much of its interest — a mausoleum has things to find, a dust plain does not |
| `name` | what the player is told they are standing in |

`cluster_min` and `cluster_max` were already in all three map configs and read
by nothing, alongside `road_chance`, which is deleted until the road network has
a use for it. The fill seeds PATCHES now rather than rolling each tile alone,
which is what those two numbers were always for: per-tile independence gives
speckle, and three passes of smoothing turn speckle into porridge — which is
why a terrain declared at under a tenth of a zone used to vanish entirely.

**The seams take care of themselves.** The cellular-automata smoothing already
runs across the whole zone, so it blurs subregion borders into each other —
the same job greeble does on a battlefield seam, for free, because the pass was
already there.

What this buys, beyond looking like a place:

- **Settlements can be placed sensibly.** A quota per subregion — this one has
  the town, that one has two hamlets — spreads them evenly without a spacing
  loop fighting itself, and a settlement can be put where its own subregion
  produces something.
- **Roads have something to connect.** Subregion centres are the natural nodes
  of a two-level network: within a subregion, and between neighbours.
- **The NPC schedule becomes legible.** A caravan travels from one subregion's
  town to its neighbour's, which is a route a player can learn and intercept.
- **Battlefields inherit it.** The battlefield generator samples the world map;
  subregions mean the sample varies by *place* rather than by noise, so a fight
  in the pine slopes looks different from one on the salt flats.

## Generating settlements, and the roads between them

Today the generator places `guaranteed_shops: [1, 2]` per zone from events
tagged `shop`. On a 192×192 map with three to five zones that is about five
shops in thirty-seven thousand tiles, each a template with no position of its
own — which is why the map has no places, only encounters.

What I would generate instead, per zone:

| Tier | Name | Per zone | Spacing | Wants |
|---|---|---|---|---|
| 3 | **Town** | 0–1 | ≥ 20 from another town | habitable ground, water or road nearby |
| 2 | **Village** | 1–2 | ≥ 10 | near what it produces |
| 1 | **Hamlet** | 2–4 | ≥ 6 | anywhere passable |

Roughly five to seven settlements a zone, fifteen to twenty-five a map: enough
for routes to exist, few enough that you learn their names. Tier decides what
the market holds, what the trainers there will teach, and how much stock the
place can absorb before its prices move — a hamlet is a bad place to sell forty
bales of anything.

**Placement follows production.** A village that produces ore wants to be on or
beside mountains; one that produces grain wants plains. So the settlement layer
reads the terrain the generator has already laid down, and the economy comes out
of the map rather than being sprinkled on top.

**Then roads, which should go somewhere.** `road_chance` currently scatters
road tiles at 3–6% per zone: texture, not infrastructure. Instead:

1. Connect the towns to each other with a least-cost path over terrain speed —
   roads follow the valleys, because that is what `speed` already says.
2. Connect each village to the nearest town or road, if it is within a
   reasonable distance.
3. Leave some hamlets unconnected on purpose. A road that reaches everywhere is
   a road that means nothing, and the unreached places are where the interesting
   prices are.

Roads already move the party at 2.0× speed, so a road network immediately
changes how travel feels — and it gives the trade layer something to price
against: the cheap route and the fast route stop being the same route.

## Who is on the roads

With settlements in places and roads between them, the friendly-NPC item in
TODO §2 stops being abstract. Three kinds, all of them moving:

- **Trader caravans** — a market that walks. A caravan carries goods from
  wherever it set out, so its prices are *that place's* prices: meeting one on
  the road is a chance to buy a distant market's cheap side without going
  there. It can be traded with, escorted, or robbed, and robbing it is the
  obvious way to be paid in cargo and karma both.
- **Travellers** — rumour. They know what a settlement two zones away is paying
  for grain, which is exactly the information `supply_and_demand` promises, and
  they will reveal a settlement you have not met.
- **Pilgrims** — going somewhere sacred, slowly, with nothing worth taking.
  Karma, blessings, and the occasional request. The realm decides who they are:
  hungry ghosts walk to water they cannot drink.

They spawn on roads between settlements and move along them, which means the
road network is also the NPC schedule. A caravan that left the ore town three
days ago is somewhere on the road to the grain town, and if you rob it the ore
town's prices notice.

## Where the two perks land

- **`supply_and_demand`** (Trade 5) becomes what its text says: it *reveals*
  the spread — the prices of goods at settlements you have visited — and
  improves the margin you realise. "Triple the difference" wants rereading
  against a fourfold spread; a better shape is that it pays you the *full*
  difference where an untrained trader realises a third of it, which is the
  same idea from the other end and cannot run away.
- **`investment`** (Trade 4) becomes buying into a settlement's production:
  gold in now, more gold later, scaled by the town's prosperity — and at risk
  from what happens to the town. It matures on the day tick whether or not you
  are there, which is the answer to the abandoned-realm question: portals are
  two-way, so it is always collectable, and collecting it is a reason to go
  back.

---

## What a region declares

*Added after review. Three things a region should say about itself that it
cannot say today: where it ends, how many people live in it, and what it makes.*

The vocabulary has three levels now, and the three questions land on different
ones — which is most of the answer:

| Level | What it is | Count |
|---|---|---|
| **Zone** (output as `regions`) | a band of rows/cols — `ocean`, `forest`, `meadow` | 3–5 per map |
| **Subregion** | a lattice cell, grown from a biome, with a seed and a name | 6–9 per zone |
| **Biome** | a *kind* of place, defined once, drawn on by any zone | 12 in `animal.json` |

### Borders

**A border is an edge, not a property of a region.** `"border": "mountains"` on
a region cannot say which side it is on, and two neighbours can disagree about
the thing between them. So a border is declared once, between two regions.

The mechanism already exists and is shipping: `mountain_wall` zones.
`coastal_wall` is rows 120–127 with 2–3 passes; `ridge` is cols 96–103 with 1–2.
A band of impassable terrain with a declared number of gaps, and
`_validate_connectivity` guarding the result. What it lacks is a *kind* — it can
only ever be mountains, so the Coral Barrier is a mountain range that has been
asked politely to read as coral.

Generalise the zone type to `border`, and let the kind supply the fill, the
thickness, and what the crossing is called:

| `kind` | Fill | Crossing | Thickness | Note |
|---|---|---|---|---|
| `mountains` | mountains | pass | 6–10 | what exists today |
| `reef` | water + sand | channel | 6–8 | the Coral Barrier, named honestly |
| `chasm` | lava | bridge | 2–4 | hell's own |
| `river` | water | ford / bridge | 1–3 | **needs new code** — a traced path, not a rect |
| `wall` | ruins | gate | 1–2 | somebody *built* it |
| `cliff` | mountains | stair | 2–3 | candidate for one-way |

```jsonc
{
  "id": "coastal_wall",
  "type": "border",
  "kind": "reef",
  "orientation": "horizontal",
  "rows": [120, 127],
  "display_name": "Coral Barrier",
  "crossings": [2, 3],            // was pass_count
  "crossing_width": 3,            // was pass_width
  "crossing_range": [0.15, 0.85], // was pass_range
  "toll": 0
}
```

Everything but `river` is the existing band mechanism with a different fill, so
the first phase is close to free: a rename, a defaults table, and the three
map configs updated. **The river is the one that costs real work**, because it
has to follow a subregion seam rather than sit in a row range — and it is also
the one that makes a map look like a map rather than like a diagram.

**The reason to do this beyond terrain.** A border is *trade friction*, and it
solves a problem this design otherwise has: two adjacent regions only hold
different prices if goods do not flow freely between them. Left alone, a price
index equalises across neighbours and flattens into the single price it was
built to replace. Permeability — crossings per unit of length, times any toll —
is exactly the term that stops that. It also turns "the unreached places are
where the interesting prices are" from an accident of the road roll into
something the map declares.

`wall` earns its place on lore alone. A wall implies a builder, a gate, a guard
and a toll: a price differential with a face on it, and an obvious hook for
both the karma system and a border-crossing event.

**One rule to hold: a border may never fully seal.** `_validate_connectivity`
checks only that the start can reach the portal, so a region could be walled off
entirely and the check would still pass. That wants to become *every region
reachable*, and it is one more check in `verify_map_regions`.

### How many people live here

Two declarations, because "how many" and "where" are different questions
answered at different levels.

**The zone says how many** — the quota from the settlement table above, made
explicit rather than implied:

```jsonc
"settlements": { "town": [0, 1], "village": [1, 2], "hamlet": [2, 4] }
```

**The biome says where they may land**, with one number:

```jsonc
"habitability": 0.0   // open_water — nobody lives here
"habitability": 0.6   // reef_flats — a fishing hamlet, at most
"habitability": 1.4   // watering_holes — everybody does
```

`habitability: 0` is the load-bearing case. After the terrain fix in `09e6be8`
the ocean zone is 73% water, so a placement rule that only checks passability
puts hamlets on rafts. One field forbids it without a special case per realm,
and the same field keeps villages off lava and out of the dust plains.

**The big town should be authored, not rolled.** `"town": [0, 1]` per zone means
a map can roll zero in every zone and have no town anywhere — a bad map that
only turns up by playing it, which is precisely the class of bug this realm has
been shipping. Each realm should declare one or two zones `"capital": true`,
and the rest roll. The big town is the place you route *through*; it belongs
with the portal and the boss as a fixed feature of the realm, not with the
scenery.

That is also where the best unclaimed idea in this memo pays off. If
`guild_max_tier` and `training.max_skill_level` become properties of a town
rather than a shop template, then the capital is the only place you can train
past a certain tier — and the journey to it is content rather than transit.

### What a region makes, and what it wants

There is a real tension to settle here. This memo derives production from
**terrain** — emergent, "map generation becomes the thing that lays out the
economy". The alternative is to **declare** it per region. The answer is both,
with terrain as the floor and the biome as the tilt:

```jsonc
"reef_flats": {
  "name": "The Reef Flats",
  "terrain_weights": { "5": 45, "12": 30, "0": 15, "3": 10 },
  "produces": { "fish": 2, "salt": 1 },         // ADDED to the terrain sum
  "wants":    { "grain": 1.5, "timber": 1.3 },  // demand multiplier
  "special":  "naga_pearl",
  "wealth":   1.1,
  "habitability": 0.6
}
```

**Keep terrain as the base, because it self-maintains.** If somebody rewrites a
zone's weights the economy follows them, and that is exactly the failure
`signature_terrain` was invented to catch after the animal realm generated a
mountainous ocean for months without anyone noticing. A declared-only economy
would have gone on paying for pearls from a reef that had become a mountain.

**Add the declaration, because fourteen terrain types cannot carry eight
goods.** Terrain has no way to say "salt flats", or that this particular reef
grows pearls and that one does not. `produces` is a *bonus on top of* the
terrain sum rather than a replacement, so the emergent layer keeps doing the
work and the declaration only says what terrain cannot.

Three specifics:

- **`wants` is the half that is missing.** The goods chart above has a real
  "Produced by" column and a hand-waving "Consumed by: everywhere inland" with
  no number behind it. Demand is what actually sets a price, and a route exists
  because somewhere *wants* the thing — so it should be data, at the same level
  as production.
- **`special` belongs on the biome, not the zone.** This memo assigns ash-iron
  to "the fire hells", which is a zone. But the point of a biome library is that
  a kind of place is defined once: pearls come from reefs, and reef is a biome.
  Moving it down also buys per-run variation — a map that rolled three reef
  subregions has cheap pearls this run, and that is a run worth telling someone
  about.
- **Wealth should be derived, with a declared floor.** `wealth` on the biome is
  a multiplier — 0.5 for an icy desert, 1.3 for a river valley — and a
  settlement's actual wealth is `biome wealth × tier × prosperity`, so
  `investment` has something to raise and a town can become richer than its
  ground. The floor is what stops a hamlet on an ore seam from outfitting a
  party better than a capital.

What wealth then buys is the concrete version of "better stuff in a wealthy
city": **stock depth** (how much the market absorbs before its prices move),
the **item tier ceiling** the shop will carry, the **training and guild caps**
that already exist on shop templates, and **whether the place brokers specials
at all** — a hamlet does not handle naga pearl.

### Two cautions on the numbers

**Multiplicative terms compound.** `wants` × `wealth` × `tier_multiplier` ×
`scarcity` is four multipliers on one price. Each is individually reasonable and
together they are how a 20× spread appears without anyone deciding on one. The
`scarcity` clamp of [0.5, 2.0] above is not enough on its own: the *total* ratio
between the cheapest and dearest market for a single good needs its own clamp,
asserted in a verifier rather than reasoned about.

**Wealth gating is progression gating.** If the wealthy town is also where
training uncaps, then wealth decides where progression happens, and the route to
the capital becomes the critical path. That is a defensible design — it gives
the map a spine — but it collides with the headline finding at the top of this
memo, and it should be chosen rather than discovered three systems later.

---

## Guard rails I would build in from the first commit

- **Stock depletion, always on.** The market answers back. This is the one that
  does most of the work.
- **Weight against carrying capacity.** A cargo is a thing you chose instead of
  something else.
- **Food on the road.** Already true; make the trade UI show it, so a route's
  profit is visibly net of its cost.
- **A clamped spread.** [0.5, 2.0] on scarcity, so no good is ever worth a
  fortune anywhere.
- **No arbitrage inside one settlement.** Buy and sell prices at one market
  must never cross, whatever the discounts stack to — this is the bug that
  ends economies, and it is one assertion in a verifier.
- **A clamp on the total ratio, not just each term.** `wants`, `wealth`,
  `tier_multiplier` and `scarcity` all multiply; four reasonable numbers make an
  unreasonable one. Assert the cheapest-to-dearest ratio for a single good
  directly, in the same verifier.
- **No region fully sealed.** A border must always leave a crossing, and
  `verify_map_regions` should check that every region is reachable — not just
  that the start can reach the portal, which is all `_validate_connectivity`
  asks today.

---

## What I need from you

1. **Does gold keep buying attribute points and skill levels?** Trainers sell
   them today, so a money press is a progression press. This decides how
   careful the rest has to be, and it is a question about what gold *is*.
2. **Are the eight staples the right eight, and are the specials the right
   ones?** The chart above is a first pass in your register; the names
   especially want your hand — *thal-lchags* for ash-iron is a guess at the
   compound.
3. **How much of the map layer do you want built with this?** The settlement
   and road generation is the biggest single piece and the one that changes how
   the game *feels* to travel through. It can be built first, alone, and would
   be worth having even if no trade good ever existed — or it can wait and the
   economy can start on the five shops per map that already exist.
4. **Do the three unbuilt realms get maps designed around this?** Human as the
   realm that makes things, God as the one that sells what cannot be grown
   elsewhere. If so, this design should land before those maps are written
   rather than after.
5. **Is the capital authored or rolled?** I argue above for authored — one or
   two `"capital": true` zones per realm — because a rolled town count can come
   up empty across a whole map. The cost is that every run of a realm has its
   big town in the same place, which is less surprising and more learnable.
   Which of those you want is a question about how much a realm should vary
   between reincarnations.
6. **Does wealth gate progression?** If training and guild caps become
   properties of a town, the rich town is where progression happens and the
   route to it is the critical path. That gives the map a spine and it
   sharpens question 1 rather than answering it.
