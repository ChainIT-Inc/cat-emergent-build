# Data model

Every entity the Sales Cockpit holds, every field on it, and every closed set of
values a field can take.

*Written so it can become a MongoDB schema. Field names are given exactly as the
API returns them, because the front end reads those names literally.*

Pair this with `01-api-reference.md`, which shows the same data as response
shapes, and with `seed/`, which holds the fixtures.

---

## Conventions

| Thing | Rule |
|---|---|
| Money | USD, plain dollars, a floating-point number. Never cents. Never a string. |
| Timestamps | Epoch **milliseconds**, an integer. |
| Timestamp exceptions | `config_revisions.created_at` is an ISO 8601 string. `meeting_date` and `due_date` are `YYYY-MM-DD` strings. Growth-series `day` is a `YYYY-MM-DD` string. |
| Booleans | The storage layer holds `0` and `1`. The API returns real booleans. Use real booleans in MongoDB. |
| Ids | Strings, always. Even the numeric-looking ones like `"101"` and `"638415376"`. Never parse them into integers. |
| Ordering | Where a `displayOrder` exists it is the sort key. Array position is not meaningful. |
| Empty vs missing | CRM-sourced text fields are `null` when unset. Operator-authored leadership fields are `""` when unset, never `null`. That difference is deliberate and the UI relies on it. |

### The fixture clock

Every fixture is dated against a fixed instant:

```
now                            = 1787234400000  =  2026-08-20T14:00:00Z (a Thursday)
start of week (Mon 00:00 UTC)  = 1786924800000
```

Pin "now" to that constant in the prototype rather than reading the real clock.
Otherwise every deal ages a day per day and the fixtures stop matching their own
aging buckets.

---

## Which collections you actually need

Only about a third of what follows needs to be a MongoDB collection. The rest is
either computed when a request comes in, or is a stored blob you serve back
unchanged.

**Store as real collections** — these are read, written, or filtered:

`owners` · `deals` · `pipelines` (one document per pipeline with an embedded
ordered `stages[]`) · `companies` · `contacts` · `deal_annotations` ·
`lead_meetings` · `lead_contracts` · `config_revisions` · `sync_runs` ·
`object_counts` · `scope_status` · `onboarding_counts` · `deal_handoff`

**Store as a single stored document each**, served back with no computation.
These are rollups the real system precomputes on a schedule, and re-deriving
them in a prototype buys nothing:

`marketing_view` (the whole `seed/marketing.json` body) ·
`onboarding_view` (the whole `seed/onboarding.json` body)

**Derive at read time from `deals`, `companies`, `contacts` and `owners`.** Do
not store these; if you do, they will drift from the deals you are showing:

- the per-stage rollup and the owner leaderboard in `GET /api/snapshot`
- the whole Home digest
- the Pipeline Health rows
- the Data to Fix rows, and all four of its counts
- every `missing[]` array and every `missingByLabel` count

**Do not build at all:** the daily per-deal snapshot table, and the tickets
table. Both are written by the real sync and read by nothing.

---

## Relationships

```
Deal            ─ many-to-one  → Owner            (deal.ownerId → owner.id; NULL means "Unassigned")
Deal            ─ many-to-one  → Pipeline         (deal.pipeline → pipeline.pipeline)
Deal            ─ many-to-one  → PipelineStage    (deal.dealstage → stage.stage, scoped by pipeline)
Deal            ─ zero-or-one  → DealAnnotation   (one annotation per deal, keyed by deal id)
Deal            ─ zero-or-one  → DealHandoff      (closed-won deals only)
DealHandoff     ─ many-to-one  → Company          (company name is copied onto the handoff row)
Pipeline        ─ one-to-many  → PipelineStage    (unique on pipeline + stage)
Company         ─ many-to-one  → Owner            (nullable)
Contact         ─ many-to-one  → Owner            (nullable)
Owner           ─ zero-or-one  → signed-in user   (owner.email matched against the verified email, lowercased)
SyncRun         ─ many-to-one  → sync lane        (fast | heavy | marketing)
SyncCursor      ─ one per (lane, objectType)
OnboardingObject─ many-to-one  → OnboardingType
Form            ─ zero-or-many → FormPerformance      (unique on window + form id)
Campaign        ─ zero-or-many → CampaignPerformance  (unique on window + campaign id)
ConfigRevision  ─ append-only log; the highest revision wins
```

**Three relationships are deliberately not modelled anywhere: Deal to Company,
Deal to Contact, and Company to Contact.** The only association ever traversed
is Deal to Company, and only in two places: the live deal-context read behind a
quote link, and the handoff-leak sync. Do not add the others to the prototype
just because MongoDB makes it easy. Nothing reads them.

---

# Entities

## 1. Owner

A salesperson. Also the join between a signed-in user and the deals they own.

**Collection:** `owners`. **Fixture:** `seed/owners.json`, 6 rows.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | Owner id, a numeric-looking string. Primary key. |
| `name` | string | — | yes | Display name. Falls back to `id` when absent, never blank. |
| `email` | string | — | yes | **The join key to the signed-in user.** Matched lowercased on both sides. |
| `team` | string | — | yes | Team name. Present in the fixtures, never surfaced by any endpoint today. |

A quirk worth knowing if you ever look at raw CRM output: the upstream owner
payload puts the owner **id** in a field called `name` and the person's name in
a field called `label`. The normalised shape above is the one the API returns.

## 2. Deal

The central entity. Every Revenue tab, the Home digest and Pipeline Health all
read from one deal list.

**Collection:** `deals`. **Fixture:** `seed/deals.json`, 40 rows.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | Deal id. Primary key. |
| `pipeline` | string | — | yes | Pipeline **id**, not its label. |
| `dealstage` | string | — | yes | Stage **id**, not its label. |
| `amount` | number | USD dollars | **yes, on purpose** | Deal value. One fixture deal has none, to exercise the "amount unknown" path. |
| `dealtype` | string | — | yes | CRM deal type. An open set, pass-through. |
| `ownerId` | string | — | **yes, on purpose** | Null means Unassigned, which is a real and common state. |
| `createdate` | number | epoch ms | yes | When the deal was created. |
| `lastmodified` | number | epoch ms | yes | Last modification. Drives `daysInStage`. |
| `isClosed` | boolean | — | no | From the stage's flags, not from the deal. |
| `isWon` | boolean | — | no | Always `won AND closed`, never won alone. Forced at build time so the six Revenue tabs cannot disagree. |
| `closedWonReason` | string | — | yes | Free text. |
| `closedLostReason` | string | — | yes | Free text. |
| `predictiveScore` | number | score | yes | Pass-through. No closed value set exists. |
| `latestSource` | string | — | yes | Where the deal came from. An open set, pass-through. |
| `daysInStage` | number | days | yes | **Days since last modification, not since stage entry.** An approximation, recomputed at each fast sync. Null is a real value and is not counted as stuck. |
| `dealName` | string | — | yes | Shown to users as "Opportunity". Falls back to the deal id. |
| `nextStep` | string | — | **yes, on purpose** | What happens next. A required field for data-quality purposes. |
| `closeDate` | number | epoch ms | **yes, on purpose** | Expected close. Six fixture deals have none. |
| `description` | string | — | **yes, on purpose** | A required field for data-quality purposes. |

Two more columns exist in the real storage and are **never returned by the API**:
`affiliate_type` (string) and `raw_json` (the full upstream row). Do not port
either.

**Unverified:** the real production stage ids and labels are unknown. They
sync live from the CRM and are never committed to the repository. **Every stage
id in the fixtures and in this document is invented or taken from a test
fixture.** Treat them as shape, not as truth, and do not hard-code them into
prototype logic beyond what the fixtures need.

## 3. Pipeline

**Collection:** `pipelines`, one document per pipeline with `stages[]` embedded.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `pipeline` | string | — | no | Pipeline id. Primary key. |
| `pipelineLabel` | string | — | no | Display label. Falls back to the id. |
| `stages` | array | — | no | Ordered stage list, sorted by `displayOrder`. |

**The two pipelines never merge.** This is a structural invariant, not a styling
preference. Every rollup groups by pipeline, and every view iterates the
pipeline list rather than summing across it. Mixing a direct deal and an
affiliate deal in one total produces a meaningless number.

## 4. PipelineStage

Embedded inside a pipeline document. Unique on pipeline plus stage.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `stage` | string | — | no | Stage id. |
| `stageLabel` | string | — | no | Display label. Falls back to the stage id. |
| `displayOrder` | number | — | no | The sort key. Array position is not the order. |
| `isClosed` | boolean | — | no | Deals in this stage are closed. |
| `isWon` | boolean | — | no | Deals in this stage are won. |

A deal whose stage is absent from this list is still shown; its stage label
degrades to the raw stage id. Reproduce that rather than dropping the deal.

## 5. Ticket

Synced by the fast lane into its own table and read by nothing. Four properties
are pulled. **Do not build this in the prototype.** Listed here only so nobody
concludes it was missed.

## 6. Company

**Collection:** `companies`. **Fixture:** `seed/datafix-companies.json` holds 15
companies in the Data to Fix response shape.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | Company id. Primary key. |
| `name` | string | — | yes | Company name. |
| `domain` | string | — | **yes, on purpose** | Web domain. A required field for data-quality purposes. |
| `owner_id` | string | — | **yes, on purpose** | Owning salesperson. A required field for data-quality purposes. |
| `country` | string | — | yes | Country. |
| `createdate_ms` | number | epoch ms | yes | Created. |
| `lastmodified_ms` | number | epoch ms | yes | Last modified. Part of the Data to Fix worklist ordering. |
| `regulated` | boolean | — | yes | Regulated industry flag. Sparsely populated in production, so counts on it read close to zero today. That is the honest current state. |
| `intent_30d` | number | count | yes | Intent signal over 30 days. Also sparse. |
| `annualrevenue` | number | USD dollars | yes | Annual revenue. |

Display name is `name`, else `domain`, else `id`.

## 7. Contact

**Collection:** `contacts`. No fixture file; build one in the Data to Fix row
shape if you need the contacts tab.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | Contact id. Primary key. |
| `firstname` | string | — | yes | |
| `lastname` | string | — | yes | |
| `email` | string | — | yes | |
| `lifecyclestage` | string | — | yes | Lifecycle stage. Open set, pass-through. |
| `analytics_source` | string | — | yes | Acquisition source. Open set, pass-through. |
| `owner_id` | string | — | **yes, on purpose** | The only required field for contacts. |
| `country` | string | — | yes | |
| `createdate_ms` | number | epoch ms | yes | |
| `lastmodified_ms` | number | epoch ms | yes | |
| `annualrevenue` | number | USD dollars | yes | |

Display name is `"first last"` trimmed, else `email`, else `id`.

A live-data asymmetry worth knowing but not worth reproducing: upstream,
contacts carry one modification field and companies carry a differently named
one, and the created date arrives as an ISO string rather than epoch
milliseconds. The normalisation above already resolves it.

## 8. DealAnnotation

The operator's overlay on a CRM deal. These notes live only in our database; the
CRM never sees them.

**Collection:** `deal_annotations`, keyed by deal id.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `deal_id` | string | — | no | Primary key. Also the link to the deal. |
| `cta` | string | — | no | What we are asking for. `""` when unset. |
| `risk_blocker` | string | — | no | What is in the way. `""` when unset. |
| `updated_at` | number | epoch ms | no | Last edit. |
| `updated_by` | string | — | no | Email of the editor, taken from the session and never from the request body. |

There is no 404 on writing an annotation. Annotating a deal id that has no
annotation row simply creates one.

## 9. DealHandoff

One row per closed-won deal, recording whether that customer actually reached
onboarding. A won deal linked to none of the four progression objects is a
**leak**.

**Collection:** `deal_handoff`, keyed by deal id. **Fixture:** inside
`seed/onboarding.json` under `handoff`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `dealId` | string | — | no | Primary key. |
| `amount` | number | USD dollars | yes | Deal value. |
| `ownerId` | string | — | yes | |
| `ownerName` | string | — | yes | Denormalised for display. |
| `dealstage` | string | — | yes | The closed-won stage id. |
| `closedMs` | number | epoch ms | yes | When it closed. |
| `companyId` | string | — | yes | |
| `companyName` | string | — | yes | Denormalised for display. |
| `intakeCount` | number | count | no | Linked intake records. |
| `onboardingCount` | number | count | no | Linked onboarding records. |
| `merchantCount` | number | count | no | Linked merchants. |
| `submerchantCount` | number | count | no | Linked sub-merchants. |
| `linkCount` | number | count | no | Total across the four. Zero means a leak. |
| `is_leak` | boolean | — | no | True when all four counts are zero. |
| `checked_ms` | number | epoch ms | no | When the check ran. |

Only the first four onboarding object types count as handoff milestones. Staff
and External Business Parties are deliberately **not** milestones.

## 10. LeadMeeting

A customer meeting an operator typed by hand. Not CRM data.

**Collection:** `lead_meetings`. **Fixture:** `seed/leadership-meetings.json`, 5
rows.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | A UUID generated on create. |
| `customer` | string | — | no | Who the meeting was with. **Required on create.** `""` otherwise. |
| `attendees` | string | — | no | Free text. `""` when unset. |
| `internal_lead` | string | — | no | Who ran it. `""` when unset. |
| `demo` | string | — | no | `"Yes"` or `"No"`. Stored verbatim as the display string. |
| `cta` | string | — | no | The ask. `""` when unset. |
| `objective` | string | — | no | What we wanted. `""` when unset. |
| `a_win_is` | string | — | no | The success definition. `""` when unset. |
| `meeting_date` | string | `YYYY-MM-DD` | no | A date string, **not** a timestamp. `""` when unset. |
| `created_at` | number | epoch ms | no | |
| `updated_at` | number | epoch ms | no | Sort key: the list is newest edit first. |
| `created_by` | string | — | no | From the session. |
| `updated_by` | string | — | no | From the session, **never from the request body.** |

**Every text field is `""` when unset, never `null`.** Each value is trimmed and
cut to 4000 characters on write. Unknown keys in the body are dropped silently.

## 11. LeadContract

Same discipline as a meeting, different fields.

**Collection:** `lead_contracts`. **Fixture:** `seed/leadership-contracts.json`,
5 rows.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | A UUID generated on create. |
| `agreement` | string | — | no | What the contract is. **Required on create.** |
| `business_owner` | string | — | no | Who owns it internally. |
| `status` | string | — | no | One of four fixed values. |
| `legal_risk` | string | — | no | Free text. |
| `compliance_risk` | string | — | no | Free text. |
| `decision_needed` | string | — | no | One of three fixed values. |
| `due_date` | string | `YYYY-MM-DD` | no | A date string, not a timestamp. |
| `created_at` | number | epoch ms | no | |
| `updated_at` | number | epoch ms | no | Sort key. |
| `created_by` | string | — | no | From the session. |
| `updated_by` | string | — | no | From the session, never from the body. |

## 12. DealsByPipelineStageRow — derived

The per-stage rollup in `GET /api/snapshot`. Recompute it; do not store it.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `pipeline` | string | — | no | Pipeline id. |
| `stage` | string | — | no | Stage id. |
| `dealCount` | number | count | no | Open **and** closed deals in this stage. |
| `openAmount` | number | USD dollars | no | Sums `amount` on open deals only. Closed deals contribute 0. |

Sorted by pipeline, then stage.

## 13. OwnerLeaderboardRow — derived

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `ownerId` | string | — | no | |
| `openDeals` | number | count | no | |
| `openAmount` | number | USD dollars | no | |
| `wonDeals` | number | count | no | |
| `wonAmount` | number | USD dollars | no | |
| `winRate` | number | ratio 0–1 | **yes, on purpose** | Won divided by closed. **Null when the owner has no closed deals at all.** Zero means "closed some, won none", which reads very differently. |

Sorted by `openAmount` descending. The leaderboard total must equal the grand
total from the per-stage rollup.

## 14. HomeDigest — derived

Role-scoped. Not a collection. **Fixtures:** `seed/home-rep.json`,
`seed/home-manager.json`, `seed/home-unmatched.json`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `role` | string | — | no | The caller's view role. |
| `ownerResolved` | boolean | — | no | False when the email matched no owner. |
| `fallback` | string | — | yes | `null`, or `"fresh-leads"` for a rep with no owner record. |
| `myOpenDeals.count` | number | count | no | Over **all** matching open deals, not just the listed ones. |
| `myOpenDeals.amount` | number | USD dollars | no | Sum over all matching open deals. |
| `myOpenDeals.deals` | array | — | no | Stuck-first, **capped at 12**. |
| `agingDeals.count` | number | count | no | Open and `daysInStage > 14`. |
| `agingDeals.amount` | number | USD dollars | no | Sum over the same set, ignoring nulls. |
| `tasksDueToday.count` | number | count | no | Always 0 today. |
| `tasksDueToday.available` | boolean | — | no | **Always false.** No task data is synced. |
| `newMqlSqlSince.count` | number | count | no | Deals created in the last 7 days. |
| `weekWins.count` | number | count | no | Won since Monday 00:00 UTC. |
| `weekWins.amount` | number | USD dollars | no | |
| `hotLeads.count` | number | count | no | |
| `hotLeads.leads` | array | — | no | Max 25. |
| `hotLeads.degraded` | boolean | — | no | True when the live lead lookup failed or returned nothing. |

**HomeDigestDeal:** `id`, `pipeline`, `dealstage`, `amount` (nullable),
`ownerId` (nullable), `daysInStage` (nullable), `lastModifiedMs`.

**HomeDigestLead:** `id`, `name`, `email`, `createdMs`.

Constants: 12-deal cap, 14-day aging threshold, 7-day lookback, 25 hot leads,
week starts Monday 00:00 UTC.

**The counting rule that breaks naive MongoDB aggregation:** a sum ignores
nulls, a count does not. The fixture deal with a null amount is counted in
`agingDeals.count` and adds nothing to `agingDeals.amount`. Sum
`{ $ifNull: ["$amount", 0] }` while counting every matching document, or in
Python sum only the non-null amounts alongside `len(rows)`. Adding a null
straight into a running total gives `NaN`, and the front end has an explicit
no-NaN rule.

## 15. PipelineHealthRow — derived

Open deals joined to their annotation. **Fixture:**
`seed/leadership-pipeline.json`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `dealId` | string | — | no | |
| `opportunity` | string | — | no | The deal name, falling back to the deal id. |
| `pipeline` | string | — | no | The pipeline **id**. |
| `stage` | string | — | no | The resolved stage **label**, falling back to the stage id. |
| `ownerName` | string | — | no | `"Unassigned"` when there is no owner. |
| `ownerId` | string | — | yes | |
| `amount` | number | USD dollars | yes | |
| `nextStep` | string | — | no | Trimmed. `""` rather than null. |
| `cta` | string | — | no | From the annotation. `""` when unset. |
| `riskBlocker` | string | — | no | From the annotation. `""` when unset. |
| `needsNextStep` | boolean | — | no | Exactly `nextStep === ""`. |
| `missing` | array | — | no | MissingField entries for this deal. |
| `hubspotUrl` | string | — | no | Deep link to the CRM record. |

The id-versus-label asymmetry on `pipeline` and `stage` is intentional: the
switcher needs an id, the column is read by a human.

## 16. DataFixRow — derived

One row per incomplete company or contact. **Fixture:**
`seed/datafix-companies.json`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | |
| `name` | string | — | no | Display name, already resolved through its fallback chain. |
| `owner` | string | — | no | Owner name, or `"Unassigned"`. |
| `missing` | array | — | no | MissingField entries. Never empty; a complete record is not in this list. |
| `hubspotUrl` | string | — | no | Deep link to the CRM record. |

Capped at 200 rows. There is no page two. The response carries four separate
counts alongside the rows — `shown`, `scoped`, `synced`, `reportedTotal` — and
the screen shows all four. Do not collapse them into one number.

Default ordering is a worklist: rows with no usable name last, then most-missing
first, then most recently modified.

## 17. RequiredField and MissingField — the completeness model

A small, pure model shared by Pipeline Health and Data to Fix, so a chip and a
count can never disagree.

**RequiredField:** `{ key, label, type }` where `type` is `"text"` or
`"number"`.

| Object | Required fields |
|---|---|
| deal | `nextStep` → Next Step (text) · `closeDate` → Close Date (number) · `amount` → Amount (number) · `description` → Description (text) |
| company | `owner_id` → Owner (text) · `domain` → Domain (text) |
| contact | `owner_id` → Owner (text) |

Deal keys use the API's camelCase; company and contact keys use the raw storage
column names. That split is deliberate — do not "tidy" it, because the front end
matches on these exact strings.

**MissingField** is the same entry minus the type: `{ key, label }`.

**The missing rule, locked with the user on 2026-07-08:**

| Condition | Missing? |
|---|---|
| Value is null or undefined | Yes |
| `type: "number"` and the value is `0` | **Yes.** A $0 amount and an epoch-0 date are missing, not present. |
| `type: "text"` and the value is blank after trimming | Yes |
| Anything else | No |

## 18. OnboardingType

A code constant, not a collection: 6 entries keyed by a stable upstream name,
because the numeric object type id changes if an object is recreated. The live
numeric id is discovered at sync time. Members are listed in the enum section.

## 19. OnboardingObject

One row per onboarding record. **Not needed in the prototype** — only the
per-type counts are read. Fields: `object_type_id`, `id`, `status`,
`created_ms`, `lastmodified_ms`, `raw_json`.

## 20. OnboardingCount

**Collection:** `onboarding_counts`, keyed by object type id. **Fixture:**
inside `seed/onboarding.json` under `steps`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `objectTypeId` | string | — | no | Live numeric object type id, such as `"2-60233737"`. |
| `label` | string | — | no | Display label. |
| `total` | number | count | no | How many records exist. |
| `truncated` | boolean | — | no | **True means `total` is a floor, not a count** — the crawl was capped or rate-limited. Keep this state; it is a deliberate honesty decision. |
| `latestMs` | number | epoch ms | yes | Most recent record. |
| `displayOrder` | number | — | no | Sort key, 0 through 5. |

## 21. SyncRun

One row per lane execution. Append-only; "last run" is the newest row for that
lane.

**Collection:** `sync_runs`. **Fixture:** inside `seed/snapshot.json` under
`sync.lastRun`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | number | — | no | Auto-incrementing. |
| `lane` | string | — | no | `fast`, `heavy` or `marketing`. |
| `startedMs` | number | epoch ms | yes | |
| `finishedMs` | number | epoch ms | yes | The cooldown anchor. |
| `status` | string | — | yes | A null column is reported as `"unknown"`. |
| `pages` | number | count | yes | Pages fetched. |
| `requests` | number | count | yes | Requests made. |
| `http429` | number | count | no | Rate-limit responses seen. |
| `http403` | number | count | no | Permission-denied responses seen. |
| `rows` | number | count | no | Rows written. |
| `errorText` | string | — | yes | |

**A lane with no row at all is `null` in the API response, and that is the
canonical "never synced" signal.** It is not an error.

## 22. SyncCursor

Where a resumable crawl left off. **Not needed in the prototype**, which does no
crawling. One row per lane and object type, holding the raw upstream `after`
token.

## 23. ObjectCount

The honest "N of M synced" pair.

**Collection:** `object_counts`, keyed by object type.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `objectType` | string | — | no | Only `"contacts"` and `"companies"` are ever written. There is no deals row. |
| `rowsInD1` | number | count | no | How many we hold locally. |
| `hsReportedTotal` | number | count | yes | How many the CRM says exist. |
| `capturedMs` | number | epoch ms | no | When the pair was captured. |

## 24. ScopeStatus

Which CRM permission surfaces we actually have. Feeds the Setup and Data
Readiness screen.

**Collection:** `scope_status`, keyed by surface.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `surface` | string | — | no | One of nine surface keys. |
| `httpStatus` | number | — | no | 200 granted, 403 blocked, 0 unreachable. |
| `granted` | boolean | — | no | True only on a clean 200 with no block marker. |
| `checkedMs` | number | epoch ms | no | |

## 25. DealSnapshotDaily

A per-deal daily append, written on every fast sync and **read by nothing.** It
is a deliberate time-series seed for a feature that does not exist yet. Keyed by
day plus deal id, with `day` as `YYYY-MM-DD`. **Do not build a UI for it and do
not build the collection.**

## 26. Campaign

**Serve from the stored `marketing_view` document.**

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | |
| `name` | string | — | no | |
| `updatedMs` | number | epoch ms | yes | |

## 27. MarketingList

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `listId` | string | — | no | |
| `name` | string | — | no | |
| `processingType` | string | — | yes | An **open set**, pass-through. The fixtures use `DYNAMIC` and `SNAPSHOT`. |
| `size` | number | count | yes | |
| `objectTypeId` | string | — | yes | `"0-1"` contacts, `"0-2"` companies. |

A separate `lists.total` figure comes from a small key-value table; the only key
ever used is `lists_total`. It can be null.

## 28. Form

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | |
| `name` | string | — | no | |
| `archived` | boolean | — | no | |
| `fieldCount` | number | count | yes | |

## 29. MarketingEmail

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `id` | string | — | no | |
| `name` | string | — | no | |
| `state` | string | — | yes | An **open set**, pass-through. **Unverified** which values occur in production; the fixtures use `PUBLISHED`, `SCHEDULED` and `DRAFT`. |
| `publishMs` | number | epoch ms | yes | |

## 30. LeadFunnelStage

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `stage` | string | — | no | One of five fixed lifecycle keys. |
| `count` | number | count | no | |
| `displayOrder` | number | — | no | Sort key. |

## 31. LeadSourceRoi

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `source` | string | — | no | Acquisition source. An open set. |
| `leads` | number | count | no | |
| `contacts` | number | count | no | |
| `opportunities` | number | count | no | |
| `visits` | number | count | no | |

## 32. FormPerformanceTotals

One per time window. `totals` may legitimately be `null` for a window.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `formViews` | number | count | no | |
| `submissions` | number | count | no | |
| `contactSubs` | number | count | no | Submissions that became contacts. |
| `nonContactSubs` | number | count | no | |
| `visibles` | number | count | no | Times the form was visible. |
| `interactions` | number | count | no | |
| `subsPerView` | number | ratio 0–1 | no | A ratio, not a percentage. |
| `ctPerView` | number | ratio 0–1 | no | |
| `rangeStartMs` | number | epoch ms | no | |
| `rangeEndMs` | number | epoch ms | no | |

**Never substitute a zero for an absent window or an absent total.** Render an
em dash. A fabricated 0 reads as a real measurement.

## 33. FormPerformance

Per window and form id.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `formId` | string | — | no | |
| `formViews` | number | count | no | |
| `submissions` | number | count | no | |
| `contactSubs` | number | count | no | |
| `subsPerView` | number | ratio 0–1 | no | |

## 34. CampaignPerformance

Per window and campaign id.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `campaignId` | string | — | no | |
| `sessions` | number | count | no | |
| `newContactsFirst` | number | count | no | First-touch attribution. |
| `newContactsLast` | number | count | no | Last-touch attribution. |
| `influencedContacts` | number | count | no | |
| `revenueAmount` | number | USD dollars | no | |
| `dealAmount` | number | USD dollars | no | |
| `dealsNumber` | number | count | no | |
| `contactsNumber` | number | count | no | |
| `currency` | string | — | no | `"USD"` in every fixture. |

## 35. LifecycleFunnelCount and LeadsBySource

Both use the same two-field shape: `{ stage: string, count: number }`. Lifecycle
counts use lifecycle stage keys; leads-by-source reuses the `stage` field name
to hold a **source** key. That naming reuse is in the real payload; keep it.

## 36. GrowthPoint

Two series, contacts and companies, same shape.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `day` | string | `YYYY-MM-DD` | no | A date string, not a timestamp. |
| `netNew` | number | count | no | Net new records that day. |

## 37. DataQualitySnapshot

The audience-level data-quality finding. Four fixed metrics.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `metric` | string | — | no | One of four fixed keys. |
| `numerator` | number | count | no | Records that have the thing. |
| `denominator` | number | count | no | Records checked. |

The worker supplies no display labels for these; the view supplies them.

## 38. ConfigRevision

The pricing configuration audit log. Append-only.

**Collection:** `config_revisions`. **Fixture:**
`seed/pricing-config-history.json`.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `revision` | number | — | no | Monotonic, auto-incrementing. **`0` means nothing has ever been saved.** |
| `overrides` | object | — | no | A **flat** `{ "dot.path": number|string }` map. Not a nested tree. Not returned by the history endpoint. |
| `editor_email` | string | — | no | From the verified session, never from the request body. |
| `note` | string | — | yes | Maximum 500 characters. |
| `created_at` | string | ISO 8601 | no | **A string, not epoch milliseconds.** The one place in the model that uses ISO. |

There is no update path and no delete path. Rolling back means saving the older
override set again as a new revision. In MongoDB, back `revision` with a counter
document rather than a document count, so a delete could never reuse a number.

## 39. EditableField

The form registry the config endpoint returns, so the Configure screen can build
itself. Thirteen entries.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `path` | string | — | no | The dot path this field writes. |
| `label` | string | — | no | Field label. |
| `group` | string | — | no | Group key, one of seven. |
| `groupLabel` | string | — | no | Group display label. |
| `kind` | string | — | no | One of five: `bps`, `usd`, `pct`, `count`, `date`. Drives the input control and the validation message. |
| `min` | number | depends on kind | yes | Lower bound. |
| `max` | number | depends on kind | yes | Upper bound. |
| `help` | string | — | yes | Helper text. |

Anything outside these thirteen paths is silently dropped on merge and rejected
on save with `"not an editable field"`.

## 40. DealInputs — the quote, which lives in the URL

Not a collection. **The URL is the quote**: a priced deal is encoded entirely in
the query string, and the hash selects the section and tab. Links of this shape
are already in customers' inboxes.

| Field | Type | Unit | Meaning |
|---|---|---|---|
| `vertical` | string | — | One of four preset keys. |
| `processor` | string | — | `elavon` or `qorpay`. |
| `riskLevel` | string | — | `low` or `high`. |
| `presentment` | string | — | `cardPresent` or `cardNotPresent`. |
| `monthlyVolume` | number | USD dollars per month | Merchant processing volume. |
| `avgTicket` | number | USD dollars | Average transaction size. |
| `pricingType` | string | — | `flat` or `interchangePlus`. |
| `ratePct` | number | percent | The quoted rate. |
| `ratePerItem` | number | USD dollars | Per-transaction fee. |
| `massPay.enabled` | boolean | — | |
| `massPay.payoutCount` | number | count per month | |
| `massPay.avgPayoutSize` | number | USD dollars | |
| `massPay.crossBorderPct` | number | percent | |
| `lineItems[].catalogId` | string | — | Which product. |
| `lineItems[].qty` | number | count | |
| `lineItems[].mode` | string | — | `default`, `custom` or `waived`. |
| `lineItems[].sellOverride` | number | USD dollars | Optional manual price. |

**`dealId` is deliberately not part of the quote.** The encoder never writes it
and the decoder ignores it. A quote is about a merchant profile, not about a CRM
record.

The business rules behind these numbers belong to `02-pricing-engine/`. This
section is the shape only.

## 41. DealContext

The identity chip shown when a quote was opened from a CRM deep link.
**Fixture:** `seed/pricing-deal-context.json`, five variants.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `available` | boolean | — | no | True once the deal itself was found. Stays true when only the enrichment failed. |
| `dealId` | string | — | no | Echoes the requested id. |
| `dealName` | string | — | yes | |
| `companyName` | string | — | yes | |
| `companyDomain` | string | — | yes | |
| `ownerName` | string | — | yes | |
| `recordUrl` | string | — | yes | Null rather than broken when the portal id is unknown. A dead link is worse than no link. |
| `reason` | string | — | yes | Present only when `available` is false. Distinguishes a wrong link from an unreachable CRM. |

**This shape pre-fills no pricing input.** Not volume, ticket, vertical,
processor, risk or rate. That was a measured decision: the relevant CRM
properties were populated on 1 deal out of 215.

## 42. AuthContext

What the verified session carries. Not a collection.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `sub` | string | — | no | Stable subject id. Keys the copilot conversation store. |
| `email` | string | — | no | **Always lowercased.** |
| `role` | string | — | no | `member` or `admin`. **Nothing in this application reads it**, and a test asserts the pricing code must not. |
| `bypassMode` | boolean | — | no | True in developer bypass. Drives the orange DEV MODE banner. |
| `iat` | number | epoch seconds | no | Issued-at. |

## 43. WhoAmI

The identity payload the front end reads on boot. **Fixture:**
`seed/whoami.json`, three variants.

| Field | Type | Unit | Nullable | Meaning |
|---|---|---|---|---|
| `email` | string | — | no | Lowercased. |
| `role` | string | — | no | `rep`, `manager` or `marketer`. A different axis from the token role above. |
| `ownerId` | string | — | **yes, on purpose** | Null is the real "signed in but not a salesperson" state and has its own screen. |
| `bypass_mode` | boolean | — | no | Note the snake_case here. The rest of the payload is camelCase. |

---

# Enumerations

Thirty-nine closed sets. Where a stored value differs from its display label,
both are given. An **open set** is called out explicitly; those are
pass-throughs from the CRM and must not be treated as exhaustive.

### 1. View role (3)

| Stored | Label |
|---|---|
| `rep` | *(no separate label; the raw value is displayed)* |
| `manager` | *(as above)* |
| `marketer` | *(as above)* |

### 2. Token role (2)

`member` · `admin`. A **different axis** from the view role. Nothing in this
application branches on it.

### 3. Sync lane (3)

| Stored | Label |
|---|---|
| `fast` | Deals & pipelines |
| `heavy` | Contacts & companies |
| `marketing` | Marketing assets & funnel |

### 4. Sync status (5 observable)

| Stored | Meaning |
|---|---|
| `ok` | Everything completed. |
| `partial` | A rate limit truncated a pull and a cursor was saved. |
| `error` | A caught catastrophic failure. |
| `skipped` | The lane did not run. |
| `unknown` | Substituted when the stored status is null. |

The type declares the first three; the run record documents `skipped`; the
reader substitutes `unknown`. The front end can see all five.

### 5. Scope-probe surfaces (9, in display order)

| Stored | Label | Permission needed upstream |
|---|---|---|
| `crm` | CRM — deals, owners, pipelines | `crm.objects.deals.read`, `crm.objects.owners.read`, `crm.schemas.deals.read` |
| `campaigns` | Marketing campaigns | `marketing.campaigns.read` |
| `lists` | Lists & segments | `crm.lists.read` |
| `forms` | Forms | `forms` |
| `marketing-email` | Marketing email | `marketing-email`, `content` |
| `analytics` | Attribution analytics | `business-intelligence` |
| `conversations` | Inbox conversations | `conversations.read` |
| `cms` | Content & pages | `content` |
| `onboarding` | Onboarding custom objects | `crm.objects.custom.read` |

### 6. Sections (5)

| Stored | Label |
|---|---|
| `home` | Home |
| `revenue` | Revenue |
| `marketing` | Marketing |
| `leadership` | Leadership |
| `pricing` | Pricing |

Plus one non-section route: **Setup & Data Readiness** at `#/setup`.

### 7. Sub-tabs (20, grouped by section)

| Section | Stored → Label |
|---|---|
| home | `today` → Today · `signals` → Signals · `onboarding` → Onboarding |
| revenue | `pipeline` → Pipeline · `forecast` → Forecast · `owners` → Owners · `velocity` → Velocity · `stuck` → Stuck · `winloss` → Win / Loss |
| marketing | `leadfunnel` → Lead Funnel · `sources` → Source ROI · `audience` → Audience · `campaigns` → Campaigns · `formsemails` → Forms & Email |
| leadership | `meetings` → Meetings · `pipeline` → Pipeline Health · `contracts` → Contracts · `datafix` → Data to Fix |
| pricing | `price` → Price a deal · `configure` → Configure |

Deep-linkable hash routes exist for `#/setup`, `#/leadership/<tab>` and
`#/pricing[/<tab>]`. The other sections hold their tab in memory only.

### 8. Pipelines (2)

| Stored | Label | Deals in the fixtures |
|---|---|---|
| `default` | Sales Pipeline | 28 |
| `638415376` | Affiliate Pipeline | 12 |

These two ids are real and pinned in production code and tests. **They never
merge.**

### 9. Stage ids (unverified)

Stage ids and labels are **not** a code constant. They sync live from the CRM
and are never committed, so **every stage id below is invented or lifted from a
test fixture.** The real production list is unknown and would be settled by
querying the live pipeline table.

The set used across the fixtures and this bundle:

| Pipeline | Stage ids |
|---|---|
| `default` | `appointmentscheduled` · `qualifiedtobuy` · `presentationscheduled` · `decisionmakerboughtin` · `contractsent` · `closedwon` · `closedlost` |
| `638415376` | `aff_app` · `aff_review` · `aff_active` · `aff_declined` |

Other stage ids appear in the real repository's test fixtures and are equally
invented: `aff_new`, `demo`, `qualified`, `negotiation`, `won`.

Build against stage **labels** resolved from the pipeline document, never
against a hard-coded id list.

### 10. Aging tier (4)

| Stored | Rule | Sense |
|---|---|---|
| `unknown` | `daysInStage` is null | Not counted as stuck. Honest: it is unmeasurable. |
| `fresh` | 14 days or fewer | Fine |
| `aging` | more than 14, up to 30 | Stuck |
| `stale` | more than 30 | Worst tier |

Thresholds: aging at 14 days, stale at 30 days.

### 11. Health verdict

There is **no multi-valued health enumeration.** The verdict band is binary:
`ok: true` renders a mint-tinted pill with a shield glyph, anything else renders
neutral with a dashed-circle glyph.

### 12. Status badge tone (3)

`good` · `accent` · `neutral`. Colour is never the only cue; every badge carries
a glyph and a label as well.

### 13. Marketing time window (4)

| Stored | Label | Range |
|---|---|---|
| `7d` | Last 7d | now minus 7 days |
| `30d` | Last 30d | now minus 30 days |
| `90d` | Last 90d | now minus 90 days |
| `all` | All time | from 2020-01-01 UTC |

### 14. Lifecycle funnel stage (5, ordered)

| Stored | Label |
|---|---|
| `leads` | Leads |
| `marketingQualifiedLeads` | MQLs |
| `salesQualifiedLeads` | SQLs |
| `opportunities` | Opportunities |
| `customers` | Customers |

### 15. Data to Fix — object (2)

`companies` (default) · `contacts`. Anything other than `contacts` means
companies.

### 16. Data to Fix — scope (3)

`mine` · `all` (default) · `unowned`. Junk falls back to `all`. The server does
not role-gate this; hiding `unowned` from reps is a UI choice.

### 17. Data to Fix — sort (3)

`name` · `owner` · `missing`. Absent or junk means the default worklist order.

### 18. Data to Fix — direction (2)

`asc` (default) · `desc`. Only the literal `desc` flips it.

### 19. Data-quality metric key (4)

`contacts_with_lifecycle` · `contacts_with_source` · `companies_with_country` ·
`companies_regulated`. No display labels exist in the data; the view supplies
them.

### 20. Onboarding step (6, ordered)

| Order | Stable name | Label |
|---|---|---|
| 0 | `stg_universal_intake` | Intake Records |
| 1 | `prd_onboarding` | Onboarding Records |
| 2 | `prd_merchant` | Merchants |
| 3 | `prd_sub_merchant` | Sub-Merchants |
| 4 | `prd_external_business_party` | External Business Parties |
| 5 | `staffs` | Staff |

### 21. Handoff milestone key (4)

`intake` · `onboarding` · `merchant` · `submerchant`. **Only the first four
onboarding types count.** Staff and External Business Parties are deliberately
not milestones.

### 22. Contract status (4)

`Not started` · `In progress` · `Blocked` · `Complete`. Stored verbatim as the
display string; there is no code-and-label split.

### 23. Contract decision needed (3)

`Yes` · `No` · `TBD`. Stored verbatim.

### 24. Meeting demo (2)

`Yes` · `No`. Stored verbatim.

### 25. Pricing processor (2)

`elavon` · `qorpay`.

### 26. Pricing risk level (2)

`low` · `high`.

### 27. Card presentment (2)

| Stored | In the URL |
|---|---|
| `cardPresent` | `cp` |
| `cardNotPresent` | `cnp` |

### 28. Pricing type (2)

| Stored | In the URL |
|---|---|
| `flat` | `flat` |
| `interchangePlus` | `icplus` |

### 29. Line-item mode (3)

| Stored | In the URL |
|---|---|
| `default` | `d` |
| `custom` | `c` |
| `waived` | `w` |

### 30. Vertical (4)

| Stored | Label |
|---|---|
| `insurance` | Insurance |
| `government` | Government & utilities |
| `healthcare` | Healthcare |
| `ecommerce` | Consumer ecommerce / NIL |

### 31. Interchange bucket key (5)

`regulatedDebit` · `unregulatedDebit` · `standardCredit` · `premiumCredit` ·
`commercialCorporate`.

### 32. Editable field kind (5)

`bps` · `usd` · `pct` · `count` · `date`. Drives both the input control and the
validation message.

### 33. Editable config paths (13)

The **only** writable settings. Everything else in the pricing configuration is
a signed fact or locked research, and the merge silently drops anything outside
this set.

`marginFloorBps` · `marginFloorPerItem` · `downgrade.share` ·
`downgrade.upliftPct` · `processors.qorpay.losses.flatMonthly` ·
`fbo.sell.perTxnOut` · `fbo.sell.fundsFlowBps` · `fbo.sell.monthlyPlatformFee` ·
`fbo.sell.floatSharePct` · `massPay.sell.perPayoutFee` ·
`massPay.sell.fxSpreadPct` · `massPay.quoteValidUntil` ·
`lineItems.amortizeMonths`

### 34. Editable field group (7)

| Stored | Label |
|---|---|
| `policy` | Approval floor |
| `downgrade` | Downgrade assumption |
| `losses` | QorPay loss allowance |
| `fboSell` | FBO — what we charge |
| `masspaySell` | MassPay — what we charge |
| `masspayQuote` | MassPay quote |
| `lineItems` | Products & equipment |

### 35. Validation message (5)

The literal strings a failed save returns:

`not an editable field` · `must be a date (YYYY-MM-DD)` · `must be a number` ·
`must be at least {min}` · `must be at most {max}`

### 36. Provenance tag source (3)

`real` · `placeholder` · `illustrative`. Tells the pricing screens whether a
number is a signed fact, a stand-in, or an illustration.

### 37. Home fallback (2 states)

`null`, or `"fresh-leads"`. The second is set for a rep whose email matched no
owner record, so the screen leads with hot leads rather than an empty board.

### 38. Deal-context reason (open set, 3 known)

Present only when `available` is false: `deal_not_found` ·
`hubspot_error:<status>` (for example `hubspot_error:429`) ·
`hubspot_blocked_non_read`. The status suffix makes this an open set. The two a
prototype should simulate are `deal_not_found` and `hubspot_error:429`, because
a rep needs different words for each.

### 39. CRM record type id (3)

Used to build deep links of the form
`https://app.hubspot.com/contacts/{portal}/record/{typeId}/{id}`:

| Object | Type id |
|---|---|
| contact | `0-1` |
| company | `0-2` |
| deal | `0-3` |

The portal id in the fixtures is `46378407`. These links point at a real CRM
portal that a prototype viewer will not have access to. Keep the field, and
render the link inert in the prototype rather than navigating to it.

### Open sets, listed so nobody mistakes them for enumerations

These fields are pass-throughs from the CRM. The values in the fixtures are
examples, not the full set.

| Field | Fixture values used |
|---|---|
| `Deal.dealtype` | `newbusiness`, `affiliate` |
| `Deal.latestSource` | `REFERRALS`, and others |
| `Deal.predictiveScore` | numeric, no closed set |
| `Contact.lifecyclestage` | lifecycle keys, matching enum 14 in practice |
| `Contact.analytics_source` | `ORGANIC_SEARCH`, and others |
| `LeadSourceRoi.source` | `ORGANIC_SEARCH`, and others |
| `MarketingEmail.state` | `PUBLISHED`, `SCHEDULED`, `DRAFT` — unverified, the live set may be wider |
| `MarketingList.processingType` | `DYNAMIC`, `SNAPSHOT` — unverified, same caveat |

---

## Nullable on purpose — the summary

Seven fields are null in the fixtures deliberately. Without them the Data to Fix
screen, the missing-close-date warnings and the "amount unknown" path all render
empty and you cannot tell whether they work.

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

`seed/datafix-companies.json` carries the same idea at the company level: a mix
of complete and incomplete records, so the completeness scoring has something to
score.

The same principle applies to the whole-field level: `ownerId` null on a deal,
`owner_id` null on a company or contact, `domain` null on a company, `winRate`
null for an owner with no closed deals, `daysInStage` null on an unmeasurable
deal, and a null `totals` block for a marketing window. Every one of those has a
designed empty or honest state on screen.

---

## Internal consistency the fixtures hold

These should keep holding if anything is edited:

- Per-stage deal counts sum to 40.
- Per-stage open amounts sum to the per-pipeline open total.
- The owner leaderboard sums to the same grand total.
- The Home digest counts derive from the same 40 deals.
- Every `daysInStage` is consistent with its deal's `lastmodified`. Change one,
  change the other, or the aging views will contradict the timestamps.

Open pipeline value across the fixtures totals **$1,431,950**. Outcomes: 7 won,
3 lost, 30 open. Six owners hold 5 to 8 deals each, so the leaderboard has a
real ranking rather than a flat one.

**Unverified:** real production magnitudes. Code comments in the real system
mention roughly 44 deals, 50,000 contacts and 43,000 companies. The fixtures use
40 deals, 12,400 contacts and 8,320 companies — plausible, but invented.
