# Design brief — ChainIT Sales Cockpit

**This file is written to be handed straight to the AI builder.** Paste it, or
attach it, before asking for any screen. It is the main defence against the
prototype drifting into generic AI-dashboard aesthetics.

Everything here was extracted from the live app's stylesheet
(`apps/sales/src/index.css`) and verified value by value, not described from
memory.

---

## The aesthetic, in one paragraph

A calm, dense, quiet instrument panel. Warm off-white paper in light mode, warm
near-black in dark mode — the neutrals carry a slight yellow cast (hue 80–90),
never a blue-grey one. Content is numbers and tables; chrome gets out of the
way. There are **no drop shadows anywhere**, no gradients, no glassmorphism, no
decorative illustration. Depth is expressed by stepping up a ladder of surface
tones and by hairline borders. There is exactly **one accent colour, and it is
a forest green**, spent only on the active nav item, focus rings, and a single
mark on an empty state. Everything else is ink, hairline, and surface. It should
feel like a well-made piece of software for people who use it eight times a day,
not like a landing page.

Nearest reference points: Linear's surface ladder, Stripe's dashboard density,
Raycast's restraint. Not: Vercel-style neon gradients, not shadcn-out-of-the-box,
not any dashboard template.

---

## Hard prohibitions

The AI builder must not produce any of these. They are the tells that a screen
was generated rather than designed, and every one of them is wrong for this
product specifically.

- **No purple or blue gradient.** Not in a header, not on a button, not on a
  chart, not as a background wash.
- **No drop shadows.** No `box-shadow` at all. Not on cards, not on dropdowns,
  not on the header. If something must feel raised, move it one step up the
  surface ladder or give it a hairline border.
- **No Inter, Roboto, Arial, or `system-ui` as the primary face.** The product
  uses **Geist**. It has a specific character and the layout is tuned to its
  metrics.
- **No 16px base font size.** The base is **14px**. This is a dense internal
  tool. Raising it silently breaks every spacing relationship.
- **No cool grey neutrals.** The greys carry a warm cast. `#f6f5f1`, not
  `#f8fafc`. `#e2e1de`, not `#e5e7eb`.
- **No colour for decoration.** If a colour is not communicating a status, a
  health verdict, or "this is the active item", it does not belong.
- **No emoji in the UI.** No 🎉 on a success state, no 📊 next to a heading.
- **No pill-shaped buttons.** Controls are 8px radius. Fully-round shapes are
  reserved for badges, status dots and avatars.
- **No hero sections, no marketing copy, no illustrations, no empty-state
  cartoons.** Empty states are a line of text and one small accent mark.
- **No sidebar.** Navigation is a two-level horizontal switcher at the top.
- **No notification bell, no global search, no command palette, no onboarding
  modal, no confetti.** None of these exist in this product.

---

## Colour

Full token list with values in `02-tokens.css`. The important structural facts:

### The accent is green, despite its name

The token is called `--color-accent-lavender` in the original source. **It is not
lavender.** The declared value is `oklch(0.58 0.12 152)` — hue 152, which is a
forest green, `#388e56`. A stale comment in that file claims hue 270; the
comment is wrong and the value is right.

If your rebuild renders the accent purple, it is wrong. Verify against a
screenshot of the live app.

Dark mode lifts it to `#51af6f` so it clears 3:1 on the dark surfaces.

### The surface ladder

Depth is tone, not shadow. Three steps, and they mean the same thing in both
themes:

| Step | Light | Dark | Used for |
|---|---|---|---|
| **canvas** | `#f6f5f1` | `#14110d` | The page floor |
| **surface** | `#ffffff` | `#1d1a15` | Cards, panels, drawers |
| **surface-strong** | `#e6e4e1` | `#2a2620` | Hover, table headers, chips |

Note that in dark mode *lighter means closer to the user*. A dropdown over a
panel is `surface-strong`, not a shadowed `surface`.

### The ink ramp — three tiers, never four

| Tier | Light | Dark | Used for |
|---|---|---|---|
| **ink** | `#191610` | `#efeeeb` | Body text, headings, numbers |
| **ink-muted** | `#504d47` | `#bab7b2` | Labels, captions, table headers |
| **ink-subtle** | `#66635d` | `#a19e99` | Least emphasis, timestamps |

Do not invent a fourth grey to sit between two of these. If something needs less
emphasis than ink-subtle, it probably should not be on the screen.

### Status colours and the tint/ink pattern

**These are pricing-only.** The health triad appears exclusively in the pricing
screens — there is not a single health colour in the cockpit's dashboard
components. The app runs **two deliberate colour dialects**: the dashboard uses
ink, hairline, surface and the accent; pricing adds the health triad on top.

Keep that boundary. Scattering health colours across the cockpit's tables would
be a visible change to the product's character, not a styling tweak. If you want
one there, propose it in your handoff.

The health colours come in threes and the pattern is strict:

- `--health-green-tint` is a **background**.
- `--health-green-ink` is **text on that tint**, and clears 4.5:1.
- `--health-green` (the bare token) is a **meaningful graphic** — a status dot, a
  bar, a mark on the rate ladder — and clears 3:1.

**Never put a bare health token on canvas as body text.** It will fail contrast.
The pattern repeats identically for amber, red, and the info chip.

| Meaning | Tint (bg) | Ink (text) | Graphic |
|---|---|---|---|
| Healthy / won / on track | `#d5f5da` | `#154f27` | `#05893e` |
| Watch / aging / at risk | `#ffecc1` | `#784900` | `#a56e00` |
| Bad / lost / underwater | `#ffe2de` | `#8d1a1e` | `#c92f33` |
| Informational | `#d2f0ff` | `#004e71` | — |

---

## Typography

**Geist Variable** for everything, **Geist Mono Variable** for the mono role.
Both are available on Google Fonts as "Geist" and "Geist Mono".

```html
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@100..900&family=Geist+Mono:wght@100..900&display=swap" rel="stylesheet">
```

**Root size is 14px.** Every size below is an absolute px value, counted from the
real app, so it does not matter how your rem base is configured.

The app does not use named type classes. It sizes with explicit px values, and
the distribution is heavily weighted toward the small end.

| Role | Size | Weight | Tracking | Family | Colour |
|---|---|---|---|---|---|
| **Eyebrow / column header / micro-meta** — the most common text in the app | **11px** | 500 | **+0.08em, uppercase** | sans | ink-muted |
| Body, table cell, nav tab | **13px** | 400 | normal | sans | ink |
| Secondary label, sub-tab | 12px | 500 | normal | sans | ink-muted |
| Emphasis body, primary button label | 14px | 600 | normal | sans | ink |
| Form input (cockpit drawer) | 13.5px | 400 | normal | sans | ink |
| Dense table variant | 12.5px | 400 | normal | sans | ink |
| **KPI value, default** | **15px** | **640** | normal | **mono**, tabular | ink |
| **KPI value, hero** | **24px** | **640** | normal | **mono**, tabular | ink |
| Panel or section headline | 19px | 600 | −0.01em | sans | ink |
| Larger headline | 20px | 600 | −0.01em | sans | ink |
| KPI hint line | 10px | 500 | normal | sans | ink-muted |
| Smallest badge / micro-hint | 10px | 500 | +0.06em, uppercase | sans | ink-muted |

There is no row here for a delta or a change indicator, because **the product
has none.** No trend arrows, no "versus last period", nowhere. A KPI carries its
context in a hint line instead: a count, a denominator, or a caveat such as "too
few closed". Adding a delta would mean inventing a number the underlying data
does not support.

**Nothing in the app is larger than 36px**, and that single instance is one
pricing headline number. This is an operator cockpit, not a marketing page.

### The pricing screens run a stricter, governed scale

The table above describes the **cockpit dashboard**, which grew organically and
uses thirteen ad-hoc sizes. The **pricing screens** are different: they are
locked to a five-value scale by an automated test that fails the build if a size
outside it appears.

| Pricing scale | 12px · 14px · 16px · 26px · 36px |
|---|---|

Plus three permitted letter-spacing values. Nothing else is allowed in that
subtree.

For the rebuild: **adopt the governed scale everywhere.** It is the better of
the two, and the dashboard's thirteen sizes are drift, not design. If you unify
on 12 / 14 / 16 / 26 / 36 the whole product gets more coherent, and you can say
so in your handoff as a deliberate improvement.

### Three details that carry the character

1. **The uppercase micro-label is the core motif, not an accent.** It appears
   about 75 times across 22 files. The recipe is fixed: `11px`, weight 500,
   `uppercase`, `letter-spacing: 0.08em`, muted ink. Panel eyebrows, table column
   headers, status captions — all of them. Get this one right and the whole thing
   starts to look correct.

2. **Weight 640 is the signature.** A custom variable-font weight, heavier than
   semibold and lighter than bold, used **only** for large mono numbers. It is
   what makes the KPI figures look the way they do. Geist Variable supports it
   because the weight axis is continuous.

3. **There is no bold anywhere.** Not one `font-bold` in the whole app. The
   weight ladder is 400 → 500 → 600 → 640, and it stops.

Paragraph line-height is `1.625` throughout; tight multi-line labels use `1.375`.

### When to use mono

Mono is semantic here, not decorative:

- **Large numbers** — KPI values, headline figures. Always with `640` weight and
  tabular numerals.
- Any figure compared down a column — rates, percentages, basis points, currency
  in tables.
- Identifiers, versions, and config revision stamps.

**Eyebrow labels are sans, not mono.** They get their character from the
uppercase and the letter-spacing. Do not set them in mono.

Never use mono for prose, headings, or button labels.

### The tabular-numbers rule

Any column of numbers gets `font-variant-numeric: tabular-nums`. Digits must
line up vertically. This is the single highest-value typographic detail in the
whole product and it is easy to forget.

---

## Shape and spacing

| Radius | Value | Applies to |
|---|---|---|
| card | **16px** | Panels, cards, drawers, sheets |
| small | 10px | Small tiles and grouped surfaces |
| control | **8px** | Buttons, inputs, selects, sub-tabs, icon buttons, chips |
| tight | 6px | A fourth radius that appears only in the pricing screens |
| full | 9999px | Pills, badges, status dots, progress bars, avatars |

The two that carry the look are **8px for controls and 16px for cards**. Use
those unless there is a reason not to.

Two traps here:

- **Fully-round shapes are for badges, not buttons.** Pills, status dots and
  avatars are round; a button is 8px. A rebuild that makes buttons pill-shaped
  reads as a different product.
- **The "small" radius is 10px, not 2px.** The real app overrides Tailwind's
  built-in `rounded-sm` (normally 2px) to 10px. Nothing currently uses it, so
  the override is inert — but reaching for it expecting 2px gives 10px. Either
  port the override deliberately or drop the name entirely.

### The 14px root changes every spacing number

This is the detail most likely to make a faithful-looking rebuild feel subtly
wrong, and it is worth reading twice.

The production app sets `html { font-size: 14px }` and uses a **rem-based**
spacing scale with no override. So every nominal spacing value renders at
**14/16 = 87.5%** of what its name suggests. A Tailwind `gap-6` is nominally
24px and actually renders at **21px**.

| Nominal | Actually renders | Used for |
|---|---|---|
| 4px | 3.5px | Between a label and its value |
| 8px | 7px | Inside a chip, between icon and text |
| 12px | 10.5px | Between related controls in a row |
| 16px | 14px | Panel padding, gap between cards |
| 24px | **21px** | Page side gutter, gap between panel groups |
| 32px | **28px** | Side gutter at ≥640px, gap between major sections |

Two ways to get this right, and either is fine as long as you pick one:

- Set the root to 14px and use rem-based spacing, exactly as production does; or
- Set the root to 16px and use the **rendered** px values in the middle column.

What does not work is a 16px root with nominal spacing values. That reads
visibly airier than the real product — the density is a large part of its
character.

Page shell: content centred, **max-width 1200px**, side padding of 21px rising
to 28px at 640px and above.

Controls have a **minimum 44px tap target**, even when the visible control is
smaller. Icon buttons are 36px square with the hit area padded out.

---

## Elevation, borders, and the no-shadow rule

There is no shadow token in this product and there should be none in the
rebuild. The three ways to separate things:

1. **Surface tone** — move up the ladder.
2. **A hairline border** — `1px solid var(--hairline)`, or `--hairline-strong`
   when it needs to assert itself.
3. **Whitespace.**

The doctrine is stated in fifteen separate places in the source, and one of them
puts it well: *refusing sheet shadows is the brand tell.* Two components go as
far as setting `shadow-none` explicitly, to stop a library default sneaking one
in.

**There is exactly one shadow in the entire application**: a `shadow-lg` on the
pricing citation popover — a small floating panel that has to read as detached
from everything under it. That is the whole inventory. If your rebuild has two
shadows, one of them is wrong.

The other visual effect in the app is the sticky header: a hairline bottom
border plus a translucent background at 90% opacity with a backdrop blur.

Together those two are the complete list of effects. No gradients, no glows, no
borders that fake depth.

---

## Motion

Restrained and functional. Motion tells you something moved; it does not
perform. The entire vocabulary is four things.

**1. One entrance transition, used everywhere.** Fade in from 4px below, 250ms,
ease-out. Every animated surface in the app uses this exact literal — panels,
cards, placeholders. No spring, no stagger, no scale.

```js
initial:    { opacity: 0, y: 4 }
animate:    { opacity: 1, y: 0 }
transition: { duration: 0.25, ease: "easeOut" }
```

**2. Colour transitions on hover and state change.** 150ms, ease-in-out, on
colour, background, border, fill and stroke. Nothing else transitions.

**3. A skeleton pulse while loading.** Always on the strong-surface colour with a
hairline border. It is the only loading idiom in the app — there is no spinner
except on the sync button, which spins its refresh icon while busy.

**4. One signature: the sparkline self-draws.** The trend line animates its SVG
path length from 0 to 1 over **1100ms**, ease-out. It is deliberately the one
expressive moment, and it exists partly to make a point — the data visualisation
is hand-drawn SVG, never a chart library.

### Never

No parallax. No scroll-triggered reveals. No staggered page-load choreography.
No looping ambient animation. No custom keyframes. Numbers update in place on
refresh; do not animate layout when data changes.

### Reduced motion needs two layers, not one

This is the part rebuilds usually get wrong.

1. **The CSS clamp** collapses animation and transition durations to `0.01ms`
   under `prefers-reduced-motion: reduce`. It is already in `02-tokens.css`.
2. **A JavaScript gate.** The CSS clamp does **not** affect JS-driven animation.
   Every animated component must also check the reduced-motion preference in
   code and mount at its final state rather than animating quickly.

Ship both. One without the other leaves motion running for the people who asked
for it to stop.

Where press feedback exists, reduced motion drops the scale but **keeps the
colour tint**, so those users still get feedback that the press registered.

---

## Icons

**Lucide**, 16px, stroke width 2. Nothing else.

Section icons, fixed:

| Section | Icon |
|---|---|
| Home | `home` |
| Revenue | `trending-up` |
| Marketing | `megaphone` |
| Leadership | `clipboard-list` |
| Pricing | `calculator` |

Theme toggle: `sun` when dark is active (click to go light), `moon` when light is
active. No text label; use `aria-label` and `title`.

Icons sit next to text, never replace it in navigation.

---

## Accessibility — treat as requirements, not aspirations

The real app has an automated contrast guard that grades every token pair in
both themes and fails the build on a regression. Match its rules:

1. **Body text clears 4.5:1** against whatever surface it actually sits on —
   including tinted surfaces, not just canvas.
2. **Meaningful graphics clear 3:1** — status dots, chart marks, borders that
   carry meaning.
3. **Focus is always visible**: a 2px accent outline with a 2px offset. Never
   `outline: none` without a replacement.
4. **Colour is never the only signal.** A red row also carries a word. A health
   light also carries a label.
5. **Every control is keyboard reachable**, and tab order follows visual order.
6. **Every icon-only button has an accessible name.**
7. Disabled controls are the one exemption from the contrast floor.

If you change a colour, re-check it against the surface it lands on. The most
common regression is muted text that reads fine on white and fails on a tint.

### Visual defects in the real app — fix them, do not copy them

These were found while extracting this brief. The prototype is a good place to
prove the fix.

The full list, including behavioural bugs beyond the visual ones, is in
`01-product/05-known-defects.md`.

1. **Tab rows are not keyboard navigable.** Both nav rows, the pipeline switcher
   and the time-window chips set a roving `tabIndex` but implement no
   arrow-key handler, so a keyboard user can only reach the *active* tab. Add
   ArrowLeft / ArrowRight / Home / End.
2. **No `role="tabpanel"` and no `aria-controls`** anywhere in the shell. The
   tab rows are visual tabs without the relationship a screen reader needs.
3. **Four app-shell screens are hardcoded light** — they use inline colour values
   and ignore dark mode entirely. In the rebuild, every screen uses tokens.
4. **A stale product name.** The unprovisioned-user screen still says "the
   ChainIT AI Budget dashboard". It should say Sales Cockpit.
5. **One surviving violet.** A single input on the pricing deal form still
   carries the old lavender as its `accent-color`, hardcoded rather than
   tokenised. It is the last trace of the pre-move palette. Use the green.

---

## A quick self-check before you call a screen done

Nine questions. If any answer is "no", the screen is not finished.

1. Does it look right in **both** light and dark mode?
2. Are all numbers in a column tabular and right-aligned?
3. Is there exactly one accent colour on screen, and is it green?
4. Are there zero shadows?
5. Is the base text 14px or smaller, and is Geist actually loading?
6. Does tabbing through reach every control with a visible ring?
7. Is the empty state designed, with real words, rather than blank?
8. Does the loading state hold the layout rather than collapsing it?
9. Would a sales rep find the number they came for in under two seconds?
