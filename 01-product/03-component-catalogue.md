# Component catalogue

*The shared parts every screen is assembled from. Seventeen of them. Build these
first, on their own preview page, before building a single screen — every later
screen can then be described as "the same as Pipeline, but…", which is far
cheaper than describing a table from scratch nine times.*

Each entry gives the component's job, its inputs, what it looks like, what
states it has, and which screens use it. Sizes are the real ones. Colours are
named by their role — the actual values live in
`03-design-system/02-tokens.css`.

Three rules apply to all seventeen and are not repeated in each entry:

- **No drop shadow, ever.** Depth is a hairline border or a step up the surface
  ladder.
- **Every interactive element has a visible focus ring** — 2px accent, 2px
  offset.
- **Every column of numbers uses tabular figures.**

Where an entry says **Defect — fix, do not copy**, that is a real fault in the
current app. Fix it in the prototype.

---

## Index

| # | Component | Job | Screens using it |
|---|---|---|---|
| 1 | [PanelFrame](#1-panelframe) | The container every block of content sits in | All but three |
| 2 | [KpiTile](#2-kpitile) | One headline number | Every data screen |
| 3 | [KpiRow](#3-kpirow) | A responsive band of tiles | Every data screen |
| 4 | [DataTable](#4-datatable) | The workhorse table | 12 screens |
| 5 | [StatusBadge](#5-statusbadge) | A small word-bearing pill | 10 screens |
| 6 | [PipelineSwitcher](#6-pipelineswitcher) | Choose one pipeline, never both | 7 screens |
| 7 | [WindowChips](#7-windowchips) | Choose a time window | 2 screens |
| 8 | [ScopeToggle](#8-scopetoggle) | Choose whose records to show | 3 screens |
| 9 | [SparkLine](#9-sparkline) | A tiny trend line | 1 screen |
| 10 | [EmptyCard](#10-emptycard) | A designed empty state | 15 places |
| 11 | [Skeleton](#11-skeleton) | A designed loading state | Every data screen |
| 12 | [RecordDrawer](#12-recorddrawer) | The right-hand editing panel | 2 screens |
| 13 | [EditableReport](#13-editablereport) | The whole create/edit/delete chassis | 2 screens |
| 14 | [InlineEditCell](#14-inlineeditcell) | Edit one cell in place | 1 screen |
| 15 | [SyncNowButton](#15-syncnowbutton) | Force a refresh, with a cooldown | 1 screen |
| 16 | [AskCopilot](#16-askcopilot) | A link out to the company copilot | 2 screens |
| 17 | [HandoffPanel](#17-handoffpanel) | Won deals that never reached onboarding | 1 screen |

Then: [the app-shell screens](#the-app-shell-screens) and
[do not build these](#do-not-build-these).

---

## 1. PanelFrame

**Job.** The container every block of content sits in. Every panel in the app is
one of these — there is no second card style.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `testId` | string | — | A hook for tests |
| `ariaLabel` | string | — | The panel's accessible name |
| `icon` | icon | — | Drawn at 14px in the accent colour, left of the eyebrow |
| `eyebrow` | string | — | The panel's label: 11px, uppercase, letter-spaced, muted |
| `meta` | node | none | A right-aligned slot. **Omitted entirely when nothing is passed** — no empty space reserved |
| `animate` | boolean | `true` | Entrance motion. Skeletons pass `false` |
| `children` | node | — | The body |

**Anatomy.** A card on the surface tone, 16px corner radius, a 1px hairline
border, 21px of horizontal padding and 17.5px of vertical padding. Inside it, a
header row — eyebrow and icon on the left, the meta slot on the right, separated
by a hairline rule with 10px of space beneath — then the body.

The meta slot is a block element, not inline text, because it often carries a
whole control group.

**What actually goes in the meta slot,** across the whole app: a small mono count
string, the time-window chips, a pipeline switcher and scope toggle side by side,
the Sync now button, the log/linear scale toggle, and the "+ New" button. Nothing
else.

**States**

| State | Behaviour |
|---|---|
| Default | As above |
| Entrance | Fades in and rises 4px over 0.25s, ease-out |
| Reduced motion | The entrance is suppressed entirely |
| Hover / active / focus | None. The panel is not interactive |
| Loading | Not a panel state. The screen swaps in a Skeleton instead |
| Empty | Not a panel state. The screen puts an EmptyCard inside or instead |

**Used by.** Every screen except the My Day empty card, the Lead Funnel cliff
band, and the standalone honesty bands — those are bare bordered sections.

---

## 2. KpiTile

**Job.** One headline number with a label and, usually, one line of context under
it.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `icon` | icon | — | A 15px accent glyph on the left |
| `value` | string | — | The number, already formatted |
| `label` | string | — | What the number is |
| `hint` | string | none | One line of context beneath the label |
| `hero` | boolean | `false` | Makes the value 24px instead of 15px |

**Anatomy.** A horizontal strip: a hairline border, 8px corner radius, surface
background, 10.5px horizontal and 9px vertical padding. Inside, the accent glyph,
then a stacked column — the value in mono at a heavy weight with tabular figures,
then the label at 11px muted and truncated, then the optional hint at 10px muted
and truncated.

The first tile in a band is usually the hero.

**States.** Default only. The tile is not interactive and has no hover state of
its own. Interactivity is added by KpiRow, not here.

**Defect — fix, do not copy.** Nothing about this component is broken, but note
what is *deliberately absent*: **there is no delta, no trend arrow, and no
"versus last period" anywhere in the product.** The hint line carries the context
instead — a count, a denominator, or a caveat like `"too few closed"`. Do not add
one; it would be inventing a number the data does not support.

**Used by.** Every data screen.

---

## 3. KpiRow

**Job.** The responsive band that holds the tiles.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `testId` | string | none | A hook for tests |
| `ariaLabel` | string | — | Names the band for screen readers |
| `tiles` | list | — | Each entry is `{ id, icon, value, label, hint?, hero?, actionLabel?, onSelect? }` |

**Anatomy.** A grid with an 7px gap: **two columns on a phone, three at 640px,
five at 1024px** — regardless of how many tiles it holds. A band of three tiles
therefore occupies three of five columns on a wide screen and leaves the rest
empty. That is intentional and consistent across the app.

**States**

| State | Behaviour |
|---|---|
| Default, no `onSelect` | The tile renders as a plain block. **Never a dead button** |
| With `onSelect` | The tile is wrapped in a button with no border and no background of its own |
| Hover, clickable | The whole tile drops to 90% opacity. No transform, no lift |
| Focus, clickable | The accent focus ring |
| Disabled / loading / empty | None. The screen swaps the whole band for a Skeleton |

A clickable tile's accessible name is its `actionLabel` when given, otherwise its
label.

**Used by.** Every data screen. Only **My Day** and **Signals** use the clickable
form; every other screen passes plain tiles.

---

## 4. DataTable

**Job.** The workhorse. Twelve screens render their content through this.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `headers` | list | — | Each entry is either a plain string or `{ label, sort, onSort }` for a sortable column |
| `rows` | list of lists | — | Cells are arbitrary content, not just text |
| `caption` | string | none | A screen-reader-only description of the table |
| `className` | string | none | Merged onto the scrolling wrapper |
| `numericCols` | list of numbers | empty | Which column indices carry numbers |

Sort state is one of `none`, `ascending`, `descending`.

**Anatomy.** A wrapper with a 16px radius, a hairline border and horizontal
overflow scrolling, around a full-width table at 13.5px.

- **Header row.** Background one step up the surface ladder, a hairline beneath,
  cells in mono at 11px, uppercase, letter-spaced, muted.
- **A sortable header** is a full-width button inside the cell with the accessible
  name "Sort by {label}", plus a chevron: up or down in the accent colour when
  sorted, a double chevron at half opacity when not. The sort state is announced
  to screen readers, and **omitted entirely when the column is unsorted** rather
  than announced as "none".
- **Body rows.** A hairline beneath each row except the last, and **zebra
  striping** — even rows get the surface-strong tone at 40% opacity.
- **Cells.** 14px horizontal, 8.75px vertical padding, top-aligned, ink coloured.
  Columns listed in `numericCols` get tabular figures; build them right-aligned.

**States**

| State | Behaviour |
|---|---|
| Default | As above |
| Hover | **None.** There is no row hover highlight anywhere in the app |
| Active / focus | Only on a sortable header button |
| Loading | **Not built in.** The screen supplies a Skeleton around the table |
| Empty | **Not built in.** The screen supplies its own empty copy around the table |

**What it deliberately does not have:** a row click handler, row selection,
checkboxes, bulk actions, pagination, a sticky header, or column resizing. Do not
add any of them.

**Used by.** Setup, My Day, Meetings, Contracts, Pipeline Health, Data to Fix,
Forecast, Owner leaderboard, Stuck & aging, Win / Loss, Lead Source ROI,
Campaigns & Segments, Forms & Emails.

Sortable headers are used on **exactly one screen**: Data to Fix.

---

## 5. StatusBadge

**Job.** A small pill that always carries a word. It is how the app conveys status
without ever relying on colour alone.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `tone` | `"good"` · `"accent"` · `"neutral"` | — | Which background tint |
| `children` | node | — | The word or short phrase |

**Anatomy.** A fully rounded pill, 7px horizontal and 2px vertical padding, text
at 10px, medium weight, uppercase, letter-spaced. It never shrinks.

| Tone | Background | Text |
|---|---|---|
| `good` | mint tint | muted ink |
| `accent` | accent tint | muted ink |
| `neutral` | surface-strong | muted ink |

**The text is always muted ink — never coloured text.** The tint carries the
signal; the word carries the meaning.

**States.** One. No hover, no focus, no disabled — it is not interactive.

**Everywhere it appears:** "Granted" / "Locked" on Setup; the three sync-lane
statuses; deal age tiers ("14d · aging", "37d · stale"); "{n} stuck · {maxDays}d";
"Needs next step"; each missing-field chip; "You" on the leaderboard; "funnel
floor", "no volume", and the conversion readout on Velocity; "Active" / "Archived"
on forms; and the marketing-email state.

---

## 6. PipelineSwitcher

**Job.** Choose which of the two pipelines is on screen. **This component is the
structural enforcement of the rule that the two pipelines never merge.**

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `pipelines` | list of `{ pipeline, pipelineLabel }` | — | The options |
| `selected` | string | — | Which one is active |
| `onSelect` | function | — | Fires with the chosen pipeline id |
| `ariaLabel` | string | none | Without it the control is named "Pipeline"; with it, "Pipeline — {ariaLabel}" |

**Anatomy.** A small hairline "tray": an inline flex row with a 1px border, an 8px
radius, the surface background, and 3.5px of padding, holding one button per
pipeline at 36px minimum height and 12.5px text.

- **Active chip.** Background one step up the surface ladder, ink-dark text, and a
  1.5px accent dot before the label.
- **Inactive chip.** Muted text, a transparent dot in the same place so the labels
  do not shift.

**States**

| State | Behaviour |
|---|---|
| Default | Inactive treatment |
| Hover, inactive | Surface-strong at 60%, text darkens to ink |
| Active | As above |
| Focus | Accent ring |
| Disabled / loading / empty | None |

**There is deliberately no "All" option**, and there must never be one. The two
pipelines have different stage counts — 7 and 9 — so an aggregate would be
meaningless. The real pipeline identifiers seen in the app are `default` →
"Sales Pipeline" and `638415376` → "Affiliate Pipeline".

> **Defect — fix, do not copy.** Like the main tab rows, this control sets a
> roving tab index but implements no arrow keys, so only the active chip is
> keyboard reachable. Add ArrowLeft, ArrowRight, Home and End.

**Used by.** Pipeline board, Forecast, Owner leaderboard, Velocity, Stuck & aging,
Win / Loss, and Pipeline Health. On Pipeline Health it renders **only when more
than one pipeline exists**.

---

## 7. WindowChips

**Job.** Choose a time window for a panel's figures.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `value` | window key | — | The active window |
| `onChange` | function | — | Fires with the new key |
| `ariaLabel` | string | none | Names it "Time window" or "Time window — {ariaLabel}" |

**The four options, fixed:**

| Key | Label |
|---|---|
| `7d` | Last 7d |
| `30d` | Last 30d |
| `90d` | Last 90d |
| `all` | All time |

There is no QTD and no YTD. If an earlier draft of the prompt library mentions
them, it is wrong — build these four.

**Anatomy.** Visually identical to PipelineSwitcher, with one difference: the
buttons are **44px** tall rather than 36px.

**States.** The same five as PipelineSwitcher, including the same missing-arrow-key
defect.

**Behaviour.** Selection is **instant and local**. No request is made. Every
window's figures already arrived in the one payload, so the table re-joins against
the new window immediately.

**Used by.** Campaigns & Segments and Forms & Emails. Both default to **30d**.

---

## 8. ScopeToggle

**Job.** Choose whose records are on screen.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `value` | string | — | The active option id |
| `onChange` | function | — | Fires with the new id |
| `options` | list of `{ id, label }` | — | Two or three entries |
| `ariaLabel` | string | — | Names the group |

**Anatomy.** Identical to PipelineSwitcher — the same tray, the same 36px chips,
the same accent dot on the active option.

**The important difference is under the surface.** This is a *group* of pressed
buttons rather than a tab list, which means **every option is reachable by Tab**.
The pipeline switcher and the tab rows are not. When in doubt, copy this one's
keyboard behaviour rather than theirs.

**States.** Default, hover, active, focus — as PipelineSwitcher. No disabled, no
loading, no empty.

**The three places it appears, with their real option sets:**

| Screen | Options |
|---|---|
| Stuck & aging | **All reps** · **Mine only** |
| Pipeline Health | **All reps** · **Mine only** |
| Data to Fix (object) | **Companies** · **Contacts** |
| Data to Fix (owner) | **Mine** · **All**, plus **Unowned** for a manager |

There is no "Team" option anywhere in the product. If an earlier draft mentions
one, it is wrong.

**A related control that is not this component.** Lead Funnel's **Log / Linear**
scale toggle is a local copy of this pattern, not the shared component: same group
semantics, but 44px chips and an accent-*tint* fill on the active option instead of
surface-strong, with no leading dot. Build it as a variant rather than a fourth
component.

---

## 9. SparkLine

**Job.** A tiny trend line, inline, with no axes and no grid.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `variant` | `"banner"` · `"row"` · `"chip"` | — | Which of three fixed sizes |
| `data` | list of numbers | — | The series |
| `ariaLabel` | string | `"Spark line — {n} buckets"` | The spoken description |
| `className` | string | none | — |
| `highlightIndices` | list of numbers | none | Draws a dot at those points |

| Variant | Size | Stroke |
|---|---|---|
| `banner` | 120 × 40 | 1.5 |
| `row` | 60 × 16 | 1 |
| `chip` | 32 × 12 | 1 |

**Anatomy.** Hand-drawn vector, never a chart library. A hairline baseline plus a
single ink-coloured polyline. No fill, no axes, no grid, no tooltip.

**States**

| State | Behaviour |
|---|---|
| Default | The line draws itself in over 1.1s, ease-out |
| Reduced motion | The finished line renders immediately |
| Empty data | **Renders nothing at all.** The screen supplies its own empty copy |
| Hover / focus / disabled | None |

**Used by.** Audience Growth only, in the banner size, on the two net-new panels.

---

## 10. EmptyCard

**Job.** A designed empty state. In the real app this is a copy-pasted block rather
than a component; in the prototype, make it a component — fifteen places use it.

**Props** *(the real app has none; these are what the fifteen copies actually
vary)*

| Prop | Type | Default | What it does |
|---|---|---|---|
| `icon` | icon | — | The glyph in the badge |
| `eyebrow` | string | — | 11px uppercase muted label |
| `headline` | string | — | The 19px semibold sentence |
| `body` | string | — | The 13.5px muted explanation |
| `showCta` | boolean | `true` | Whether the Setup button appears |
| `tone` | `"accent"` · `"mint"` | `"accent"` | The badge tint |

**Anatomy.** A hairline card on the surface tone, 16px radius, 28px horizontal and
roughly 49px vertical padding, everything centred:

1. A 44px circular badge in the accent tint, holding an 18px accent icon.
2. The eyebrow, 11px, uppercase, letter-spaced, muted.
3. The headline, 19px semibold ink, capped at 42 characters wide.
4. The body, 13.5px muted with relaxed line height, capped at 54 characters wide.
5. The button: 44px tall, 8px radius, filled in the accent colour with
   surface-coloured text, reading **"Setup & Data Readiness"** with an up-right
   arrow.

**States**

| State | Behaviour |
|---|---|
| Sync-pending (State A) | With the Setup button. This is the "we have never received data" case |
| Synced but empty (State B) | **Without** the button — there is nothing to configure |
| Good news | The mint variant: mint tint badge, a check-circle glyph in ink. Used once, for "Nothing stuck" |
| Entrance | Fades in and rises 4px over 0.25s |
| Reduced motion | Entrance suppressed |
| Hover / focus | Only on the button |

**Used by.** My Day, Onboarding, Pipeline board, Forecast (twice), Owner
leaderboard (twice), Velocity (twice), Stuck & aging (twice), Win / Loss (twice),
Lead Funnel, Lead Source ROI, Audience Growth, Campaigns (twice), Forms & Emails
(twice).

The exact headline for each is in the screen specification.

---

## 11. Skeleton

**Job.** Hold the layout while a cold load resolves, so the page does not jump when
the numbers land.

**Props** *(again, a pattern rather than a component in the real app)*

| Prop | Type | Default | What it does |
|---|---|---|---|
| `tileCount` | number | 3 | How many pulsing KPI cells |
| `bodyHeight` | number | 280 | The height of the large pulsing card, in px |
| `variant` | `"page"` · `"panel"` | `"page"` | Full-page or the small in-panel bar |

**Anatomy, page variant.** A vertical stack with a 21px gap:

1. A grid of pulsing cells at **52px** high, 8px radius, hairline border,
   surface-strong background. Two columns on a phone, three or four at 640px, five
   on My Day.
2. One large pulsing card between **200px and 320px** tall, 16px radius, hairline
   border, surface-strong background.

My Day adds a third bar. The card height by screen: Audience 200, Campaigns and
Forms 220, Stuck and Pipeline board 280, Forecast, Owners and Win / Loss 300,
Velocity, Source ROI and Onboarding 320.

**Anatomy, panel variant.** A single 96px pulsing bar, 16px radius, surface-strong
at 60%, inside the panel. Used by Pipeline Health, Data to Fix, Meetings and
Contracts.

**States**

| State | Behaviour |
|---|---|
| Default | A gentle pulse, marked busy for screen readers |
| Reduced motion | The pulse stops |

**The rule that matters more than the anatomy.** The skeleton appears **only on a
cold load** — when a request is pending *and* there is no data yet. A background
refresh, which happens every 30 seconds on the leadership screens and every five
minutes elsewhere, must never blank a screen that already holds numbers.

---

## 12. RecordDrawer

**Job.** The right-hand panel for creating or editing one record.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `open` | boolean | — | Whether it is showing |
| `onOpenChange` | function | — | Fires on open and close |
| `title` | string | — | The header text |
| `fields` | list | — | Each is `{ key, label, type, options?, required?, placeholder? }` |
| `initial` | object | — | Starting values, keyed by field |
| `onSave` | async function | — | Receives the values; may throw |

Field types: `text`, `textarea`, `select`, `date`.

**Anatomy.** A dark overlay at 40% opacity over the page, plus a panel anchored to
the right edge, full height, **full width on a phone and capped at 440px above
that**, on the canvas tone. Three regions:

1. **Header** — the title, with a hairline rule beneath and a description for
   screen readers.
2. **Body** — a scrolling column of fields with 14px between them.
3. **Footer** — a hairline rule above, then **Cancel** and **Save** right-aligned.

**How each field type renders**

| Type | Renders as |
|---|---|
| `text` | A single-line input |
| `textarea` | A three-row text area |
| `select` | A text input backed by a suggestion list. **It is a combo box, not a locked dropdown** — the options are suggestions and free text is allowed |
| `date` | A native date input |

A required field gets an accent-coloured asterisk after its label.

**States**

| State | Behaviour |
|---|---|
| Opening | Slides in from the right. The first field is focused automatically |
| Default | Values seeded from `initial` |
| Invalid | On blur, an empty required field gets an accent border, an invalid flag, and an alert beneath reading **"{Label} is required."** |
| Saving | The Save button reads **"Saving…"** and drops to 50% opacity, disabled |
| Save failure | The drawer **stays open with the typed values intact** so the operator can retry. The error is swallowed here — the calling screen owns the toast |
| Closing while dirty | A native browser confirm reading **"Discard unsaved changes?"** |
| Loading / empty | None |

**Two behaviours worth copying exactly.** Pressing Save with a required field still
empty marks the field as touched and **does nothing else** — no request is made.
And the seed values are held stable, so a background refresh landing mid-typing
cannot overwrite what the operator is entering.

**Used by.** Customer Meetings and the Contract Queue, through EditableReport.

**Note.** There is no automated test for this component in the real app. Its
behaviour is only exercised indirectly. Treat the description above as the
specification.

---

## 13. EditableReport

**Job.** The entire create, edit and delete chassis. Give it a column list and a
field list and it produces a working screen. Two Leadership tabs are nothing but a
configuration of this.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `title` | string | — | Used in the drawer titles |
| `eyebrow` | string | — | The panel eyebrow |
| `icon` | icon | — | The panel icon |
| `fields` | list | — | Passed straight to RecordDrawer |
| `crud` | object | — | `{ query, create, update, remove }` |
| `columns` | list of `{ header, cell }` | — | One entry per visible column |
| `emptyLabel` | string | — | The sentence shown when there are no rows |
| `rowLabel` | function | row id | Produces the words in each row's button labels |

**Anatomy.** A PanelFrame whose meta slot holds a **"+ New"** button — accent
filled, with a plus glyph, 32px minimum height. Inside, a DataTable whose headers
are the given columns plus one trailing **unlabelled** column. Each row's last
cell is a right-aligned pair of icon buttons: a pencil labelled
**"Edit {rowLabel}"** and a bin labelled **"Delete {rowLabel}"**.

Two drawers are mounted at all times: one titled **"New — {title}"** and one titled
**"Edit — {title}"**.

**States**

| State | Behaviour |
|---|---|
| Loading | The small in-panel pulsing bar |
| Empty | A centred bordered card inside the panel showing `emptyLabel`, plus a second button reading **"Add the first one"** |
| Populated | The table |

**Toasts, verbatim**

| Event | Toast |
|---|---|
| Create succeeded | **"Added"** |
| Update succeeded | **"Saved"** |
| Create or update failed | **"Couldn't save — please try again"**, and the error is re-thrown so the drawer stays open |
| Delete succeeded | **"Row deleted"**, with an **Undo** action |
| Delete failed | **"Couldn't delete — please try again"** |
| Undo failed | **"Couldn't undo"** |

Deleting first fires a native browser confirm reading **"Delete this row?"**.

> **Defect — fix, do not copy.** **Undo does not restore the deleted row.** It
> creates a brand new row with a new identifier, and re-attributes "created by" and
> "created at" to whoever pressed Undo. There is no restore endpoint behind it. In
> the prototype, either implement a real restore or change the toast so it does not
> promise one.

**Used by.** Customer Meetings and Contract / Agreement Review Queue.

---

## 14. InlineEditCell

**Job.** Turn one table cell into an editable field in place, without a drawer.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `value` | string | — | The saved text |
| `placeholder` | string | — | What to show when empty |
| `onSave` | async function | — | Receives the new text; may throw |

**Anatomy, read state.** A full-width, left-aligned button, at least 28px tall. Ink
text when there is a value; muted text when it is showing the placeholder. A pencil
glyph fades in on hover, and the whole cell picks up the surface-strong background.
Its accessible name is **"Edit: {value}"** or **"Add {placeholder}"**.

**Anatomy, edit state.** A two-row text area, focused automatically, with an
**accent border** — so it reads as visibly different from the read-only HubSpot
cells sitting beside it.

**States**

| State | Behaviour |
|---|---|
| Default (read) | As above |
| Hover | Surface-strong background, pencil visible |
| Focus | Accent ring |
| Edit | The accent-bordered text area |
| Saving | Disabled |
| Escape pressed | The draft resets to the last saved value and the cell exits **without writing** |
| Save failure | The cell **stays in edit mode with the typed text intact**, and a toast reads **"Couldn't save — please try again"** |
| Loading / empty | None |

**Saving happens on blur**, not on a button, and only when the text actually
changed — so an Escape followed by the cell unmounting never writes.

**There is no optimistic update and no success toast.** The cell returns to read
mode and the table quietly refetches underneath.

**Used by.** Pipeline Health only, on the CTA and Risk / Blocker columns.

**Note.** There is no automated test for this component in the real app.

---

## 15. SyncNowButton

**Job.** Force a data refresh, with a visible cooldown so nobody hammers it.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `pulledAtUtcIso` | string | — | When the last sync ran. Drives the countdown |

**Anatomy.** A small hairline chip: inline flex, at least 28px tall, 8px radius, a
1px border, surface background, 10.5px horizontal padding, text in mono at 11px
with tabular figures, muted. A refresh glyph on the left.

**States**

| State | Label | Accessible name | Enabled |
|---|---|---|---|
| Cooling down | **"Sync in M:SS"**, counting down every second | "Sync available in M:SS" | No |
| Ready | **"Sync now"** | "Sync now" | Yes |
| Busy | **"Syncing…"**, glyph spinning | "Syncing" | No |
| Disabled | Cursor shows not-allowed, opacity 60% | — | — |

The cooldown is **five minutes**, mirrored in the browser. The remaining time is
computed during render, so the very first paint is already correct rather than
showing a wrong value for one second.

**Toasts, verbatim**

| Outcome | Toast |
|---|---|
| Success | **"Synced · {n} events"** |
| Rate limited (429) | **"Already up to date — try again shortly."** — an *info* toast, deliberately not an error. This is the benign case where the browser re-enabled the button a beat before the server agreed |
| Anything else | **"Sync failed: {message}"** |

After a successful sync the data refetches, which feeds a new `pulledAtUtcIso` in,
which restarts the countdown on its own.

**Used by.** Setup & Data Readiness only, in the Sync freshness panel's header.

---

## 16. AskCopilot

**Job.** A link out to the company copilot, from a row about a specific deal or
lead.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `about` | string | — | What the row is about. Feeds the tooltip and the accessible name |
| `label` | string | `"Ask copilot"` | The visible text |
| `className` | string | none | — |

**Anatomy.** A small link chip, at least 32px tall, 12px text, with a
message-question glyph in the accent colour. Hover gives it the surface-strong
background.

Its tooltip reads "Open Fetch AI to ask about {about} (opens in a new tab)" and its
accessible name reads "Ask Fetch AI about {about} (opens in a new tab)".

**States.** Default, hover, focus. Not disabled, no loading, no empty.

**Three constraints that shaped it, and that the prototype should respect:**

1. **It cannot pre-fill a question.** The copilot it opens has no way to accept a
   starting prompt from outside. So the chip is labelled for what it does — open
   the copilot — not for what we wish it did. Do not label it "Ask about this
   deal".
2. **It opens in a new tab on purpose.** The copilot lives on a different origin
   behind a different login; navigating in the same tab would tear down the whole
   cockpit — the section, the sub-tab, the scroll position and every cached figure.
3. Each chip mints a fresh conversation identifier when it mounts, so the link has
   a real destination for middle-click and copy-link.

**Used by.** My Day (label "Ask copilot", on open-deal rows and hot-lead rows) and
Stuck & aging (label **"Ask"**, in the denser queue rows).

**Note.** There is no automated test for this component in the real app.

---

## 17. HandoffPanel

**Job.** Show won deals that never made it into onboarding — the leak between sales
and operations.

**Props**

| Prop | Type | Default | What it does |
|---|---|---|---|
| `handoff` | object | — | The won-deal and leak data |
| `syncPending` | boolean | — | Whether the first sync has landed |

**Anatomy.** A PanelFrame with an arrows-swap icon, eyebrow **"Sales → Ops
handoff"**, and meta reading `"{n} won deal(s)"` — omitted entirely at zero.

**Three headline states, in priority order**

| Condition | Glyph | Copy |
|---|---|---|
| No won deals at all | inbox | Sync pending: *"Building — the next sync will check won-deal handoffs."* Otherwise: *"No Closed-Won deals to check yet."* |
| Won deals, no leaks | check-circle, accent | *"All {n} won deals handed off to onboarding."* |
| Leaks exist | triangle-alert, accent | *"{k} of {n} won deals not handed off"* and *"{$} at risk"* |

When leaks exist, a table follows. It is hand-built rather than the shared
DataTable, and the prototype should just use DataTable.

| # | Header | Align | Content |
|---|---|---|---|
| 1 | `Company` | left | Falls back to `"—"` |
| 2 | `Amount` | **right, numeric** | Falls back to `"—"` |
| 3 | `Owner` | left | Falls back to **"Unassigned"** |
| 4 | `Stage` | left | Falls back to `"—"` |
| 5 | `Updated` | left | An absolute date, formatted like "Aug 20, 2026" |

The last column is called **"Updated"** and not "Closed" on purpose: it is the
deal's last-modified time, a recency signal, not a true close date. Keep the
header word.

A closing paragraph defines what counts as a leak. *Exact text: not specified in
source.*

**States.** Covered by the three headlines above. No hover, no loading state of its
own.

**Used by.** The Onboarding funnel screen only.

---

## The app-shell screens

Not part of the seventeen, but the prototype needs them and they carry four real
defects.

| Screen | What it is |
|---|---|
| Loading screen | A 48px company cube in the accent colour over a small sliding track |
| Boot error | A centred card. Heading **"Unable to load app"**; body *"Something went wrong verifying your session. Try refreshing the page. If this keeps happening, contact your administrator."*; the raw error message in a mono block; a **"Reload page"** button |
| Access restricted | A centred card. Heading **"Access restricted"**; body naming the product; footer *"Access is restricted to @chainit.com accounts."* |
| Dev-mode banner | A full-width amber strip reading **"DEV MODE — Cloudflare Access auth bypassed · running as localhost@dev"** |
| Theme toggle | A 36 × 36 icon button. A sun when dark is active, a moon when light is. Accessible name and tooltip: **"Switch to light mode"** / **"Switch to dark mode"** |

The loading screen is deliberately delayed: for the first **300 milliseconds**
nothing renders at all, so a fast response never produces a flash of spinner.

> **Defect 1 — fix, do not copy.** The first four of these use hardcoded colour
> values instead of theme tokens, so **they do not respond to dark mode** while
> every other surface does. Build them from tokens.

> **Defect 2 — fix, do not copy.** The access-restricted screen names the wrong
> product. It says "the ChainIT AI Budget dashboard" — a leftover from a different
> app this shell was copied from. It should say Sales Cockpit.

> **Defect 3 — fix, do not copy.** That screen is built to show the signed-in email
> address, but the caller never passes it, so the clause is permanently dead. Wire
> it or delete it.

> **Defect 4 — fix, do not copy.** These screens declare themselves full-height,
> but they render *inside* the main body — so the sticky header and both nav rows
> sit above them, the card is pushed down, and the page overflows. They are not
> actually full-screen. Either lift them above the header or stop claiming full
> height.

---

## Do not build these

Four things exist in the real code with full source and passing tests, and **no
screen uses any of them.** They are leftovers from the application this one was
copied from. Building them in the prototype would be wasted effort.

| Name | What it was | Verdict |
|---|---|---|
| `SpendBar` | A 6px progress track with an accent fill, exposed to screen readers as one labelled image rather than a bare percentage. Clamps to 0% when the maximum is zero or less | Zero consumers. Do not build |
| `VerdictBand` | A hairline card carrying one pill: a shield-check on mint when the verdict is good, a dashed circle on surface-strong when it is not. Pill text always ink. An optional right-aligned mono note | Zero consumers. Do not build |
| `DisclosurePanel` | A hairline card whose full-width header button toggles an expanded state and rotates a chevron 180°. The body is genuinely removed when collapsed, not just hidden | Zero consumers. Do not build |
| `SectionPlaceholder` | A "Lands in Slice N" card for sections that had not shipped yet | Unreachable — every section has shipped. The `slice` number that feeds it is stale metadata. Do not build, and drop the field |

They are recorded here for one reason only: they document the house style for a
progress bar, a verdict line and a collapsible, should the prototype ever genuinely
need one.

---

## One naming trap, repeated because it matters

The accent colour token in the original source is named `--color-accent-lavender`.
**It is green.** A forest green, hue 152. Every mention of "lavender" in the
original code — including in the descriptions of the accent dot, the accent tint
and the accent border above — means that green. A rebuild that takes the name
literally will ship purple on every screen.
