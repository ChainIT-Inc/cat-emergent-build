# Styling recipes — which tokens go where

The design brief says what the system is. This file says exactly how to build
each surface out of it. Hand it to Emergent alongside `02-tokens.css`.

The fully cited source research is held outside this repository. Ask Pawel.

---

## The panel — the one chassis everything sits in

Every block of content in the app is this. There is one panel component, not
several.

```
background:    var(--surface)
border:        1px solid var(--hairline)
border-radius: 16px
padding:       14px            (nominal 16px on a 14px root)
box-shadow:    none
```

Optional header row, above a hairline rule:

- **Eyebrow** — 11px, weight 500, uppercase, `letter-spacing: 0.08em`, muted ink.
  Optionally preceded by a 16px accent-coloured lucide icon.
- **Title** — 19px, weight 600, `letter-spacing: -0.01em`, ink.
- **Controls** — pushed right on the same row.

Entrance: fade in from 4px below, 250ms, ease-out. Gated on reduced motion.

## Buttons

| Kind | Recipe |
|---|---|
| **Primary** | `background: var(--accent)`, ink-on-accent text at 14px weight 600, 8px radius, `hover: opacity 0.9` |
| **Secondary** | `background: var(--surface)`, `1px solid var(--hairline)`, ink text, `hover: background var(--surface-strong)` |
| **Ghost** | No background, muted ink, `hover: background var(--surface-strong)` and text to full ink |
| **Icon-only** | 36×36px, 8px radius, muted ink, same hover as ghost. Always has an `aria-label`. |

All of them: `transition-colors` at 150ms, and a focus-visible ring of 2px accent
at 2px offset.

### Disabled — one canonical form

The real app has five different disabled recipes. Do not reproduce that. Use one:

```
cursor:  not-allowed
opacity: 0.5
color:   var(--ink-subtle)
```

**No colour change beyond demoting the text.** Disabled controls are the one
place exempt from the contrast floor.

## Segmented controls — pick one treatment and use it everywhere

The real app has **two** treatments for an active segment, split between the
dashboard and the pricing screens:

| Where | Active segment |
|---|---|
| Dashboard (time window, pipeline switcher) | `background: var(--surface-strong)`, ink text |
| Pricing (deal form toggles) | `background: var(--ink)`, **surface-coloured text** — an inversion |

The inverted one is stronger and more distinctive. **Use `bg-ink` with
surface-coloured text throughout**, and note the unification in your handoff as a
deliberate change.

Inactive segments in both: muted ink, `hover: background var(--surface-strong)`.

```
min-height:    36px
border-radius: 6px
padding:       0 8px
font:          14px, weight 500
transition:    colors 150ms
```

Add ArrowLeft / ArrowRight / Home / End key handling. The production version has
none, and its inactive segments are keyboard-unreachable.

## Tables

| Part | Recipe |
|---|---|
| Header row | `background: var(--surface-strong)`, 11px weight 500 uppercase `0.08em` muted ink |
| Body cell | 13px, ink. Numeric cells right-aligned with `font-variant-numeric: tabular-nums` |
| Row separator | `1px solid var(--hairline)` |
| Row hover | `background: var(--surface-strong)`, 150ms |
| Sort glyph | A small chevron at 50% opacity, full opacity on the active column |

Dense variants drop the body cell to 12.5px.

## KPI tiles

A **horizontal strip**, not a stacked card.

```
container:  background var(--surface), 1px solid var(--hairline),
            border-radius 8px, padding 9px 10.5px
layout:     optional 15px accent glyph on the LEFT, then a stacked column
value:      15px MONO, weight 640, tabular-nums, ink   (hero variant: 24px)
label:      11px, weight 500, muted ink, truncated
hint:       10px, weight 500, muted ink, truncated
```

Weight **640** is the signature. It is a variable-font weight between semibold
and bold, and it is what makes the numbers look right. There is no `font-bold`
anywhere in this product.

The first tile in a row is usually the hero variant.

**No delta, no trend arrow, no "versus last period".** The product has none, on
purpose. The hint line carries context instead — a count, a denominator, or a
caveat like "too few closed". Adding a delta invents a number the data does not
support.

The tile is not interactive and has no hover state of its own. Any
interactivity belongs to the row that holds it.

## Status badges

```
border-radius:  9999px
background:     var(--health-*-tint)
color:          var(--health-*-ink)
font:           10px, weight 500, uppercase, letter-spacing 0.06em
padding:        2px 8px
```

Always carries a **word**. Colour is never the only signal.

Reminder from the brief: the health triad is used in the **pricing screens
only**. The cockpit dashboard's badges use surface-strong with muted ink.

## Inputs and selects

```
background:    var(--surface)
border:        1px solid var(--hairline)
border-radius: 8px
padding:       0 10px
min-height:    36px
font:          13.5px in cockpit drawers, 14px in pricing forms
```

Focus: the hairline goes to `--hairline-strong` **and** the 2px accent
focus-visible ring appears. Do not remove the outline in favour of a border
change alone.

Label above the field: 11px, weight 500, uppercase, 0.08em, muted ink.
Helper text below: 12px, muted ink.
Error text below: 12px, `var(--health-red-ink)`.

## Empty states — the designed-empty idiom

Never a blank area. The recipe:

1. One small accent-coloured lucide icon, 16px.
2. A headline at 13px in full ink. It says what is true, in plain words —
   "Nothing stuck. Good." not "No data".
3. One line of 12px muted-ink explanation, if it helps.
4. Optionally one link or button to the place that would fix it. In this app
   that is usually Setup & Data Readiness.

Centred inside the panel, holding roughly the height the populated panel would
have, so the page does not jump when data arrives.

## Loading states

One idiom: a **pulsing skeleton** on `var(--surface-strong)` with a hairline
border, in the shape of the content that is coming.

There is no spinner anywhere except the sync button, which spins its refresh
icon while busy.

Skeletons must hold the real layout's height. A skeleton that collapses causes
the page to jump twice — once loading, once loaded.

## The sticky header

```
position:        sticky, top 0
background:      var(--canvas) at 90% opacity
backdrop-filter: blur
border-bottom:   1px solid var(--hairline)
z-index:         20
```

The only element in the app with a backdrop effect.

## The theme toggle

A single 36×36px button, 8px radius, pinned right in the header.

- Idle: muted ink. Hover: `background: var(--surface-strong)`, text to full ink.
- Icon: `sun` when dark is active, `moon` when light is active. 16px, stroke 2.
- `aria-label` and `title` both describe the **action**: "Switch to dark mode".
- `aria-pressed` reflects the current state.

Persist to `localStorage`. Wrap the write in a try/catch — private-browsing mode
throws, and the class should still apply for the session. Persistence is
best-effort and never fatal.

## Drawers and sheets

16px radius, `var(--surface)`, hairline border, **no shadow**. Entrance uses the
standard fade-up. Focus moves into the drawer on open and returns to the trigger
on close. Escape closes.

## Popovers

The one exception to the no-shadow rule. A floating popover gets a `shadow-lg`
because it must read as detached from the panel beneath it. `var(--surface)`,
hairline border, 8px radius.

Exactly one component in the app does this. Do not add a second.

## Charts and data visualisation

**There is no chart library, and adding one would change the product's
character.** The sparkline is hand-drawn SVG: a single accent-coloured stroke,
about 80×24px, no axes, no grid, no fill.

Its one flourish is that the path draws itself in over 1100ms on first render —
gated on reduced motion. That is the app's signature animation.

If a screen genuinely needs a chart type that cannot be hand-drawn, raise it in
your handoff rather than importing a library into the prototype.

---

## Two known gaps worth fixing while you are here

1. **Toasts are not theme-aware.** The toast library is mounted without a theme
   setting, so it defaults to light and probably renders as a bright block on a
   dark page. Set the theme explicitly in the prototype.
2. **Motion tokens do not resolve.** A shared token package is declared as a
   dependency but its stylesheet is never imported, so any code reading a motion
   custom property silently gets nothing. Either import it or use literal
   durations. The prototype should use literals.
