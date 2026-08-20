# Guardrails — what the prototype must not do

Short file. Every line here exists because getting it wrong is expensive or
embarrassing.

---

## 1. No real data. Ever.

The prototype runs on the fake fixtures in `04-data-contracts/seed/`. Every
company name in there is invented.

**Never type into the prototype:**

- a real merchant or customer name
- a real monthly processing volume from a real deal
- a real negotiated rate
- anyone's email address, phone number, or bank detail
- anything from a HubSpot record

The prototype may end up on a public URL, and Emergent is a third-party service.
Treat everything you put in it as if it could be read by someone outside
ChainIT. If you need to demo a specific scenario, invent a merchant with
plausible numbers and say so on the screen.

**No real colleague email addresses either.** The seed fixtures use six
fictional owners for exactly this reason. Every address in the uploadable part
of this bundle is invented, including the ones in the permission examples. Keep
it that way.

The engineers' raw research is deliberately **not in this repository** for the
same reason: it does contain real staff addresses, lifted from the authorisation
lists in the source code. If someone sends it to you, do not upload it.

## 2. The prototype has no real login

The live cockpit sits behind Cloudflare Access and Microsoft Entra. None of that
can be reproduced in Emergent and you should not try.

Instead the prototype gets a **fake role switcher** in the header — a plain
dropdown that changes which role you are pretending to be. It exists so you can
see each role's view. It is a prototyping device, not a feature, and it will not
be implemented in production.

The roles to include, and what each changes:

| Role | Sees |
|---|---|
| **Rep** | Their own deals. No cost or margin columns. Cannot open Configure. |
| **Manager** | The whole team's deals, plus the unowned scope. Still no Configure. |
| **Marketer** | The Marketing section's data. |
| **Config editor** | Everything a manager sees, plus the **Configure** tab. |
| **Admin** | Everything, plus the per-row **cost and margin** columns. |

### There are three permissions here, not two

This is the single easiest thing in the whole product to get wrong, because all
three sound like "admin".

| Permission | Driven by | Grants |
|---|---|---|
| **Config editor** | A named Leadership group | May edit the pricing cost engine |
| **Pricing admin** | `PRICING_ADMIN_EMAILS` | May see per-row cost and margin in pricing |
| **Cockpit manager** | `ADMIN_EMAILS` | Team-wide cockpit views and the "Unowned" scope |

They are independent. A person can hold any one without the others.

The third one is a live trap in the real code: `ADMIN_EMAILS` is folded into the
cockpit's **manager** view role. Setting it to grant someone pricing access would
silently promote them to manager across every cockpit view — the team-wide Home
digest, the Unowned scope in Data to Fix, all of it. That is why pricing uses its
own separate `PRICING_ADMIN_EMAILS` variable and **never reads `ADMIN_EMAILS`**.

If your prototype collapses these into one "admin" toggle, the production
implementation will inherit the wrong shape. Keep all three apart.

There is also a **fourth** thing called a role, on a different axis entirely: the
login token carries `member` or `admin`. **Nothing in this app reads it**, and a
test actively asserts that the pricing code must not. Mentioned only so that
seeing the word "admin" in a token does not tempt anyone into wiring it up.

## 3. Do not redesign the URL contract

A priced deal in the real system is **encoded in the URL**. Every quote the
sales team has ever shared is a link of that shape, and those links are sitting
in customers' inboxes right now.

Two rules follow:

- The part **after `#`** selects the section and tab (`#/pricing/price`).
- The part **after `?`** carries the deal (vertical, volume, ticket, config
  version, and so on).

You may propose adding a parameter. Do not propose removing one, renaming one,
or moving the quote into the hash. That breaks links already in circulation, and
the fix is not on our side — it is in inboxes we cannot reach.

If a redesign genuinely needs a different URL shape, flag it as an open question
in your handoff rather than building it.

## 4. Do not invent business rules

The pricing math in `02-pricing-engine/` is not a suggestion — it reproduces
real rate schedules from Elavon and QorPay and a PRD written by Jodi Durst.

You may **propose** a change. Emergent may **not** improvise one. If you see the
agent inventing a rate, a fee, a threshold, or a rounding rule that is not in the
docs, stop it and re-paste the rules.

The tell to watch for: a number appearing on screen that is not in
`03-config-schema-and-defaults.md` and not something you typed.

## 5. Keep the two pricing screens separate

**Price a deal** is every rep's screen. **Configure** is the locked cost engine.

The boundary is the whole point of the design — Stacey Wiles's requirement was
that only a couple of people can touch the cost side. Do not merge the two
screens, do not surface Configure fields inside Price a deal, and do not add a
shortcut that lets a rep edit a rate inline.

Showing a rep *what* the configured rate is: fine. Letting them *change* it:
not fine.

## 6. Do not change these without asking

| Thing | Why it is fixed |
|---|---|
| The five section names (Home, Revenue, Marketing, Leadership, Pricing) | People navigate by muscle memory; renaming costs more than it gains |
| "The URL is the quote" | Links already circulating |
| The dark-mode storage key | Renaming it silently resets everyone to light mode |
| The golden pricing examples | They are the regression test; if they change, the engine changed |
| Cost/margin visibility rules | A rep seeing our margin on a live call is a real commercial problem |

Everything else — layout, ordering, wording, colours within the palette, which
KPI leads, what the empty states say, how many columns a table has — is yours to
change. That is most of the surface area, and it is where the value is.

## 7. If in doubt

Ask. A two-minute question to Pawel or Jodi beats a week spent prototyping
something that cannot ship.
