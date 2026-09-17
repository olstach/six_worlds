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

---

## What I need from you

1. **Does gold keep buying attribute points and skill levels?** This decides
   how careful the rest has to be.
2. **How far does trade go?** A light version — prices differ by place, the two
   perks work, no cargo — is layers 1, 2 and 5 and is genuinely useful. The
   full version adds goods you carry and routes you learn. Both are coherent;
   the light one is perhaps a third of the work.
3. **Is a settlement a shop with a position, or a shop *inside* a settlement?**
   I would build the second — a town holds a market, a trainer, a temple — but
   it means the nine `town` shop definitions become settlement templates, and
   that is a data migration you may want to write yourself.
