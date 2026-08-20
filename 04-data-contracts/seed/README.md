# Seed fixtures

Fake data for the prototype, shaped exactly like the real API responses. Load
all of it into MongoDB on startup and serve it from the FastAPI endpoints.

**Every company, contact and person name here is invented.** Owner addresses use
`@chainit.com` only because that domain is the identity join key in the real
system. External domains use the reserved `.example` TLD, so nothing can
accidentally resolve to a real site.

Generated from the source research (held outside this repository, ask Pawel)
by a extraction script. Edit these files directly; there is nothing to re-run here.

---

## The files

| File | Size | Shape | Serves |
|---|---|---|---|
| `owners.json` | 701 B | array of 6 | The owner list; the join key between a signed-in user and their deals |
| `whoami.json` | 379 B | object with 3 variants | `GET /api/whoami` — one entry each for `rep`, `manager`, `unmatched` |
| `deals.json` | 27 KB | object | `GET /api/snapshot?view=deals` — the main payload |
| `snapshot.json` | 4.9 KB | object | `GET /api/snapshot` — the default body, with sync state |
| `home-rep.json` | 2.7 KB | object | `?view=home` as a rep, scoped to their own deals |
| `home-manager.json` | 4.0 KB | object | `?view=home` as a manager, team-wide |
| `home-unmatched.json` | 1.3 KB | object | `?view=home` for a signed-in user with no matching owner record |
| `datafix-companies.json` | 4.3 KB | object | `GET /api/leadership/datafix?object=companies&scope=all` |
| `leadership-pipeline.json` | 16 KB | object | `GET /api/leadership/pipeline` |
| `leadership-meetings.json` | 2.7 KB | array of 5 | `GET /api/leadership/meetings` |
| `leadership-contracts.json` | 2.5 KB | array of 5 | `GET /api/leadership/contracts` |
| `marketing.json` | 9.4 KB | object | `GET /api/snapshot?view=marketing` |
| `onboarding.json` | 1.7 KB | object | `GET /api/snapshot?view=onboarding` |
| `pricing-config.json` | 7.0 KB | object | `GET /api/pricing/config`, with one saved revision applied |
| `pricing-config-history.json` | 180 B | object | `GET /api/pricing/config/history` |
| `pricing-deal-context.json` | 1.1 KB | object | `GET /api/pricing/hubspot/deal/:id` |

### One thing that looks like a contradiction and is not

`pricing-config.json` reports a margin floor of **40 basis points**, while
`02-pricing-engine/03-config-schema-and-defaults.md` says the default is **35**.

Both are right. The fixture carries **one saved override revision** on top of the
bundled defaults, and that revision raises the floor to 40. You can see the
mechanic in the file itself:

```
config.version           "2026-08-04·r1"     bundled version, then revision 1
config.marginFloorBps    40                  the effective value
overrides.marginFloorBps 40                  what revision 1 changed
```

That is deliberate. A fixture with no overrides would not exercise the revision
system at all, and the revision system is the whole reason the Configure tab can
safely be given to a small group. Keep it.

Everything else in the fixture matches the shipped defaults, including
`revShare: 1` on all three processor paths.

---

## What the data contains

**40 deals**, split across the two pipelines that never merge:

| Pipeline | Id | Deals |
|---|---|---|
| Sales Pipeline | `default` | 28 |
| Affiliate Pipeline | `638415376` | 12 |

**11 stages**, with a realistic falling distribution through the funnel:

```
Sales Pipeline    appointmentscheduled 6 · qualifiedtobuy 5 ·
                  presentationscheduled 4 · decisionmakerboughtin 4 ·
                  contractsent 3 · closedwon 4 · closedlost 2

Affiliate         aff_app 5 · aff_review 3 · aff_active 3 · aff_declined 1
```

**6 owners**, with deals spread 5 to 8 each, so the leaderboard has a real
ranking rather than a flat one.

**Outcomes:** 7 won, 3 lost, 30 open. Open pipeline value totals **$1,431,950**.

## The deliberate holes

Seven fields are null on purpose. Without them the Data to Fix screen, the
missing-close-date warnings and the "amount unknown" path all render empty and
you cannot tell whether they work.

| Deal | Missing |
|---|---|
| `d-1003` Larkspur Outdoors | close date |
| `d-1005` Marrow Bay Cannabis | close date |
| `d-1011` Halyard Marine Rentals | close date |
| `d-1018` Oakmoss Veterinary | **amount** and close date |
| `d-2002` Vector Nine Media | close date |
| `d-2007` Northgate Merchant Services | close date |

**Do not "fix" these.** If the prototype shows a clean, complete dataset, half
the product's reason for existing becomes invisible.

`datafix-companies.json` carries the same idea at the company level: a mix of
complete and incomplete records, so the completeness scoring has something to
score.

## The fixture clock

Everything is dated against a fixed instant:

```
now = 1787234400000  =  2026-08-20T14:00:00Z  (a Thursday)
start of week (Mon 00:00 UTC) = 1786924800000
```

Every `daysInStage` value is consistent with its deal's `lastmodified`. If you
change one, change the other, or the aging views will contradict the timestamps.

Consider pinning "now" to that constant in the prototype rather than using the
real clock. Otherwise every deal ages a day every day and the fixtures slowly
stop matching their own aging buckets.

## Role wiring

To make the role switcher change what is visible, wire it to these owners:

| Prototype role | Owner |
|---|---|
| Manager | Dana Whitlock, `dana.whitlock@chainit.com` |
| Marketer | Ellen Boyd, `ellen.boyd@chainit.com` |
| Rep | Marcus Ilo, `marcus.ilo@chainit.com` |
| Unmatched | Any address not in `owners.json` |

Everyone else falls through to `rep`. The `unmatched` case is worth keeping —
it is a real state in production, and it has its own screen.

## Internal consistency

These hold across the fixtures, and they should keep holding if you edit
anything:

- Per-stage deal counts sum to 40.
- Per-stage open amounts sum to the per-pipeline open total.
- The owner leaderboard sums to the same grand total.
- The Home digest counts derive from the same 40 deals.

The quickest way to check after an edit:

```bash
python3 - <<'PY'
import json, collections
d = json.load(open('deals.json'))['deals']
print('deals:', len(d))
print('by pipeline:', dict(collections.Counter(r['pipeline'] for r in d)))
print('open total:', sum(r['amount'] or 0 for r in d if not r['isClosed']))
PY
```

If the totals on screen disagree with that, the bug is in the prototype's
aggregation, not in the data.

---

## Two things nobody could determine from the source

Both are worth an engineer settling before the prototype goes far, because both
could change what you build.

### 1. The real stage names are unknown

The pipeline stages here — Discovery, Qualified, Demo Scheduled, and the rest —
are **invented**. The real ones are not in the codebase at all: they are synced
live from HubSpot into a database table and never committed, so every stage id
that appears anywhere in the repository is a test fixture.

The prototype will therefore show plausible stage names that may not match what
the sales team actually sees. That is fine for layout work and wrong for anything
where the wording matters.

An engineer can settle it with one query against the live database:

```
SELECT pipeline, pipeline_label, stage, stage_label, display_order, is_closed, is_won
FROM hs_pipelines
ORDER BY pipeline, display_order
```

Ask for that output and swap the real names into `deals.json`.

### 2. Everyone in production may currently be a "rep"

The manager and marketer roles are driven by two optional settings. Nothing in
the repository shows whether either is actually set on the live worker.

If they are not set, **every user resolves to `rep`**, which would mean the
team-wide manager digest and the marketer views have never been seen by anyone in
production, and nobody would have noticed — a rep view of your own data looks
perfectly reasonable.

Worth checking before designing anything that depends on the manager view. An
engineer can list the worker's secrets to find out.

Build the prototype with all five roles regardless. If it turns out production is
rep-only, that is a bug to fix, not a feature to remove.
