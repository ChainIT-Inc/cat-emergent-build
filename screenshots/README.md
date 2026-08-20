# Screenshots — captured 2026-08-20

**42 screenshots. All 21 routes, light and dark. Every pair matched.**

Captured from the live app at `sales.chainithub.com` by driving a real
authenticated Chrome session. Not mockups, not a dev server — the actual
production UI as it renders today.

```
light/   21 files   01-setup-light.jpg … 21-pricing-configure-light.jpg
dark/    21 files   01-setup-dark.jpg  … 21-pricing-configure-dark.jpg
```

Total 2.6 MB. Filenames pair on the number and slug, so
`05-revenue-pipeline-light.jpg` and `05-revenue-pipeline-dark.jpg` are the same
screen in both themes.

---

## Upload these to Emergent

They are the single highest-value input in the bundle. Emergent matches a
reference image far better than it matches a written description. Upload them
early, with this instruction:

> Match these screenshots exactly — spacing, grid, typography, colour. This is
> an existing product, not a new design.

---

## Capture conditions

| Setting | Value |
|---|---|
| Window | 1440 × 1000, viewport 1440 × 752 |
| Device pixel ratio | 2 (retina) |
| Format | JPEG |
| Theme | Toggled via the app's own control, `marketing-theme` in localStorage |
| Stabilisation | Animations, transitions and the text caret disabled; skeleton pulse and spinner frozen; scrolled to top before each shot |

**Viewport only, not full page.** Every shot is the top 752px of the screen.
Several screens are much taller — Pipeline Health runs to 18,536px and Data to
Fix to 12,300px — so what you see is the first screenful. That is the part that
matters for layout and it is what a user sees on landing. The row patterns
repeat below the fold.

---

## Redaction

**Real customer, prospect and staff data is blurred.** These screenshots go to a
third-party service, so the blur is applied in the page before the shot is taken.

Blurred:

- Person names and email addresses (the Hot Leads list, owner columns, the
  "Top rep" tile)
- Company and opportunity names (Pipeline Health, Data to Fix, Stuck & aging)
- The editor's email on the pricing Configure header

Deliberately **not** blurred, because it is layout information rather than
personal data:

- Aggregate counts and totals
- Stage names, source channels, campaign names
- Every label, heading, button and column header
- The pricing configuration values

Blur was chosen over deletion on purpose: row heights, column widths and action
placement all stay exactly as they render, which is what the screenshots are for.
Two shots were captured, reviewed, found to be leaking, and re-taken.

**Business figures are visible.** Open pipeline values, contact counts and the
rate configuration are all readable. They are ChainIT's own operational numbers
rather than anyone's personal data, but they do go to a third party. If that is
not acceptable, say so and they can be masked too.

---

## What the capture confirmed

Reading the source got most things right. Driving the live app settled the rest.

### Confirmed exactly as documented

- **The accent is green.** `#388e56`, on every active tab, focus ring and
  primary button. The token named `accent-lavender` renders green.
- **The floor is 35 bps + $0.10/item.** Visible on both pricing screens.
- **Downgrade defaults are 7.5% and 0.6%**, each carrying a `PROVISIONAL` badge.
- **13 editable config values**, shown as "9 of 13 values still awaiting a
  confirmed figure".
- **Time windows are Last 7d / Last 30d / Last 90d / All time**, defaulting to
  30d.
- **Scope toggles are All reps / Mine only**, **Companies / Contacts**, and
  **Mine / All**. There is no "Team" option anywhere.
- **KPI tiles are horizontal strips** with the icon on the left, and carry no
  delta or trend arrow.
- **No shadows.** Depth is surface tone and hairlines throughout.
- **The URL is the quote** — using the pricer rewrote the address bar to
  `?v=2026-08-04·r2&vert=ecommerce&proc=elavon&pm=cnp&vol=100000&tkt=75&type=flat&rate=0.0274&item=0.3`,
  exactly the parameter names in the docs.
- **Dark mode works** on all 21 captured screens.
- **All 9 HubSpot scope surfaces are granted.**

### Corrections the live app forced

**1. There are three pipelines in production, not two.**

Every document in this bundle says two. The switcher actually shows:

| Pipeline |
|---|
| Affiliate Pipeline |
| **STAGING - ChainIT Pay Sales Pipeline** |
| Sales Pipeline |

A pipeline named STAGING is live in the production switcher. Worth a decision:
either it belongs there, or it should be filtered out.

**2. The default pipeline is the Affiliate one.**

On every Revenue screen the switcher lands on Affiliate Pipeline, which holds 2
open deals worth $3.4k. Sales Pipeline holds 216 opportunities worth $14.9M. A
rep opening the Revenue section sees the small one first.

### New defects observed live

These are additions to `01-product/05-known-defects.md`.

**Currency renders with three decimal places.** The Forecast screen shows a
weighted forecast of **`$921.333`**. Money should carry two decimals. Visible in
`06-revenue-forecast-light.jpg` and its dark twin.

**Pipeline Health repeats the same row.** The identical opportunity appears
three times in a row, same name, same stage, same everything. Either duplicate
source data or a rendering fault. Visible in `17-leadership-pipeline-*.jpg`.

**An owner id renders with no name.** One row of the Owners leaderboard shows a
raw numeric id followed by "name pending" instead of a person. Visible in
`07-revenue-owners-*.jpg`.

**The Setup link triggers a full page reload.** It is a real anchor pointing at
`/#/setup`, so clicking it reloads the whole application rather than routing
client-side. Every other navigation is instant.

### Data-quality findings worth escalating

Not UI bugs. They are what the tool was built to surface, and it is working.

| Finding | Number |
|---|---|
| Open opportunities in the Sales Pipeline | 216 |
| Of those, missing a next step | **216 — all of them** |
| Of those, missing required fields | **216 — all of them** |
| Open revenue potential | $14,896,252 |
| Companies missing an owner | 34,740 |
| Companies missing a domain | 29,894 |
| Leads reaching MQL | 1 of 51,498 |

The Lead Funnel screen states the last one plainly: of 51,498 leads, one reached
MQL, a 0% pass-through.

### Still unverified

**Whether toasts render light against a dark page.** Triggering one needs a
write action — saving a leadership record — and this was a read-only pass. It
remains the open question from the design brief.

---

## Re-capturing

The capture drove the live site through the browser rather than a script in this
repo, so there is nothing here to re-run. To refresh:

1. Open `sales.chainithub.com` in a logged-in Chrome at 1440 wide.
2. Walk the 21 routes in the order of the filenames.
3. Toggle the theme and walk them again.
4. Redact person, company and opportunity names before sharing.

Note that Home, Revenue and Marketing carry **no URL hash** — those tabs are
in-memory only and must be clicked. Only `#/setup`, `#/leadership/<tab>` and
`#/pricing/<tab>` are deep-linkable.
