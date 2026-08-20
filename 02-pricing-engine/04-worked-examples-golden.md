# Worked examples — the numbers the rebuild must reproduce

**This file is the regression test.** If the Emergent prototype computes these
numbers, its pricing engine is correct. If it does not, it is wrong — do not
adjust the expected values to match the prototype.

Every example below was lifted from the real engine's test suite in
`apps/sales/src/pricing/lib/engine/`, and the formulas were read off the
implementation, not inferred.

Ask Emergent to print its output next to the expected column, as a table, every
time you change a pricing rule.

---

## Example 1 — the golden table

**Source:** `src/pricing/lib/engine/card.golden.test.ts:1-90`.

This is the validation gate Jodi Durst set. It was required to pass before
anything else in the engine was built, and it still guards the primitive that
everything else calls.

### The scenario

One transaction. A **$100 ticket** priced at ChainIT's standard go-to-market
flat rate of **2.74% + $0.30**.

The buy rate here is a deliberate **placeholder** of 0.10% + $0.05, which comes
to $0.15 on a $100 ticket. That is not our real cost — production uses the real
Elavon and QorPay schedules — but it is the number Jodi's table was built on, so
the test uses it to reproduce her table exactly.

Network assessments are **0.14% of the amount**, so $0.14 on $100.

### The four card types and their interchange

| Card type | Interchange rate | On $100 |
|---|---|---|
| Regulated debit | 0.05% + $0.21 | $0.26 |
| Standard consumer credit | 1.51% + $0.10 | $1.61 |
| Premium rewards credit | 2.20% + $0.10 | $2.30 |
| Corporate, card-not-present | 2.75% + $0.10 | $2.85 |

### The arithmetic

Revenue is the same for all four, because a flat rate does not care what card
was used:

```
revenue = 2.74% × $100 + $0.30
        = $2.74 + $0.30
        = $3.04
```

Cost differs by card type:

```
all-in cost = interchange + assessments + buy rate
margin      = revenue − all-in cost
```

### The expected output — must match within one cent

| Card type | Revenue | Interchange | Assessments | Buy | All-in cost | **Margin** |
|---|---|---|---|---|---|---|
| Regulated debit | $3.04 | $0.26 | $0.14 | $0.15 | $0.55 | **$2.49** |
| Standard consumer credit | $3.04 | $1.61 | $0.14 | $0.15 | $1.90 | **$1.14** |
| Premium rewards credit | $3.04 | $2.30 | $0.14 | $0.15 | $2.59 | **$0.45** |
| Corporate, card-not-present | $3.04 | $2.85 | $0.14 | $0.15 | $3.14 | **−$0.10** |

### What this example is telling you

The last row is the entire reason the tool exists. **At our standard rate, a
corporate card-not-present transaction loses us ten cents.** A merchant whose
volume skews that way is unprofitable at the rate a rep would quote by default,
and nobody could see that before this tool existed.

One caveat worth carrying: on our *real* buy rates — around $0.05 rather than
the $0.15 placeholder — that row lands near breakeven instead of at −$0.10. The
placeholder overstates the problem. The direction is right; the magnitude
depends on which processor schedule is loaded.

---

## Example 2 — downgrades do not touch the golden numbers

**Source:** `src/pricing/lib/engine/card.ts:76-110` and
`card.downgrade.test.ts`.

The golden table has **no downgrade cost in it**, and that is deliberate. The
downgrade uplift is applied one layer higher up, when per-card-type economics
are blended across a merchant's card mix.

So two things are true at once:

- `bucketEconomics()` — one transaction, one card type — reproduces the golden
  margins exactly.
- `priceCard()` — a whole merchant, blended across a mix — reproduces those same
  margins **only when the downgrade share is set to zero**.

If your prototype's single-transaction numbers are slightly worse than the
golden table, you have almost certainly applied the downgrade cost at the wrong
layer.

### The downgrade formula

```
downgrade cost = share × uplift × monthly volume × (1 − regulated-debit share)
```

Defaults: share **7.5%**, uplift **0.60%**.

Two things about that formula matter and are easy to get wrong:

1. **It excludes regulated debit.** Debit is capped by law and cannot fall into
   a more expensive category, so the uplift applies only to the rest of the
   volume. Multiplying by the whole volume overstates cost.
2. **It applies to flat pricing only.** Under interchange-plus the merchant
   already absorbs interchange, downgrades included, so our markup margin is
   untouched. Applying it on the interchange-plus path is a bug.

---

## Example 3 — flat versus interchange-plus, same merchant

**Source:** `src/pricing/lib/engine/card.ts:74-125`.

A merchant with **$500,000** monthly volume and a **$100** average ticket, so
5,000 transactions a month.

### Flat pricing at 2.74% + $0.30

```
revenue      = 2.74% × 500,000 + $0.30 × 5,000
             = $13,700 + $1,500
             = $15,200

cost         = blended interchange and assessments across the card mix
             + buy rate on volume and count
             + downgrade uplift

gross margin = revenue − cost
```

The merchant's cost of acceptance is exactly our revenue: **$15,200**. Under flat
pricing there is nothing else for them to pay.

### Interchange-plus at a 0.45% + $0.10 markup

```
our revenue  = 0.45% × 500,000 + $0.10 × 5,000
             = $2,250 + $500
             = $2,750

our cost     = buy rate only  (interchange passes through)
our margin   = $2,750 − buy cost

what the merchant pays = our markup + the interchange and assessments
                         that passed through
```

The structural difference to hold onto: **under flat, a bad card mix is our
problem. Under interchange-plus, it is the merchant's.** Our margin under
interchange-plus barely moves regardless of what cards they take.

---

## Example 4 — revenue share, direct costs, and what "high risk" actually changes

**Source:** `card.ts:120-126`, `config.ts:76-152`.

The net we keep is not the gross margin:

```
monthly net = revenue share × gross margin − direct monthly costs
```

### The revenue share is 1.00 everywhere today

This is the most commonly mis-stated fact in this engine, so it gets its own
heading.

| Processor and risk class | Revenue share in the shipped config |
|---|---|
| Elavon, Schedule A | **1.00** |
| QorPay, low risk | **1.00** |
| QorPay, high risk | **1.00** |

An earlier design document described a **0.60** share on high-risk QorPay. The
shipped configuration does not implement that — `revShare` is `1` on both QorPay
risk classes (`config.ts:110` and `config.ts:118`). A sub-1.0 share exists in the
code only for **Elavon Schedule B**, which ships **disabled** pending a decision
(`config.ts:99-102`).

If the prototype applies a 0.60 share anywhere, it is wrong.

### What high risk actually changes: the buy rate

Risk class selects a different cost of goods, not a different split.

| | Low risk | High risk |
|---|---|---|
| Percentage of volume | 0.0275% | **0.35%** |
| Per item | $0.03 ÷ 0.97 + $0.01 AVS ≈ $0.0409 | $0.10 ÷ 0.97 + $0.01 AVS ≈ $0.1131 |

On $500,000 of monthly volume at a $100 ticket, that is a buy-cost difference of
roughly `(0.0035 − 0.000275) × 500,000 + (0.1131 − 0.0409) × 5,000`, about
**$1,974 a month**. The economics move a lot; they just move through cost, not
through a split.

The `÷ 0.97` is the decline gross-up: authorisation fees are charged on every
attempt, declines included, so the billable count is about 3% higher than the
approved count.

### Direct monthly costs sit outside the share

Per-merchant fixed costs are billed to us directly and come off after the split:

| Processor | Per-merchant monthly | What it is |
|---|---|---|
| Elavon | **$4.00** | $2.00 customer service + $2.00 monthly, per MID |
| QorPay, either risk | **$13.90** | Merchant monthly, partner reporting, PCI, batch headers |

QorPay also carries a **flat $15.00 monthly loss allowance**
(`config.ts:135-141`). The chargeback-rate model behind it is present in the code
but multiplied by zero, because the real chargeback rate is unknown — the terms
are kept so a future number is a config edit rather than a rebuild.

**Elavon is not free.** It was modelled at $0 until 2026-07-29, which silently
flattered every Elavon deal against QorPay. That is fixed; do not re-introduce
it.

### Putting it together

A low-risk QorPay merchant with $2,000 of gross margin nets
`1.00 × 2,000 − 13.90 − 15.00 = $1,971.10`.

The same merchant on Elavon nets `1.00 × 2,000 − 4.00 = $1,996.00` — but on a
different, lower buy rate, so the gross margin would not have been $2,000 in the
first place. Compare the two processors end to end, never on one line.

---

## Example 5 — the minimum rate

**Source:** `src/pricing/lib/engine/solve.ts`, and DESIGN-SPEC §10.2.

This is the headline number on the screen — the lowest rate a deal can bear and
still clear the margin floor. It is what a rep looks at when a customer pushes
back on price.

For flat pricing, holding the per-item leg fixed and solving the percentage leg:

```
                (floor$ + F) / revShare  +  Mproc  −  p × C
minimum rate = ─────────────────────────────────────────────
                                    V
```

| Symbol | Meaning |
|---|---|
| `floor$` | The margin floor in dollars — **two legs**, see below |
| `F` | Direct monthly fixed costs, outside the revenue share |
| `revShare` | 1.00 today on every live processor path |
| `Mproc` | Monthly processing cost, including the downgrade add |
| `p` | The per-item leg of the tested rate |
| `C` | Transaction count = V ÷ average ticket |
| `V` | Monthly volume |

### The floor has two legs, not one

This is the detail most likely to be got wrong. Jodi set the approval floor on
2026-07-15 as a percentage **plus** a flat per-transaction amount:

```
floor$ = (floorBps / 10000) × V  +  floorPerItem × C
```

| Config value | Shipped default |
|---|---|
| `marginFloorBps` | **35** basis points on volume |
| `marginFloorPerItem` | **$0.10** per item |

Both are tagged `real` in the config's provenance map, sourced to that meeting —
they are **not** placeholders. An earlier design document proposed a single
25 bps floor with no per-item leg; that was superseded. If the prototype uses
25 bps, or omits the per-item leg, it will quote a floor that is too low, and
"too low" here means a rep can concede a rate the deal cannot carry.

### How the implementation avoids drift

The engine does not re-derive `Mproc` symbolically. It prices the deal once at a
**0% rate** and reads the cost off that run — cost terms do not depend on our
sell rate, so `monthlyCost(0)` is exactly `Mproc`. One cost path serves both the
forward price and the reverse solve, so the two can never disagree.

Worth reproducing in the prototype for the same reason.

### Where the revenue share sits

The floor and the direct costs are **divided** by the revenue share. If a
sub-1.0 share is ever enabled, that deal will need a *higher* rate to clear the
same retained floor. Counter-intuitive, and correct. Today every live path runs
at 1.00, so the division is a no-op — but keep the term.

### The edge cases the prototype must handle

| Situation | Correct behaviour |
|---|---|
| Volume or ticket is zero | No solve. Show "enter deal size". Never divide by zero. |
| The solved rate is negative | Clamp to 0.00% and annotate it — the per-item revenue alone clears the floor |
| The solved rate exceeds the tested rate | The deal is below floor. Say so plainly, in words. |
| The solved rate exceeds our standard rate | Show it anyway. That is the insight, not an error. |

---

## Example 6 — the health light

**Source:** DESIGN-SPEC §10.2.

Graded on the **card module's retained margin** in basis points on volume —
after the revenue share, and after direct fixed costs.

| Verdict | Condition |
|---|---|
| **Red** | Retained margin below 0 bps — we lose money at this rate |
| **Amber** | 0 to 10 bps — technically positive, uncomfortably thin |
| **Green** | 10 bps or more |

Two rules that are easy to get wrong:

1. **The light is card-based only.** A profitable FBO or mass-pay leg must never
   repaint it green. The question the light answers is "is the card rate
   underwater for this vertical", and a rich side module masking that would be
   actively misleading.
2. **It grades the retained margin, not the gross.** A high-risk QorPay deal can
   be green on gross and amber on retained. Retained is what we keep.

---

## Example 7 — the sanity check

**Source:** DESIGN-SPEC §10.1.

A normal e-commerce card mix, priced at 2.74% + $0.30, should land in the
neighbourhood of a **43 basis point** gross spread plus about **5 cents** an
item, against an industry benchmark of roughly 2.31% + $0.25.

```
2.74% − 2.31% = 0.43% = 43 bps
$0.30 − $0.25 = $0.05
```

**Treat this as a neighbourhood check, not an equality test.** Our five-bucket
blend is not the industry's flat constant, and the downgrade uplift moves the
spread by four or five basis points on its own. The real engine tests that the
blended margin lands somewhere in a generous 25 to 60 bps band.

Jodi's actual intent, in her words: if the number is wildly above or below,
check the math.

---

## How to use this file with Emergent

After any pricing change, paste this:

```text
Re-run these worked examples against your current implementation and show me a
table with three columns: the example, your computed value, and the expected
value from the worked-examples document. Flag every row that disagrees by more
than one cent. Do not change any expected value to make a row pass — if
something disagrees, show me your calculation step by step instead.
```

Then put the resulting table in your handoff. That table is what lets an
engineer implement your change without re-deriving your reasoning.
