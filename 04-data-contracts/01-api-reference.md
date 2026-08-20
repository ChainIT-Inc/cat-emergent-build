# API reference

Every endpoint the Sales Cockpit serves, with its parameters, its exact response
shape, and the seed fixture that matches it.

*Written for two readers: the AI agent building the FastAPI backend, and the
product owner checking that a screen is asking for something that exists.*

---

## How to read this file

The real cockpit is a Hono app on a Cloudflare Worker reading two SQLite
databases. You are building FastAPI over MongoDB. **The paths, the parameters
and the response shapes carry across unchanged.** The storage, the login and the
background sync do not — the last section of this file says what to do instead
for each one.

Conventions that hold everywhere:

| Thing | Rule |
|---|---|
| Money | USD, plain dollars, a floating-point number. Never cents. Never a string. |
| Timestamps | Epoch **milliseconds**, an integer. Three exceptions below. |
| Date exceptions | `created_at` on a pricing revision is an ISO 8601 string. `meeting_date` and `due_date` are `YYYY-MM-DD` strings. Growth-timeseries `day` is `YYYY-MM-DD`. |
| Read failures | Read endpoints do not fail. A broken or empty database returns a well-formed empty shape with a `syncPending` flag, status 200. |
| Caching | `GET /api/snapshot` sets `Cache-Control: no-store`. The copilot proxy sets `Cache-Control: private, no-store`. Nothing else sets a cache header. |
| Pagination | There is none. No `limit`, `offset`, `page` or cursor exists on any read endpoint. Two endpoints cap their rows instead and say so in the body. |
| Live updates | None. No websockets, no server-sent events, no polling interval on any hook. |
| Rate limiting | None, except the five-minute per-lane cooldown on `POST /api/refresh`. |

All paths are relative to the app origin. In production that is
`https://sales.chainithub.com`.

---

## Endpoint index

| # | Method | Path | Who may call it | Fixture |
|---|---|---|---|---|
| 1 | GET | `/api/health` | Anyone. This route sits outside the login gate. | none |
| 2 | GET | `/api/whoami` | Any signed-in user | `seed/whoami.json` |
| 3 | GET | `/api/snapshot` | Any signed-in user | `seed/snapshot.json` |
| 3a | GET | `/api/snapshot?view=deals` | Any signed-in user | `seed/deals.json` |
| 3b | GET | `/api/snapshot?view=home` | Any signed-in user | `seed/home-rep.json`, `seed/home-manager.json`, `seed/home-unmatched.json` |
| 3c | GET | `/api/snapshot?view=marketing` | Any signed-in user | `seed/marketing.json` |
| 3d | GET | `/api/snapshot?view=onboarding` | Any signed-in user | `seed/onboarding.json` |
| 4 | POST | `/api/refresh` | Any signed-in user. No role gate. | none |
| 5 | — | `/api/agent/*` (11 routes) | Any signed-in user | none |
| 6 | GET | `/api/leadership/meetings` | Any signed-in user | `seed/leadership-meetings.json` |
| 7 | POST | `/api/leadership/meetings` | Any signed-in user | — |
| 8 | PUT | `/api/leadership/meetings/:id` | Any signed-in user | — |
| 9 | DELETE | `/api/leadership/meetings/:id` | Any signed-in user | — |
| 10 | GET | `/api/leadership/contracts` | Any signed-in user | `seed/leadership-contracts.json` |
| 11 | POST | `/api/leadership/contracts` | Any signed-in user | — |
| 12 | PUT | `/api/leadership/contracts/:id` | Any signed-in user | — |
| 13 | DELETE | `/api/leadership/contracts/:id` | Any signed-in user | — |
| 14 | GET | `/api/leadership/pipeline` | Any signed-in user | `seed/leadership-pipeline.json` |
| 15 | PUT | `/api/leadership/annotations/:dealId` | Any signed-in user | — |
| 16 | GET | `/api/leadership/datafix` | Any signed-in user | `seed/datafix-companies.json` |
| 17 | GET | `/api/pricing/config` | Any signed-in user | `seed/pricing-config.json` |
| 18 | GET | `/api/pricing/config/history` | **Config editors only** | `seed/pricing-config-history.json` |
| 19 | POST | `/api/pricing/config` | **Config editors only** | — |
| 20 | GET | `/api/pricing/hubspot/deal/:id` | Any signed-in user | `seed/pricing-deal-context.json` |

Thirty endpoints in total, counting the eleven copilot proxy routes in row 5
individually. Two of them are role-gated. Everything else, including every
write, is open to any signed-in user.

---

## 1. `GET /api/health`

Liveness probe for the fleet monitor.

- **Who may call it:** anyone. It is registered before the login gate, so it
  answers without a session.
- **Parameters:** none.
- **Errors:** none.

```jsonc
// 200
{
  "ok": true,           // boolean — always true when the process is up
  "name": "cat-sales"   // string — the Worker name; keep the literal
}
```

---

## 2. `GET /api/whoami`

Tells the front end who is signed in, what view role they hold, and whether
their email matches a sales owner record.

- **Who may call it:** any signed-in user.
- **Parameters:** none.
- **Fixture:** `seed/whoami.json` — one object with three keys, `rep`,
  `manager` and `unmatched`. Serve whichever matches the selected role.

```jsonc
// 200
{
  "email": "dana.whitlock@chainit.com",  // string — the verified email, always lowercased
  "role": "manager",                     // "rep" | "manager" | "marketer"
  "ownerId": "101",                      // string | null — the owner record id; null when no owner matches this email
  "bypass_mode": false                   // boolean — true only in developer bypass mode; drives the orange DEV MODE banner
}
```

`role` is derived from email lists on the server. It is never stored per user
and there is no UI to change it. See *Identity and authorisation* below.

This endpoint never returns an error of its own. A database failure still
returns 200 with the role that the email lists gave and `ownerId: null`.

---

## 3. `GET /api/snapshot`

One path, five different response bodies, chosen by `?view=`. This is the main
read endpoint of the whole application.

- **Who may call it:** any signed-in user.
- **Caching:** always `Cache-Control: no-store`.

| Param | Type | Required | Default | Notes |
|---|---|---|---|---|
| `view` | string | no | *(absent)* | Accepted: `home`, `deals`, `marketing`, `onboarding`. **Any other value, including absent, returns the default body in 3.0.** There is no validation error. |

**There are no error responses on this route.** Every builder degrades to a
well-formed empty shape rather than throwing.

### 3.0 `GET /api/snapshot` — the default body

Sync state plus two pipeline rollups. This is what the Setup and Data Readiness
screen reads.

**Fixture:** `seed/snapshot.json`

```jsonc
// 200
{
  "sync": {
    "lastRun": {                       // one key per lane: "fast" | "heavy" | "marketing"
      "fast": {
        "status": "ok",                // "ok" | "partial" | "error" | "skipped" | "unknown"
        "startedMs": 1787233200000,    // number | null — epoch ms
        "finishedMs": 1787233260000,   // number | null — epoch ms
        "rows": 51,                    // number — rows written by that run
        "http429": 0,                  // number — rate-limit responses seen
        "http403": 0,                  // number — permission-denied responses seen
        "errorText": null              // string | null
      },
      "heavy": null,                   // null means this lane has NEVER run. Not an error.
      "marketing": null
    },
    "objectCounts": [                  // only "contacts" and "companies" are ever written here
      {
        "objectType": "contacts",      // "contacts" | "companies"
        "rowsInD1": 12400,             // number — how many we hold locally
        "hsReportedTotal": 50218,      // number | null — how many the CRM says exist
        "capturedMs": 1787230000000    // number — when the pair was captured
      }
    ],
    "scopeStatus": [                   // one row per probed CRM surface; 9 surfaces, see the enum list
      {
        "surface": "crm",              // string — the stored surface key
        "httpStatus": 200,             // number — 200 granted, 403 blocked, 0 unreachable
        "granted": true,               // boolean
        "checkedMs": 1787230000000     // number
      }
    ]
  },
  "deals": {
    "byPipelineStage": [               // sorted by pipeline, then stage
      {
        "pipeline": "default",         // string — pipeline id, not its label
        "stage": "qualifiedtobuy",     // string — stage id, not its label
        "dealCount": 5,                // number — open AND closed deals in this stage
        "openAmount": 371250           // number — sums amount only where the deal is open; closed deals add 0
      }
    ],
    "ownerLeaderboard": [              // sorted by openAmount descending
      {
        "ownerId": "101",              // string
        "openDeals": 5,                // number
        "openAmount": 437550,          // number — USD
        "wonDeals": 2,                 // number
        "wonAmount": 204250,           // number — USD
        "winRate": 1                   // number | null — null when the owner has NO closed deals at all
      }
    ]
  }
}
```

Three rules that matter:

- `sync.lastRun.fast === null` is the canonical "nothing has synced yet" signal.
  The whole UI keys off it.
- `winRate` is won divided by closed. When an owner has no closed deals the
  answer is **`null`, not `0`**. Zero means "closed some, won none" and reads
  very differently.
- `openAmount` sums the amount only on open deals. Closed deals still add to
  `dealCount` but contribute nothing to the amount.

### 3a `GET /api/snapshot?view=deals`

Every deal, open and closed, plus the pipeline and stage metadata needed to
label them. This one payload feeds all six Revenue tabs.

**Fixture:** `seed/deals.json` — 40 deals across the two pipelines.

```jsonc
// 200
{
  "deals": [                                        // every deal, unbounded, no pagination
    {
      "id": "d-1007",                               // string
      "pipeline": "default",                        // string | null — pipeline id
      "dealstage": "qualifiedtobuy",                // string | null — stage id
      "amount": 64000,                              // number | null — USD. null on purpose in the fixtures.
      "dealtype": "newbusiness",                    // string | null — pass-through from the CRM, open set
      "ownerId": "101",                             // string | null — null renders as "Unassigned"
      "createdate": 1782864000000,                  // number | null — epoch ms
      "lastmodified": 1786716000000,                // number | null — epoch ms
      "isClosed": false,                            // boolean
      "isWon": false,                               // boolean — always (won AND closed), never won alone
      "closedWonReason": null,                      // string | null
      "closedLostReason": null,                     // string | null
      "predictiveScore": null,                      // number | null — pass-through, no closed value set
      "latestSource": "REFERRALS",                  // string | null — pass-through, open set
      "daysInStage": 6,                             // number | null — days since last modification, NOT since stage entry
      "dealName": "Vireo Health Partners — Gateway", // string | null — shown as "Opportunity"
      "nextStep": "Security review call",           // string | null — null on purpose in the fixtures
      "closeDate": 1790294400000,                   // number | null — epoch ms. null on purpose in the fixtures.
      "description": "Multi-site clinic group."     // string | null — null on purpose in the fixtures
    }
  ],
  "pipelines": [
    {
      "pipeline": "default",                        // string — pipeline id
      "pipelineLabel": "Sales Pipeline",            // string — falls back to the id if no label is known
      "stages": [                                   // sorted by displayOrder, NOT by array position
        {
          "stage": "qualifiedtobuy",                // string — stage id
          "stageLabel": "Qualified",                // string — falls back to the stage id
          "displayOrder": 1,                        // number — the sort key
          "isClosed": false,                        // boolean
          "isWon": false                            // boolean
        }
      ]
    }
  ],
  "ownerNames": { "101": "Dana Whitlock" },         // object keyed by owner id; falls back to the id, never blank
  "syncPending": false                              // boolean — true when the fast lane has never run
}
```

Rules that matter:

- `isWon` is forced to `won AND closed` when the payload is built, so the six
  Revenue tabs cannot disagree about what a win is.
- `daysInStage` is days since the deal was last modified. It is not a real
  stage-entry timestamp and the UI carries a footnote saying so. It is
  recomputed on each fast sync, so it is a snapshot taken at sync time, not a
  live value.
- `ownerNames` holds real owner ids only. A deal with a null owner is labelled
  `"Unassigned"` by the front end.
- A deal whose stage is missing from `pipelines` is still returned. Its label
  degrades to the raw stage id rather than disappearing.

### 3b `GET /api/snapshot?view=home`

The Home digest: what this person should act on today. Role-scoped.

**Fixtures:** `seed/home-rep.json` (a rep, own deals only),
`seed/home-manager.json` (team-wide), `seed/home-unmatched.json` (signed in but
matching no owner record).

```jsonc
// 200
{
  "role": "rep",                       // "rep" | "manager" | "marketer"
  "ownerResolved": true,               // boolean — false when this email matched no owner record
  "fallback": null,                    // null | "fresh-leads" — set for a rep with no owner record
  "myOpenDeals": {
    "count": 6,                        // number — over ALL matching open deals, not just the ones listed
    "amount": 334400,                  // number — USD, sum over all matching open deals
    "deals": [                         // stuck-first ordering, CAPPED AT 12
      {
        "id": "d-1022",
        "pipeline": "default",
        "dealstage": "contractsent",
        "amount": 99000,               // number | null
        "ownerId": "102",              // string | null
        "daysInStage": 23,             // number | null
        "lastModifiedMs": 1785247200000
      }
    ]
  },
  "agingDeals":     { "count": 3, "amount": 239800 },   // open AND daysInStage > 14
  "tasksDueToday":  { "count": 0, "available": false }, // available is ALWAYS false — no task data is synced
  "newMqlSqlSince": { "count": 1 },                     // deals created in the last 7 days
  "weekWins":       { "count": 1, "amount": 54000 },    // won since Monday 00:00 UTC
  "hotLeads": {
    "count": 5,
    "leads": [                                          // max 25
      {
        "id": "l-3001",
        "name": "Odile Marchetti",
        "email": "odile.marchetti@brightfold-dental.example",
        "createdMs": 1787148000000
      }
    ],
    "degraded": false                                   // boolean — true when the live lead lookup failed or returned nothing
  }
}
```

Constants baked into this view: 12-deal cap, 14-day aging threshold, 7-day
lookback for new leads, 25 hot leads, week starts Monday 00:00 UTC.

Role scoping: `rep` filters to their own owner id. `manager` and `marketer` are
team-wide. A rep with no matching owner record gets every owner-scoped block
zeroed and `fallback: "fresh-leads"`, so the screen leads with the hot-leads
panel instead of an empty board.

Every aggregate is additionally restricted to deals in a known pipeline, so the
Home numbers can never exceed the sum of the Revenue tabs.

### 3c `GET /api/snapshot?view=marketing`

Everything the Marketing section reads: funnel, source ROI, campaigns, lists,
forms, emails, audience growth and per-window performance.

**Fixture:** `seed/marketing.json`

```jsonc
// 200
{
  "leadFunnel": [                                        // ordered; 5 stages
    { "stage": "leads", "count": 4820 }                  // stage is the stored key; the UI supplies the label
  ],
  "leadSourceRoi": [
    { "source": "ORGANIC_SEARCH",                        // string — pass-through source key, open set
      "leads": 1840, "contacts": 1610,
      "opportunities": 34, "visits": 21400 }
  ],
  "campaigns": [
    { "id": "cmp-501", "name": "Q3 Merchant Webinar",
      "updatedMs": 1786752000000 }                       // number | null
  ],
  "lists": {
    "total": 63,                                         // number | null — total lists the CRM reports
    "items": [
      { "listId": "lst-8801", "name": "MQL — Cannabis",
        "processingType": "DYNAMIC",                     // string — pass-through, open set
        "size": 1204,                                    // number | null
        "objectTypeId": "0-1" }                          // string — "0-1" contacts, "0-2" companies
    ]
  },
  "forms": [
    { "id": "frm-a1", "name": "Contact Sales",
      "archived": false, "fieldCount": 7 }
  ],
  "marketingEmails": [
    { "id": "eml-77", "name": "August product note",
      "state": "PUBLISHED",                              // string — pass-through, open set
      "publishMs": 1786320000000 }                       // number | null
  ],
  "audience": {
    "lifecycleCounts": [ { "stage": "lead", "count": 8640 } ],
    "leadsBySource":   [ { "stage": "ORGANIC_SEARCH", "count": 4210 } ],
    "contactGrowth":   [ { "day": "2026-08-14", "netNew": 61 } ],  // day is YYYY-MM-DD, not a timestamp
    "companyGrowth":   [ { "day": "2026-08-14", "netNew": 22 } ],
    "dataQuality": [
      { "metric": "contacts_with_lifecycle",             // one of 4 fixed metric keys
        "numerator": 11890, "denominator": 12400 }
    ],
    "contactsInD1": 12400,                               // number — contacts held locally
    "companiesInD1": 8320                                // number — companies held locally
  },
  "formPerformance": {
    "byWindow": {                                        // keys: "7d" | "30d" | "90d" | "all"
      "30d": {
        "totals": {                                      // object | null — null means "we have no figure", render an em dash
          "formViews": 9820, "submissions": 412,
          "contactSubs": 366, "nonContactSubs": 46,
          "visibles": 10400, "interactions": 2180,
          "subsPerView": 0.042,                          // number — a ratio, not a percentage
          "ctPerView": 0.222,
          "rangeStartMs": 1784592000000,
          "rangeEndMs": 1787184000000
        },
        "perForm": {                                     // keyed by form id
          "frm-a1": { "formId": "frm-a1", "formViews": 4100,
                      "submissions": 210, "contactSubs": 190,
                      "subsPerView": 0.051 }
        }
      }
    }
  },
  "campaignPerformance": {
    "byWindow": {
      "30d": {                                           // keyed by campaign id
        "cmp-501": { "campaignId": "cmp-501", "sessions": 3120,
                     "newContactsFirst": 88, "newContactsLast": 102,
                     "influencedContacts": 260,
                     "revenueAmount": 148000, "dealAmount": 210000,
                     "dealsNumber": 6, "contactsNumber": 260,
                     "currency": "USD" }
      }
    }
  },
  "syncPending": false,        // boolean — true when the marketing lane has never run
  "audiencePending": false     // boolean — true when the heavy lane has never run
}
```

A window key can be absent, and `totals` inside a present window can be `null`.
A missing form id or campaign id in `perForm` is also legitimate. **Render an
honest em dash in every one of those cases. Never substitute a zero.** A
fabricated 0 reads as a real measurement.

### 3d `GET /api/snapshot?view=onboarding`

The customer onboarding funnel, and the closed-won deals that never reached
onboarding.

**Fixture:** `seed/onboarding.json`

```jsonc
// 200
{
  "steps": [                                       // ordered by displayOrder; 6 steps
    {
      "objectTypeId": "2-60233737",                // string — the live CRM object type id
      "label": "Intake Records",                   // string
      "total": 412,                                // number
      "truncated": false,                          // boolean — true means `total` is a FLOOR, not a count
      "latestMs": 1787140000000,                   // number | null
      "displayOrder": 0                            // number
    }
  ],
  "handoff": {
    "wonDeals": 7,                                 // number — all closed-won deals checked
    "leakCount": 2,                                // number — won deals linked to none of the 4 progression objects
    "leakAmount": 110700,                          // number — USD
    "leaks": [
      {
        "dealId": "d-1026", "amount": 76800,       // number | null
        "ownerId": "104", "ownerName": "Tomás Vega",
        "dealstage": "closedwon",
        "closedMs": 1785196800000,
        "companyId": "c-9016",
        "companyName": "Juniper Rail Freight",
        "intakeCount": 0, "onboardingCount": 0,
        "merchantCount": 0, "submerchantCount": 0,
        "linkCount": 0                             // number — total links across the four
      }
    ]
  },
  "syncPending": false
}
```

Empty fallback when nothing has synced:
`{ "steps": [], "handoff": { "wonDeals": 0, "leakCount": 0, "leakAmount": 0, "leaks": [] }, "syncPending": true }`.

`truncated: true` means the crawl was capped or rate-limited and the number is a
floor. Keep that state. It is a deliberate product decision to show an honest
floor rather than a confident wrong number.

---

## 4. `POST /api/refresh`

Force one sync lane to run now.

- **Who may call it:** any signed-in user. There is no role gate on this.
- **Body:** ignored entirely. Everything is in the query string.

| Param | Type | Required | Default | Notes |
|---|---|---|---|---|
| `lane` | `fast` \| `heavy` \| `marketing` | no | `fast` | Any other value returns 400. |
| `force` | string | no | treated as true | Only the literal `"0"` or `"false"` re-enables the cooldown gate. |

```jsonc
// 200 — the lane ran
{
  "ok": true,
  "lane": "fast",        // string — the lane that ran
  "skipped": false,      // boolean
  "status": "ok",        // "ok" | "partial" | "error" | "skipped"
  "rows": 51             // number — rows written
}
```
```jsonc
// 400 — unknown lane
{ "ok": false, "error": "unknown lane \"bogus\"" }
```
```jsonc
// 429 — this lane finished less than five minutes ago. Nothing was fetched.
{ "ok": false, "lane": "fast", "cooldown": true, "retryInSeconds": 173 }
```
```jsonc
// 502 — defensive only; the real refresh path never throws
{ "ok": false, "lane": "fast", "error": "<message>" }
```

The cooldown is **five minutes per lane**, measured from that lane's last
finish time.

**Known drift, reproduce or fix deliberately.** The front end expects
`{ ok, skipped, events?, teamOndemand? }` and the success toast renders
`events`. The server never returns `events` or `teamOndemand`, so the toast
always reads `Synced · — events`. Both names are leftovers from an unrelated
app. If you fix it in the prototype, say so in your handoff.

---

## 5. `/api/agent/*` — the copilot proxy

Eleven routes that forward to a separate internal assistant service. This app
holds no assistant logic; it attaches the verified identity and passes the
upstream JSON straight through.

- **Who may call it:** any signed-in user.
- **Caching:** `Cache-Control: private, no-store` on the conversation, share
  and file routes.

| Method | Path | Body | What it does |
|---|---|---|---|
| POST | `/api/agent/chat` | `{ "message": string, "conversationId"?: string }` | Send a message |
| GET | `/api/agent/conversations` | — | List my conversations |
| GET | `/api/agent/conversations/:id` | — | Read one transcript |
| DELETE | `/api/agent/conversations/:id` | — | Soft-delete a conversation |
| POST | `/api/agent/conversations/:id/rename` | `{ "title": string }` | Rename |
| POST | `/api/agent/conversations/:id/share` | — | Mint a share link |
| GET | `/api/agent/shares` | — | List my live share links |
| GET | `/api/agent/shared/:token` | — | Read a shared snapshot |
| POST | `/api/agent/shared/:token/continue` | — | Fork a shared thread into mine |
| DELETE | `/api/agent/shared/:token` | — | Revoke a share link |
| GET | `/api/agent/files/:id` | — | Stream raw bytes, not JSON |

```jsonc
// 503 — the upstream binding or its shared secret is missing. This fails closed.
{ "error": "Agent unavailable", "detail": "agent proxy not configured" }
// 400
{ "error": "Bad Request", "detail": "invalid JSON body" }   // or "missing message" | "title required"
// 502
{ "error": "Agent unavailable", "detail": "<fetch error>" }
{ "error": "Agent error", "detail": "non-JSON agent response" }
// upstream status passed through
{ "error": "Agent error", "status": 404 }
```

A 2xx body is the upstream service's JSON, verbatim. Its shape belongs to that
service, not to this app.

**Unverified:** the upstream chat and conversation response shapes are not
documented anywhere in this bundle. If the prototype shows a copilot drawer,
invent a shape and flag it in the handoff.

The rename route re-parses the body and forwards only a sanitised `{ title }`,
never the raw client body.

---

## 6–13. `/api/leadership/meetings` and `/api/leadership/contracts`

The Leadership section is the only place where a user writes data. These rows
are typed by an operator; they are not CRM data.

- **Who may call them:** any signed-in user. There is no role gate on any
  leadership write.
- **Author stamping:** every write stamps `updated_by` from the verified signed-in
  email and **never from the request body.** A test proves a caller cannot spoof
  it. Reproduce that: read the identity from the session, ignore any author
  field a client sends.
- **Input sanitising:** allow-listed keys only. Each value is coerced to a
  string, trimmed, and cut to 4000 characters. Unknown keys are silently
  dropped, not rejected.

### 6. `GET /api/leadership/meetings`

Purpose: list the customer meetings the team has logged, newest edit first.

**Fixture:** `seed/leadership-meetings.json` — an array of 5.

```jsonc
// 200 — an array, ordered by updated_at descending
[
  {
    "id": "0f2b7d1e-9a4c-4f18-8f0b-2c6a51f4d3a7",  // string — a UUID generated on create
    "customer": "Kestrel County Water",             // string — never null; empty string when unset
    "attendees": "K. Ovalle, R. Diaz",              // string
    "internal_lead": "Dana Whitlock",               // string
    "demo": "Yes",                                  // string — "Yes" | "No"
    "cta": "Send the redlined MSA by Friday",       // string
    "objective": "Get procurement to name a signer",// string
    "a_win_is": "A signer named and a date set",    // string
    "meeting_date": "2026-08-18",                   // string — YYYY-MM-DD, NOT a timestamp
    "created_at": 1786924800000,                    // number — epoch ms
    "updated_at": 1787011200000,                    // number — epoch ms
    "created_by": "dana.whitlock@chainit.com",      // string — from the session, never the body
    "updated_by": "dana.whitlock@chainit.com"       // string — from the session, never the body
  }
]
```

**Every text column is an empty string when unset, never `null`.** That is a
deliberate discipline: the UI never has to null-check a leadership field.

On a database failure this returns `[]` with status 200, not an error.

### 7. `POST /api/leadership/meetings`

Purpose: create a meeting row.

Body: any subset of `customer`, `attendees`, `internal_lead`, `demo`, `cta`,
`objective`, `a_win_is`, `meeting_date`.

```jsonc
// 201 — the created row, same shape as above
```
```jsonc
// 400 — customer blank or absent. This check applies to CREATE only.
{ "error": "customer is required" }
```

### 8. `PUT /api/leadership/meetings/:id`

Purpose: edit a meeting row in place. Partial merge over the stored row;
`updated_at` and `updated_by` are restamped. There is no required-field check on
update.

```jsonc
// 200 — the merged row
// 404
{ "error": "not found" }
```

### 9. `DELETE /api/leadership/meetings/:id`

```jsonc
// 200
{ "ok": true }
// 404
{ "error": "not found" }
```

### 10–13. `/api/leadership/contracts[/:id]`

Structurally identical to meetings, with different fields: `agreement`,
`business_owner`, `status`, `legal_risk`, `compliance_risk`,
`decision_needed`, `due_date`, plus the same four audit columns. The create
required field is `agreement`.

**Fixture:** `seed/leadership-contracts.json` — an array of 5.

```jsonc
// 400 on create
{ "error": "agreement is required" }
```

`due_date` is a `YYYY-MM-DD` string, like `meeting_date`. `status` and
`decision_needed` come from fixed option sets listed in the enum section of
`02-data-model.md`.

---

## 14. `GET /api/leadership/pipeline`

Purpose: the Pipeline Health table — every open deal, joined to the CTA and
risk notes an operator has typed against it.

- **Who may call it:** any signed-in user.
- **Parameters:** none.
- **Fixture:** `seed/leadership-pipeline.json`

```jsonc
// 200
{
  "rows": [                                        // OPEN deals only; closed deals never appear here
    {
      "dealId": "d-1022",
      "opportunity": "Alder & Pine Hospitality — Multi-property",  // string — the deal name, falls back to the deal id
      "pipeline": "default",                       // string — the pipeline ID, not the label
      "stage": "Contract Sent",                    // string — the resolved stage LABEL, falls back to the stage id
      "ownerName": "Marcus Ilo",                   // string — "Unassigned" when there is no owner
      "ownerId": "102",                            // string | null
      "amount": 99000,                             // number | null
      "nextStep": "",                              // string — trimmed, never null
      "cta": "Escalate to the GM",                 // string — operator-typed; "" when unset
      "riskBlocker": "Legal is out until the 25th",// string — operator-typed; "" when unset
      "needsNextStep": true,                       // boolean — exactly (nextStep === "")
      "missing": [                                 // which required deal fields are absent
        { "key": "nextStep", "label": "Next Step" }
      ],
      "hubspotUrl": "https://app.hubspot.com/contacts/46378407/record/0-3/d-1022"  // string — deep link to the CRM record
    }
  ],
  "pipelines": [
    { "pipeline": "default", "pipelineLabel": "Sales Pipeline" }
  ],
  "missingNextStep": 11,       // number — rows where needsNextStep is true
  "missingRequiredCount": 14,  // number — rows with at least one missing field
  "syncPending": false
}
```

Note the asymmetry, it is intentional: `pipeline` is an **id**, `stage` is a
resolved **label**. The pipeline switcher needs the id; the stage column is read
by a human.

Empty fallback: `{ "rows": [], "pipelines": [], "missingNextStep": 0, "missingRequiredCount": 0, "syncPending": true }`.

---

## 15. `PUT /api/leadership/annotations/:dealId`

Purpose: save the operator's CTA and risk note against a deal. These notes live
in our database only; the CRM never sees them.

- **Who may call it:** any signed-in user.
- **Body:** `{ "cta"?: string, "risk_blocker"?: string }`. A partial body merges
  into the stored row.

```jsonc
// 200 — always. There is NO 404 here: annotating an unknown deal id simply creates the row.
{
  "deal_id": "d-1022",
  "cta": "Escalate to the GM",
  "risk_blocker": "Legal is out until the 25th",
  "updated_at": 1787230000000,                  // number — epoch ms
  "updated_by": "dana.whitlock@chainit.com"     // string — from the session
}
```

---

## 16. `GET /api/leadership/datafix`

Purpose: the Data to Fix worklist — companies or contacts that are missing a
field somebody needs.

- **Who may call it:** any signed-in user.
- **Fixture:** `seed/datafix-companies.json` (the `object=companies&scope=all`
  case). There is no contacts fixture; build one the same shape if you need it.

| Param | Type | Required | Default | Notes |
|---|---|---|---|---|
| `object` | `companies` \| `contacts` | no | `companies` | Anything other than `contacts` means companies. |
| `scope` | `mine` \| `all` \| `unowned` | no | `all` | Junk falls back to `all`. |
| `missing` | comma-separated field keys | no | *(none)* | OR-combined. Unknown keys are dropped, not rejected. |
| `sort` | `name` \| `owner` \| `missing` | no | *(worklist order)* | Junk falls back to worklist order. |
| `dir` | `asc` \| `desc` | no | `asc` | Only the literal `desc` flips it. |

**A bad parameter is never an error.** Every value is validated inside the
builder and silently ignored if it is junk. There is no 400 on this route.

```jsonc
// 200
{
  "object": "companies",     // string — echoes the resolved object
  "scope": "all",            // string — echoes the resolved scope
  "rows": [                  // CAPPED AT 200. There is no page 2.
    {
      "id": "c-9005",
      "name": "Marrow Bay Cannabis",       // string — display name; falls back to domain, then id
      "owner": "Unassigned",               // string — owner name or "Unassigned"
      "missing": [
        { "key": "owner_id", "label": "Owner" },
        { "key": "domain",   "label": "Domain" }
      ],
      "hubspotUrl": "https://app.hubspot.com/contacts/46378407/record/0-2/c-9005"
    }
  ],
  "shown": 15,               // number — rows on this page
  "scoped": 15,              // number — the FULL scoped count, before the 200-row cap
  "synced": 15,              // number — how many of this object we hold locally
  "reportedTotal": 43640,    // number | null — how many the CRM says exist
  "missingByLabel": [        // per-field counts over the FULL scoped set, NOT narrowed by `missing`
    { "key": "owner_id", "label": "Owner",  "count": 5 },
    { "key": "domain",   "label": "Domain", "count": 6 }
  ],
  "matching": null,          // number | null — full-scoped count matching the `missing` filter; null when no filter is applied
  "syncPending": false       // boolean — true when we hold zero rows of this object
}
```

The four counts are deliberately different numbers and the screen shows all
four. `shown` is this page, `scoped` is the whole filtered set, `synced` is what
we hold, `reportedTotal` is what the CRM claims. Showing `synced` next to
`reportedTotal` is the honest "N of M synced" pair — do not collapse them.

Default ordering is a worklist, not an alphabetical list: rows with no usable
name last, then most-missing first, then most recently modified.

`scope=mine` binds the caller's owner id. A caller with no owner record binds an
empty string, so the set is correctly empty rather than accidentally everything.
**Scope is deliberately not role-gated** on the server. Hiding the `unowned`
option from reps is a user-interface choice only.

---

## 17. `GET /api/pricing/config`

Purpose: the effective pricing configuration a rep prices against, plus the two
permission flags that decide what the pricing screens show them.

- **Who may call it:** any signed-in user. **Reads are open to everyone**,
  because every rep prices on the effective configuration.
- **Parameters:** none.
- **Fixture:** `seed/pricing-config.json`

```jsonc
// 200
{
  "config": { /* the full pricing configuration tree — see 02-pricing-engine/ */ },
  "overrides": { "marginFloorBps": 40 },     // object — a FLAT { "dot.path": number|string } map from the latest revision
  "revision": 1,                             // number — 0 means nothing has ever been saved
  "updatedAt": "2026-08-14T16:22:10.418Z",   // string (ISO 8601) | null — NOT epoch ms
  "updatedBy": "priya.raman@chainit.com",           // string | null
  "editableFields": [ /* 13 entries — the form registry, see 02-data-model.md */ ],
  "me": {
    "email": "priya.raman@chainit.com",
    "isAdmin": true,        // boolean — from PRICING_ADMIN_EMAILS. Reveals per-row "Our cost" and "Margin".
    "canEditConfig": true   // boolean — from the Leadership list. May open and save the Configure tab.
  }
}
```

**`isAdmin` and `canEditConfig` are two separate flags and must stay separate.**
See the identity section below.

The effective configuration is the bundled defaults, deep-copied, with only
whitelisted override paths applied on top. Once anything is saved, `version`
inside `config` gains a revision suffix: `"2026-08-04"` becomes
`"2026-08-04·r1"`.

Failure behaviour worth copying: if `me` is missing from the response the front
end defaults **both flags to false**. If the whole fetch fails it falls back to
the bundled configuration with `revision: 0` and both flags false. Pricing
permissions fail closed, never open.

---

## 18. `GET /api/pricing/config/history`

Purpose: the audit trail of saved pricing revisions.

- **Who may call it:** **config editors only.** Anyone else gets 403.
- **Parameters:** none.
- **Fixture:** `seed/pricing-config-history.json`

```jsonc
// 200 — newest first, LIMIT 50. Note: the override values are NOT returned here.
{
  "revisions": [
    {
      "revision": 1,                            // number
      "editor_email": "priya.raman@chainit.com",       // string
      "note": "Q3 floor + longer amortization window",  // string | null — max 500 chars
      "created_at": "2026-08-14T16:22:10.418Z"  // string (ISO 8601)
    }
  ]
}
```
```jsonc
// 403
{ "error": "Forbidden", "detail": "editing the pricing config is restricted to leadership" }
```

---

## 19. `POST /api/pricing/config`

Purpose: save a new pricing configuration revision.

- **Who may call it:** **config editors only.**
- **Body:** `{ "overrides": { "<dot.path>": number|string }, "note"?: string }`.
  `note` is truncated to 500 characters.

```jsonc
// 200 — the new effective config plus a receipt
{
  "config": { /* … */ },
  "overrides": { /* … */ },
  "revision": 2,
  "updatedAt": "2026-08-20T14:05:00.000Z",
  "updatedBy": "priya.raman@chainit.com",
  "saved": {                                   // the receipt the UI shows after a save
    "revision": 2,
    "at": "2026-08-20T14:05:00.000Z",
    "by": "priya.raman@chainit.com"
  }
}
```
```jsonc
// 400 — body will not parse
{ "error": "Bad request", "detail": "invalid JSON" }
// 400 — overrides is not a plain object (null, an array, or a scalar)
{ "error": "Bad request", "detail": "overrides must be an object" }
// 422 — a path is not editable, or a value is out of range
{
  "error": "Validation failed",
  "errors": [
    { "path": "marginFloorBps", "message": "must be at least 0" },
    { "path": "processors.qorpay.lowRisk.buy.perItem", "message": "not an editable field" }
  ]
}
// 403 — not a config editor
{ "error": "Forbidden", "detail": "editing the pricing config is restricted to leadership" }
```

There are exactly five validation messages. Use these literal strings:

| Message | Raised when |
|---|---|
| `not an editable field` | The dot path is outside the 13-path whitelist |
| `must be a date (YYYY-MM-DD)` | A `date`-kind field got something else |
| `must be a number` | A numeric field got a non-number |
| `must be at least {min}` | Below the field's minimum |
| `must be at most {max}` | Above the field's maximum |

**Writes are append-only.** One revision row per save. There is no update path
and no delete path. Rolling back means saving the older override set again as a
new revision. Do not add `PUT` or `DELETE` here.

---

## 20. `GET /api/pricing/hubspot/deal/:id`

Purpose: read-only identity context for a quote that was opened from a CRM deep
link — which deal, which company, which owner.

- **Who may call it:** any signed-in user.
- **Path parameter:** `id` — must match `^[0-9]{1,20}$`.
- **Fixture:** `seed/pricing-deal-context.json` — five variants keyed
  `available`, `partial`, `notFound`, `hubspotDown`, `invalidId`.

```jsonc
// 200 — context available
{
  "available": true,
  "dealId": "23361448738",
  "dealName": "Paysafe Affiliate Agreement",       // string | null
  "companyName": "Paysafe",                        // string | null
  "companyDomain": "paysafe.com",                  // string | null
  "ownerName": "Jodi Durst",                       // string | null
  "recordUrl": "https://app.hubspot.com/contacts/46378407/record/0-3/23361448738"  // string | null
}
```
```jsonc
// 200 — no context. `reason` separates a wrong link from an unreachable CRM.
{
  "available": false, "dealId": "999",
  "dealName": null, "companyName": null, "companyDomain": null,
  "ownerName": null, "recordUrl": null,
  "reason": "deal_not_found"      // or "hubspot_error:429", "hubspot_blocked_non_read", …
}
```
```jsonc
// 400 — the ONLY error status on this route; the id failed the digits-only check
{ "error": "invalid_deal_id" }
```

Three behaviours worth reproducing:

- **Partial context is a success.** Once the deal is found, a failed company or
  owner lookup leaves those fields null and keeps `available: true`. See the
  `partial` fixture variant.
- **`reason` matters to the user.** A rep needs different words for "that link
  is wrong" than for "the CRM is unreachable". Keep the distinction.
- **`recordUrl` is null rather than broken** when the portal id is unknown. A
  dead link is worse than no link.

**This endpoint pre-fills no pricing input** — not volume, not ticket, not
vertical, processor, risk or rate. That was a measured decision: the relevant
CRM properties were populated on 1 deal out of 215. A test asserts it stays that
way. Do not have the prototype auto-fill the pricing form from a deal id.

---

## Errors, all of them

### From the login layer, on every `/api/*` route except health

| Status | Body | Means |
|---|---|---|
| 503 | `{ "error": "Service misconfigured", "detail": "CF_ACCESS_TEAM_DOMAIN and CF_ACCESS_AUD unset" }` | An operator forgot a secret. The app is down. |
| 401 | `{ "error": "Unauthorized" }` | No session presented. |
| 401 | `{ "error": "Unauthorized", "detail": "<error text>" }` | A session was presented and failed verification. |

**The login layer never returns 403.** That has a consequence worth knowing: the
front end has an "unprovisioned user" screen that only renders on a 403 from
`/api/whoami`, and nothing can produce one. That screen is unreachable dead
code. Either wire a real 403 in the rebuild or drop the screen.

### From routes

| Status | Route | Body |
|---|---|---|
| 400 | `POST /api/refresh` | `{ "ok": false, "error": "unknown lane \"…\"" }` |
| 429 | `POST /api/refresh` | `{ "ok": false, "lane": "…", "cooldown": true, "retryInSeconds": n }` |
| 502 | `POST /api/refresh` | `{ "ok": false, "lane": "…", "error": "…" }` |
| 400 | `POST /api/leadership/meetings` | `{ "error": "customer is required" }` |
| 400 | `POST /api/leadership/contracts` | `{ "error": "agreement is required" }` |
| 404 | `PUT`/`DELETE` on a leadership row | `{ "error": "not found" }` |
| 400 | `POST /api/pricing/config` | `{ "error": "Bad request", "detail": "invalid JSON" }` or `"overrides must be an object"` |
| 422 | `POST /api/pricing/config` | `{ "error": "Validation failed", "errors": [ { "path", "message" } ] }` |
| 403 | `GET /api/pricing/config/history`, `POST /api/pricing/config` | `{ "error": "Forbidden", "detail": "editing the pricing config is restricted to leadership" }` |
| 400 | `GET /api/pricing/hubspot/deal/:id` | `{ "error": "invalid_deal_id" }` |
| 400/502/503 | `/api/agent/*` | See section 5 |

**The pricing config gate is the only 403 the entire application can emit.**

The front-end fetch helper throws on any non-2xx, carrying the status and
`body.error`. The message a user sees comes from the `error` field, so keep
those strings human-readable.

---

## Identity and authorisation

### How a caller is identified in production

One shared verifier runs in front of every `/api/*` route except `/api/health`.
It accepts the identity token either as a header or as a cookie. The cookie path
is deliberate: a browser navigating the single-page app carries the token as a
cookie, not as a header.

Resolution order:

1. Read the auth mode. **Unset means Access-only**, and the first-party session
   cookie is never even read. This app does not set the mode, so it is
   Access-only today.
2. Check the two Access secrets. Both present means verify the token. The
   audience secret absent **and** a developer bypass flag set to `"1"` means run
   as the bypass identity. Anything else is a 503.
3. A verified token becomes an auth context:
   `{ sub, email (always lowercased), role: "member"|"admin", bypassMode, iat }`.

The bypass identity is a frozen constant:
`{ sub: "bypass-localhost", email: "localhost@dev", role: "admin", bypassMode: true, iat: 0 }`.
When `bypassMode` is true the app renders an orange strip reading
**`DEV MODE — Cloudflare Access auth bypassed · running as localhost@dev`**.
That banner is a real production affordance, not a mock artefact. Keep it.

There is no credential user interface anywhere in the real app. No password
form, no sign-up, no password reset. **Do not add one to the prototype.**

### How the view role is derived

```
e         = email, trimmed and lowercased
managers  = MANAGER_EMAILS  ∪  ADMIN_EMAILS      (both lowercased)
marketers = MARKETER_EMAILS                       (lowercased)

role = manager   if e is in managers
     = marketer  if e is in marketers
     = rep       otherwise
```

Precedence is strictly manager, then marketer, then rep. An address in both
lists resolves to manager. The comparison is case-insensitive and trimmed on
both sides.

The role is computed **before** any database access, so it survives a database
failure. Only the owner-id lookup touches the database, and a failure there
leaves `ownerId` null rather than erroring.

**The role is driven by email lists only. It is not stored per user and there is
no interface to change it.**

**Unverified:** whether `MANAGER_EMAILS` and `MARKETER_EMAILS` are set in
production at all. They are optional secrets and are absent from the committed
configuration. If neither is set, every signed-in user is a `rep` today and the
manager Home digest has never been seen by anyone. Settled by listing the
Worker's secrets.

### Three permissions, not one. This is the load-bearing part.

All three sound like "admin". They are independent, they come from three
different places, and a person can hold any one without the others.

| Flag | Source | Exact rule | What it grants |
|---|---|---|---|
| `canEditConfig` | The **ChainIT-Leadership** list, a code constant of 9 addresses | bypass mode, or the email is in the Leadership list. **Never reads the token role.** A missing auth context is false. | Open and save the pricing **Configure** tab. Read `GET /api/pricing/config/history`. |
| `isAdmin` | **`PRICING_ADMIN_EMAILS`**, a 2-address setting | bypass mode, or the email is in that list | Reveals the per-row **"Our cost"** and **"Margin"** columns in pricing. Nothing else. |
| view `role` | **`MANAGER_EMAILS` + `ADMIN_EMAILS`**, and `MARKETER_EMAILS` | The rules above | Team-wide Home digest. The "Unowned" scope affordance in Data to Fix. |

**The real addresses are deliberately not written down here.** This bundle is
uploaded to a third-party service, and a list of named executives with the
systems each can reach is not something to hand over for a prototype that does
not need it. What the prototype needs is the *shape*, and the shape is below.

| List | Size in production | Use in the prototype |
|---|---|---|
| Leadership, drives `canEditConfig` | 9 people | Two fictional addresses from `seed/owners.json` |
| `PRICING_ADMIN_EMAILS`, drives `isAdmin` | 2 people | One fictional address, and a **different** one |

Make the two prototype lists overlap partially rather than fully. That is what
production looks like, and a fully-overlapping pair hides the bug where the two
permissions get collapsed into one.

Suggested wiring, using the seed owners:

```
LEADERSHIP     = ["dana.whitlock@chainit.com", "priya.raman@chainit.com"]
PRICING_ADMINS = ["priya.raman@chainit.com"]
```

Dana can then edit the cost engine but cannot see per-row margin. Priya can do
both. Everyone else can do neither. That spread makes the distinction visible on
screen, which is the point.

The real Leadership list is held as a code constant rather than configuration on
purpose. The population is a decision, not an environment setting, and a drifted
authorisation list fails silently: the person reports "the tab is missing", never
"authorisation is broken". An engineer implementing your work will find the real
list in `packages/hub-auth/src/leadership.ts`.

**`ADMIN_EMAILS` is a third, unrelated thing and pricing must never read it.**
It folds into the cockpit **manager** view role. Granting somebody the pricing
cost columns through it would silently promote them to manager on every cockpit
surface — the team-wide Home digest, the Unowned scope in Data to Fix, all of
it. A configuration test asserts that setting stays out of this app's
configuration entirely, precisely so nobody wires the cost columns to it.

**Collapsing `canEditConfig` and `isAdmin` into one "admin" boolean is the most
consequential thing a rebuild could get wrong here.** It changes who sees our
cost and margin on a live merchant call. Keep them as two separate flags on the
`me` object, backed by two separate lists.

There is a **fourth** thing called a role, on a different axis again: the
identity token carries `member` or `admin`. **Nothing in this application reads
it**, and a test actively asserts that the pricing code must not. It is
mentioned only so that seeing the word "admin" in a token does not tempt anyone
into wiring it up.

Guard behaviour that pins the boundary, worth reproducing:

- A rep calling the config gate gets 403.
- A caller whose token role is `admin` but who is **not** in the Leadership list
  gets **403**.
- A Leadership member whose token role is only `member` is **admitted**.
- A missing auth context is 403.
- The cost/margin flag ignores the token role entirely.

### What each role can see and do

| Capability | rep | manager | marketer |
|---|---|---|---|
| Home digest scope | own deals only | team-wide | team-wide |
| Home `fallback` when no owner record matches | `"fresh-leads"` | `null` | `null` |
| Revenue, Marketing and Onboarding tabs | full | full | full |
| Leadership meetings and contracts, create/edit/delete | yes | yes | yes |
| Deal annotations (CTA, risk) | yes | yes | yes |
| Data to Fix `scope=unowned` | server allows it; the UI treats it as a manager affordance | yes | yes |
| Trigger `POST /api/refresh` | yes | yes | yes |
| Pricing, Price a deal | yes | yes | yes |
| Pricing, Configure | only if in the Leadership list | only if in the Leadership list | only if in the Leadership list |
| Per-row cost and margin | only if in `PRICING_ADMIN_EMAILS` | same | same |

Only two things in the entire application are gated: the pricing Configure
data plane, and the cost/margin columns. Everything else, including every write,
is open to any signed-in user.

The Configure tab stays **visible** to everyone. A non-editor sees a designed
boundary card reading "Configuration is ChainIT-Leadership only" rather than a
hidden tab, and the server enforces the rule regardless of what the UI shows.

### The two "unknown user" states

1. **Not in the access policy at all.** They never reach the application; the
   edge blocks them. Nothing in the codebase renders that state.
2. **Signed in but not a sales owner.** `ownerId` is null, the Home digest
   returns `ownerResolved: false` with `fallback: "fresh-leads"` for a rep, and
   Data to Fix `scope=mine` returns an empty set correctly rather than
   accidentally returning everything. `seed/home-unmatched.json` is this state.
   It is worth keeping in the prototype; it happens in production.

The front end also delays its loading screen by 300 ms to avoid a flash on a
fast response.

---

## Data freshness and sync

### There is no cache. The database is the cache.

No key-value store, no in-memory cache, no HTTP cache. Every read endpoint runs
bounded queries against the local database, and the freshness of a number is the
freshness of the sync that wrote it. `/api/snapshot` explicitly sets
`no-store`.

Two endpoints read the CRM live on the request path, and both are bounded:

- `?view=home` makes one search for up to 25 fresh contacts.
- `GET /api/pricing/hubspot/deal/:id` makes up to four reads.

Nothing else ever touches the CRM on a request. The bulk of the contact and
company data is only ever touched by the hourly background lane.

### The cron schedule

Times are UTC. Cloudflare cron has no daylight-saving handling, which is why
everything is expressed in UTC.

| Cron expression | Lane | Cadence |
|---|---|---|
| `*/20 * * * *` | fast | Every 20 minutes |
| `17 * * * *` | heavy | Hourly at 17 minutes past, offset to avoid contention |
| `0 9 * * *` | marketing | Daily at 09:00 UTC |

The scheduled path has **no cooldown** and always pulls. Each dispatch is
handed off so the scheduler returns promptly while the work drains. A
catastrophic failure is caught and recorded as an `error` run row; the scheduler
itself never throws.

### What each lane does

**Fast lane** — six steps, every 20 minutes:

1. Read the pipeline schema. Build the closed/won stage flags in memory and
   persist stage labels and display order.
2. Read the owner list and upsert it.
3. Page through deals (16 properties) and upsert them.
4. Page through tickets (4 properties) and upsert them. Nothing reads tickets
   today.
5. Recompute the per-stage rollup and the owner leaderboard from scratch: delete,
   then insert from a grouped select.
6. Append today's per-deal snapshot row. Nothing reads that table today either.

Production holds roughly 44 deals, so this is a single cheap page — but the code
is still paginated and resumable.

**Heavy lane** — a resumable, capped crawl of contacts and companies, hourly.
The cap is **25 pages per object per run**, roughly 2,500 rows. The unconsumed
cursor is saved and the next run resumes from it. It then recomputes the
lifecycle funnel, leads by source, both growth series, the four data-quality
rows, and the local-versus-reported counts.

At 25 pages an hour, a full 50,000-contact crawl takes many hours. **While a
crawl is in flight, the counts are floors, not totals.** The UI must frame them
as "N of M synced", which is exactly what Data to Fix does.

**Marketing lane** — bounded live calls, no crawl, daily. Campaign, list, form
and email rosters; one analytics call producing the lifecycle funnel and
per-source ROI; form and campaign performance for all four windows; the
onboarding custom-object crawl (capped); the sales-to-operations handoff walk
(capped at 500 deals); and the nine-surface permission probe. A surface that
returns 403, 429, a block marker or nothing is recorded and skipped without
aborting the lane, and the run finishes with status `partial`.

### Never throw, degrade forward

Every lane and every read builder is wrapped. A rate-limited pull becomes
`partial` with the cursor saved. A catastrophic failure becomes `error`, is
still returned, and is never thrown at the caller. The schema check runs at the
top of every read path so a virgin database answers 200 with the sync-pending
shape rather than a database error.

The pending signals the UI keys off:

| Signal | Means |
|---|---|
| `sync.lastRun.fast === null` | Nothing has ever synced |
| `DealsView.syncPending` | The fast lane has never run |
| `MarketingView.syncPending` | The marketing lane has never run |
| `MarketingView.audiencePending` | The heavy lane has never run |
| `OnboardingView.syncPending` | The marketing lane has never run |
| `DataFixView.syncPending` | We hold zero rows of that object |
| `HomeDigest.hotLeads.degraded` | The live lead lookup failed |

### What "Sync Now" actually does

The button lives in exactly one place: the Sync-freshness panel of the Setup and
Data Readiness view. It is not in the header and not on every screen.

- It posts `/api/refresh?force=1` with **no lane**, so it always runs the **fast
  lane only.** Heavy and marketing are cron-only from the interface.
- It self-gates on a client-side mirror of the five-minute cooldown, ticking
  once a second. The countdown is computed during render so the first paint is
  already correct.
- Label states: `Sync now` → `Syncing…` (with a spinner) → `Sync in M:SS` while
  cooling. The accessible label mirrors the visible one.
- The cooldown anchor is the newest lane finish. When nothing has ever synced
  the view passes `1970-01-01T00:00:00.000Z`, so the button is immediately
  enabled.
- On success: a success toast. On a 429, which is the benign
  cooldown-boundary race, an **info** toast reading
  `"Already up to date — try again shortly."` Anything else is an error toast.
- On success it refreshes **only the snapshot query.** It does not refresh
  deals, home, marketing or onboarding, all of which hold their data for five
  minutes. So a manual sync updates the Setup panel and leaves the Revenue and
  Home tabs showing pre-sync numbers for up to five minutes. Reproduce that
  faithfully or fix it deliberately, and say which you did.

Note: the success toast reads `Synced · — events` because of the field drift noted
under `POST /api/refresh`.

### How long the front end holds data

| Query | Hold time |
|---|---|
| whoami, deals, marketing, onboarding | 5 minutes |
| leadership meetings, contracts, pipeline health, data fix | 30 seconds |
| snapshot, home | none set |

Data to Fix keeps the previous page's rows while a new one loads, so toggling
Companies against Contacts never flashes empty.

---

## What cannot be reproduced in Emergent

Ten things in the real cockpit depend on infrastructure the prototype does not
have. For each one, here is the stub to build instead. These are prescriptions,
not suggestions.

### 1. Cloudflare Access authentication

There is no identity token, no team domain, no audience value and no session
cookie outside Cloudflare.

**Stub:** an identity picker that selects one of the three variants in
`seed/whoami.json`, with every endpoint reading the selected identity. Keep the
`bypass_mode` flag in the payload and keep rendering the orange DEV MODE banner
when it is true — that banner is a real production affordance. **Do not build a
password login**; the real application has no credential interface at all.

Do not reproduce the 503 "Service misconfigured" branch as a user-facing state.
In production it means an operator forgot a secret, and the user's correct
experience is "the app is down".

### 2. The three view-role email lists

`MANAGER_EMAILS`, `MARKETER_EMAILS` and `ADMIN_EMAILS` are server secrets with
no interface.

**Stub:** a static map in the backend configuration, for example
`{"dana.whitlock@chainit.com": "manager", "ellen.boyd@chainit.com": "marketer"}`,
defaulting to `rep`. Keep the precedence manager, marketer, rep, and keep the
lookup case-insensitive and trimmed on both sides.

### 3. The Leadership list and `PRICING_ADMIN_EMAILS`

**Stub:** two hard-coded arrays in the backend, checked case-insensitively, with
the exact addresses given above. Keep them as **two separate lists** and keep
`canEditConfig` and `isAdmin` as **two separate flags** on the `me` object.
Collapsing them into one "admin" boolean silently changes who sees our cost on a
live merchant call.

### 4. The SQLite database at the edge

Every read in the real app is SQL.

**Stub:** MongoDB collections mirroring the entity model in `02-data-model.md`:
`owners`, `deals`, `pipelines` (one document per pipeline with an embedded,
ordered `stages[]`), `companies`, `contacts`, `lead_meetings`,
`lead_contracts`, `deal_annotations`, `deal_handoff`, `onboarding_counts`,
`sync_runs`, `object_counts`, `scope_status`, `config_revisions`, plus the
marketing rollups.

**Two SQL behaviours must be preserved explicitly, because MongoDB does not give
them to you for free:**

- **`SUM` ignores nulls; `COUNT` does not.** That is why deal `d-1018`, which
  has a null amount, is counted in `agingDeals.count` but adds nothing to
  `agingDeals.amount`. A naive `sum += deal.amount` produces `NaN`, and the
  front end has an explicit no-NaN rule. **Fix:** filter nulls out of the sum and
  not out of the count — in an aggregation, sum `{ $ifNull: ["$amount", 0] }`
  while counting every matching document; in Python, `sum(d["amount"] for d in
  rows if d["amount"] is not None)` alongside `len(rows)`.
- **A win rate with no closed deals is `null`, not `0`.** The real query divides
  by a null-guarded denominator. **Fix:** return `None` when the closed count is
  zero, and let the front end render an em dash.

### 5. The read-only CRM service

All CRM access goes through a separate read-only service over an internal
binding. This application never holds a CRM token.

**Stub:** serve the fixtures. Two failure states are worth simulating, because
the UI has designed states for them:

- **`hotLeads.degraded: true`** — a toggle that makes the Home digest return
  `{ "count": 0, "leads": [], "degraded": true }`.
- **`reason` on the deal-context endpoint** — a toggle between
  `deal_not_found` and `hubspot_error:429`, because a rep needs different words
  for "wrong link" than for "the CRM is unreachable". Both are already in
  `seed/pricing-deal-context.json`.

**Do not call the real HubSpot API from Emergent.**

### 6. The copilot service

`/api/agent/*` is a pure proxy to another service, guarded by a shared secret.
Conversation state lives in a durable object keyed by the caller's identity;
share links are minted and revoked there.

**Stub:** either omit the copilot drawer entirely, or back it with a canned
question-and-answer that returns a fixed `{ message, conversationId }`. Do not
try to reproduce share links, the cross-origin hop to the full assistant, or
file downloads. All three depend on infrastructure the prototype cannot have.

### 7. Cron triggers and the sync lanes

**Stub:** make `POST /api/refresh` a **no-op that only rewrites the sync-run
document** — set `finishedMs` to now, keep `status: "ok"`, and keep the
five-minute cooldown returning a real 429 with `retryInSeconds`. That is enough
to exercise every UI state (idle, syncing, cooling, the 429 info toast) with no
actual sync. **Do not build a background job.**

Keep two honest states while you are there: `truncated: true` on an onboarding
step, and `status: "partial"` on the heavy lane. Those "this number is a floor"
states are a deliberate product decision, not noise.

### 8. Assets-first routing

The real configuration has a Cloudflare-specific setting forcing the Worker to
run before static assets for `/api/*`. It has no analogue in a FastAPI and React
stack. Ignore it.

### 9. Things that do not exist yet and must stay honest

- **Tasks.** `tasksDueToday.available` is hard-coded `false` because no task
  data is synced at all. Render the calm "tasks not synced yet" tile. **Do not
  invent task data.**
- **Per-stage probability.** The CRM has one, the sync reads it, and it is never
  stored — only the derived closed and won booleans are. The Forecast tab's
  weights are a positional heuristic running from a floor of 0.1 to a ceiling of
  0.8, and must be framed as directional. Never label them as the CRM's
  forecast.
- **`daysInStage`** is days since last modification, not since stage entry. Keep
  the footnote.
- **The daily per-deal snapshot table** is written on every fast sync and read by
  nothing. It is a deliberate seed for a feature that does not exist. **Do not
  build a UI for it.**

### 10. Real production magnitudes

**Unverified.** Code comments say roughly 44 deals, 50,000 contacts and
43,000 companies. The fixtures use 40 deals, 12,400 contacts and 8,320
companies — plausible, but invented. Do not present any of these as measured
figures.

---

## Related files

| You want | Read |
|---|---|
| The entity model and every enumeration | `02-data-model.md` |
| The fixtures themselves | `seed/README.md` and the JSON files beside it |
| What the screens do with this data | `01-product/02-sales-cockpit-spec.md` |
| The pricing configuration tree in detail | `02-pricing-engine/03-config-schema-and-defaults.md` |
| What the prototype must not change | `05-emergent-setup/04-guardrails-do-not-change.md` |
