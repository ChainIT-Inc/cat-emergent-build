# Handing your work back to engineering

You prototype in Emergent. An engineer implements it for real on
`sales.chainithub.com`. This file is the contract between those two steps.

The goal is that an engineer can read your handoff **once** and build the right
thing without asking you a follow-up question.

---

## The handoff package

For each change you want shipped, send one folder (or one email, or one
Confluence page — the medium does not matter, the contents do) containing:

### 1. A one-line summary

What changed, in the language a salesperson would use.

> "Reps can now see the minimum rate a deal supports without opening the
> Configure tab."

### 2. Before and after screenshots

- One screenshot of the **current live app** (`sales.chainithub.com`).
- One screenshot of **your Emergent prototype** showing the change.
- Both in **light and dark mode** if the change is visual.
- Full screen, not a crop, so the engineer can see the surrounding layout.

Name them so the pairing is obvious: `pipeline-before-light.png`,
`pipeline-after-light.png`.

### 3. The Emergent preview link

Paste the live preview URL. The engineer will click through it. This catches
the things a screenshot cannot show — hover states, what happens on click,
loading behaviour.

### 4. The flow, written as numbered steps

Not a paragraph. Numbered steps, with what the user sees after each one.

> 1. Rep opens **Pricing → Price a deal**.
> 2. They pick a vertical from the dropdown. The rate ladder on the right
>    updates immediately — no Save button.
> 3. They type a monthly volume. If it is below $10,000 an amber note appears
>    under the field reading "Below our usual floor — check with Jodi."
> 4. The Results panel shows the blended rate, the margin, and a green / amber /
>    red health light.
> 5. They click **Copy quote link**. A toast says "Quote link copied." The link
>    contains every input, so whoever opens it sees the same numbers.

### 5. Business-rule changes, with numbers

This section is mandatory whenever you touched the pricing engine, and it is
the one people skip.

State the rule as **before → after**, and give the effect on at least two of the
worked examples from `02-pricing-engine/04-worked-examples-golden.md`.

> **Rule changed:** the downgrade share default.
> **Before:** 7.5% of volume downgrades, at a 0.60% uplift.
> **After:** 6.0% of volume downgrades, at a 0.60% uplift.
>
> Effect on a reference deal — e-commerce vertical, $500,000 monthly volume,
> $100 average ticket, Elavon, flat at 2.74% + $0.30:
>
> | Figure | Before | After |
> |---|---|---|
> | Monthly cost | $12,436 | $12,376 |
> | Monthly net | $2,760 | $2,820 |
> | Margin, bps on volume | 55.2 | 56.4 |
> | Health light | green | green |
> | Minimum rate | 2.31% | 2.30% |
>
> **Why:** Jodi's revised read of the last two quarters of Elavon statements.

The numbers above are illustrative of the *format*, not real. Produce yours from
the prototype.

**Pick a reference deal that the change actually moves.** A downgrade tweak, for
instance, cannot move the golden single-transaction table at all — that table is
computed one layer below where the downgrade is applied, and it has no downgrade
term in it. Showing an unchanged table proves nothing. Use a full monthly deal.

If you cannot produce a table like this, the rule change is not ready to hand
over.

### 6. What you deliberately did NOT change

One or two lines. This tells the engineer where the boundaries are and stops
them "tidying up" something you left alone on purpose.

> "I did not touch the Leadership section or the Marketing tabs at all. The
> Configure tab layout is unchanged — only the two default values moved."

### 7. Open questions

Anything you were unsure about. Better a question in the handoff than a wrong
guess in production.

---

## What engineering will do with it

1. Read the summary and the flow.
2. Diff your screenshots against the live app.
3. Re-derive your pricing numbers against the real engine's tests. If your
   before/after table does not reproduce, they will come back to you — this is
   the check that stops a bad rate reaching a customer.
4. Implement it in the real codebase, behind the real permissions.
5. Deploy, and send you a link to verify on the live site.

Expect step 5 to come back to you. **Verifying the real implementation matches
your prototype is part of your job**, not the engineer's.

---

## What NOT to send

- **Do not send code.** Emergent's generated code targets a different stack
  (FastAPI/MongoDB vs. our Cloudflare/SQLite). It will not be used. Sending it
  invites someone to try, and that wastes a day.
- **Do not send a GitHub repo of the prototype** unless someone specifically
  asks for it.
- **Do not send real customer data** in a screenshot. If you somehow have real
  merchant names or volumes on screen, redact them or reshoot with seed data.
- **Do not send "it should look better."** If you cannot point at it, it is not
  a handoff yet.

---

## Cadence

Small and frequent beats big and rare. A handoff covering one screen gets
implemented in a day. A handoff covering nine screens sits in a queue.

Rough guide:

| Size of change | Send it as |
|---|---|
| A label, a colour, a threshold | One handoff, same week |
| One screen's layout | One handoff per screen |
| A new screen | One handoff, plus a short call to walk through it |
| A pricing rule | One handoff, plus the numbers table, plus Jodi's sign-off |

Pricing rules need **Jodi Durst's** agreement before they are handed over. She
owns the cost model. Getting her on the prototype link early is much cheaper
than getting her on it after engineering has built it.
