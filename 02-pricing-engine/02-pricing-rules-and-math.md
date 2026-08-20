# The pricing rules, step by step

**This is the specification. Emergent must implement it exactly.**

Every formula below was read off the live engine in
`apps/sales/src/pricing/lib/engine/`. The fully cited version, with a `file:line`
against every claim, is held outside this repository. Ask Pawel when you need to
check something.

Read `01-pricing-primer-plain-english.md` first if the vocabulary is new.

---

## Notation

Every formula uses these names. Keep them in the prototype's code too; it makes
the handoff conversation much shorter.

| Symbol | Meaning | Unit |
|---|---|---|
| `V` | Monthly volume | dollars per month |
| `T` | Average ticket | dollars |
| `C` | Transaction count — **derived**, `V ÷ T` | per month |
| `p` | The percentage leg of the rate being tested | decimal (0.0274 = 2.74%) |
| `f` | The per-item leg of the rate being tested | dollars |
| `m_b` | Share of volume in card bucket `b` | fraction, sums to 1 |
| `ic_b` | Interchange rate for bucket `b` | percentage + per item |
| `a` | Network assessments | 0.0014 |
| `buy` | The processor's buy rate | percentage + per item |
| `s` | Downgrade share | 0.075 |
| `u` | Downgrade uplift | 0.006 |
| `R` | Revenue share retained | 1.0 today |
| `F` | Direct monthly costs, outside the revenue share | dollars per month |

**Rates are always pairs.** A rate is a percentage *and* a per-item amount,
never one number. Model it as a two-field object everywhere.

---

## Step 0 — Resolve the inputs

1. Look up the vertical preset. An unknown key falls back to `ecommerce`.
2. Determine the processor: Elavon or QorPay.
3. On QorPay, pick the rate set by risk class — `lowRisk` or `highRisk`. Elavon
   has one set.
4. `C = T > 0 ? V / T : 0`. Never divide by zero anywhere; a zero ticket yields
   a zero count, not an error.

## Step 1 — Direct monthly costs

```
F = processor.perMerchantMonthly

if processor is QorPay:
    lossCost = (chargebackRateBps / 10000) × V × partnerLiabilityShare
             + C × occurrenceRatePerTxn × feePerOccurrence
    F = F + losses.flatMonthly + lossCost
```

With the shipped config, `chargebackRateBps` and `occurrenceRatePerTxn` are both
zero, so `lossCost` is zero and:

| Processor | `F` |
|---|---|
| Elavon | **$4.00** per month |
| QorPay, either risk class | **$28.90** per month ($13.90 + $15.00) |

Keep the loss terms in the formula even though they multiply out to zero. When
the real chargeback rate arrives it should be a config edit, not a rewrite.

> **Do not set Elavon's direct cost to zero.** Until 2026-07-29 this whole block
> sat inside an "if QorPay" branch, so Elavon's $4.00 never reached the math and
> every Elavon deal read better than it was — in exactly the comparison the tool
> exists to inform. That bug is fixed and guarded by a test. Do not reintroduce
> it.

## Step 2 — Price the card module

### 2a. Revenue

```
monthlyRevenue = p × V + f × C
```

Same expression for both pricing structures. Under interchange-plus this is only
our markup.

### 2b. Blend interchange and assessments across the card mix

```
blendedICA = Σ over buckets b of:
                m_b × ( ic_b.pct × V  +  ic_b.perItem × C  +  a × V )
```

Loop the five buckets in a fixed order and skip zero-weight ones. Because the
weights sum to 1, putting the assessments term inside the sum is arithmetically
the same as adding `a × V` once — either is fine.

### 2c. Cost — this is where the two pricing structures diverge

**Flat:**

```
buyCost      = buy.pct × V + buy.perItem × C
downgradable = 1 − mix.regulatedDebit
downgradeAdd = s × u × V × downgradable

monthlyCost       = blendedICA + buyCost + downgradeAdd
merchantGrossFees = monthlyRevenue
```

**Interchange-plus:**

```
monthlyCost       = buy.pct × V + buy.perItem × C      (buy rate only)
merchantGrossFees = monthlyRevenue + blendedICA        (markup + pass-through)
```

Two rules that are easy to get wrong and both are tested:

- **The downgrade cost exists only on the flat path.** Under interchange-plus
  the merchant absorbs interchange, downgrades included.
- **The downgrade applies only to the non-regulated-debit share.** Debit is
  capped by law and cannot fall into a pricier category.

`merchantGrossFees` is not cosmetic — it is the amount withheld before net
settlement reaches the FBO, so on interchange-plus it must include the
pass-through and not just our markup.

### 2d. Margins

```
grossMarginMonthly = monthlyRevenue − monthlyCost
monthlyNet         = R × grossMarginMonthly − F
marginPerTxn       = C > 0 ? monthlyNet / C : 0
marginBpsOnVolume  = V > 0 ? (monthlyNet / V) × 10000 : 0
```

**The order matters.** The revenue share multiplies the gross margin, *then*
direct costs are subtracted. Subtracting `F` before the split gives a different
and wrong answer.

### The single-transaction primitive

One transaction, one card type. This is the function the golden test grades.

```
revenue         = rate.pct × ticket + rate.perItem
interchangeCost = interchange.pct × ticket + interchange.perItem
assessmentsCost = assessmentsPct × ticket
buyCost         = buy.pct × ticket + buy.perItem
allInCost       = interchangeCost + assessmentsCost + buyCost
margin          = revenue − allInCost
```

Note there is **no downgrade term here.** The downgrade lives one layer up, in
the blend. Getting this wrong makes the golden table fail by a few cents.

## Step 3 — FBO, on QorPay only, automatically

Activated by the processor being QorPay. **There is no toggle.** Elavon settles
the merchant directly, so the module never appears.

```
settlementVolume = V − card.merchantGrossFees
legs             = batchLegsPerMonth            (44)
outboundLegs     = legs / 2                     (22)
perTxnFee        = tiered rate looked up on the LEG COUNT

monthlyCost    = perEndCustomerMonthly
               + legs × perTxnFee
               + outboundLegs × achOrigPerItem

monthlyRevenue = sell.monthlyPlatformFee
               + outboundLegs × sell.perTxnOut
               + (sell.fundsFlowBps / 10000) × settlementVolume
               + sell.floatSharePct × settlementVolume

monthlyNet     = monthlyRevenue − monthlyCost
```

The per-transaction tier resolves on the **leg count, not on dollars**. With 44
legs that lands in the $0.10 tier; only an implausible 600,000 legs would reach
$0.05.

The US Bank portfolio fixed costs — $5,250 a month plus a $10,000 implementation
— are **deliberately not allocated to any single deal.** Allocating them would
invert the health of every mid-size deal. They appear in the assumptions
footnote as a disclosure instead.

## Step 4 — Mass pay, on QorPay and only when toggled on

```
crossBorderCount  = payoutCount × crossBorderPct
domesticCount     = payoutCount − crossBorderCount
crossBorderVolume = crossBorderCount × avgPayoutSize

feeRevenue  = payoutCount × sell.perPayoutFee
fxRevenue   = crossBorderVolume × sell.fxSpreadPct

monthlyCost = domesticCount    × costPerPayoutDomestic
            + crossBorderCount × costPerPayoutCrossBorder
            + crossBorderVolume × fxCostPct

monthlyRevenue = feeRevenue + fxRevenue
monthlyNet     = monthlyRevenue − monthlyCost
```

**The ACH volume tier is resolved on the domestic count, not the total.**
Cross-border payouts ride SEPA or wire, not ACH, so counting them would buy a
cheaper tier the deal has not earned.

The sell fee applies to **every** payout while the cost splits by rail. That
asymmetry is deliberate.

## Step 5 — Line items (products and equipment)

**5a. Prune.** Drop rows whose catalogue id is unknown, and rows whose product
belongs to the other processor.

**5b. Inject required rows.** A card-not-present deal **on Elavon** requires the
gateway rows `UGWAY-M` and `UGWAY-T`. Card-not-present on QorPay requires
nothing, because that gateway is disabled.

If the rep already added a required row, leave their price alone and just mark
it required. If they did not, append it at quantity 1 on the default price.

Required rows are **derived at pricing time and never stored in the URL.**

**5c. Apply the cap.** The maximum is **12 rows** — and the cap applies to
non-required rows only. Required rows price on top of it, so a deal can carry 12
plus its required rows. Anything cut is reported, never dropped silently.

**5d. Price each row.**

```
months  = amortizeMonths > 0 ? amortizeMonths : 1
qty     = basis is "perTransaction" ? 1 : max(0, row.qty)
refusesWaive = (item.waivable is false) OR the row is required

unitSell:
    fixed-price product          → item.defaultSell, whatever the mode
    mode is "waived"             → refusesWaive ? item.defaultSell : 0
    mode is "custom"             → max(0, row.sellOverride ?? item.defaultSell)
    otherwise                    → item.defaultSell

driver depends on basis:
    "monthly"        → qty
    "oneTime"        → qty / months
    "perTransaction" → C          (the card module's count, not qty)

monthlySell   = unitSell × driver
monthlyBuy    = item.buy × driver
monthlyMargin = monthlySell − monthlyBuy
```

**A custom price of exactly $0 is a real quote and must stay $0.** It is
different from "no override was given". Use a null-check, not a truthiness
check — this is a classic place to introduce a silent bug.

Three violations are flagged rather than silently corrected:

| Violation | When |
|---|---|
| Fixed price | A fixed-price product with any mode other than default |
| Not waivable | A non-waivable or required row set to waived |
| Above ceiling | A custom price above the product's maximum |

## Step 6 — Stack the modules

```
monthlyNet = card.monthlyNet
           + (fbo?.monthlyNet ?? 0)
           + (massPay?.monthlyNet ?? 0)
           + (lineItems?.monthlyNet ?? 0)

annualNet  = monthlyNet × 12
```

## Step 7 — Name what is dragging the deal down

If the all-in health ranks worse than the card health, find every loss-making
source — each line-item row with a negative margin, the FBO if its net is
negative, mass pay if its net is negative — sort them worst-first, and name the
worst one in a sentence:

> "Terminal rental costs $8,000/mo and is not charged — the card module carries
> it."

This is one of the most useful things on the screen. Do not drop it.

## Step 8 — Solve for the minimum rate

**What it answers:** the lowest percentage leg that still clears the margin
floor, holding the per-item leg at whatever the rep typed.

**Method: closed form, one division. Not iteration.**

Every cost term is independent of our percentage leg — interchange, assessments,
buy rates and the downgrade uplift are all set by schedules and volume, never by
what we charge. So price the deal once at a 0% rate, read the monthly cost off
that run, and solve directly.

```
if V ≤ 0 or T ≤ 0 or R ≤ 0:  return null      (no solve, never divide by zero)

C            = V / T
f            = the tested per-item leg, held fixed
M_proc       = monthlyCost when priced at 0% + f
floorDollars = (floorBps / 10000) × V  +  floorPerItem × C
F            = direct monthly costs

minRatePct   = ( (floorDollars + F) / R  +  M_proc  −  f × C ) / V
return max(0, minRatePct)
```

Reusing the same pricing function for `M_proc` is the point: the solve can never
drift away from the forward price. Build it the same way.

**The floor has two legs**: 35 basis points on volume **plus** $0.10 per item.
Both come from Jodi Durst's decision of 2026-07-15 and both are real values, not
placeholders.

Round-trip property, and a good self-test: pricing at the solved rate retains
*exactly* the floor.

Two derived flags:

```
belowFloor  = solved !== null AND testedRate < solved
gtmDeltaBps = (testedRate − 0.0274) × 10000
```

## Step 9 — The health light

```
retainedBps < 0    → red
retainedBps < 10   → yellow
otherwise          → green
```

Exactly 0 bps is yellow. Exactly 10 bps is green.

**Graded on the card module alone.** Module stacking never repaints it. The
all-in light sits *beside* it, never instead of it — a profitable side module
must not hide an underwater card rate.

## Step 10 — The HubSpot payload

```
dealAmount        = annualNet                  (all modules)
monthlyNetRevenue = monthlyNet
marginBps         = card.marginBpsOnVolume     (the CARD figure only)
processor         = "elavon" | "qorpay"
pricingType       = "flat" | "interchangePlus"
quotedRate        = "2.74% + $0.30"
```

Note the deliberate asymmetry: `dealAmount` is all-in, `marginBps` is
card-only. Label them clearly on screen so nobody compares them as if they had
the same basis.

`quotedRate` uses plain two-decimal formatting with **no thousands separators**.

## Step 11 — The assumptions footnote

Always four lines, always in this order, always visible:

1. **Card mix** — the preset label and its bucket percentages, zero-weight
   buckets omitted, rounded to whole percent.
2. **Downgrade assumption** — "7.50% of non-regulated-debit volume at +0.60%
   (placeholder midpoints)".
3. **Buy rates** — which signed schedule, plus the config version.
4. **Margin floor** — "35 bps on volume + $0.10/item (Jodi 2026-07-15)".

Then conditional lines: QorPay or Elavon direct costs, FBO batch legs and the
unallocated portfolio cost, mass pay's illustrative sell side and its expired
quote date, the products row count, the required-gateway note, the amortisation
note, and the QorPay annual minimum.

**Every number on the screen must be traceable to this footnote.** It is what
makes a quote auditable, and it is the reason anyone trusts the tool.

---

## Rounding and precision

| Rule | Detail |
|---|---|
| **Nothing rounds inside the math** | Plain floating-point dollars end to end. Round only when displaying. |
| **The minimum rate rounds UP** | Deliberately, so a displayed floor is never below the true floor. Rounding it down would let a rep concede a rate the deal cannot carry. |
| **Percentages are decimals internally** | 2.74% is `0.0274`, never `2.74`. |
| **Basis points are integers on display** | `(x / V) × 10000`. |
| **Money is not stored in integer cents** | The engine uses floats. Match it, so your numbers match. |
| **Currency is USD only** | There is no multi-currency support and none is planned. |

## Guards the prototype must reproduce

| Situation | Behaviour |
|---|---|
| Volume is zero | No solve; results show "enter deal size". No divide by zero. |
| Ticket is zero | Count is zero. No divide by zero. |
| Unknown vertical in a URL | **The whole quote is nulled.** Fail loud. |
| Unknown product SKU in a URL | **Silently dropped.** Fail quiet. |
| Solved rate is negative | Clamp to 0.00% and annotate. |
| More than 12 non-required rows | Cut the excess and report which. |
| Custom price above a ceiling | Flag a violation; do not silently clamp. |

The vertical and SKU policies are opposite on purpose. A wrong vertical means
the whole card mix is wrong and every number below it is meaningless. A retired
SKU just means one line no longer exists.

---

## Deliberately not in scope

Do not add any of these to the prototype. Each was checked and confirmed absent
from the real engine:

Server-side pricing · saved quotes in a database · PDF or proposal export ·
writing back to HubSpot · any currency but USD · a tax or surcharge module ·
the customer-tier engine · editing card mixes from the UI · any iterative solver
· a third processor.

If you want one of these, that is a **product proposal**, not a prototype
change. Flag it in your handoff as an open question.
