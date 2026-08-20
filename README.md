# emergent-build

**Context bundle for rebuilding the ChainIT Sales Cockpit and its pricing engine
as a prototype on [app.emergent.sh](https://app.emergent.sh).**

There is no application code in this repository. It is documentation, design
tokens, fake seed data and screenshots: everything an AI app builder needs to
reproduce an existing internal tool faithfully, and everything a non-technical
product owner needs to work in that builder without breaking the rules that
matter.

| | |
|---|---|
| **The real app** | `sales.chainithub.com`, built from `ChainIT-Inc/cat-hub` at `apps/sales` |
| **This repo** | The spec for a throwaway prototype of it |
| **Why it exists** | So product changes can be tried in a sandbox before an engineer implements them for real |

Two audiences, written for both at once:

- **A person.** The product owner who prototypes UI and business-logic changes in
  Emergent, then hands screenshots and flows back to engineering.
- **An AI agent.** Emergent's builder, which reads these files as its
  specification.

## How to use it with Emergent

1. Attach this repository to a new Emergent project.
2. Upload `screenshots/light/` and `screenshots/dark/` into the chat. All 42.
3. Paste `00-KICKOFF-PROMPT.md` as the first message, whole and unedited.
4. Work through `05-emergent-setup/02-prompt-library.md` in order.

`05-emergent-setup/01-how-to-use-this-bundle.md` is the full walkthrough.

## What is deliberately not here

**The raw research.** Building this bundle produced roughly 8,700 lines of
engineer-facing extraction with `file:line` citations back into `cat-hub`. It is
excluded from this repository for one reason: it contains real ChainIT staff
email addresses, lifted from the authorisation lists in the source, and this
repository is attached to a third-party service.

Everything here is scrubbed. Every email address in the bundle belongs to one of
six fictional owners defined in `04-data-contracts/seed/owners.json`.

If you need the raw research, it lives outside this repository. Ask Pawel.

**Application code.** Nothing here deploys. The prototype Emergent generates
targets React, FastAPI and MongoDB, while the real system runs React on
Cloudflare Workers with D1. That difference does not matter for prototyping and
should not be fixed.

---

## Start here

| If you are | Read, in this order |
|---|---|
| **The new product owner** | `01-product/01-what-this-is.md` → `05-emergent-setup/01-how-to-use-this-bundle.md` → `00-KICKOFF-PROMPT.md` |
| **An engineer picking this up** | `01-product/02-sales-cockpit-spec.md` → `04-data-contracts/` → `01-product/05-known-defects.md` |
| **Emergent's builder agent** | Everything, in folder order |

The first build takes about an afternoon. The pricing screens take longer than
the cockpit screens, and they should — that is where the money is.

---

## What is in here

```
emergent-build/
├── README.md                        you are here
├── 00-KICKOFF-PROMPT.md             the exact text to paste into Emergent first
│
├── 01-product/
│   ├── 01-what-this-is.md           the product, its users, and why it exists
│   ├── 02-sales-cockpit-spec.md     every screen, panel, table and state
│   ├── 03-component-catalogue.md    the shared UI pieces and their props
│   ├── 04-user-flows.md             the flows an operator actually performs
│   └── 05-known-defects.md          17 bugs found in the live app — fix, don't copy
│
├── 02-pricing-engine/
│   ├── 01-pricing-primer-plain-english.md   payments pricing for a non-expert
│   ├── 02-pricing-rules-and-math.md          the algorithm, step by step
│   ├── 03-config-schema-and-defaults.md      every rate, unit and default value
│   └── 04-worked-examples-golden.md          the numbers the rebuild must match
│
├── 03-design-system/
│   ├── 01-design-brief.md           how it must look — hand this to the agent
│   ├── 02-tokens.css                the exact colours, fonts and radii
│   └── 03-component-styling.md      which tokens go where, per component
│
├── 04-data-contracts/
│   ├── 01-api-reference.md          every endpoint, request and response
│   ├── 02-data-model.md             the entities and their relationships
│   └── seed/                        16 fake fixtures + a README explaining them
│
├── 05-emergent-setup/
│   ├── 01-how-to-use-this-bundle.md how to work in Emergent, day to day
│   ├── 02-prompt-library.md         copy-paste prompts, one per screen
│   ├── 03-handoff-back-to-engineering.md  what to send back, and how
│   └── 04-guardrails-do-not-change.md     the things that must not drift
│
├── screenshots/
│   ├── README.md                    manifest, conditions, redaction, findings
│   ├── light/                       21 screens
│   └── dark/                        the same 21 screens
│
└── screenshots/                     42 captures of the live app, light and dark
```

The raw research that backs every claim here is **not in this repository** — see
*What is deliberately not here* above. Where a document says "fully cited source",
that citation points into it. Ask Pawel if you need it.

---

## The three rules

If this package is reduced to three sentences, these are them.

1. **Prototype freely, but never with real data.** No real merchant, no real
   volume, no real rate, no real customer name goes into Emergent. The seed
   fixtures exist so you never need to.

2. **A business-rule change is not handed over without its numbers.** If you
   move a pricing default, show its effect on the worked examples — before and
   after. A rule change without numbers cannot be implemented safely.

3. **Small and frequent beats big and rare.** One screen per handoff gets built
   in a day. Nine screens at once sit in a queue.

---

## The screenshots

**Done — 42 of them, captured 2026-08-20 from the live app.**

All 21 routes in light and dark, driven through a real authenticated browser
session. Person, company and opportunity names are blurred before capture, since
this bundle goes to a third-party service.

They are the highest-value input here: Emergent matches a reference image far
better than it matches a written description. Upload them early.

`screenshots/README.md` has the manifest, the capture conditions, the redaction
policy, and what the live pass confirmed or corrected. The headline corrections:

- **Production has three pipelines, not two**, and one is named STAGING.
- **The switcher defaults to the smallest pipeline** ($3.4k) rather than the
  main one ($14.9M).
- **Five further defects** confirmed visually, now in
  `01-product/05-known-defects.md` as items 18 to 22.

One question the pass could not settle: whether toasts render light against a
dark page. Triggering one needs a write action, and the capture was read-only.

## Provenance

Extracted from `ChainIT-Inc/ChainIT-Hub` at `origin/main`, 2026-08-20, from:

- `apps/sales/` — the Sales Cockpit SPA and its Cloudflare Worker
- `apps/sales/src/pricing/` — the pricing engine, moved here from
  `apps/pay-pricing` in August 2026 (that app is now only a redirect)
- `.planning/chainit-pay-pricing-engine/DESIGN-SPEC.md` — the approved engine
  design, itself derived from Jodi Durst's pricing PRD
- Confluence: *Workflow Execution Process (ChainIT Pay money flow)*

**Jodi Durst's pricing document wins on any conflict about the money.** Where
this bundle and the live code disagree, the live code wins about behaviour and
Jodi wins about rates.
