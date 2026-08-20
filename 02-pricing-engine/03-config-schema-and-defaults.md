# The configuration — every value, its unit, and its default

This is what the **Configure** tab edits, and it is where every number in a quote
ultimately comes from.

Two separate things are in play:

1. **The bundled config** — a frozen set of defaults shipped with the app.
2. **Saved overrides** — a short list of values a Config editor may change,
   stored as numbered revisions.

The config a rep actually prices on is the bundled defaults with the latest
saved overrides merged on top.

Current bundled version: **`2026-08-04`**.

A fully cited version, with `file:line` on every value, is held outside this
repository. Ask Pawel.

---

## Units — read this before anything else

Getting a unit wrong here produces a plausible-looking quote that is off by a
factor of 100. It is the single most dangerous thing in the whole engine.

| Kind | How it is stored | Example |
|---|---|---|
| **Percentages** | Decimal fraction, everywhere | 2.74% is `0.0274`, never `2.74` |
| **Basis points** | Whole integers | 35 bps is `35`; divide by 10,000 at point of use |
| **Money** | Plain dollars as floating point | `13.90`. **Not** integer cents. |
| **Shares and weights** | Fractions from 0 to 1 | A 7.5% share is `0.075` |
| **Months** | Whole numbers | `12` |

Only three values in the entire config are in basis points: the margin floor,
the two health thresholds, and the FBO funds-flow rate. Everything else that
looks like a percentage is a decimal fraction.

---

## Provenance — every value is tagged

Each numeric value carries one of three tags, and the tag drives what the UI
shows next to it:

| Tag | Meaning | Count |
|---|---|---|
| **real** | From a signed schedule, the PRD, or a recorded decision | most |
| **placeholder** | Our estimate, awaiting Jodi's real number | 7 |
| **illustrative** | Sell-side price we invented for the demo; badged in the UI | 6 |

98 values are tagged, and a test fails the build if any new value ships
untagged. That mechanism is worth reproducing: it is what stops a made-up number
quietly becoming a real one.

**The placeholders:** the downgrade share and uplift, the amortisation window,
the FBO batch-leg count, and all four verticals' typical-ticket hints.

**The illustratives — worth knowing:** *every* sell-side price for FBO and mass
pay is invented. We know what those modules cost us; we have not been told what
we charge for them. Those output blocks are badged in the UI and should stay
badged in the prototype.

---

## Top-level values

| Key | Default | Unit | What it is |
|---|---|---|---|
| `version` | `"2026-08-04"` | date string | Bump on any value change |
| `assessmentsPct` | `0.0014` | fraction of volume | Network assessments, 0.14% |
| `marginFloorBps` | **`35`** | basis points on volume | The approval floor, first leg |
| `marginFloorPerItem` | **`0.10`** | dollars per transaction | The approval floor, second leg |
| `healthThresholds.yellowBps` | `0` | basis points | Below this is red |
| `healthThresholds.greenBps` | `10` | basis points | At or above this is green |
| `lineItems.amortizeMonths` | `12` | months | One-time costs spread over this |

Both margin-floor values come from Jodi Durst's decision of 2026-07-15 and are
tagged **real**. Earlier drafts used a single 25 bps floor with no per-item leg —
that is superseded and wrong.

### Reference rates

| Key | Percentage | Per item | What it is |
|---|---|---|---|
| `gtmAnchor` | `0.0274` (2.74%) | `$0.30` | Our standard go-to-market rate; the default a rep starts from |
| `industryBenchmark` | `0.0231` (2.31%) | `$0.25` | The market comparison for the sanity check |

---

## The five interchange buckets

Percentages are decimal fractions; the last column shows what each costs on a
$100 ticket.

| Bucket | Percentage | Per item | On $100 |
|---|---|---|---|
| `regulatedDebit` | `0.0005` (0.05%) | `$0.21` | $0.26 |
| `unregulatedDebit` | `0.0080` (0.80%) | `$0.15` | $0.95 |
| `standardCredit` | `0.0151` (1.51%) | `$0.10` | $1.61 |
| `premiumCredit` | `0.0220` (2.20%) | `$0.10` | $2.30 |
| `commercialCorporate` | `0.0275` (2.75%) | `$0.10` | $2.85 |

All five are tagged **real** and match the April 2026 Elavon interchange table.

One documented wrinkle: the live table shows `$0.22` for regulated debit with a
fraud adjustment, while the config keeps Jodi's `$0.21` Durbin base. That
difference is deliberate and flagged in the provenance note.

---

## Downgrades

| Key | Default | Unit |
|---|---|---|
| `downgrade.share` | `0.075` | fraction of volume |
| `downgrade.upliftPct` | `0.006` | fraction added |

Both are **placeholders** — the midpoints of the ranges in Jodi's PRD (5–10% of
volume, at 0.40–1.00% extra). They are the two most likely values to be tuned,
and tuning them moves every flat-rate deal.

---

## Processors

### Elavon

| Key | Value | Unit |
|---|---|---|
| `settlementPct` | `0.00015` | 0.015% of volume |
| `settlementPerItem` | `$0.02` | dollars |
| `authPerItem` | `$0.015` | dollars — Tier 3, grandfathered for 12 months |
| `buy.pctOfVolume` | `0.00015` | fraction |
| `buy.perItem` | `$0.02 + $0.015 ÷ 0.97` ≈ **`$0.03546`** | dollars |
| `revShare` | `1` | fraction retained |
| `perMerchantMonthly` | **`$4.00`** | $2 customer service + $2 monthly, per MID |
| `scheduleB` | `{ enabled: false, revShareTier1: 0.6 }` | disabled alternative |

### QorPay

| Key | Low risk | High risk |
|---|---|---|
| `buy.pctOfVolume` | `0.000275` (0.0275%) | `0.0035` (**0.35%**) |
| `buy.perItem` | `$0.03 ÷ 0.97 + $0.01` ≈ `$0.04093` | `$0.10 ÷ 0.97 + $0.01` ≈ `$0.11309` |
| `revShare` | `1` | **`1`** |
| `perMerchantMonthly` | `$13.90` | `$13.90` |

Plus, shared across both risk classes:

| Key | Value | Note |
|---|---|---|
| `avsPerAuth` | `$0.01` | Already folded into `buy.perItem` |
| `gateway` | `{ enabled: false, monthlyPerMid: 2, perTxn: 0.02 }` | Disabled; applicability unconfirmed |
| `losses.flatMonthly` | `$15.00` | A flat allowance |
| `losses.chargebackRateBps` | `0` | Real rate unknown |
| `losses.partnerLiabilityShare` | `0.5` | Signed fact, currently multiplied by zero |
| `losses.feePerOccurrence` | `$12.00` | Signed fact |
| `losses.occurrenceRatePerTxn` | `0` | Unknown |
| `portfolioAnnual` | `{ year1: $10,000, year2+: $20,000, allocation: "none" }` | Disclosed, never charged to a deal |

### The decline gross-up

`0.97` appears in both processors' per-item buy rates. Authorisation fees are
billed on **every attempt including declines**, so the cost per *approved*
transaction is the schedule fee divided by 0.97. Roughly 3% more than the naive
figure.

### `revShare` is 1.0 on every live path

Elavon Schedule A, QorPay low risk, QorPay high risk — all `1`. Risk class
changes the **buy rate**, not the split. The only sub-1.0 value in the file
belongs to Elavon Schedule B, which ships disabled.

---

## Vertical presets — the card mixes

Each vertical's mix must sum to exactly 1. A test asserts it.

| Vertical | Label | Reg. debit | Unreg. debit | Std. credit | Premium | Commercial | Typical ticket |
|---|---|---|---|---|---|---|---|
| `insurance` | Insurance | 10% | 5% | 13% | **52%** | 20% | $2,000 |
| `government` | Government & utilities | **35%** | 20% | 15% | 25% | 5% | $150 |
| `healthcare` | Healthcare | 30% | 20% | 15% | 30% | 5% | $120 |
| `ecommerce` | Consumer ecommerce / NIL | 21% | 12% | 17% | **45%** | 5% | $35 |

`typicalTicket` is a **hint shown in the UI and never used in the math.**

The mixes are hard-coded from public research because, as Jodi put it, a rep
would not know a merchant's actual card mix. **They are not editable from the
Configure tab** — see the editable list below.

---

## FBO

| Key | Value | Unit | Tag |
|---|---|---|---|
| `perEndCustomerMonthly` | `$10.00` | per sub-merchant per month | real |
| `perTxnTiers` | `$0.10` up to 500,000 legs, then `$0.05` | per leg | real |
| `achOrigPerItem` | `$0.20` | per outbound leg | real |
| `batchLegsPerMonth` | `44` | 22 settlement days × in and out | placeholder |
| `sell.perTxnOut` | `$0.25` | per outbound leg | **illustrative** |
| `sell.fundsFlowBps` | `0` | bps on settlement volume | **illustrative** |
| `sell.monthlyPlatformFee` | `$25.00` | per month | **illustrative** |
| `sell.floatSharePct` | `0` | fraction of settlement volume | **illustrative** |
| `portfolioFixed` | `$5,250/mo` + `$10,000` one-time | dollars | disclosed, not allocated |
| `fixedAllocation` | `"none"` | — | do not change |

---

## Mass pay

| Key | Value | Unit | Tag |
|---|---|---|---|
| `achNextDayTiers` | `$0.90` ≤5,000 · `$0.85` ≤7,500 · `$0.75` ≤10,000 · `$0.65` ≤50,000 · `$0.25` above | per domestic payout, tiered on monthly domestic count | real |
| `costPerPayoutCrossBorder` | `$3.00` | per cross-border payout, excluding FX | real |
| `fxCostPct` | `0.01` | fraction of cross-border volume | real |
| `quoteValidUntil` | `"2026-07-07"` | date | **expired** |
| `sell.perPayoutFee` | `$2.00` | per payout | **illustrative** |
| `sell.fxSpreadPct` | `0.015` | fraction | **illustrative** |

**The mass pay quote is expired.** The UI badges every mass pay number
accordingly, and should keep doing so until a fresh schedule arrives.

---

## Products and equipment catalogue

15 rows, versioned separately as `2026-08-04`, and **not carried in the quote
URL**.

| Id | Label | Basis | Buy | Default sell | Markup | Processor |
|---|---|---|---|---|---|---|
| `N950-R` | Newland N950 (rental) | monthly | $20 | $20 | ceiling $80 | Elavon |
| `950DK-R` | Newland N950 docking station | monthly | $4 | $4 | ceiling $16 | Elavon |
| `D3503-R` | Ingenico Desk 3500 V3 | monthly | $8 | $8 | ceiling $32 | Elavon |
| `DX80U-R` | Ingenico Axium DX8000 | monthly | $12 | $12 | ceiling $48 | Elavon |
| `TLEL4-P` | talech elo iSeries 4.0 Slim | **one-time** | $1,098 | $1,098 | open | Elavon |
| `TC003` | talech Standard SaaS | monthly | $41 | **$69** | **fixed** | Elavon |
| `TLPSM` | talech Premium Support | monthly | $85 | $85 | **fixed** | Elavon |
| `UGWAY-M` | Elavon Payment Gateway (monthly) | monthly | $10 | $10 | open | Elavon |
| `UGWAY-T` | Elavon Payment Gateway (per txn) | **per transaction** | $0.02 | $0.05 | open | Elavon |
| `QORPAX` | Acceptance device — Visa Pax | monthly | $8.50 | $8.50 | open | QorPay |
| `CBFEE-E` | Chargeback fee (Elavon) | monthly | $15 | **$25** | open | Elavon |
| `CBFEE-Q` | Chargeback fee (QorPay) | monthly | $12 | **$25** | open | QorPay |
| `PACTVERA` | Pactvera | monthly | $0 | $0 | open | either |
| `KYC` | Identity verification | monthly | $0 | $0 | open | either |
| `KYB` | Business verification | monthly | $0 | $0 | open | either |

Three markup kinds:

- **ceiling** — a rep may price anywhere from zero up to the maximum
- **fixed** — the price cannot move at all
- **open** — no ceiling

`UGWAY-T` is marked **not waivable**. The three ChainIT products price at zero
on both sides because Tim still owes their real numbers.

Catalogue invariants worth reproducing: ids are unique, a ceiling is never below
cost, a default sell never exceeds its ceiling, every price is non-negative and
finite, and the rows are deeply immutable.

---

## What a Config editor may actually change

**Exactly 13 values are editable.** Everything else in this document is frozen,
including — deliberately — the card mixes and every signed buy rate.

A save applies only the whitelisted paths and **silently ignores anything else**,
so a stale or malicious override can never move a signed rate. That behaviour is
tested, and it is the reason the whole scheme is safe to expose at all.

Reproduce this in the prototype: an allow-list, applied to a deep clone of the
defaults, with everything off-list dropped.

---

## Revisions

Saved configuration is **append-only**. Each save writes a new numbered
revision:

| Field | Meaning |
|---|---|
| `revision` | Auto-incrementing number |
| `overrides` | The flat map of changed values, as JSON |
| `editor_email` | Who saved it |
| `note` | Why |
| `created_at` | When, ISO 8601 |

Nothing is ever updated in place and nothing is deleted. That gives a free audit
trail and one-click rollback, and it is why the tab can be trusted to a small
group rather than locked away entirely.

The effective version string a rep sees combines both: `2026-08-04·r7` — the
bundled version, then the revision number.

### How a quote relates to a version

A quote URL carries `v=<version>`. **It pins the version, not the config.**

On opening a quote link, the deal is **re-priced on the current config**. If the
pinned version differs from the current one, an amber banner appears:

> "This link was priced on rate config v2026-08-04·r5; it has been re-priced on
> the current v2026-08-04·r7."

There is no mechanism to reconstruct an old config from a version string, and
that is intentional — an old quote should show today's truth, loudly labelled,
rather than a stale number presented as current.

---

## Who may read and who may write

| Action | Who |
|---|---|
| Read the effective config | **Any signed-in user.** Every rep prices on it. |
| Write a new revision | **Config editors only.** Anyone else gets a 403 reading "editing the pricing config is restricted to leadership". |
| Read the revision history | Config editors only, last 50 revisions |

Validation runs **twice** — once in the browser and again on the server before
the insert. Server-side rejection returns a per-field error list. Reproduce
both: the client check is for the human, the server check is the actual gate.

---

## Open items — numbers Jodi still owes

Carry these into the prototype as visible placeholders. Do not invent values for
them.

| # | Owed |
|---|---|
| 1 | Real pricing for Pactvera, KYC and KYB (owed by Tim) |
| 2 | FBO sell-side pricing — per-rail fees, funds-flow bps, platform fee, float share |
| 3 | Mass pay sell-side — per-payout fee and FX spread |
| 4 | The real downgrade share and uplift, replacing our midpoints |
| 5 | The real amortisation window |
| 6 | Elavon Schedule A versus Schedule B |
| 7 | A renewed mass pay quote — the current one expired 2026-07-07 |
| 8 | The QorPay chargeback rate, currently zero |
| 9 | Whether the QorPay gateway fee applies at all |
