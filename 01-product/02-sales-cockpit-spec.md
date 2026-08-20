# Sales Cockpit — screen-by-screen build specification

*This is the build document. Everything the prototype needs to render is here:
routes, panels in order, exact column headers, exact tile labels, exact copy,
and the loading, empty and error states. Read it alongside
`03-design-system/01-design-brief.md`, which supplies the look.*

Nothing in this file is invented. Every column name, label, threshold and
sentence in quotation marks was read out of the live application. Where the
source did not record something, the line says `Not specified in source.`

A handful of items are marked **Defect — fix, do not copy.** Those are real
faults found while reading the app. The prototype is the cheapest place to fix
them.

---

## Contents

1. [How the shell works](#1-how-the-shell-works)
2. [Formatting rules that apply everywhere](#2-formatting-rules-that-apply-everywhere)
3. [The three shared card patterns](#3-the-three-shared-card-patterns)
4. [Route index](#4-route-index)
5. [The screens](#5-the-screens) — one section per route
6. [Role-dependent behaviour, collected](#6-role-dependent-behaviour-collected)
7. [Invariants that must not drift](#7-invariants-that-must-not-drift)
8. [Things that deliberately do not exist](#8-things-that-deliberately-do-not-exist)

---

## 1. How the shell works

One page. A sticky header, a body, and a persistent bar along the bottom
inherited from the wider company shell.

The header carries, left to right: the wordmark **"Sales Cockpit"**, a small
mono chip reading **"HubSpot · read-only"**, and a theme toggle pushed to the
right edge. Below that sit two rows of tabs — five sections on the first row,
the selected section's sub-tabs on the second.

Pinned to the right-hand end of the section row, outside the five sections, is
a sixth destination: **"Setup & Data Readiness"**. It is a link, not a tab, and
it is reachable from every section. Nearly every empty state in the app has a
button pointing at it, so treat it as a first-class page.

### Content width and gutters

Header and body share one centred container, **max-width 1200px**, side padding
of 21px rising to 28px at 640px and above. The body is a single vertical stack
with a 21px gap between blocks.

### The section tree

| Section | Icon | Sub-tabs in order (default first) |
|---|---|---|
| Home | `home` | Today · Signals · Onboarding |
| Revenue | `trending-up` | Pipeline · Forecast · Owners · Velocity · Stuck · Win / Loss |
| Marketing | `megaphone` | Lead Funnel · Source ROI · Audience · Campaigns · Forms & Email |
| Leadership | `clipboard-list` | Meetings · Pipeline Health · Contracts · Data to Fix |
| Pricing | `calculator` | Price a deal · Configure |

Selecting a section always lands on its **first** sub-tab.

### What goes in the URL

Only two of the five sections write to the address bar. This is worth
reproducing because it is why a Pricing quote survives a section switch.

| Where you are | What the URL shows |
|---|---|
| Setup | `#/setup` |
| Leadership | `#/leadership/meetings` · `/pipeline` · `/contracts` · `/datafix` |
| Pricing | `#/pricing` or `#/pricing/price` · `#/pricing/configure` |
| Home, Revenue, Marketing | No hash at all. Selecting one of these *clears* any hash left behind. |
| A priced deal | The query string, for example `?vert=…&vol=…&v=…` |

Pricing rewrites its hash without touching the query string, so the encoded
quote survives navigating away and back.

### Unknown addresses

There is no 404 screen. Three fallbacks cover everything:

- An address that matches nothing (`#/foo`, `#/leadership/bogus`) is ignored.
  The screen stays wherever it was; on a cold load that is Home → Today. The bad
  text stays in the address bar and does nothing.
- A bare `#/pricing` lands on **Price a deal**. A retired domain still redirects
  here, so this case is live.
- An unknown sub-tab inside a known section renders that section's default
  screen: Revenue → Pipeline board, Marketing → Lead Funnel, Leadership →
  Customer Meetings, Home → Today, Pricing → Price a deal.

### Keyboard and screen readers

Both tab rows are marked up as tab lists with a selected state, and every tab is
a real button. Section tabs are 44px tall, sub-tabs 36px. Every control carries a
visible focus ring — 2px accent, 2px offset. The active tab is signalled by more
than colour: section tabs get a 2px bottom border, an ink-dark label and a tinted
icon; sub-tabs get a filled background.

> **Defect — fix, do not copy.** The tab rows set a roving tab index but never
> implement arrow-key handling, so a keyboard user can reach only the *active*
> tab. The same gap exists on the pipeline switcher and the time-window chips.
> Add ArrowLeft, ArrowRight, Home and End.

> **Defect — fix, do not copy.** Nothing in the app declares a tab panel or links
> a tab to the content it controls. The rows are visual tabs only. Give each body
> `role="tabpanel"` and wire `aria-controls`.

Both rows scroll horizontally on narrow screens rather than wrapping.

### Theme

Light and dark, class-driven, stored in the browser under the key
`marketing-theme`. The default is **light**. The app deliberately does **not**
follow the operating-system preference — the stored choice is the only authority.

---

## 2. Formatting rules that apply everywhere

Six formatters cover every number in the product. Use these names; the screens
below refer to them.

| Name | What it does | Example |
|---|---|---|
| `usd` | Whole dollars, US grouping | `1234` → `$1,234` |
| `usd2` | Dollars and cents | `12.5` → `$12.50` |
| `pct` | A fraction rendered as a whole percent | `0.823` → `82%` |
| `compactUsd` | Compact dollars, one decimal | `8600` → `$8.6k`; `1500000` → `$1.5m` |
| `intf` | Grouped integer | `12345` → `12,345` |
| `timeAgo` | Relative time | `"just now"` · `"12m ago"` · `"3h ago"` · `"4d ago"` |

**Every formatter returns an em dash `"—"` when the input is not a finite
number.** This is the app's single most important rule. The product never renders
`$NaN`, never renders `NaN%`, and never invents a `$0` where the truth is "no
value recorded". Where a table needs to say more than "—", it uses a longer
literal: **`"— no amount"`**, **`"— no $"`**, **`"— no age"`**, **`"— empty"`**.

### Column alignment

Table cells are left-aligned and top-aligned by default. Columns that hold
numbers are flagged as numeric and rendered with tabular figures so digits line
up down the column. The source does not record a right-align rule on numeric
cells; the design brief asks for one in the rebuild. **Build numeric columns
right-aligned and tabular.** Each column table below marks which columns those
are.

### Shared thresholds

| Constant | Value | Used by |
|---|---|---|
| Aging | more than **14 days** in stage | My Day, Pipeline board, Stuck & aging |
| Stale | more than **30 days** in stage | My Day, Pipeline board, Stuck & aging |
| Unknown age | a null day count is `"unknown"` and is **not** counted as stuck | the same three |
| Thin win/loss sample | fewer than **5** closed deals suppresses the win rate | Win / Loss |
| Small funnel sample | fewer than **5** deals triggers a caveat note | Velocity |
| Vanity source | more than 0 leads and exactly 0 opportunities | Source ROI |
| Sync cooldown | **5 minutes** | Sync now button |

### Links out to HubSpot

Deep links are portal-scoped to portal `46378407`.

| Record | Path |
|---|---|
| Contact | `https://app.hubspot.com/contacts/46378407/record/0-1/{id}` |
| Company | `…/record/0-2/{id}` |
| Deal | `…/record/0-3/{id}` |

Every one of them opens in a new tab and its accessible name ends with
**"(opens in a new tab)"**.

### Tables have no extras

The shared table has **no pagination, no row click, no row hover highlight, no
row selection, no checkboxes, no bulk actions, no sticky header, no column
resizing and no built-in empty state**. Sorting exists on exactly one screen
(Data to Fix). Row caps are handled by the server and stated in prose. Do not add
any of these to the prototype.

---

## 3. The three shared card patterns

Nine screens reuse the same three blocks. They are described once here so each
screen below can name them instead of repeating them.

### 3a. The skeleton (loading)

A block that holds the same height as the content it replaces, so the page does
not jump when data lands. Anatomy: a grid of pulsing tiles at 52px high — two
columns on a phone, three or four at 640px, five on My Day — followed by one
large pulsing card between 200px and 320px tall. Both carry a busy state for
screen readers.

**The skeleton only appears on a cold load.** A background refresh never blanks a
screen that already has numbers on it.

Three screens use a smaller in-panel version instead: a single 96px pulsing bar
inside the panel (Pipeline Health, Data to Fix, and the editable-report chassis
behind Meetings and Contracts).

### 3b. The sync-pending card (State A)

Shown when the data has never arrived — the normal first-run state. Anatomy,
centred in a hairline card on the surface tone:

1. A 44px circular badge in accent tint, holding an 18px accent icon.
2. An 11px uppercase muted eyebrow.
3. A 19px semibold headline, at most 42 characters wide.
4. A 13.5px muted body paragraph, at most 54 characters wide.
5. A button reading **"Setup & Data Readiness"** with an up-right arrow.

The recurring sentence at the end of eight of these cards, to be used verbatim:

> "Nothing is broken — this is the normal state while the connection is being
> configured."

The rest of each body paragraph is not quoted in the source. Each screen below
gives its exact headline.

### 3c. The synced-but-empty card (State B)

Same anatomy, **without** the Setup button — there is nothing to configure, the
data simply is not there yet. State B cards render *inside* the screen shell, so
the pipeline switcher above them stays reachable and the operator can flip to the
other pipeline.

One State B card breaks the pattern on purpose: **Nothing stuck** on the Stuck &
aging screen uses a mint tint and a check-circle glyph instead of the accent
tint, because an empty stuck queue is good news and should look like it.

---

## 4. Route index

| # | Route | Screen | What it answers |
|---|---|---|---|
| 1 | `#/setup` | Setup & Data Readiness | What is connected, what is syncing, what is still locked |
| 2 | `home / today` | My Day (Today) | What should I do right now |
| 3 | `home / signals` | Signals | What is new and hot since I was last here |
| 4 | `home / onboarding` | Onboarding funnel | How many merchants are moving through setup |
| 5 | `revenue / pipeline` | Pipeline board | What does one pipeline look like, stage by stage |
| 6 | `revenue / forecast` | Forecast | What is likely to close, weighted by stage |
| 7 | `revenue / owners` | Owner leaderboard | Who is carrying what book |
| 8 | `revenue / velocity` | Stage conversion & velocity | Where do deals fall out, and where do they sit |
| 9 | `revenue / stuck` | Stuck & aging | What has not moved and needs chasing today |
| 10 | `revenue / winloss` | Win / Loss | What closes, what does not, and why we lose |
| 11 | `marketing / leadfunnel` | Lead Funnel | How many leads become customers |
| 12 | `marketing / sources` | Lead Source ROI | Which channels actually convert |
| 13 | `marketing / audience` | Audience Growth | Is the contact and company base growing, and is it complete |
| 14 | `marketing / campaigns` | Campaigns & Segments | What campaigns and lists exist, and did they do anything |
| 15 | `marketing / formsemails` | Forms & Emails | Which forms convert, what email assets exist |
| 16 | `#/leadership/meetings` | Customer Meetings | The hand-written log of customer meetings |
| 17 | `#/leadership/pipeline` | Pipeline Health | Live deals annotated by hand with a CTA and a risk |
| 18 | `#/leadership/contracts` | Contract / Agreement Review Queue | What agreements are in review and what is blocking them |
| 19 | `#/leadership/datafix` | Data to Fix | Which records are missing required fields |
| 20 | `#/pricing/price` | Price a deal | What rate can I quote this merchant |
| 21 | `#/pricing/configure` | Configure | The locked cost engine behind every quote |

Routes 20 and 21 are covered in depth in `02-pricing-engine/`. This file records
only their shell, their loading line, their banners and the permission boundary.

---

## 5. The screens

---

### 1. `#/setup` — Setup & Data Readiness

**Purpose.** The trust anchor. Every other screen's empty state points here, so
it has to look the most finished when there is no data at all.

**Data.** `GET /api/snapshot`.

**This screen has no loading state.** If the data has not arrived, a well-formed
empty shape is substituted, so all nine surfaces render as Locked rather than a
spinner appearing.

**Top to bottom**

1. **Header.** A shield-check eyebrow reading "Setup & Data Readiness", an `<h1>`
   reading **"What's connected, what's syncing"**, and a lede paragraph capped at
   64 characters wide. *Lede text: not specified in source.*
2. **Readiness tiles.** Two non-interactive tiles, one column on a phone and two
   at 640px.
3. **Scope checklist panel.**
4. **A two-up grid** at 1024px and above: Sync freshness on the left, Data
   completeness on the right. One column below that.

**Readiness tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `shield-check` | `{granted}/9` | Surfaces connected | Granted scopes |
| `lock` | `9 − granted` | Surfaces locked | Awaiting scope or tier |

**Scope checklist panel.** Eyebrow "Scope checklist". Right-hand meta text:
`"{granted}/9 granted"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Surface` | left | A check-circle glyph when granted or a lock glyph when locked, the surface label, and the blurb beneath |
| 2 | `Status` | left | A badge reading **"Granted"** or **"Locked"** |
| 3 | `What to grant` | left | Either the quiet **"Connected — no action needed."** or a key glyph plus one code chip per required scope |

All nine rows always render, even before anything has been checked. A surface
that is missing from the response renders as Locked.

| Surface label | Blurb | Scopes shown when locked |
|---|---|---|
| CRM — deals, owners, pipelines | Powers Revenue (pipeline, owners, affiliate) and the deal rollups. | `crm.objects.deals.read`, `crm.objects.owners.read`, `crm.schemas.deals.read` |
| Marketing campaigns | The campaign roster for Campaigns & Segments. | `marketing.campaigns.read` |
| Lists & segments | List roster + membership sizes for Campaigns & Segments. | `crm.lists.read` |
| Forms | Lead-capture forms feeding the Forms & Emails view. | `forms` |
| Marketing email | The marketing-email roster + state for Forms & Emails. | `marketing-email`, `content` |
| Attribution analytics | The lifecycle funnel + per-source ROI (Lead Funnel / Lead Source ROI). | `business-intelligence` |
| Inbox conversations | Read-only conversation threads. | `conversations.read` |
| Content & pages | Landing / site / blog pages. | `content` |
| Onboarding custom objects | The Intake → Merchant funnel (Onboarding tab). | `crm.objects.custom.read` |

Below the table, a paragraph explaining what a scope is. *Exact text: not
specified in source.*

**Sync freshness panel.** Eyebrow "Sync freshness". Its right-hand meta slot holds
the **Sync now** button. Three lane rows in this fixed order:

| Order | Lane label | Row shape |
|---|---|---|
| 1 | Deals & pipelines | `[status badge] {label} ……… {relative time, or "not yet run"}` |
| 2 | Contacts & companies | same |
| 3 | Marketing assets & funnel | same |

Badge tone: never run → neutral, reading `"pending"`; a successful run → the good
tone; an errored run → the accent tone; anything else → neutral.

When the first lane has never run, an extra calm note appears:

> "First sync hasn't landed yet. The cockpit fills in automatically on the next
> scheduled pull — or run it now with Sync."

**Data completeness panel.** Eyebrow "Data completeness". Meta reads
`"no objects yet"` or `"{n} object(s)"`. One row per object type:
`{object type} …… {rows held}` and, when the source reports a total,
`/ {total}` plus a 1px-high accent proportion meter beneath.

Empty body:

> "No objects have been counted yet — completeness fills in after the first sync.
> Sparse is normal while the HubSpot connection is being configured live; nothing
> here is broken."

**States.** No loading state. No error state — the underlying request never
throws. An empty scope list still renders nine Locked rows. Empty object counts
render the paragraph above.

---

### 2. `home / today` — My Day (Today)

**Purpose.** A role-aware briefing: what matters today. **This is the landing
screen of the whole app.**

**Data.** `GET /api/snapshot?view=home`, plus the signed-in identity.

**Role.** One of `rep`, `manager`, `marketer`. It is decided server-side, with the
identity as a fallback and `rep` as the last resort.

**Top to bottom**

1. **View header** — a sparkle eyebrow reading **"My Day"**, then a role-specific
   heading and lede.
2. **KPI band** — four tiles, all of them clickable.
3. **Fresh-leads nudge** — conditional.
4. **My open deals panel.**
5. **Tasks due today panel.**

**Heading and lede by role**

| Role | Heading | Lede |
|---|---|---|
| `rep` | **Your day** | "The few signals that matter today — your stuck deals, what's due, and the freshest leads. Lead with these, ignore the rest." |
| `manager` | **Team day** | "Today across the team — open pipeline, what's aging, and this week's wins. The signal, surfaced; the 50k contacts stay out of your way." |
| `marketer` | **Your leads & day** | "Today's freshest leads and new pipeline first — what marketing surfaced that sales should act on now." |

**KPI tiles.** For a manager, every label is prefixed with `"Team "`.

| Icon | Value | Label | Hint | Click goes to |
|---|---|---|---|---|
| `briefcase` (hero) | `compactUsd(amount)`, or `"—"` when the count is 0 | `{Team }My open deals` | `"{count} open · across all pipelines"` | Revenue |
| `timer-reset` | `intf(count)` | `{Team }Aging (>14d)` | `"{compactUsd} at risk"`, or `"none stuck"` | Revenue |
| `check-square` | `intf(count)`, or `"—"` when unavailable | `{Team }Tasks due today` | `"due today"`, or `"not synced yet"` | Home |
| `trophy` | `intf(count)` | `{Team }Week wins` | `compactUsd(amount)`, or `"this week"` | Revenue |

The phrase **"across all pipelines"** on the first tile is deliberate. It is the
only number anywhere in the cockpit that combines the two pipelines, and the hint
says so out loud. Keep the wording.

**Fresh-leads nudge.** Appears only when the data says the operator has no deals
of their own. An accent-tinted inline band:

> "**No deals assigned to you yet** — check the **Signals** tab for the freshest
> leads to pick up and start your pipeline."

**My open deals panel.** Eyebrow "My open deals". Meta reads
`"{count} · {compactUsd}"`, or `"none open"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Pipeline` | left | Pipeline name, muted |
| 2 | `Stage` | left | Stage name, medium weight, ink |
| 3 | `Amount` | **right, numeric** | `compactUsd`, or `"—"` |
| 4 | `Age` | left | The age badge, below |
| 5 | *(no header)* | right | An **"Ask copilot"** chip, labelled for "the {stage} deal" |

Screen-reader caption: "My open deals, most-stuck first".

The age badge: a null day count renders `"—"`; more than 30 days renders an accent
badge reading **`"{days}d · stale"`**; more than 14 days renders a neutral badge
reading **`"{days}d · aging"`**; anything else is plain mono text reading
`"{days}d"`.

A footnote under the table explains the ordering and the cross-pipeline total.
*Exact text: not specified in source.*

Empty:

> "No open deals are assigned to you right now. When you own deals, the ones most
> in need of a nudge surface here first."

**Tasks due today panel.** Eyebrow "Tasks due today". The body is either a large
mono count with the caption `"due today"` beneath, or, when tasks are not
available at all, this calm gap card:

> "Tasks aren't synced yet — this fills in once HubSpot tasks land. Nothing here
> is broken."

**Loading.** The five-tile skeleton: a pulsing KPI grid at 52px plus a 220px card
and a 160px card.

**Empty and error — the same card.** When the request errors, *or* when the login
cannot be matched to a HubSpot owner, the screen renders one designed card. A
failed request never produces an error screen.

- Eyebrow: "My Day"
- Headline: **"We couldn't match your login to a HubSpot owner"**
- Body: differs for a marketer versus everyone else. *Exact text: not specified in
  source.*
- Button: **"Setup & Data Readiness"**

This is the realistic first-run state over an empty database.

---

### 3. `home / signals` — Signals

**Purpose.** What is new and hot: the freshest leads, new pipeline since the last
visit, and this week's wins.

**Data.** Same as My Day.

**Top to bottom**

1. **View header** — a flame eyebrow reading **"Signals"**, heading **"Signals"**,
   and one lede, the same for every role:

   > "What's new and hot — the freshest leads, new pipeline since you were away,
   > and this week's wins. The opportunities to act on, surfaced; the 50k contacts
   > stay out of your way."

2. **KPI band** — three tiles.
3. **Hot leads panel.**
4. **The "since you were away" strip.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `flame` | `intf(count)` | Hot leads | `"fresh now"`, or `"search unavailable"` |
| `sparkle` | `intf(count)` | For a rep, **"New since you were away"**; for everyone else, **"New since last visit"** | `"new pipeline"` |
| `trophy` | `intf(count)` | `{Team }Week wins` | `compactUsd(amount)`, or `"this week"` |

**Hot leads panel.** Eyebrow "Hot leads". Meta reads `"{n} fresh"` or
`"search unavailable"`.

The body is a **list, not a table**. Each row: the contact name — falling back to
the email address, then to **"Unknown contact"** — an optional second line with
the email, and two right-aligned actions: **"Open in HubSpot"** (external-link
glyph, new tab, contact deep link) and an **"Ask copilot"** chip.

Empty, two variants:

- When the lead search itself is unavailable:
  > "The live lead search is unavailable right now — it retries on the next load."
- Otherwise:
  > "No fresh leads surfaced right now. New contacts since you were away appear
  > here first."

**The away strip.** A slim hairline band. Its label reads **"Since you were
away"** for a rep and **"Since last visit"** for everyone else, followed by two
statistics: `sparkle {n} new in pipeline` and `trophy {n} wins · {compactUsd}`
(or `"wins this week"` when there is no amount).

This is deliberately not a sparkline. The data is counts, not a series.

**Loading, empty, error.** Shared with My Day.

---

### 4. `home / onboarding` — Onboarding funnel

**Purpose.** Merchant onboarding as a step funnel across six separate HubSpot
custom objects — Intake, Onboarding, Merchant, Sub-Merchant, External Party,
Staff. These are six object types, not six stages of one pipeline, and the screen
says so repeatedly.

**Data.** `GET /api/snapshot?view=onboarding`.

**Top to bottom**

1. **View header** — a workflow eyebrow reading "Onboarding funnel", heading
   **"Onboarding funnel"**, and a lede naming the six objects and warning that
   step-to-step conversion is *"a count ratio, not a per-record handoff"*.
2. **KPI band** — three tiles.
3. **Step funnel panel.**
4. **Sales → Ops handoff panel.**
5. **The "How to read this" honesty band.**
6. **Summary strip.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `workflow` (hero) | `intf(total)` of the first step, prefixed **`"≥ "`** when the count is a floor | `{step label} (intake)` | `"floor · syncing"`, or `"the funnel mouth"` |
| `store` | `intf(total)` of the step labelled "Merchants" | Merchants | `"floor · syncing"` · `"live merchant objects"` · `"no merchants object"` |
| `percent` | `pct(merchants ÷ intake)`, or `"—"` | Intake → merchant | `"cross-object count ratio"` · `"no intake yet"` · `"no merchants object"` |

**Step funnel panel.** Eyebrow **"Step funnel · cross-object progression"**. Meta
reads `"{n} object(s)"`. One row per object, three lines each:

- Line 1: an ordinal chip (1 to N), the step label, an optional truncation chip,
  then the total, right-aligned.
- Line 2: an accent proportion bar sized as a share of the **largest** step.
- Line 3: on the left, `↘ from previous {pct}` — except at the first step, where
  the literal text is **"intake — the funnel mouth"**. On the right,
  `"{pct} of intake"`.

A count that the source could not fully enumerate renders as **`"≥ {n}"`** plus a
chip reading **"syncing · floor"** with a refresh glyph.

**Sales → Ops handoff panel.** See the component catalogue; it is a shared block
used only here.

**Honesty band.** An info eyebrow reading **"How to read this"**, with body copy
explaining the cross-object caveat and, when any step is truncated, that the `≥`
counts are floors. *Exact text: not specified in source.*

**Summary strip.** Label "Funnel", then three statistics: intake, merchants,
intake → merchant.

**Loading.** Three-tile grid plus a 320px card.

**State A and B — one card.** Headline **"The onboarding funnel fills in after the
first sync"**, shown whenever the sync is pending or there are no steps.

---

### 5. `revenue / pipeline` — Pipeline board *(Revenue default)*

**Purpose.** One pipeline at a time, its stages in their real display order, as a
horizontal funnel of bars. This is the screen the sales team opens most, and the
pattern every other data screen follows.

**Data.** `GET /api/snapshot?view=deals`. All the maths happens in the browser.

**Top to bottom**

1. **View header** — a git-branch eyebrow reading "Pipeline", heading **"Pipeline
   board"**, and this lede:

   > "Your pipeline the way HubSpot's board should look — un-fragmented. Each
   > stage in real order with its open deals and value. The two pipelines stay
   > separate; switch between them, never a blended total."

2. **Control row** — the pipeline switcher on the left. On the right, a small mono
   uppercase note reading `"{n} closed won"`, falling back to the literal
   **`"read-only"`**.
3. **KPI band** — four tiles, none clickable.
4. **Stage funnel panel.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `briefcase` (hero) | `compactUsd(open amount)`, or `"—"` | Open pipeline | `"{n} open"`, plus `" · {k} no $"` when some deals carry no amount |
| `layers` | `intf(open count)` | Open deals | `"across stages"`, or `"none open"` |
| `trending-up` | `intf(count)`, or `"—"` | Biggest stage | the stage label, or `"no open deals"` |
| `timer-reset` | `intf(stuck count)` | `Stuck (>14d)` | `"needs a nudge"`, or `"none aging"` |

**Stage funnel panel.** Eyebrow `"{pipeline label} · stages"`. Meta reads
`"{n} open · {compactUsd}"`, or **`"no open deals"`**.

One row per stage. At 640px and above the row is: a fixed 180px label block
holding a trophy glyph for a won stage or an accent dot otherwise, then the stage
label; a flexible 8px-high proportion bar whose width is the stage's share of the
busiest stage; then a fixed 230px right-aligned cluster of the count, the amount
and the stuck badge. Below 640px the row stacks: label, bar, numbers.

- **Amount cell.** `"—"` when the stage is empty. **`"— no amount"`** when the
  stage has open deals but none of them carry a value. Otherwise `compactUsd`,
  plus a small `"+{k} no amount"` note.
- **Stuck badge.** Nothing at zero. Otherwise a badge reading
  **`"{n} stuck · {maxDays}d"`**, in the accent tone when the worst deal is past
  30 days and the neutral tone otherwise.
- A closed-won stage's bar fill is a muted grey rather than accent.

Two conditional footnotes:

- A pipeline with nothing in it:
  > "No deals in this pipeline yet. Each stage is shown above so the shape is
  > clear — deals appear here as they sync."
- Any stuck deals: the aging-approximation footnote (see §7).

**The orphan-stage rule.** An open deal whose stage is not in the known stage list
gets its own catch-all row, labelled with the raw stage identifier, or
**"Unrecognized stage"** when the stage is missing entirely. This exists so the
board's totals can never read lower than Forecast or Owners for the same pipeline.

**Loading.** A two-by-four grid of 52px pulses plus one 280px pulse.

**State A / B — one card.** Headline **"Your pipeline fills in after the first
sync"**, shown when the sync is pending, when there are no pipelines, or when none
is selected.

---

### 6. `revenue / forecast` — Forecast

**Purpose.** A weighted-pipeline forecast, framed hard so nobody mistakes it for
HubSpot's own probability figure.

**Data.** `GET /api/snapshot?view=deals`.

**The weights.** Open stages are interpolated between a floor of **0.1** and a
ceiling of **0.8** according to how far through the pipeline they sit. Closed won
is **1**. Closed lost is **0**. An unknown stage is **0.1**.

**Top to bottom**

1. **View header** — a telescope eyebrow reading "Forecast", heading
   **"Forecast"**.
2. **Control row** — pipeline switcher, plus `"{n} open"` / `"read-only"`.
3. **KPI band** — three tiles.
4. **The coverage band** — placed above the breakdown, on purpose.
5. **Breakdown panel.**
6. **Summary strip** — weighted, best case, deals weighted.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `trending-up` (hero) | `compactUsd(weighted)`, or `"—"` | Weighted forecast | `"directional estimate"`, or `"no amounts yet"` |
| `scale` | `compactUsd(best case)`, or `"—"` | Best case | `"all open close"`, or `"no amounts yet"` |
| `layers` | `{deals with an amount}/{open deals}` | Deals weighted | `"{k} no amount"`, or `"full coverage"` |

**Coverage band.** An accent-tinted band with an info glyph. Its eyebrow reads
**`"Forecast confidence: {confidence}"`**, where the confidence word is one of
four:

| Word | When |
|---|---|
| `no data` | Nothing carries an amount |
| `low` | Coverage below 60%, **or** fewer than 5 deals with an amount |
| `moderate` | Coverage below 85% |
| `fair` | Everything else |

The body sentence names the excluded deals explicitly and ends *"— so the real
number is likely higher."*

**Breakdown panel.** Eyebrow `"{pipeline label} · weighted by stage"`. Meta reads
`"{compactUsd} weighted"`, or **`"no amounts yet"`**.

Body, in order:

1. **Two stacked bars sharing one scale**, each 10px high. The first is labelled
   "Weighted forecast" with its value and an accent fill sized at weighted divided
   by best case. The second is labelled **"Best case (all open close)"** with its
   value, drawn as a full-width muted track.
2. The table.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Stage` | left | Stage label, open stages only, in display order |
| 2 | `Open` | **right, numeric** | `intf` |
| 3 | `Open $` | **right, numeric** | `compactUsd`; **`"— no $"`** when the stage has deals but no amounts, plus a `"+{k} no $"` note |
| 4 | `Stage weight` | **right, numeric** | The stage's weight |
| 5 | `Weighted` | **right, numeric** | Open amount × weight, or `"—"` |

3. The heuristic footnote (see §7).

**Loading.** Three-tile grid plus a 300px card.

**State A.** Headline **"Your forecast lands after the first sync"**, with the
Setup button.

**State B — synced, nothing open in this pipeline.** Headline **"No open pipeline
to forecast yet"**, rendered inside the shell so the switcher stays available.
**No Setup button on this one.**

---

### 7. `revenue / owners` — Owner leaderboard

**Purpose.** A standings board, not a flat grid. Reps are ranked by their open
book.

**Top to bottom**

1. **View header** — a trophy eyebrow reading "Owners", heading **"Owner
   leaderboard"**.
2. **Control row** — pipeline switcher, plus `"{n} ranked"` / `"read-only"`.
3. **KPI band** — three tiles.
4. **Standings panel.**
5. **Summary strip** — reps with a book, team open, top rep.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `circle-dollar-sign` (hero) | `compactUsd(team open)`, or `"—"` | Team open $ | `"{n} open · {k} reps"` |
| `trophy` | The top rep's name, or `"—"` | Top rep | `"by open $"`, or `"no book yet"` |
| `sparkle` | `"#{rank}"`, or `"—"` | Your rank | `"of {repCount}"`, or `"no book here"` |

**Standings panel.** Eyebrow `"{pipeline label} · standings"`. Meta reads
`"{n} with a book"`, or **`"no book carriers yet"`**.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Rank` | left | `"—"` when unranked. Otherwise the number, with an award glyph and heavier weight for ranks 1 to 3 |
| 2 | `Owner` | left | The name, plus an accent badge reading **"You"** for the signed-in rep, or the small note **"name pending"** when an owner has no synced name |
| 3 | `Open deals` | **right, numeric** | The count, de-emphasised at zero |
| 4 | `Open $` | **right, numeric** | `"—"` · **`"— no $"`** · `compactUsd` plus a `"+{k} no $"` note |
| 5 | `Won $` | **right, numeric** | `"—"` when nothing is won; otherwise `compactUsd` (or `"— no $"`) with a trailing `"{n} won"` |
| 6 | `Win-rate` | **right, numeric** | `pct(won ÷ closed)`, or `"—"` when there is no closed history. Never `NaN%` and never a fabricated `0%` |

**Row order.** Book-carriers first, ranked 1 to N; then the zero-book team members,
unranked. The ranking sort is open dollars descending, then open deal count
descending, then won dollars descending. When the zero-book tail is non-empty, a
footnote explains it. *Exact text: not specified in source.*

**The Unassigned bucket.** Deals with no owner stay visible as a table row, but
that row is excluded from "Top rep", from the rep count, and from the "Your rank"
denominator.

**Loading.** Three-tile grid plus a 300px card.

**State A.** Headline **"Owner standings appear after the first sync"**.

**State B.** Headline **"No deals yet to rank in this pipeline"**, rendered with
the header and switcher still above it.

---

### 8. `revenue / velocity` — Stage conversion & velocity

**Purpose.** Where deals fall out of the funnel, and how long they sit. Three
metrics with three different honesty positions.

**Top to bottom**

1. **View header** — a filter eyebrow reading **"Conversion & velocity"**, heading
   **"Stage conversion & velocity"**.
2. **Control row** — pipeline switcher, plus `"{n} reached won"` / `"read-only"`.
3. **KPI band** — three tiles.
4. **Conversion funnel panel.**
5. **The "history building" band.**
6. **Summary strip** — biggest drop, slowest now, reached won.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `trending-down` (hero) | `pct(drop-off)`, or `"—"` | Biggest drop-off | `"{from stage} → {to stage}"`, or `"no stage leak yet"` |
| `hourglass` | `"{n}d"`, or `"—"` | Slowest stage now | the stage label, or `"nothing sitting"` |
| `gauge` | `intf(won count)` | Reached won | `"{n} lost / exited"`, or `"the funnel floor"` |

**Conversion funnel panel.** Eyebrow `"{pipeline label} · conversion funnel"`.
Meta reads `"{n} deals"` or `"no deals"`.

One row per rung: a 170px label block with a trophy or a dot, then a **centred**
12px bar whose width is the rung's reached count over the top rung — so the rungs
visibly step down — then a 300px cluster of the reached count, the conversion
badge and the occupancy label.

- **Conversion badge.** At the bottom rung, a neutral badge reading **"funnel
  floor"**. When conversion cannot be computed, **"no volume"**. Otherwise
  **`"{pct} on · {pct} drop"`**, switching to the accent tone when the drop
  exceeds 50%.
- **Occupancy label.** `"{n}d"` with the caption `"median"`, or **`"— no age"`**,
  or **`"— empty"`**.
- When the pipeline holds fewer than five deals, a small-sample note appears:
  > "Small sample — {n} deals in this pipeline. The conversion rates below show
  > the shape of the funnel, but there are too few deals to read them as
  > meaningful rates yet."
- A footnote distinguishing *current occupancy* from *transition time* (see §7).

**History-building band.** Always rendered, because the screen has no read into
the server's daily history. An accent-tinted band with a history glyph, eyebrow
**"Transition velocity over time · history building"**, and body copy ending:

> "…The over-time trend appears here once that history is surfaced from the server
> — a forward-looking view by design, not something this page fills in on its own."

**Loading.** Three-tile grid plus a 320px card.

**State A.** Headline **"Your funnel lands after the first sync"**.

**State B.** Headline **"No deals to chart a funnel yet"**, inside the shell.

---

### 9. `revenue / stuck` — Stuck & aging

**Purpose.** The most actionable screen in the product: a staleness-sorted action
queue, worst first.

**Top to bottom**

1. **View header** — a flame eyebrow reading **"Stuck & aging"**, heading
   **"Stuck & aging"**.
2. **Control row** — pipeline switcher on the left; on the right, a scope toggle
   that appears **only when the signed-in user maps to a HubSpot owner**. Options:
   **"All reps"** (the default) and **"Mine only"**.
3. **KPI band** — three tiles.
4. **Queue panel.**
5. **Summary strip** — aging, stale, at risk.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `circle-dollar-sign` (hero) | `compactUsd(at risk)`, or `"—"` | $ at risk | `"{k} no amount"` · `"in stuck deals"` · `"nothing at risk"` |
| `timer-reset` | `intf(count)` | `Aging (>14d)` | `"needs a nudge"`, or `"none aging"` |
| `alarm-clock-off` | `intf(count)` | `Stale (>30d)` | `"chase today"`, or `"none stale"` |

**Queue panel.** Eyebrow `"{pipeline label} · stuck deals"`. Meta reads
`"{n} stuck"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Deal · pipeline` | left | The stage name stacked over the pipeline label. Below 640px the age badge is inlined here as well |
| 2 | `Owner` | left | Owner name |
| 3 | `Age` | left | The age badge. **Hidden below 640px** |
| 4 | `Amount` | **right, numeric** | `compactUsd`, or **`"— no amount"`** when null |
| 5 | *(no header)* | right | A **"HubSpot"** link with an external-link glyph, plus an **"Ask"** chip |

The age badge here carries a glyph as well as the badge: an alarm-clock-off or
timer-reset icon, then a badge reading **`"{days}d · stale"`** in the accent tone
or **`"{days}d · aging"`** in the neutral tone.

Footnote, which states the thresholds inline:

> "Aging is measured from each deal's last activity (an approximation — the source
> has no exact stage-entry time). 'Aging' is more than 14 days, 'stale' more than
> 30."

**How the queue is built.** Open deals only; only those past the aging threshold;
optionally filtered to the signed-in owner; sorted by days descending so the worst
sits at the top.

**Loading.** Three-tile grid plus a 280px card.

**State A.** Headline **"Your stuck-deals queue lands after the first sync"**.

**State B — the good-news card.** Headline **"Nothing stuck — your pipeline is
moving"**. This is the one empty state in the app that uses the **mint** tint and
a check-circle glyph instead of the accent tint. The body copy differs by scope;
under "Mine only" it reads:

> "None of **your** open deals in this pipeline have aged past 14 days in-stage…"

The KPI band and the summary strip stay rendered around this card.

---

### 10. `revenue / winloss` — Win / Loss

**Purpose.** What closes won versus lost, the win rate, the average won deal size,
and — where anyone recorded it — why deals are lost. This is the thinnest data in
the cockpit, so the degraded states *are* the feature.

**The thin-sample rule.** Below **5** closed deals, the win-rate percentage **and**
the proportion bar are suppressed, and everything below the tiles is withheld.

**Top to bottom**

1. **View header** — a swords eyebrow reading **"Win / Loss"**, heading **"Win /
   Loss"**.
2. **Control row** — pipeline switcher, plus `"{n} closed"` / `"read-only"`.
3. **KPI band** — five tiles.
4. Either the thin-sample band, **or** everything in step 5.
5. Summary panel, reasons-coverage nudge, reasons panel, two dimension panels.
6. **Summary strip** — win rate, won, lost, average won deal.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `percent` (hero) | `pct(win rate)`, or `"—"` when the sample is thin | Win rate | `"too few closed"` · `"{n} of {m} closed"` · `"nothing closed"` |
| `check` | `intf(won count)` | Won | `compactUsd(won amount)`, or `"no $"` |
| `x` | `intf(lost count)` | Lost | `compactUsd(lost amount)`, or `"no $"` |
| `circle-dollar-sign` | `compactUsd(avg won)`, or `"—"` | Avg won deal | `"won deals with $"`, or `"no won $"` |
| `clipboard-check` | `pct(1 − share missing)`, or `"—"` | Reasons coverage | `"no lost deals"` · `"every lost deal tagged"` · `"{pct} missing"` |

**Thin-sample band.** An accent-tinted band with an info glyph, eyebrow **"Too few
closed deals"**, body naming the raw counts. When this shows, everything below it
is withheld.

**Summary panel.** Eyebrow `"{pipeline label} · won vs lost"`. Meta reads
`"{n} closed"`. Body: a single 12px split bar — the won segment in mint tint, the
lost segment in muted grey — with a legend beneath. On the left, a check-in-mint
chip, the word **"Won"**, and `"{n} · {pct}%"`. On the right, an x-in-surface chip,
the word **"Lost"**, and `"{n} · {pct}%"`. Below the bar, a two-up grid of stat
cards labelled **`Won $`** and **`Lost $`**.

**Reasons-coverage nudge.** Renders only when at least one lost deal has no reason
recorded. Eyebrow **"Reasons coverage"**, megaphone glyph.

**Reasons panel — one of two forms.**

When reasons exist: eyebrow `"{pipeline label} · why we lose"`, meta reads
**`"{n} of {m} lost tagged"`**.

| # | Header | Align |
|---|---|---|
| 1 | `Loss reason` | left |
| 2 | `Deals` | **right, numeric** |
| 3 | `Share` | **right, numeric** |

When none exist: a plain band with eyebrow **"Why we lose — not recorded yet"**, a
triangle-alert glyph, and an underlined link reading **"How to record loss
reasons"** pointing at Setup.

**Two dimension panels**, in this order: by **source** (megaphone glyph), then by
**deal type** (tag glyph). Each has eyebrow `"{pipeline label} · by {dimension}"`
and meta `"{n} bucket(s)"`.

| # | Header | Align |
|---|---|---|
| 1 | `{dimension}` | left |
| 2 | `Won` | **right, numeric** |
| 3 | `Lost` | **right, numeric** |
| 4 | `Win rate` | **right, numeric** — `"—"` for a thin bucket |

When no closed deal records that dimension, the panel degrades to a plain band
with the eyebrow **`"By {dimension} — not recorded yet"`**.

**Loading.** Three-tile grid plus a 300px card.

**State A.** Headline **"Win/loss history fills in after the first sync"**.

**State B.** Headline **"Nothing has closed yet"**, with a Setup button, inside the
shell.

---

### 11. `marketing / leadfunnel` — Lead Funnel *(Marketing default)*

**Purpose.** The HubSpot lifecycle funnel, framed around the collapse between
leads and MQLs.

**Stage labels**, in the order the data supplies them — **never re-sorted by
count**:

| Key | Label |
|---|---|
| `leads` | Leads |
| `marketingQualifiedLeads` | MQLs |
| `salesQualifiedLeads` | SQLs |
| `opportunities` | Opportunities |
| `customers` | Customers |

**Top to bottom**

1. **View header** — a filter eyebrow reading "Lead Funnel", heading **"Lead
   Funnel"**, and a lede ending *"Switch the bars to a log scale to see the
   orders-of-magnitude collapse."*
2. **KPI band** — four tiles.
3. **The cliff band.**
4. **Lifecycle funnel panel.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `users` (hero) | `intf(leads)` | Leads | `"funnel mouth"` |
| `target` | `intf(opportunities)` | Opportunities | `"qualified past MQL/SQL"` |
| `trophy` | `intf(customers)` | Customers | `"closed-won lifecycle"` |
| `percent` | `pct(opps ÷ leads)`, or `"—"` | Lead → opp | `"{n} of {m}"`, or `"no leads yet"` |

**Cliff band.** An accent-tinted band with a trending-down glyph. Eyebrow reads
**`"The {leads} → {next stage} cliff"`** with the labels lower-cased. The body
names the raw counts and the pass-through percentage and ends *"read them as raw
counts, not rates."* It renders only when a leads stage, a following stage, and a
non-zero lead count all exist.

**Lifecycle funnel panel.** Eyebrow **"Lifecycle funnel"**. The meta slot holds the
**scale toggle**.

Each stage row is two lines: line 1 has a dot and the stage label on the left, the
count and `"{pct} of leads"` on the right; line 2 is an 8px accent bar. The bar
width uses whichever scale is selected, floored at 1.5% for any non-zero stage so
that a stage holding 1 of 50,000 is never a zero-width bar.

**Scale toggle.** Two buttons, **"Log"** and **"Linear"**, 44px tall, the active
one filled with the accent tint. **Default is Log.** Log width is
`log10(count+1) ÷ log10(max+1)`; linear width is `count ÷ max`.

Beneath the funnel, a note whose copy flips with the toggle. The log variant:

> "Bars use a **log scale** so the orders-of-magnitude drop between stages is
> legible — the bar width is not a raw proportion. The count and share-of-leads
> beside each stage are the exact figures."

*The linear variant's exact text: not specified in source.*

**Loading.** A two-by-four grid plus a 280px card.

**State A / B — one card.** Headline **"The lifecycle funnel fills in after the
first sync"**, shown when the sync is pending or there are no rows.

---

### 12. `marketing / sources` — Lead Source ROI

**Purpose.** Which channels actually convert. Ranked by **conversion density** —
opportunities divided by leads — deliberately not by volume.

**Ranking.** Density descending, then opportunities descending, then a stable sort
on the name. Density is null when a source has zero leads, and renders `"—"`. A
source is **vanity** when it has leads and exactly zero opportunities.

**Top to bottom**

1. **View header** — a compass eyebrow reading "Lead Source ROI", heading **"Lead
   Source ROI"**.
2. **KPI band** — three tiles.
3. **The vanity band.**
4. **Sources table.**
5. **The attribution caveat.**
6. **Summary strip** — label "Ranked by conversion density", then sources,
   opportunities, vanity.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `trophy` (hero) | `pct(density)`, or `"—"` | Best-converting source | the source name, or `"no leads yet"` |
| `target` | `intf(total opps)` | Opportunities (all sources) | `"across the ranked channels"` |
| `ghost` | `intf(vanity count)` | Vanity sources | `"none — every source converts"`, or `"leads, zero opportunities"` |

**Vanity band.** An accent-tinted band with a ghost glyph, eyebrow **"Vanity
sources — leads, zero opportunities"**. It names the loudest **five** as pill chips
reading `"{source} {n} leads"`, then a `"+{k} more"` pill. Renders only when at
least one vanity source exists.

**Sources table.** Eyebrow **"Sources · ranked by conversion density"**. Meta reads
`"{n} source(s)"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Source` | left | A leading dot and the source name. A vanity row swaps the dot for a ghost glyph and appends an uppercase **`vanity`** pill |
| 2 | `Leads` | **right, numeric** | `intf` |
| 3 | `Opps` | **right, numeric** | `intf` |
| 4 | `Conv. density` | **right, numeric** | `pct`, or `"—"` |
| 5 | `Visits` | **right, numeric** | `intf` |

**Attribution caveat.** A plain surface band with an info glyph:

> "Sources here are **last-touch web-analytics channels** (direct, organic search,
> paid search, referrals, …) — the channel recorded on the contact, not per-deal
> multi-touch attribution. A high conversion density is a correlation worth
> investigating, not a credited-revenue claim."

**Loading.** Three-tile grid plus a 320px card.

**State A / B — one card.** Headline **"Lead sources fill in after the first
sync"**.

---

### 13. `marketing / audience` — Audience Growth

**Purpose.** Net-new contact and company growth, the lifecycle mix, the top
acquisition sources, and record completeness.

**Top to bottom**

1. **View header** — a users eyebrow reading "Audience Growth", heading **"Audience
   Growth"**.
2. **KPI band** — three tiles.
3. **Two-up growth grid** — one column below 1024px, two columns above.
4. **Lifecycle mix panel** — conditional.
5. **Top sources panel** — conditional.
6. **Data completeness panel.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `users` (hero) | `intf(contacts held)` | Contacts synced | `"rows in the cockpit"` |
| `building-2` | `intf(companies held)` | Companies synced | `"rows in the cockpit"` |
| `trending-up` | `pct(contacts with a lifecycle stage)`, or `"—"` | With lifecycle stage | `"completeness"` |

**Growth panels.** Two of them, eyebrows **"Contacts — net new"** and **"Companies
— net new"**, meta `"{n} net-new"`. The body is a banner-size sparkline over the
daily net-new series plus a `"{n} day(s)"` label. Empty body: *"No dated rows
synced yet."*

**Lifecycle mix panel.** Eyebrow **"Lifecycle mix"**, meta `"{n} contacts"`. Body
is a bar list: one row per stage, label left, count right, with a 6px accent bar
beneath, floored at 1.5% for any non-zero row.

**Top sources panel.** Eyebrow **"Top sources"**, meta `"{n} sources"`. Same bar
list, **capped at the first eight sources**.

**Data completeness panel.** Eyebrow **"Data completeness"**, meta `"{n} metrics"`.
One row per metric: `{numerator} / {denominator} · {pct}` on the right, a 4px bar
below.

| Metric | Label |
|---|---|
| `contacts_with_lifecycle` | Contacts with a lifecycle stage |
| `contacts_with_source` | Contacts with a source |
| `companies_with_country` | Companies with a country |
| `companies_regulated` | Companies flagged regulated-industry |

Footnote:

> "Sparse is normal while the team is configuring HubSpot — completeness rises as
> records are enriched. Regulated-industry and intent fields are largely unset
> today."

Empty body: *"Completeness fills in as the contact/company crawl lands."*

**Loading.** Three-tile grid plus a 200px card.

**State A / B — one card.** Headline **"The audience sync is still building"**,
shown when the audience sync is pending or no contacts are held. Its body explains
the resumable batch crawl of roughly 50,000 contacts and 43,000 companies.

---

### 14. `marketing / campaigns` — Campaigns & Segments

**Top to bottom**

1. **View header** — a megaphone eyebrow reading **"Campaigns & Segments"**,
   heading **"Campaigns & Segments"**.
2. **KPI band** — three tiles.
3. **The sparse-analytics note** — conditional.
4. **Campaigns panel.**
5. **Lists panel.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `megaphone` (hero) | `intf(campaign count)` | Campaigns | `"marketing campaigns"` |
| `list-checks` | `intf(list count)` | Lists & segments | `"contact lists"` |
| `users` | `intf(largest list size)`, or `"—"` | Largest list | `"members"` |

**Sparse-analytics note.** Rendered only when some windowed campaign performance
exists. An accent-tinted band, eyebrow **"Campaign analytics are sparse for this
org"**:

> "A real 0 is shown as 0; a campaign with no analytics row for the window shows
> '—'. Nothing is estimated."

**Campaigns panel.** Eyebrow **"Campaigns"**. Its meta slot holds the **time window
chips when performance data exists**, and otherwise a plain `"{n} campaign(s)"`
count.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Campaign` | left | The name; a nameless campaign renders **"Untitled campaign"** |
| 2 | `Sessions` | **right, numeric** | `intf`, or `"—"` when no row exists for this window |
| 3 | `New contacts` | **right, numeric** | same |
| 4 | `Influenced` | **right, numeric** | same |
| 5 | `Revenue` | **right, numeric** | `usd`, or `"—"` |
| 6 | `Updated` | left | `timeAgo` |

A genuine zero renders as `0`. Only a *missing* row renders `"—"`.

Empty body: *"No campaigns synced yet."*

**Lists panel.** Eyebrow **"Lists & segments"**, meta `"{n} list(s)"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `List` | left | The name; nameless renders **"Untitled list"** |
| 2 | `Members` | **right, numeric** | `intf`, or `"—"` when the size is null |
| 3 | `Type` | left | The list type |

Empty body: *"No lists synced yet."*

When the reported total exceeds the rows returned, a footnote appears:

> "Showing {n} of {m} lists — membership sizes come from HubSpot's hs_list_size."

**Time window.** Local to the browser, starting at **30d**. No request is made when
it changes; every window's figures ship in the one payload.

**Loading.** Three-tile grid plus a 220px card.

**State A.** Headline **"Campaigns & lists fill in after the first sync"**.

**State B.** Fired when both rosters are empty. Headline **"No campaigns or lists
yet"**, with **no** Setup button.

---

### 15. `marketing / formsemails` — Forms & Emails

**Top to bottom**

1. **View header** — a clipboard-list eyebrow reading **"Forms & Emails"**, heading
   **"Forms & Emails"**.
2. **KPI band** — three tiles.
3. **Form conversion panel** — conditional.
4. **The email-performance note.**
5. **Forms panel.**
6. **Emails panel.**

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `file-text` (hero) | `intf(form count)` | Forms | `"lead-capture forms"` |
| `mail` | `intf(email count)` | Marketing emails | `"email assets"` |
| `send` | `intf(non-archived form count)` | Active forms | `"not archived"` |

**Form conversion panel.** Eyebrow **"Form conversion"**. Its meta slot holds the
time window chips. The body is a single headline sentence:

> "{views} views → {submissions} submissions · {conv} conversion · {contactSubs}
> contact subs"

The conversion figure is shown to one decimal place and is only computed when views
is greater than zero. Empty body: *"No form analytics for this window yet."*

**Email-performance note.** An accent-tinted band with an info glyph, eyebrow
**"Email send / open performance is a future enrichment"**.

**Forms panel.** Eyebrow **"Forms"**, meta `"{n} form(s)"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Form` | left | The name; nameless renders **"Untitled form"** |
| 2 | `Fields` | **right, numeric** | `intf` |
| 3 | `Views` | **right, numeric** | `intf`, or `"—"` |
| 4 | `Submissions` | **right, numeric** | `intf`, or `"—"` |
| 5 | `Conv %` | **right, numeric** | one decimal place, or `"—"` |
| 6 | `Status` | left | A badge — the good tone reading **"Active"**, or the neutral tone reading **"Archived"** |

Empty body: *"No forms synced yet."*

**Emails panel.** Eyebrow **"Marketing emails"**, meta `"{n} email(s)"`.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Email` | left | The name; nameless renders **"Untitled email"** |
| 2 | `State` | left | A neutral badge |
| 3 | `Published` | **right, numeric** | `timeAgo` |

Empty body: *"No marketing emails synced yet."*

**Time window.** Local to the browser, starting at **30d**.

**Loading.** Three-tile grid plus a 220px card.

**State A.** Headline **"Forms & emails fill in after the first sync"**.

**State B.** Headline **"No forms or emails yet"**.

---

### 16. `#/leadership/meetings` — Customer Meetings

**Purpose.** An operator-authored meeting log with full create, edit and delete.
**This is not HubSpot data.** It is typed by hand and stored in our own database.

**Data.** `GET/POST/PUT/DELETE /api/leadership/meetings`.

Leadership screens have **no `<h1>`**. They lead with the panel eyebrow.

**Panel.** Title **"Customer Meetings"**, eyebrow "Customer Meetings",
calendar-check icon. The meta slot holds a **"+ New"** button filled in the accent
colour.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Customer / Prospect` | left | Falls back to `"—"` |
| 2 | `Attendees` | left | Falls back to `"—"` |
| 3 | `Internal Lead` | left | Falls back to `"—"` |
| 4 | `Demo` | left | Falls back to `"—"` |
| 5 | `CTA` | left | Falls back to `"—"` |
| 6 | `Objective` | left | Falls back to `"—"` |
| 7 | `A Win Is…` | left | Falls back to `"—"` |
| 8 | *(no header)* | right | A pencil button labelled **"Edit {customer}"** and a bin button labelled **"Delete {customer}"** |

**Drawer fields.** The drawer slides in from the right, capped at 440px wide.

| Field | Label | Type | Options | Required |
|---|---|---|---|---|
| `customer` | Customer / Prospect | text | — | **Yes** |
| `attendees` | Meeting Attendees | text | — | No |
| `internal_lead` | Internal Lead | text | — | No |
| `demo` | Demo / Product | select | `Yes`, `No` | No |
| `cta` | CTA | textarea | — | No |
| `objective` | Objective | textarea | — | No |
| `a_win_is` | A Win Is… | textarea | — | No |
| `meeting_date` | Meeting Date | date | — | No |

Select fields are **combo boxes, not locked dropdowns** — the listed options are
suggestions and free text is allowed.

**Loading.** A single 96px pulsing bar inside the panel.

**Empty.** A centred bordered card inside the panel reading **"No meetings logged
yet."** with a second button beneath reading **"Add the first one"**.

**Toasts.** Create success **"Added"**. Update success **"Saved"**. Delete success
**"Row deleted"** with an **Undo** action. Failures: **"Couldn't save — please try
again"**, **"Couldn't delete — please try again"**, **"Couldn't undo"**.

---

### 17. `#/leadership/pipeline` — Pipeline Health

**Purpose.** Live HubSpot deals joined to hand-written CTA and risk annotations,
plus the counts of deals missing a next step or missing required fields.

**Data.** `GET /api/leadership/pipeline`; annotations save to
`PUT /api/leadership/annotations/{dealId}`.

**Top to bottom**

1. **KPI band** — four tiles, all scoped to the currently filtered rows.
2. **Panel** with the controls in its header and the table beneath.

**KPI tiles**

| Icon | Value | Label | Hint |
|---|---|---|---|
| `git-branch` | The row count | Open opportunities | — |
| `alert-triangle` | Count of deals with a blank next step | Missing a next step | `"hs_next_step is blank"` |
| `git-branch` | The summed amount, as whole dollars | Open revenue potential | — |
| `alert-triangle` | Count of deals missing any required field | Missing required fields | — |

> **Defect — fix, do not copy.** This screen formats money with its own local
> helper rather than the shared `usd` formatter. The output happens to match, but
> it is a second code path that can drift. Use one formatter.

**Panel.** Eyebrow **"Pipeline Health"**. Its meta slot carries two controls:

- The **pipeline switcher** — shown only when more than one pipeline exists.
- The **scope toggle** — shown only when the signed-in user maps to a HubSpot
  owner. Options **"All reps"** and **"Mine only"**.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Opportunity` | left | Deal name |
| 2 | `Stage` | left | Stage name |
| 3 | `Revenue` | **right, numeric** | Whole dollars |
| 4 | `Owner` | left | Owner name |
| 5 | `Next Step` | left | Either an accent badge reading **"Needs next step"**, or the plain text |
| 6 | `CTA` | left | An inline-editable cell, placeholder **"Add CTA"** |
| 7 | `Risk / Blocker` | left | An inline-editable cell, placeholder **"Add risk / blocker"** |
| 8 | `Data to fix` | left | `"—"`, or a wrap of accent badges (one per missing field) followed by a **"Fix in HubSpot"** link |

The Fix link opens in a new tab and its accessible name is **"Fix {opportunity} in
HubSpot (opens in a new tab)"**.

**Loading.** A single 96px pulsing bar inside the panel — not a full skeleton.

**Empty.** A bordered centred card inside the panel, with two copies:

- Sync still running: *"Deals are still syncing from HubSpot."*
- Otherwise: *"No open opportunities in this pipeline."*

---

### 18. `#/leadership/contracts` — Contract / Agreement Review Queue

**Purpose.** A hand-authored queue of agreements in review. Same chassis as
Customer Meetings.

**Data.** `GET/POST/PUT/DELETE /api/leadership/contracts`.

**Panel.** Title **"Contract / Agreement Review Queue"**, eyebrow **"Contract
Review"**, file-check icon, with the **"+ New"** button in the meta slot.

| # | Header | Align |
|---|---|---|
| 1 | `Agreement / Document` | left |
| 2 | `Business Owner` | left |
| 3 | `Status` | left |
| 4 | `Legal Risk` | left |
| 5 | `Compliance Risk` | left |
| 6 | `Decision Needed` | left |
| 7 | `Due Date` | left |
| 8 | *(no header)* | right — edit and delete buttons |

Every cell falls back to `"—"`.

**Drawer fields**

| Field | Label | Type | Options | Required |
|---|---|---|---|---|
| `agreement` | Agreement / Document | text | — | **Yes** |
| `business_owner` | Business Owner | text | — | No |
| `status` | Status | select | `Not started`, `In progress`, `Blocked`, `Complete` | No |
| `legal_risk` | Legal Risk | textarea | — | No |
| `compliance_risk` | Compliance Risk | textarea | — | No |
| `decision_needed` | Decision Needed | select | `Yes`, `No`, `TBD` | No |
| `due_date` | Due Date | date | — | No |

**Empty.** **"No agreements in the review queue yet."** plus **"Add the first
one"**.

**Loading and toasts.** Identical to Customer Meetings.

---

### 19. `#/leadership/datafix` — Data to Fix

**Purpose.** Companies or contacts that are missing their required fields, scoped
by owner, with a one-click jump to the HubSpot record. This is the screen that made
the data-quality problem visible.

**Data.** `GET /api/leadership/datafix?object=…&scope=…[&missing=a,b][&sort=…&dir=…]`.

**Everything on this screen is server-side.** Filtering, sorting and scoping all
refetch. The table shows at most 200 rows out of tens of thousands, so a
browser-side filter would lie. While a refetch is in flight the previous rows stay
on screen, so the table never flashes empty.

**Top to bottom**

1. **Panel** with eyebrow **"Data to Fix"** and a mono caveat string in its meta
   slot.
2. **Two scope toggles.**
3. **Missing-field checkboxes.**
4. **The table.**

**The caveat string.** Built as:

`"{shown} of {scoped, or '{matching} matching'} · {synced} synced (capped crawl)"`

plus `" · {reportedTotal} in HubSpot"` **only when that total is above zero** — it
must never read "0 in HubSpot".

**Toggle 1 — object.** Options **"Companies"** and **"Contacts"**. Switching object
**clears the active missing-field filters**, because the required fields differ
between the two.

**Toggle 2 — owner scope.** Options **"Mine"** and **"All"**, plus **"Unowned"**
*only for a manager*.

**Missing-field checkboxes.** One per required field. Each reads **`"Missing {field
label}"`** followed by a small mono count, styled as a chip with an accent dot when
checked. Checked options combine with OR, and each change refetches.

| # | Header | Align | Sortable | Content |
|---|---|---|---|---|
| 1 | `Name` | left | Yes | Record name |
| 2 | `Owner` | left | Yes | Owner name |
| 3 | `Missing` | left | Yes | A wrap of accent badges, or `"—"` |
| 4 | `Fix` | left | No | A **"Fix in HubSpot"** link — company records use `/record/0-2/`, contacts `/record/0-1/` |

**Sort behaviour.** `Missing` leads **descending**, so the most-broken records come
first. The two text columns lead **ascending**. A third click clears the sort and
returns to the server's own priority order. The sort state is announced to screen
readers and is omitted entirely when the column is unsorted.

**Loading.** A single 96px pulsing bar inside the panel.

**Empty — three different sentences:**

- Sync still running: *"{Companies|Contacts} are still syncing from HubSpot."*
- Filters active: *"No {companies|contacts} match the active filters in this
  scope."*
- Otherwise: *"No {companies|contacts} need attention in this scope."*

---

### 20. `#/pricing/price` — Price a deal

**Purpose.** A rep enters a merchant's profile and gets a rate, a margin, a health
light and a shareable quote link.

**The business rules, every rate and every worked example live in
`02-pricing-engine/`.** This section records only the shell.

**Layout.** A top meta row: a deal-context chip on the left, and on the right a
mono note reading `"rates v{n}"`. Below that, up to two banners. Then a two-column
grid at 1024px and above — a **380px** form column on the left and the results on
the right — collapsing to a single column below that, form first. The form column
is **sticky**, pinned 120px from the top. The form card carries the `<h1>` **"Price
a deal"**.

**The two banners**

| Banner | Tone | When | Copy |
|---|---|---|---|
| Unreadable link | Red tint, announced as an alert | The shared URL could not be decoded | "This link couldn't be read — it may have been truncated or edited in transit. You're seeing a blank deal, not the one that was shared. Ask for the link again before quoting from it." |
| Re-priced | Amber tint, announced as a status | The quote was recalculated under a newer config | *Not specified in source.* |

**Loading.** A bare centred line reading **"Loading live rates…"**.

> **Defect — fix, do not copy.** This is the only screen in the app without a
> designed skeleton. Give it one, matching the pattern in §3a.

**The URL is the quote.** Every input is encoded in the query string, and links
already sit in customers' inboxes. Pricing rewrites its hash without disturbing the
query string. Do not change the encoding.

---

### 21. `#/pricing/configure` — Configure

**Purpose.** The locked cost engine behind every quote: interchange tables, buy
rates, card mixes, downgrade assumptions and floors.

**The permission boundary is the point of this screen.** For a user who is not a
configuration editor, the tab **stays visible** and its body renders a designed
card:

- A shield-alert glyph
- Heading: **"Configuration is ChainIT-Leadership only"**
- Body: an explanation that the cost engine is edited by a named few

The tab is deliberately not hidden. A missing tab reads as a bug; a "Leadership
only" card reads as a rule.

**Full field list, grouping and save behaviour:**
`02-pricing-engine/03-config-schema-and-defaults.md`.

---

## 6. Role-dependent behaviour, collected

The real app derives the role from the signed-in identity. The prototype uses a
role dropdown in the header instead. These are the places the role actually changes
what is on screen.

| Screen | What changes |
|---|---|
| My Day | The heading, the lede, and a `"Team "` prefix on every KPI label for a manager |
| Signals | The second tile's label: **"New since you were away"** for a rep, **"New since last visit"** for everyone else |
| Signals — away strip | Its label: **"Since you were away"** for a rep, **"Since last visit"** otherwise |
| Stuck & aging | The scope toggle appears **only** when the login maps to a HubSpot owner |
| Pipeline Health | The scope toggle appears **only** when the login maps to a HubSpot owner |
| Data to Fix | The **"Unowned"** scope option appears **only** for a manager |
| Owner leaderboard | The signed-in rep's row carries a **"You"** badge; the "Your rank" tile reads their position |
| Pricing → Configure | A non-editor sees the read-only boundary card instead of the form |

Two permissions the prototype must **not** merge: editing the cost engine, and
seeing our margin. They are separate grants and a person can hold either without
the other.

---

## 7. Invariants that must not drift

Eight rules hold the product together. A prototype that breaks any of them is
building a different product.

1. **Never `$NaN`, never `NaN%`, never a fabricated `$0`.** Missing money is null
   and renders `"—"` or `"— no amount"`. Every roll-up sums only the subset that
   actually carries a value, and says how many it left out.
2. **The two pipelines never merge.** Exactly one pipeline renders at a time. There
   is no "All" option and there never will be — the two funnels have different
   stage counts and a blended total is meaningless. The one deliberate exception is
   My Day's open-deals tile, whose hint says **"across all pipelines"** out loud.
3. **Every state looks finished.** Loading is a designed skeleton that holds the
   layout. Sync-pending is a designed card with a Setup button. Synced-but-empty is
   a *different* designed card without one. Nothing-stuck is a mint success card.
   There are no blank walls and no spinners over content.
4. **The screen never throws.** A failed request degrades to the same designed
   empty card as no data. There is no error boundary anywhere, because nothing is
   allowed to reach one.
5. **Colour is never the only signal.** Every status carries a glyph, an explicit
   word, and an accessible attribute. The dashboard palette has no red at all —
   severity reads as `"{n}d · stale"` on an accent tint, never as a red pill.
6. **Hairline elevation, no shadow.** Nowhere in the app is a drop shadow used.
   Depth is a step up the surface ladder or a hairline border.
7. **Skeletons only on a cold load.** A background refresh never blanks a screen
   that already holds numbers.
8. **KPI tiles have no deltas.** There is no up-arrow, no "vs last month", no trend
   chip on any tile anywhere. The hint line carries the context instead — a count, a
   denominator, or a caveat like `"too few closed"`. Do not add one.

### The honesty footnotes

These paragraphs are the product's actual differentiator. A rebuild that drops them
loses the point of the design. Reproduce them verbatim.

- **Aging is an approximation.** "Aging is measured from each deal's last activity
  (an approximation — the source has no exact stage-entry time). 'Aging' is more
  than 14 days, 'stale' more than 30."
- **Forecast weights are a heuristic.** "Stage weights are a directional estimate
  from how far each stage sits in the pipeline (early stages low, late stages high;
  closed-won = 100%, closed-lost = 0%) — not HubSpot's own probability. The forecast
  is a guide to what's likely to close, not a commitment."
- **History is server-gated.** "…The over-time trend appears here once that history
  is surfaced from the server — a forward-looking view by design, not something this
  page fills in on its own."
- **Small sample.** "Small sample — {n} deals in this pipeline. The conversion rates
  below show the shape of the funnel, but there are too few deals to read them as
  meaningful rates yet."
- **Log scale is legibility, not proportion.** "Bars use a **log scale** so the
  orders-of-magnitude drop between stages is legible — the bar width is not a raw
  proportion. The count and share-of-leads beside each stage are the exact figures."
- **Last-touch attribution.** "Sources here are **last-touch web-analytics
  channels** (direct, organic search, paid search, referrals, …) — the channel
  recorded on the contact, not per-deal multi-touch attribution. A high conversion
  density is a correlation worth investigating, not a credited-revenue claim."
- **Campaign analytics are sparse.** "HubSpot campaign analytics are sparse for this
  org — most read 0 today. A real 0 is shown as 0; a campaign with no analytics row
  for the window shows '—'. Nothing is estimated."
- **Capped crawl.** "Sparse is normal while the team is configuring HubSpot —
  completeness rises as records are enriched. Regulated-industry and intent fields
  are largely unset today."

Two more exist but their full text is not quoted in the source: the
occupancy-versus-transition-time footnote on Velocity, and the cross-object caveat
on Onboarding. Write them in the same voice.

---

## 8. Things that deliberately do not exist

The prototype should not add any of these. Every one was checked and confirmed
absent from the real app.

- No router library. Navigation is state plus a small hash hook.
- No global search, no command palette, no keyboard shortcut owned by the app.
- No user settings, preferences or profile screen. The only stored preference is
  the theme.
- No notification centre, no badge counts, no unread state.
- No export, download, CSV or print affordance anywhere.
- No date-range picker. The only temporal control is the four window chips, on two
  panels.
- No free-text search box and no filter-by-text input. The only filters are the
  segmented toggles and Data to Fix's checkboxes.
- No pagination, infinite scroll, or "load more". Row caps are server-side and
  stated in prose.
- No row click, row hover highlight, row selection, checkbox or bulk action in any
  table.
- No column sorting except on Data to Fix.
- No drag-and-drop and no kanban board. "Pipeline board" is a read-only funnel of
  bars.
- No chart library. Every visualisation is a hand-rolled bar or a hand-drawn line.
- No tooltips on data points. Bars carry a spoken label instead.
- No error boundary.

### The dead numbers

Every section in the real code carries a `slice` number recording which build phase
shipped it. Those phases are all complete and the number feeds a placeholder card
that can no longer be reached. **Drop the field.**

### One more naming trap

The accent colour token in the original source is named
`--color-accent-lavender`. **It is green** — a forest green, hue 152. Every mention
of "lavender" in the original code is a misnomer. A rebuild that takes the name
literally will ship the wrong colour on every screen in this document.
