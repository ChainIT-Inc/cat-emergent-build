# Payments pricing, in plain English

**Read this before you touch the Pricing screens.** You do not need a payments
background, but you do need these eight ideas. Everything the engine does is a
combination of them.

Sources for this file: the approved engine design spec
(`.planning/chainit-pay-pricing-engine/DESIGN-SPEC.md` in the ChainIT-Hub repo),
Jodi Durst's *ChainIT Pay Pricing Engine Guide and Build Spec*, and the
Confluence page *Workflow Execution Process (ChainIT Pay money flow)*.
**Jodi's document wins on any conflict.**

---

## 1. What ChainIT Pay actually sells

We sit in the middle of a card transaction.

A shopper pays a merchant. That money passes through a processor. We resell that
processor's service to the merchant at our own price, and we keep the
difference.

```
Shopper ──pays──▶ Merchant ──▶ [ ChainIT Pay ] ──▶ Processor ──▶ Card networks
                                     │
                              we keep the gap
```

Two prices matter, and the whole tool exists to compare them:

- **Buy rate** — what the processor charges *us*.
- **Sell rate** — what we charge *the merchant*.

**Margin = sell − buy.** That is it. Everything else is detail about how to
compute each side accurately.

## 2. Why a rate is always two numbers

Card pricing is never a single percentage. It is always a percentage **plus a
flat amount per transaction**.

> **2.74% + $0.30**

On a $100 sale that is $2.74 + $0.30 = **$3.04**.

This matters more than it looks. On a $5 coffee, the $0.30 dominates. On a
$5,000 invoice, the 2.74% dominates. A merchant selling coffee and a merchant
selling furniture need different pricing even at the same monthly volume, which
is why the tool asks for **average ticket** and not just volume.

Vocabulary you will see on screen:

| Term | Means |
|---|---|
| **Volume** | Total dollars processed, usually per month |
| **Ticket** | The average size of a single sale |
| **Count** | Number of transactions = volume ÷ ticket |
| **Per-item** / **per-txn** | The flat cents part of a rate |
| **bps** (basis points) | Hundredths of a percent. 43 bps = 0.43% |

## 3. Interchange — the cost we do not control

Most of what a card transaction costs is **interchange**: a fee set by Visa and
Mastercard that goes to the shopper's bank. Nobody negotiates it. It is a
published table.

The critical fact: **interchange is not one number.** It depends on what kind of
card was tapped.

| Card type | Roughly costs | Why |
|---|---|---|
| Regulated debit | 0.05% + $0.21 | Capped by law (the Durbin amendment) |
| Standard consumer credit | ~1.51% + $0.10 | The ordinary case |
| Premium rewards credit | ~2.20% + $0.10 | The bank funds the cardholder's points |
| Corporate card | ~2.95% + $0.10 | Business cards cost more |
| Business, card-not-present | ~3.15% + $0.20 | No physical card present raises risk |

A merchant taking mostly regulated debit is cheap for us to serve. A merchant
taking mostly corporate cards over the phone is expensive — and at the same
2.74% sell rate we might **lose money on them**.

That is the single most important thing this tool tells a rep.

On top of interchange sit **assessments** — a smaller network fee, about 0.14%
of the amount. Treat it as part of the cost.

## 4. Card mix and blending

Since every card type costs differently, we need to know **what mix of cards a
merchant actually takes**. A restaurant's mix is not a B2B software company's
mix.

The engine holds a card mix per **vertical** (restaurant, e-commerce, B2B
services, and so on). To price a deal it:

1. Works out the all-in cost for each card type;
2. Weights each by that vertical's share of volume;
3. Adds them up.

The result is the **blended cost** — one number standing in for the whole mix.

> **Blending** = a weighted average of the card-type costs, using the vertical's
> card mix as the weights.

If you change a vertical's mix in Configure, every deal priced against that
vertical moves. That is a high-blast-radius change; note it in your handoff.

## 5. Downgrades

A share of transactions fail to qualify for the rate they should have got —
missing data, a late settlement, a keyed-in card. They "downgrade" to a more
expensive category.

This is normal and unavoidable, and typically hits **5–10% of volume** at an
extra **0.40–1.00%**.

The engine models it as an added cost:

```
downgrade cost = share of volume that downgrades
               × the extra percentage it costs
               × volume
```

Defaults in the config sit at the middle of those ranges (about 7.5% share,
about 0.60% uplift), and they are tunable.

**Leaving downgrades out overstates our margin.** If you ever see a margin
number that looks better than you expected, this is the first thing to check.

## 6. The two ways we can price a merchant

**Flat (the default go-to-market shape).** We quote one rate — say 2.74% + $0.30
— and absorb the variation. Simple for the merchant, riskier for us, because a
bad card mix eats the margin.

```
revenue = rate% × volume + per-item × count
margin  = revenue − blended cost
```

**Interchange-plus.** Interchange passes straight through to the merchant and we
add a fixed markup on top. Transparent, and our margin is stable regardless of
card mix.

```
revenue = markup% × volume + per-item × count
margin  = markup − buy rate
```

A rep picks the structure per deal. The tool prices both honestly.

## 7. Two processors, two economics

ChainIT runs **both** processors. The processor is an input on the deal, not a
company-wide decision.

**Elavon** (through Durst Holdings) — a traditional acquiring relationship. Very
low cost per transaction, and $4.00 a month per merchant in fixed fees.

**QorPay** — a payments-facilitator arrangement. Higher cost per transaction, and
$28.90 a month per merchant once its fixed fees and loss allowance are counted.

One wrinkle applies to both: the **authorisation fee is charged on every attempt
including declines.** Roughly 3% of attempts decline, so the real cost per
*approved* transaction is the schedule fee divided by 0.97. The engine bakes this
into the buy rate.

### Risk class changes the cost, not the split

A QorPay merchant is either **low risk** or **high risk**, and the difference is
large:

| | Low risk | High risk |
|---|---|---|
| Percentage of volume | 0.0275% | **0.35%** — about 13× |
| Per transaction | about $0.041 | about $0.113 |

There is also a **revenue share** — the fraction of the margin we keep — and it
is a real concept you will see in the code and the documents. But be careful
with it:

> **Today the revenue share is 100% on every live processor path.** Elavon
> Schedule A, QorPay low risk and QorPay high risk are all 1.00.

Some older design documents describe a 60% share on high-risk QorPay. That was
superseded and is **not** what the engine does. The only sub-100% value in the
configuration belongs to an alternative Elavon schedule that ships switched off.

So when a rep marks a merchant high risk, the deal gets worse because our **cost
of goods** went up — not because someone took a cut.

## 8. The three modules

A deal can involve up to three separate businesses, and the tool prices each
independently, then sums whichever are active.

| Module | What it is | How it earns |
|---|---|---|
| **Card** | Accepting card payments | The margin described above |
| **FBO** | A "for benefit of" account — we hold funds on the merchant's behalf and pay out to their sellers | Monthly platform fees plus a per-payout rail cost |
| **Mass pay** | Paying many recipients at once | A fee per payout, varying by rail |

"Rail" means the pipe money travels down, and each costs differently: ACH is
cheapest (around $0.17–0.20), RTP and FedNow are instant and cost more, a wire is
the most expensive, push-to-card sits in between.

FBO also carries fixed monthly costs — a maintenance fee, a reporting fee, and a
one-time implementation charge — which have to be earned back before the module
is profitable. A small FBO deal can be **worth less than nothing**, and the tool
should say so.

---

## What a completed money flow looks like

From the Confluence page, this is a real worked example of a $110 sale moving
through ChainIT Pay. It is useful for grounding what all this is ultimately for.

A shopper pays **$110** — a $100 item, $5 tax, $5 shipping.

Money goes out immediately:

| Recipient | Amount | Rail |
|---|---|---|
| ChainIT Pay's cut | $3.30 (3% of $110) | Instant (RTP) |
| Sales tax | $5.00 | Instant (RTP) |
| Shipping | $5.00 | ACH, 1–2 days |

And the rest is held until the product is marked delivered:

| Recipient | Amount |
|---|---|
| ChainIT X platform fee | $6.00 (6% of the $100 item) |
| Creator royalty | $2.00 |
| Seller | $87.70 |

$87.70 + $5 + $5 + $6 + $2 = **$106.70**, plus our $3.30 = $110. Nothing is lost.

The pricing tool is upstream of this. It answers: *given what this merchant
sells and how much, what should we charge them, and do we make money?*

---

## The five questions the tool answers

Every screen exists to answer one of these. If a design change makes one of them
harder to answer, it is the wrong change.

1. **What do we charge this merchant?**
2. **What do we make on it?** (in dollars and in basis points)
3. **Is this a good deal?** — the health light: green, amber, red.
4. **What is the lowest rate this deal still supports?** — the floor, for when a
   rep is being pushed on price.
5. **What number goes into HubSpot?**

---

## Glossary, alphabetical

| Term | Plain English |
|---|---|
| **Assessments** | A network fee on top of interchange, about 0.14% |
| **Auth fee** | Charged per authorisation attempt, declines included |
| **Basis point (bps)** | One hundredth of a percent |
| **Blended rate** | The weighted-average cost across a vertical's card mix |
| **Buy rate** | What the processor charges us |
| **Card mix** | The share of volume by card type, per vertical |
| **Config revision** | A saved, versioned snapshot of every rate and default |
| **Downgrade** | A transaction that fails to qualify and costs more |
| **FBO** | "For benefit of" — an account we hold funds in for a merchant |
| **Floor** | The lowest sell rate a deal can bear and stay viable |
| **Interchange** | The fee going to the shopper's bank; set by the networks |
| **Interchange-plus** | Pass interchange through, add a fixed markup |
| **Ladder** | The visual showing how margin moves as the rate moves |
| **Line item** | One priced component of a deal |
| **Margin** | Sell minus buy — what we keep |
| **Mass pay** | Paying many recipients in one batch |
| **Per-item** | The flat cents part of a rate |
| **Rail** | The payment pipe: ACH, RTP, FedNow, wire, push-to-card |
| **Revenue share** | The fraction of margin we keep. 100% on every live path today |
| **Risk class** | Low-risk or high-risk; on QorPay it selects the buy rate |
| **Sell rate** | What we charge the merchant |
| **Ticket** | Average size of one sale |
| **Vertical** | The merchant's industry; selects the card mix |
| **Volume** | Dollars processed, per month |
