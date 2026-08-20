# Known defects in the live app

Found while reading the source to build this bundle. None of them was the point
of the exercise; they turned up on the way.

Two audiences:

- **For the prototype** — these are "fix, do not copy". Building them faithfully
  reproduces bugs.
- **For engineering** — this is a ready-made backlog against
  `sales.chainithub.com`. Every item was read out of the code and cites where.

Items 1 through 17 were found by reading the source. Items 18 through 22 were
found on 2026-08-20 by driving the live app in a browser and are **confirmed
visually**, with a screenshot naming each one.

---

## High — these change what a user sees or gets

### 1. Inactive tabs are unreachable by keyboard

Both navigation rows, the pipeline switcher and the time-window chips set a
roving `tabIndex` (active tab `0`, the rest `-1`) but implement no arrow-key
handler anywhere. The pattern only works if arrow keys move the roving index.
They do not.

**Effect:** a keyboard user can Tab to the active tab and nowhere else. They
cannot reach any other section or sub-tab without a mouse.

**Fix:** add ArrowLeft, ArrowRight, Home and End to the tab rows. The scope
toggle already does the right thing by being a group of pressed buttons rather
than a tab list; copy its behaviour.

Where: `SectionNav.tsx` (both rows), `PipelineSwitcher.tsx`, `WindowChips.tsx`.

### 2. The Sync Now toast never shows what happened

The front end reads an `events` field off the refresh response to build its
toast. The worker never sends that field.

**Effect:** the toast is empty or generic where it was meant to summarise what
synced.

**Fix:** either have the worker return `events`, or change the client to
summarise from what it does receive.

Where: `use-force-refresh.ts` versus `routes/refresh.ts`.

### 3. Sync Now leaves most of the app stale

The same handler invalidates only the `snapshot` query. The Revenue and Home
screens hold their own separate queries, which keep serving cached data for up to
five minutes.

**Effect:** a user presses Sync Now, sees it complete, and the numbers they were
looking at do not move. The natural conclusion is that the sync did nothing.

**Fix:** invalidate every affected query, not just the snapshot.

### 4. A numeric zero counts as a missing field

The completeness check treats `0` as missing.

**Effect:** any record with a legitimate zero — a zero amount, a zero count —
is reported as incomplete on the Data to Fix screen. Someone will "fix" a value
that was already correct.

**Fix:** distinguish "absent" from "zero". Null and empty string are missing; `0`
is a value.

Where: `pipeline/completeness.ts`.

---

## Medium — wrong, but visible rather than harmful

### 5. Four app-shell screens ignore dark mode

The boot error, loading, unprovisioned and bypass screens use hardcoded colour
values rather than tokens.

**Effect:** in dark mode they render as bright white panels.

**Settled in seconds by:** loading the app in dark mode and forcing each state.

### 6. Those same screens claim full height inside the body

They declare themselves full-height while rendering inside `<main>`, below the
sticky header and both nav rows.

**Effect:** the card is pushed down and the page overflows. They are not actually
full-screen.

**Fix:** either lift them above the header or stop claiming full height.

### 7. The access-restricted screen names the wrong product

It reads "the ChainIT **AI Budget** dashboard". This app is the Sales Cockpit.
The screen was copied from the AI Budget app and the string was never changed.

### 8. That screen cannot be reached at all

It renders on a 403. No endpoint in this app returns 403 except the pricing
config write. So the screen exists, is styled, is tested, and is unreachable.

**Decide:** either wire it to a real unprovisioned state or delete it. Right now
it is the kind of dead code that looks maintained.

### 9. The same screen is built to show an email it never receives

It accepts the signed-in address as a prop to display, and the caller never
passes one. The clause is permanently dead.

### 10. One surviving violet

A single input on the pricing deal form still carries the old lavender as a
hardcoded `accent-color`. It is the last trace of the palette from before the
pricing engine moved into this app. Everything around it is green.

Where: `DealForm.tsx`.

### 11. Undo after a delete does not restore the row

It creates a **new** row with a new id, and re-attributes the author and the
creation time to whoever pressed Undo.

**Effect:** the audit trail on a leadership report says the wrong person wrote
the row, and any reference to the old id is broken.

**Fix:** a restore-by-id path, or a soft delete that Undo reverses.

Where: `EditableReport.tsx`.

---

## Low — inconsistency and dead weight

### 12. Pipeline Health formats money its own way

It uses a local helper rather than the shared currency formatter, so its figures
can disagree with the rest of the app.

### 13. Price a deal has no loading skeleton

Every other screen has a designed skeleton. This one shows the words "Loading
live rates…" and nothing else. It is the only screen in the app that does this.

### 14. Four components are built, tested, and used by nothing

`SpendBar`, `VerdictBand`, `DisclosurePanel` and `SectionPlaceholder` all have
full source, passing tests, and zero consumers. They are leftovers from the app
this one was copied from.

`SectionPlaceholder` is additionally unreachable — every section has shipped, and
the build-phase number that feeds it is stale metadata.

**Do not build these in the prototype.**

### 15. Dead scaffolding

Three files have no importers at all: the front end's `types.ts` in its entirety,
and two files under the worker's pipeline directory. Verified by grep, not
assumed.

### 16. Declared dependencies that are never used

Three packages are installed and never imported: an animation utility library, a
component library that only the shared shell uses, and a design-token package
whose stylesheet is never loaded.

That last one has a consequence worth noting: any code reading a motion custom
property silently resolves to nothing, because the file that defines those
properties never loads.

### 17. Toasts are probably light in dark mode

The toast library is mounted without a theme setting, so it uses its light
default regardless of the page theme.

**Unverified** — this one genuinely needs a screenshot. It is the first thing to
check on the screenshot pass.

---

---

## Confirmed live in the browser, 2026-08-20

### 18. A STAGING pipeline is visible in production — **high**

The pipeline switcher on every Revenue screen offers three options, and one of
them is named **"STAGING - ChainIT Pay Sales Pipeline"**. Every user can select
it and read its numbers.

Either it is legitimate and should be renamed, or it is test data that should be
filtered out of the switcher.

Screenshot: `screenshots/light/05-revenue-pipeline-light.jpg`

### 19. The switcher defaults to the wrong pipeline — **medium**

Revenue screens open on **Affiliate Pipeline**: 2 open deals, $3.4k. Sales
Pipeline holds 216 opportunities worth $14.9M and sits third in the list.

Every rep opening Revenue therefore lands on the smallest book by default and
has to click to reach the real one.

Screenshot: `screenshots/light/05-revenue-pipeline-light.jpg`

### 20. Currency renders with three decimal places — **medium**

The Forecast screen shows a weighted forecast of **`$921.333`**. Money should
carry two decimals. This is consistent with the source finding that Pipeline
Health formats money with a local helper rather than the shared formatter —
worth checking whether Forecast has the same problem.

Screenshot: `screenshots/light/06-revenue-forecast-light.jpg`

### 21. Pipeline Health repeats the same row — **medium**

The identical opportunity renders three times consecutively: same name, same
stage, same missing-field badges. Either the source data holds duplicates or the
list is keyed wrongly.

Screenshot: `screenshots/light/17-leadership-pipeline-light.jpg`

### 22. An owner id renders instead of a name — **low**

One row on the Owners leaderboard shows a raw numeric owner id followed by the
text "name pending" where a person's name belongs. The owner lookup did not
resolve and the UI shows the fallback.

Screenshot: `screenshots/light/07-revenue-owners-light.jpg`

---

## Not defects — data quality the tool is correctly surfacing

Observed at the same time. These are not bugs; they are the product working.
They are here because somebody should act on them.

| Finding | Number |
|---|---|
| Open opportunities, Sales Pipeline | 216 |
| Missing a next step | **216 — every one** |
| Missing required fields | **216 — every one** |
| Open revenue potential | $14,896,252 |
| Companies with no owner | 34,740 |
| Companies with no domain | 29,894 |
| Leads that reached MQL | 1 of 51,498 |

A 100% incompleteness rate on both checks is worth a second look. A number that
round often means the check is matching everything rather than the data being
uniformly bad — and recall defect 4 above, where a numeric zero counts as
missing. Worth confirming the 216 is real before anyone acts on it.

---

## What this list is not

It is not a code review. Nobody looked for security issues, performance problems,
or logic errors in the pricing math. These are the things that surfaced while
answering a different question.

The pricing engine, for what it is worth, came through clean. It is the most
carefully built part of the application: every configuration value carries a
provenance tag, a test fails the build if a new value ships untagged, the reverse
solve reuses the forward pricing function so the two cannot drift apart, and the
whole thing is pinned by a golden table that reproduces the source document to
the cent.
