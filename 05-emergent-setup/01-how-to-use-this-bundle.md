# How to use this bundle in Emergent

**Read this first. It takes about ten minutes and it saves you a day.**

---

## What you are being handed

Two working internal tools that ChainIT sales and operations use every day:

1. **Sales Cockpit** — the dashboard the sales team lives in. Pipeline, forecast,
   stuck deals, owner leaderboard, marketing funnels, and a leadership reporting
   section. It reads from HubSpot.
2. **Pricing** — two screens inside that same cockpit. *Price a deal* lets a rep
   quote a merchant. *Configure* is the locked cost engine behind it, which only
   a few people may edit.

Both live today at **sales.chainithub.com**. You are not going to change that
site. You are going to rebuild these screens in Emergent so you can move fast,
try things, and show people what you mean.

## What your job actually is

You are the **product designer and business-rules owner** for these screens.

- You change how the screens look, how they are laid out, what order things
  happen in, what a rep sees first.
- You change the business logic — the rules, the thresholds, the wording, the
  fields, the defaults.
- You do **not** ship to production. When something is right, you export it and
  hand it over.

**The handoff is:** screenshots + a written description of the flow + the
Emergent preview link. See `03-handoff-back-to-engineering.md` for the format.
An engineer then implements it for real on sales.chainithub.com.

## What Emergent will build

Emergent generates a **React frontend + FastAPI backend + MongoDB database**.
Our real system is React + Cloudflare + SQLite. **That difference does not
matter for your purposes** and you should not try to fix it. The prototype only
has to look right and behave right. The engineer handles the translation.

Two consequences worth knowing:

- The prototype runs on **fake seed data** that ships in this bundle
  (`04-data-contracts/seed/`). It does not connect to HubSpot and it never
  will. That is on purpose — it means you can break it freely.
- Anything about login, permissions, or Cloudflare in the real app is **faked**
  in the prototype with a simple role switcher. See
  `04-guardrails-do-not-change.md`.

---

## Before you start — what you need

Five things. Chase any that are missing before your first session, not during it.

| # | What | Who provides it | Status |
|---|---|---|---|
| 1 | An Emergent account with credits on it | Pawel | |
| 2 | This `emergent-build/` folder | You have it | ✅ |
| 3 | Screenshots of the live cockpit, light and dark, all 21 screens | — | ✅ in `screenshots/` |
| 4 | A read-only login to the live app, so you can click the real thing | Pawel | |
| 5 | Half an hour with Jodi Durst on the pricing screens before you change any rule | Book it | |

Item 5 saves the most rework: Jodi owns the cost model, and a pricing change she
has not seen will not ship.

## Step 1 — Get the bundle into Emergent

Emergent accepts context three ways. **Do all three**, in this order. They
reinforce each other and the agent gets confused less often when it can see the
same fact stated more than once.

### 1a. Attach the GitHub repo (best)

Ask your engineer to push this `emergent-build/` folder to a small GitHub repo,
then in Emergent attach that repo to the project. This is the highest-fidelity
path — the agent can read every file rather than a summary.

### 1b. Upload the key documents

If the repo route is not available, upload the files directly into the chat.
Emergent reads PDFs reliably and loose markdown less so.

**The shortcut:** run this once, from inside `emergent-build/`:

```
bash 05-emergent-setup/make-single-file.sh
```

It produces `emergent-build-combined.md` — every document in the right order,
one file. Open it in any markdown editor and print to PDF, or run
`pandoc emergent-build-combined.md -o emergent-build-combined.pdf`. Upload that
one PDF, plus `03-design-system/02-tokens.css` separately as a CSS file.

If you would rather upload individual files, use this order — later files
reference earlier ones:

| # | File | Why |
|---|---|---|
| 1 | `01-product/01-what-this-is.md` | Tells the agent what it is building and for whom |
| 2 | `03-design-system/01-design-brief.md` | Stops it producing generic AI-looking UI |
| 3 | `03-design-system/02-tokens.css` | The exact colours and fonts |
| 4 | `04-data-contracts/02-data-model.md` | The database shape |
| 5 | `04-data-contracts/seed/*.json` | The fake data to load |
| 6 | `01-product/02-sales-cockpit-spec.md` | The screens |
| 7 | `02-pricing-engine/02-pricing-rules-and-math.md` | The business rules |
| 8 | `02-pricing-engine/04-worked-examples-golden.md` | The numbers it must reproduce |

### 1c. Upload the screenshots

They are already in `screenshots/light/` and `screenshots/dark/` — 42 images,
every screen in both themes, captured from the live app. Upload them and say:

> Match these screenshots exactly — spacing, grid, typography, colour. This is
> an existing product, not a new design.

This single step does more for visual fidelity than any amount of written
description. Emergent is strong at matching a reference image.

When you build a given screen, upload **that screen's pair** again with the
prompt for it. A screenshot attached to the specific request lands better than
one uploaded forty images ago.

Names and company names in them are deliberately blurred. That is fine for
matching layout, which is what they are for. If you need to know what a column
actually contains, `01-product/02-sales-cockpit-spec.md` names every field.

---

## Step 2 — Paste the kickoff prompt

Open `00-KICKOFF-PROMPT.md` at the root of this bundle. Paste the whole thing as
your **first** message. Do not paraphrase it and do not shorten it.

Emergent will come back with clarifying questions before it builds. **Answer
them, do not rush past them.** Suggested answers are at the bottom of the
kickoff file.

Expect the first build to take 5 to 15 minutes.

---

## Step 3 — Build it in slices, never all at once

This is the single most important habit. Emergent degrades badly on long mixed
prompts and does very well on one bounded change at a time.

The build order that works:

1. The shell — header, the five-section nav, dark-mode toggle, the fake role
   switcher. Nothing else.
2. The design system — colours, fonts, the shared components (panel, KPI tile,
   table, status badge).
3. Seed the database from the fixtures.
4. One cockpit screen. Get it right. Then the next.
5. *Price a deal*.
6. *Configure*.

`02-prompt-library.md` has the ready-to-paste prompt for each of these.

---

## Step 4 — How to write a prompt that works

Every request you make should have three parts. Emergent's own guidance says
this and it holds up.

```
CONTEXT:    which screen, and what it is for
OBJECTIVE:  the exact outcome you want
CONSTRAINTS: what must not change
```

**A bad prompt:** "make the pipeline page better"

**A good prompt:**

> CONTEXT: the Revenue → Pipeline screen.
> OBJECTIVE: move the four KPI tiles above the deal table, make them a single
> row on desktop and a 2×2 grid below 768px, and show the change vs. the
> previous period underneath each number in the muted ink colour.
> CONSTRAINTS: do not change the table columns, do not change the colours, do
> not touch any other screen.

When something is wrong, give a **numbered list**, not a paragraph:

> 1. The stage column is left-aligned; it should be right-aligned.
> 2. The "Stuck" badge is red; it should be amber.
> 3. The empty state says "No data" — it should say "Nothing stuck. Good."

### The rules that save you the most time

- **One screen per conversation turn.** Mixed prompts produce mixed results.
- **Say what must NOT change.** Emergent will happily "improve" things you did
  not ask about. The constraint line prevents that.
- **Paste errors verbatim.** If the preview breaks, open the browser console
  (F12), copy the whole error, paste it, and say what you expected to happen.
- **Screenshot instead of describing.** If you can point at a picture, do.
- **Ask before it builds.** "Explain what you're about to change, don't build
  yet" is a legitimate prompt and catches a lot of wasted cycles.

---

## Step 5 — When you change a business rule

This is different from changing the UI, and it needs more care, because a wrong
pricing rule that reaches production costs real money.

When you change anything in the pricing engine:

1. State the rule change in plain English in the Emergent chat.
2. Re-run the worked examples in `02-pricing-engine/04-worked-examples-golden.md`
   and note which results changed and by how much.
3. Write the change down in your handoff with the **before and after numbers**.

Never hand over a pricing change without the numbers. "I made the margin
calculation better" is not something an engineer can implement.

---

## Step 6 — Deploy and share (optional)

You do not have to deploy to show your work — the preview link is enough for
most reviews. If you do want a stable link for a meeting, Emergent's Deploy
button gives you a live URL in about 15 minutes.

Keep in mind the prototype is public-ish and runs on fake data. Do not put any
real customer name, real merchant volume, or real rate into it. Use the seed
data. See `04-guardrails-do-not-change.md`.

---

## When you get stuck

| Symptom | What to do |
|---|---|
| The agent rebuilt a screen you did not mention | Your prompt lacked a constraint line. Re-add it and ask it to revert that screen. |
| Colours drifted to purple/blue defaults | Re-upload `02-tokens.css` and say "use only these tokens, no other colours." |
| The numbers in Pricing look wrong | Check them against `04-worked-examples-golden.md`. If they disagree, that is a real bug — paste the expected vs. actual. |
| Preview is blank | Open the console (F12), copy the error, paste it in with "please solve this error." |
| It keeps forgetting a rule | Restate the rule at the top of your next prompt. Emergent's memory of long conversations is imperfect. |
| Two screens now look inconsistent | Ask it to extract the shared piece into one component and use it in both. |

If you are stuck for more than about half an hour, stop and send Pawel the
Emergent link plus what you were trying to do. That is cheaper than grinding.
