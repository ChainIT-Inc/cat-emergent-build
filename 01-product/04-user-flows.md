# User flows

## What this document is for

A screen specification tells you what is on a page. It does not tell you what
happens when someone presses something. This file covers the gap: eight things an
operator actually does in the Sales Cockpit, written as numbered steps with the
result of each one.

Read it if you are about to change any interaction, or if you are checking that a
prototype behaves like the real thing. The details that matter most are usually
invisible in a screenshot — whether a screen refetches or just re-sorts what it
already has, whether an edit appears instantly or only after the save lands, and
what the operator sees when something fails. Those three questions are answered
explicitly for every flow below.

Three terms, defined once:

- **Optimistic** means the screen shows the change immediately and assumes the
  save will work. **Nothing in the Sales Cockpit is optimistic.** Every edit waits
  for the server. This is deliberate: the app is a reporting surface, and a number
  that briefly lies is worse than a number that takes half a second.
- **Refetch** means the screen quietly asks the server for fresh data. A refetch
  never blanks a screen that already has numbers on it.
- **Toast** is the small message that slides in at the bottom-right corner.

---

## Flow index

| Flow | What the operator is doing |
|---|---|
| [(a)](#a-landing-on-home) | Opening the app for the first time today |
| [(b)](#b-switching-pipeline) | Flipping between the direct and affiliate pipelines |
| [(c)](#c-changing-the-time-window) | Looking at a different date range on a marketing panel |
| [(d)](#d-opening-a-record-drawer) | Opening a leadership record to edit it |
| [(e)](#e-editing-and-saving-a-leadership-record) | Editing, saving, deleting and undoing |
| [(f)](#f-forcing-a-sync) | Pressing Sync now and watching it resolve |
| [(g)](#g-asking-the-copilot) | Jumping out to the company copilot from a row |
| [(h)](#h-narrowing-to-my-own-records) | Switching between everyone's records and their own |

---

## (a) Landing on Home

The first thing anyone sees. Worth walking through in full, because the realistic
first-run result is an empty state, not a populated dashboard.

1. **The page loads.** The app initialises on Home → Today. The stored theme is
   read from the browser and applied; the default is light.
2. **The header paints immediately.** It sits outside the login check, so the
   wordmark **"Sales Cockpit"**, the mono chip **"HubSpot · read-only"**, the theme
   toggle and both nav rows are on screen before anything else — with Home and
   Today marked active.
3. **The identity check fires.** For the first **300 milliseconds** the body
   renders **nothing at all**. This is deliberate: a fast response should never
   flash a spinner. Past 300ms, the loading screen appears.
4. **The check succeeds.** The body renders My Day, which asks for its own data.
5. **While that is in flight, the skeleton shows** — five pulsing KPI cells, then
   two pulsing cards.
6. **The data lands.** Two possible endings:
   - The login maps to a HubSpot owner: the populated Today screen.
   - It does not, **or the request failed**: the designed card headed **"We
     couldn't match your login to a HubSpot owner"**, with a **"Setup & Data
     Readiness"** button. This is what a fresh, empty database produces, and it is
     the state most first-time viewers will see.

**Optimistic?** Nothing.
**Refetches?** The identity check once, then the Home data once. Nothing else.
**Toast?** None.
**On failure?** A failed data request produces the same designed card as no data.
There is no error screen and no error boundary anywhere in the app — a request
that fails degrades into a well-formed empty result. The only exception is a failed
*identity* check, which produces the boot-error card headed **"Unable to load
app"** with a **"Reload page"** button.

---

## (b) Switching pipeline

The single most important interaction in the Revenue section, because it is the
mechanism that keeps the two pipelines apart.

1. The operator is on any Revenue screen — say Stuck & aging. No pipeline has been
   chosen yet, so the first one in the list is active.
2. **They click "Affiliate Pipeline"** in the switcher.
3. **Nothing is requested.** The screen already holds every pipeline's deals; the
   switch is pure re-derivation in the browser. There is no spinner, no toast, and
   the address bar does not change.
4. **Everything below re-renders against the new pipeline** — the KPI band, the
   panel, the summary strip. Crucially the numbers are *replaced*, never added to
   the previous pipeline's. There is no combined total anywhere and there is no
   "All" option to produce one.
5. If the newly selected pipeline has nothing qualifying in it, its own empty card
   appears **inside** the screen shell — so the switcher stays on screen and the
   operator can flip straight back.

**Optimistic?** Not applicable; nothing is being written.
**Refetches?** No. Zero network activity.
**Toast?** None.
**On failure?** No failure mode exists. There is nothing to fail.

**The rule this enforces.** The direct pipeline has 7 stages and the affiliate
pipeline has 9. Summing them produces a number that means nothing. The switcher is
a switcher rather than a filter chip precisely because these are two different
businesses, and the product has no way to express a blend.

---

## (c) Changing the time window

1. The operator is on Marketing → Campaigns, or Marketing → Forms & Email. The
   window starts at **Last 30d**.
2. **The chips only exist when there is windowed data to switch between.** When
   there is none, the panel's header shows a plain count instead — for example
   `"15 campaign(s)"` — and there is nothing to click.
3. **They click "All time".**
4. **Nothing is requested.** Every window's figures already arrived in the one
   payload, so the table re-joins against the new window instantly.
5. **Cells with no row for that window flip to "—"**, never to a fabricated `0`. A
   genuine zero still renders as `0`. The distinction is the point of the sparse-
   analytics note at the top of the Campaigns screen.

**Optimistic?** Not applicable.
**Refetches?** No.
**Toast?** None.
**On failure?** No failure mode exists.

---

## (d) Opening a record drawer

**There is no click-the-row-to-open-a-drawer interaction anywhere in the app.**
Tables have no row click handler and no hover affordance. The drawer is reachable
from exactly two screens, through explicit buttons.

1. The operator is on Leadership → Meetings, or Leadership → Contracts. The last
   column of each row holds two icon buttons.
2. **They click the pencil**, whose accessible name reads **"Edit {customer}"**.
3. **The drawer slides in from the right** over a dark overlay — full width on a
   phone, capped at 440px above that. Its title reads **"Edit — Customer
   Meetings"**.
4. **The first field is focused automatically**, and every field is seeded with the
   row's current values. Those seed values are held stable, so a background refresh
   landing mid-typing cannot overwrite what is being entered.
5. **The alternative entry point** is the **"+ New"** button in the panel header.
   That opens the same drawer titled **"New — Customer Meetings"**, with every
   field blank.
6. **Pressing Escape or clicking the overlay** closes it — but if anything has been
   typed and not saved, a native browser confirm appears first, reading **"Discard
   unsaved changes?"**

**Optimistic?** Nothing has been written yet.
**Refetches?** No.
**Toast?** None at this stage.
**On failure?** Not applicable.

---

## (e) Editing and saving a leadership record

Three mechanisms, all in the Leadership section, all worth reading separately
because they behave differently.

### (e1) Saving through the drawer — Meetings and Contracts

1. The operator edits fields in the open drawer.
2. **Leaving a required field empty** and moving away from it marks it invalid: an
   accent border, an invalid flag for screen readers, and a message beneath reading
   **"{Label} is required."**
3. **They click Save.** If a required field is still empty, the click marks it
   touched and **does nothing else**. No request is made and there is no error
   toast — the message under the field is the whole feedback.
4. Otherwise the button label becomes **"Saving…"** and disables, and the save is
   sent.
5. **On success:** the toast reads **"Saved"** for an edit, or **"Added"** for a new
   record. The list refetches. The drawer closes.
6. **The row updates only after that refetch lands. Nothing is optimistic.**

**Optimistic?** No.
**Refetches?** Yes — the whole list, on success.
**Toast?** **"Saved"** or **"Added"**.
**On failure?** The toast reads **"Couldn't save — please try again"**, and the
drawer **stays open with everything the operator typed still in it**, so they can
retry without re-entering anything.

### (e2) Editing a cell in place — Pipeline Health

The CTA and Risk / Blocker columns are editable directly in the table.

1. **They click the cell**, or Tab to it and press Enter. It becomes a two-row text
   area, focused, with an accent border so it reads as visibly different from the
   read-only HubSpot cells beside it.
2. **They type.**
3. **Pressing Escape** resets the text to the last saved value and exits the cell
   **without writing anything**.
4. **Clicking away, or tabbing out, saves** — but only if the text actually
   changed. The annotation is written against that deal, then the screen refetches.
5. **The cell returns to read mode. There is no success toast.** This is the one
   place in the app that saves silently, and it is deliberate: an operator
   annotating twenty rows in a row does not want twenty toasts.

**Optimistic?** No. The cell shows the new value only after the refetch.
**Refetches?** Yes — the Pipeline Health rows, after each save.
**Toast?** None on success.
**On failure?** The toast reads **"Couldn't save — please try again"**, and the
cell **stays in edit mode with the typed text intact**.

### (e3) Deleting, and undoing the delete

1. **They click the bin**, whose accessible name reads **"Delete {row}"**.
2. **A native browser confirm appears** reading **"Delete this row?"**. Cancelling
   does nothing at all.
3. **Confirming deletes the row.** The list refetches and the row disappears.
4. **The toast reads "Row deleted"**, and carries an **Undo** action.
5. **Clicking Undo re-creates the row.**

**Optimistic?** No. The row disappears only after the delete lands.
**Refetches?** Yes, after the delete and again after an undo.
**Toast?** **"Row deleted"** with an Undo action. A neutral toast, not a success
one.
**On failure?** Deleting fails with **"Couldn't delete — please try again"**. An
undo that fails shows **"Couldn't undo"**.

> **Defect — fix, do not copy.** Undo does not restore anything. It inserts a
> **new** row with a **new identifier**, and stamps "created by" and "created at"
> with whoever pressed Undo and when. There is no restore-by-id capability behind
> the button. In the prototype, either build a real restore or reword the toast so
> it does not promise one.

---

## (f) Forcing a sync

1. **They go to Setup & Data Readiness.** The Sync now button sits in the header of
   the Sync freshness panel.
2. **If the last sync ran under five minutes ago**, the button is disabled and
   reads **"Sync in 3:00"**, counting down every second. The countdown is correct on
   the very first frame — it is computed as the screen paints, not a second later.
3. **Once past the cooldown** it reads **"Sync now"** and enables.
4. **They click it.** The label flips to **"Syncing…"**, the button disables, and
   the refresh glyph spins.
5. **On success:** the toast reads **"Synced · 1,234 events"** with the real event
   count. The snapshot refetches, which repaints the lane rows, the object counts
   and the two readiness tiles.
6. **The countdown restarts on its own**, because the newly fetched data carries a
   newer "last pulled" time, which feeds the button.

**Optimistic?** No. Nothing on the page changes until the refetch lands.
**Refetches?** Yes — the whole snapshot, on success.
**Toast?** **"Synced · {n} events"**.
**On failure?** Two different outcomes, and the distinction matters:

| Outcome | Toast | Why |
|---|---|---|
| Rate limited | **"Already up to date — try again shortly."** — an *info* toast | The browser re-enabled the button a beat before the server agreed. It is a harmless race at the cooldown boundary, not an error, and it must not be dressed as one |
| Anything else | **"Sync failed: {message}"** — an error toast | A genuine failure |

---

## (g) Asking the copilot

1. From a My Day open-deal row, a hot-lead row, or a Stuck & aging queue row, the
   operator clicks the **"Ask copilot"** chip — labelled just **"Ask"** in the
   denser Stuck & aging rows.
2. **A new browser tab opens** at the company copilot, with a freshly minted
   conversation identifier.
3. **The question is not pre-filled.** The chip knows which deal or lead it sits
   next to, but that information only feeds its tooltip and its accessible name.
   The operator retypes their question in the copilot.
4. **Nothing in the cockpit changes.** No state, no refetch, no toast. The tab they
   left is untouched.

**Optimistic?** Not applicable.
**Refetches?** No.
**Toast?** None.
**On failure?** No failure mode inside the cockpit — it is a plain link.

**Two constraints behind this, worth understanding before redesigning it.** The
copilot exposes no way for another page to hand it a starting prompt, so the chip
is labelled for what it does rather than what we wish it did. And it opens in a new
tab on purpose: the copilot lives on a different origin behind a different login,
so navigating in the same tab would tear down the entire cockpit — the section, the
sub-tab, the scroll position, and every figure already fetched.

There is a second copilot entry point: the persistent bar along the bottom of every
page carries a drawer that opens in place. That bar is inherited from the wider
company shell, and the cockpit has no way to open or pre-fill it.

---

## (h) Narrowing to my own records

Three separate scope toggles, with three different option sets and — importantly —
two different implementations.

### (h1) Stuck & aging

1. **The toggle only appears when the signed-in user maps to a HubSpot owner.** A
   user with no matching owner never sees it at all.
2. Options: **"All reps"** (the default) and **"Mine only"**.
3. **They select "Mine only".** The queue is rebuilt in the browser, dropping every
   deal owned by someone else. **No request is made.**
4. **Every number below recomputes** — "$ at risk", "Aging", "Stale", the queue
   itself, and the summary strip.
5. **If nothing of theirs is stuck**, the good-news card appears with copy specific
   to the scope: *"None of **your** open deals in this pipeline have aged past 14
   days in-stage…"*

**Refetches?** No. **Toast?** None. **On failure?** No failure mode.

### (h2) Pipeline Health

1. **Same gate** — the toggle appears only when the login maps to a HubSpot owner.
2. **Same two options**, and the same browser-side filter.
3. **All four KPI tiles recompute against the filtered rows**, so "Open
   opportunities" and "Open revenue potential" become *my* numbers, not the team's.

**Refetches?** No. **Toast?** None. **On failure?** No failure mode.

### (h3) Data to Fix — the one that is different

1. **This toggle is always visible.** Options: **"Mine"** and **"All"**, plus
   **"Unowned"** for a manager only.
2. **This one is server-side.** Changing scope changes what is asked for and
   **refetches**. It has to be: the table shows at most 200 rows out of tens of
   thousands, so filtering in the browser would produce a confidently wrong answer.
3. **The previous rows stay on screen while the new ones load**, so the table never
   flashes empty.
4. **The caveat line above the table recomputes** from the new counts — how many
   are shown, how many match, how many are synced.
5. There is a second toggle on this screen, for **"Companies"** versus
   **"Contacts"**. Switching it **clears any active missing-field filters**, because
   the required fields differ between the two record types and carrying a company
   filter over to contacts would be meaningless.

**Refetches?** Yes, on every change.
**Toast?** None.
**On failure?** The screen degrades to its designed empty state rather than showing
an error.

### One note on vocabulary

There is no "Team" option anywhere in the product. The wording is **All reps /
Mine only** on the deal screens and **Mine / All / Unowned** on Data to Fix. What
does vary by team-versus-individual is the operator's *role* — rep, manager or
marketer — which changes the My Day headings and prefixes its KPI labels with
"Team ".
