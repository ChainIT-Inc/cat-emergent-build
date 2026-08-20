# Prompt library

Copy-paste prompts for Emergent, in build order. Each one is bounded — one
thing at a time, with a constraints block that stops the agent wandering into
screens you did not ask about.

Work down this list. Do not skip ahead; each prompt assumes the previous ones
landed.

---

## Order of work

| # | Prompt | Roughly |
|---|---|---|
| 0 | The kickoff — shell and navigation | `00-KICKOFF-PROMPT.md` |
| 1 | Design system and shared components | 20 min |
| 2 | Seed the database | 10 min |
| 3 | Revenue → Pipeline (the reference screen) | 30 min |
| 4 | The remaining cockpit screens, one at a time | 20 min each |
| 5 | Pricing → Price a deal | 45 min |
| 6 | Pricing → Configure | 30 min |
| 7 | The role switcher wired to visibility rules | 20 min |

Build **Revenue → Pipeline** third and get it genuinely right. Every later
screen can then be prompted as "same pattern as Pipeline, but…", which is far
cheaper than describing a table from scratch nine times.

---

## Prompt 1 — Design system and shared components

```text
CONTEXT
The shell is built. Now build the shared component library that every screen
will use. Nothing screen-specific yet.

OBJECTIVE
Create these eleven components, styled strictly from the attached tokens.css,
and put them on a single /components preview route so I can see them all at
once.

These are the eleven the screens need first. There are 17 in total; the
remaining six (RecordDrawer, EditableReport, InlineEditCell, SyncNowButton,
AskCopilot, HandoffPanel) are specified in
01-product/03-component-catalogue.md and I will ask for them when the screens
that use them come up. Do not build those yet.

1. PanelFrame — the container every block of content sits in.
   A surface-coloured card, 16px radius, 1px hairline border, 16px padding.
   Optional header row: a 14px semibold title on the left, an optional slot for
   controls on the right, separated from the body by a hairline rule.
   Supports a "loading" state (a skeleton that holds the same height) and an
   "empty" state (centred muted text plus one small accent mark).

2. KpiTile — a single headline number.
   A HORIZONTAL strip: hairline border, 8px radius, surface background, 10.5px
   horizontal and 9px vertical padding. Inside, left to right: an optional 15px
   accent-coloured glyph, then a stacked column containing the value, then the
   label, then an optional hint.
     value — mono, weight 640, tabular figures, 15px (24px in the "hero"
             variant, which is usually the first tile in a row)
     label — 11px muted, truncated
     hint  — 10px muted, truncated

   IMPORTANT: there is NO delta, NO trend arrow, and NO "versus last period"
   anywhere in this product. Do not add one. The hint line carries context
   instead — a count, a denominator, or a caveat such as "too few closed".
   A delta would be inventing a number the data does not support.

   The tile is not interactive and has no hover state of its own.

3. KpiRow — the responsive band that holds the tiles.
   Four across on desktop, two across below 1024px, one across below 640px.

4. DataTable — the workhorse.
   12px medium muted column headers on a surface-strong background row, 13px
   body cells, hairline row separators, a subtle surface-strong hover on rows.
   Numeric columns are right-aligned and tabular. Sortable headers show a small
   chevron. Supports a loading skeleton, an empty state, and clickable rows.

5. StatusBadge — a small pill.
   10px radius, tint background, ink-on-tint text, 12px medium. Four variants:
   healthy (green), watch (amber), bad (red), neutral (surface-strong with
   muted ink). Always shows a word, never colour alone.

6. WindowChips — a segmented control for a time window.
   Exactly four options, and no others: "Last 7d", "Last 30d", "Last 90d",
   "All time". Default is 30d. Buttons are 44px tall.
   The active chip sits on the strong-surface background with full ink and a
   small leading accent dot; the rest are plain with muted ink.
   Selection is instant and local — it never makes a request.

7. ScopeToggle — a two or three way segmented control, same look as
   WindowChips but 36px tall.
   Its option set is supplied per screen; do not hardcode one. The real sets
   are: "All reps / Mine only", "Companies / Contacts", and
   "Mine / All", with "Unowned" added for a manager.
   Build this one as a GROUP of pressed buttons, not as a tab list, so every
   option is reachable by Tab. This is the keyboard behaviour to copy
   everywhere.

8. SparkLine — a tiny inline trend line, one accent-coloured stroke, no axes,
   no grid, no fill. Three fixed sizes: banner, row, chip.
   Its path draws itself in over 1100ms on first render, ease-out, gated on
   reduced motion. This is the app's one expressive animation.

9. EmptyCard — the designed empty state. One 16px accent icon, a 13px headline
   in full ink saying what is true in plain words, an optional 12px muted line,
   and optionally one button. Centred, holding roughly the height the populated
   panel would have.

10. Skeleton — the designed loading state. A pulsing block on the strong-surface
    colour with a hairline border, in the shape of the content that is coming.
    It must hold the real layout's height or the page jumps twice.

11. PipelineSwitcher — choose ONE pipeline. Same tray as ScopeToggle, 36px
    chips, with a small accent-coloured dot on the active option.
    This is a switcher, not a filter: the two pipelines are never summed and
    never shown side by side. Selection is instant and local, no request.
    Give it the same arrow-key handling as ScopeToggle.

CONSTRAINTS
- Use only the tokens in tokens.css. No other colour.
- No box-shadow on any component.
- All numbers use font-variant-numeric: tabular-nums.
- Every interactive element has a visible focus ring: 2px accent, 2px offset.
- Do not build any screen yet. Components and the preview route only.
- Do not install a component library that brings its own theme.
```

---

## Prompt 2 — Seed the database

```text
CONTEXT
I have attached JSON fixtures in 04-data-contracts/seed/. They are fake data
that matches the real system's response shapes.

OBJECTIVE
1. Create MongoDB collections matching the data model in
   04-data-contracts/02-data-model.md.
2. Load every attached fixture file into its matching collection on startup,
   so the database is always populated in a fresh environment.
3. Build FastAPI endpoints that serve this data, matching the paths and
   response shapes described in 04-data-contracts/01-api-reference.md.
4. Add a small "reset data" endpoint I can call to restore the fixtures after
   I have edited things in the UI.

CONSTRAINTS
- Do not invent additional sample data. Use only the attached fixtures.
- Do not change any field name from the data model. The field names are the
  contract with the real system and an engineer will diff against them.
- Do not connect to HubSpot or any external service. There is no API key and
  there will not be one.
```

---

## Prompt 3 — The reference screen

```text
CONTEXT
Revenue → Pipeline, at #/revenue/pipeline. This is the screen the sales team
opens most, and it is the pattern every other data screen follows. Its full
specification is in 01-product/02-sales-cockpit-spec.md — read that section
before building.

OBJECTIVE
Build the screen exactly as specified there, using the components from the
component library. Do not improvise columns, tiles, or copy that the spec does
not name.

CONSTRAINTS
- Use the existing components. If something is missing, tell me before adding
  a new one — do not silently create a variant.
- The pipeline switcher selects between two separate pipelines. It is a
  switcher, not a filter: the two pipelines are never summed together and never
  shown side by side.
- Do not touch the shell, the component library, or any other screen.
- Show the loading and empty states. I will want to see both.

WHEN DONE
Tell me which components you used, and show me the screen in both light and
dark mode.
```

---

## Prompt 4 — Template for every other screen

Replace the bracketed parts. This template is the whole trick — it works
because it names the section of the spec, names the components to reuse, and
forbids collateral changes.

```text
CONTEXT
[SECTION] → [TAB], at #/[section]/[tab]. Its specification is the
"[TAB]" section of 01-product/02-sales-cockpit-spec.md.

OBJECTIVE
Build it exactly as specified, following the same structure and rhythm as the
Pipeline screen. Reuse PanelFrame, KpiRow, DataTable, StatusBadge and
WindowChips rather than building anything new.

CONSTRAINTS
- Do not modify the Pipeline screen or any other existing screen.
- Do not add a component. If you think one is needed, ask first.
- Every column header, tile label, button label and empty-state sentence comes
  from the spec. Do not reword them.
- Both themes must look right.
```

---

## Prompt 5 — Price a deal

This is the highest-stakes screen. Prompt it in **two** turns, not one.

**Turn A — the form and the numbers:**

```text
CONTEXT
Pricing → Price a deal, at #/pricing/price. This is a rep-facing quoting screen
for merchant payment processing. The business rules are in
02-pricing-engine/02-pricing-rules-and-math.md and the configuration values are
in 02-pricing-engine/03-config-schema-and-defaults.md. Read both fully. The
domain background, if you need it, is in 01-pricing-primer-plain-english.md.

OBJECTIVE
Build the input form and the calculation, with results displayed plainly. Do
not style it beautifully yet — I want the numbers correct first.

The calculation must be implemented exactly as written in the rules document.
Every rate, fee, threshold and default comes from the config document.

After building, run the worked examples in
02-pricing-engine/04-worked-examples-golden.md and show me your output next to
the expected output, as a table. If any row disagrees, stop and tell me — do
not adjust the expected values to match.

CONSTRAINTS
- Do not invent any rate, fee, percentage, threshold or rounding rule. If a
  value you need is not in the config document, stop and ask me.
- Do not round intermediate values. Round only at display time, as the rules
  document specifies.
- Every input field is exactly as named in the spec, with the stated units.
- Do not build the Configure tab yet.
```

**Turn B — the layout, once the numbers are right:**

```text
CONTEXT
The Price a deal calculation is correct. Now lay the screen out.

OBJECTIVE
Two-column on desktop: inputs on the left at about one third width, results on
the right. Single column stacked below 1024px, inputs first.

Results, in this order of prominence:
1. The health light — green, amber or red — with a word, not colour alone.
2. The minimum rate this deal supports. This is the headline number a rep is
   looking for when a customer pushes back on price.
3. The rate being tested, and its difference from our standard rate.
4. Monthly and annual net revenue.
5. Margin, in dollars and in basis points.
6. A per-module breakdown.
7. An assumptions footnote in muted 12px text, naming the card mix, the
   downgrade assumption and the config version used.

Add a "Copy quote link" button. It copies the current URL, which encodes every
input, and shows a toast reading "Quote link copied."

CONSTRAINTS
- Results update live as inputs change. There is no Save or Calculate button.
- The assumptions footnote is always visible, never behind a disclosure.
- Do not change any calculation. Layout only.
```

---

## Prompt 6 — Configure

```text
CONTEXT
Pricing → Configure, at #/pricing/configure. This is the locked cost engine
behind Price a deal. In production only a couple of named people may edit it.
Its specification is in 02-pricing-engine/03-config-schema-and-defaults.md.

OBJECTIVE
Build the editing form for every configuration value in that document, grouped
into the sections it names. Each field shows its label, its unit, its current
value, and a small badge showing whether the value is real or a placeholder.

Saving creates a new numbered revision rather than overwriting. Show the
revision number, who saved it, and when, at the top of the screen.

When the signed-in role is not "Config editor", the tab is still visible but
the body shows a read-only view plus one line explaining who to ask.

CONSTRAINTS
- Editing here must never be possible from the Price a deal screen. Keep the
  two screens completely separate.
- Do not add an inline edit shortcut anywhere else in the app.
- Do not delete revisions. Saving only ever adds one.
```

---

## Prompt 7 — Wire the role switcher

```text
CONTEXT
The role switcher in the header currently only changes a label. Wire it to
actual visibility rules.

OBJECTIVE
Selecting a role changes what is visible, per this table:

  Rep            Sees only their own deals. Scope toggle locked to "Mine".
                 No cost or margin columns anywhere. Configure is read-only.
  Manager        Sees the whole team. Scope toggle unlocked, including
                 "Unowned". No cost or margin columns. Configure read-only.
  Marketer       Marketing section fully available. Revenue is read-only.
  Config editor  Everything Manager sees, plus Configure is editable.
  Admin          Everything Manager sees, plus per-row cost and margin
                 columns appear in tables and in the pricing results.

CONSTRAINTS
- "Config editor" and "Admin" are two different permissions and must not be
  merged. One edits the cost engine; the other reveals margin figures. Someone
  can have either without the other.
- This is a prototyping device. Do not add a login screen, a password, or a
  user database.
```

---

## Prompts for iterating

Keep these to hand. They come up constantly.

**When it changed something you did not ask about:**

```text
You modified [SCREEN], which I did not ask you to change. Revert that screen to
how it was and re-apply only the change I asked for, which was: [THE CHANGE].
```

**When the styling drifted:**

```text
The colours have drifted from the design system. Re-read the attached tokens.css
and the design brief. Replace every colour on [SCREEN] with a token from that
file. There must be no purple, no gradient, and no box-shadow anywhere.
```

**When a number looks wrong:**

```text
On [SCREEN], with inputs [LIST THEM], the [FIELD] shows [ACTUAL] but the rules
document says it should be [EXPECTED]. Show me your calculation step by step,
then fix it. Do not change the expected value.
```

**When you want to see it before it builds:**

```text
Before you write any code: explain what you are going to change, which files
you will touch, and which screens will be affected. Wait for me to confirm.
```

**When the preview breaks:**

```text
The preview shows a blank page. Here is the full browser console output:

[PASTE IT VERBATIM]

I expected to see [WHAT]. Please solve this error.
```
