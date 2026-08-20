# What you are rebuilding

*This file is written for two readers: the new product owner, and the AI agent
building the prototype. Both should read it end to end before anything else.*

---

## The one-paragraph version

**Sales Cockpit** is ChainIT's internal dashboard for the sales and operations
teams. It reads deal data out of HubSpot, cleans it up, and presents it as five
sections a salesperson can act on: what to do today, the revenue pipeline,
marketing performance, leadership reporting, and deal pricing. It lives at
`sales.chainithub.com` behind a company login. It is **read-only against
HubSpot** — nothing you do in the cockpit writes back to the CRM — with two
exceptions: leadership reports, which operators author by hand, and pricing
configuration, which a small group edits.

## Who uses it

| Person | What they come for |
|---|---|
| **Sales rep** | Their own deals, what is stuck, what to chase today, and a price for a merchant they are talking to |
| **Sales manager** | The whole team's pipeline, forecast, who is performing, where deals die |
| **Marketing** | Lead funnel, source ROI, audience growth, campaign performance |
| **Leadership** | A hand-written weekly report: meetings, contracts, pipeline health, and the data quality problems that need fixing |
| **Operations (Jodi, Stacey)** | The pricing cost engine — the rates behind every quote |

Roughly 20 to 30 people. It is an internal tool, not a product we sell. That
shapes the design: **density and speed beat delight.** These are people who open
it several times a day and know exactly what they are looking for.

## Why it exists

Three problems, in the order they were felt:

1. **HubSpot's own reporting was not answering the questions.** Managers wanted
   "what is stuck and for how long" and "which stage do deals die in," and were
   rebuilding those by hand in spreadsheets every week.
2. **Data quality was invisible.** Deals with no owner, companies with no
   industry, contacts with no email — nobody could see the size of the problem,
   so nobody fixed it. The *Data to Fix* view exists to make it visible.
3. **Quoting lived nowhere.** A rep pricing a merchant deal was doing it in a
   spreadsheet, or asking Jodi. In August 2026 the head of Operations, Stacey
   Wiles, decided quoting belongs in the cockpit and not in HubSpot. That is why
   Pricing is the fifth section.

## The five sections

The whole app is a two-level switcher: five sections across the top, and each
section's tabs underneath. That structure is fixed; what lives inside is yours.

### 1. Home — "what should I do right now"

The landing surface. Today's priorities, signals worth acting on, and the
onboarding funnel for customers moving through setup.

### 2. Revenue — the pipeline

The core of the tool. Pipeline board, forecast, owner leaderboard, stage
conversion and velocity, stuck and aging deals, and win/loss.

One structural rule that is easy to miss: the pipelines are **never merged**.
Mixing them produces meaningless totals. Every Revenue view has a pipeline
switcher, and it is a switcher rather than a filter chip because the populations
are genuinely different businesses.

> **Observed live, 2026-08-20:** the design assumes two pipelines, direct and
> affiliate. Production currently shows **three**, the third being
> "STAGING - ChainIT Pay Sales Pipeline". A staging pipeline is visible to every
> user in the live switcher. Build the prototype with the switcher handling **an
> arbitrary number** of pipelines rather than exactly two, and flag the staging
> one to engineering as something to filter out or remove.
>
> Also worth knowing: the switcher defaults to **Affiliate Pipeline**, which
> holds 2 deals worth $3.4k, while Sales Pipeline holds 216 opportunities worth
> $14.9M. A rep opening Revenue lands on the small one first. See
> `screenshots/README.md`.

### 3. Marketing — where leads come from

Lead funnel, source ROI, audience growth, campaigns and segments, forms and
emails. Read from HubSpot's marketing side.

### 4. Leadership — the hand-written report

Not HubSpot data. This is the section where an operator types: meetings held,
contracts in the queue, pipeline health commentary, and the data-quality items
that need fixing. Rows are editable in place and saved to our own database.

### 5. Pricing — quoting a merchant deal

Two tabs, and the boundary between them is the point:

- **Price a deal** — every rep's screen. Enter a merchant's profile, get a rate,
  a margin, a health light, and a shareable quote link.
- **Configure** — the locked cost engine. Interchange tables, buy rates, card
  mixes, downgrade assumptions, floors. **Only a couple of named people may edit
  this.** The tab is visible to everyone; its body explains the boundary to
  people who cannot edit.

`02-pricing-engine/` covers this section in depth. It is the part of the product
where a wrong number costs real money, so it gets its own documentation.

---

## The design character

If you take nothing else from this file: **the cockpit is calm, dense, and
quiet.** It is not a marketing dashboard and it should not look like one.

What that means concretely:

- **No decorative colour.** Colour carries meaning — a status, a health verdict,
  the single accent on the active nav item. If a colour is not saying something,
  it should not be there.
- **Low chrome.** Hairline borders, flat surfaces, no drop shadows stacking up
  to fake depth. Elevation is expressed by surface tone, not by shadow.
- **Numbers are the content.** Tables and figures get the space. Headings and
  labels get out of the way.
- **Empty states are designed, not blank.** "Nothing stuck" is good news and
  should look like good news, not like a broken page.
- **Dark mode is first-class**, not an afterthought. Every surface has a
  deliberate dark counterpart that passes the same contrast checks.

`03-design-system/01-design-brief.md` turns this into specific instructions with
real colour values. Give that file to Emergent early — it is the main defence
against the prototype drifting into generic purple-gradient AI-dashboard
territory.

---

## How the real one is built (context only — do not copy)

You are not rebuilding this stack, and Emergent will not use it. It is here so
you understand why some things are the way they are.

| Layer | Real system | Your prototype |
|---|---|---|
| Frontend | React 19, Vite, Tailwind v4 | React (Emergent's default) |
| Backend | Hono on a Cloudflare Worker | FastAPI |
| Database | Cloudflare D1 (SQLite) | MongoDB |
| Login | Cloudflare Access + Microsoft Entra | A fake role dropdown |
| Data source | HubSpot API, cached and refreshed | Static seed fixtures |
| Hosting | Cloudflare, `sales.chainithub.com` | Emergent preview URL |

The relevant consequence: the real app **caches HubSpot data and refreshes it on
a schedule**, which is why there is a "Sync Now" button and a freshness
indicator. Your prototype should still show those controls — a rep's mental
model includes "how old is this number" — but they can be simulated.

---

## The three things that must not drift

Everything else is open to redesign. These three are load-bearing:

1. **The two pipelines never merge.** Direct and affiliate are separate
   populations with separate totals.
2. **The URL is the quote.** A priced deal lives in the query string, and links
   already sit in customers' inboxes.
3. **Seeing a rate and editing a rate are different permissions.** A rep may see
   what they are quoting. Only Configure editors change the cost model. And
   seeing our *margin* is a third, separate permission again.

`05-emergent-setup/04-guardrails-do-not-change.md` has the full list.

---

## Where to go next

| You want to | Read |
|---|---|
| Start building in Emergent | `00-KICKOFF-PROMPT.md`, then `05-emergent-setup/01-how-to-use-this-bundle.md` |
| Understand the screens | `01-product/02-sales-cockpit-spec.md` |
| Understand pricing | `02-pricing-engine/01-pricing-primer-plain-english.md` |
| Make it look right | `03-design-system/01-design-brief.md` |
| Know the data shapes | `04-data-contracts/` |
| Hand work back | `05-emergent-setup/03-handoff-back-to-engineering.md` |
