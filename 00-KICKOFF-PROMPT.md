# The kickoff prompt

**Paste the block below as your very first message in a new Emergent project.**
Do not shorten it. Attach the bundle first (see
`05-emergent-setup/01-how-to-use-this-bundle.md`, Step 1).

---

```text
CONTEXT

I am rebuilding an existing internal tool as a prototype. It is called the
ChainIT Sales Cockpit. It already exists in production; I am not designing
something new. My job is to prototype changes to its UI and its business rules,
then hand screenshots and flows to an engineer who implements them for real.

The users are about 25 people at a payments company: sales reps, sales
managers, marketing, and operations. It is an internal dashboard, not a
consumer product. Density and speed matter more than delight. These people open
it several times a day and know what they are looking for.

I have attached a documentation bundle. Read all of it before building. The
files that matter most, in order:

  01-product/01-what-this-is.md          — what this product is and who uses it
  03-design-system/01-design-brief.md    — how it must look
  03-design-system/02-tokens.css         — the exact colours and fonts
  04-data-contracts/02-data-model.md     — the data shapes
  04-data-contracts/seed/                — fake seed data to load into MongoDB
  01-product/02-sales-cockpit-spec.md    — the screens, in detail
  02-pricing-engine/                     — the pricing business rules and math

OBJECTIVE FOR THIS FIRST BUILD

Build ONLY the application shell. Nothing else. Specifically:

1. A sticky top header containing:
   - the wordmark "Sales Cockpit" on the left
   - a small monospace caption next to it reading "HubSpot · read-only"
   - a light/dark theme toggle on the right (sun/moon icon, no label)
   - a role switcher dropdown on the right with these five options:
     Rep, Manager, Marketer, Config editor, Admin
     (this is a prototyping device so I can preview each role's view; it is not
     a production feature)

2. Under the header, a two-level navigation switcher:
   - Row 1 — five sections: Home, Revenue, Marketing, Leadership, Pricing.
     Pinned to the RIGHT of that same row, separated from the five, is a sixth
     destination: "Setup & Data Readiness". It is not a section — it has no
     sub-tabs — and it is reachable from everywhere.
   - Row 2 — the active section's sub-tabs
   - The active item in each row is marked with the accent colour and an
     underline. Hover uses the strong-surface token. Focus shows a visible ring.
   - Tap targets are at least 44px.

   The sections and their sub-tabs, with the DEFAULT tab marked:
     Home        → Today*, Signals, Onboarding
     Revenue     → Pipeline*, Forecast, Owners, Velocity, Stuck, Win / Loss
     Marketing   → Lead Funnel*, Source ROI, Audience, Campaigns, Forms & Email
     Leadership  → Meetings*, Pipeline Health, Contracts, Data to Fix
     Pricing     → Price a deal*, Configure

   Selecting a section always lands on its first tab.

3. Routing. Use a URL hash of the form #/section/tab — for example
   #/leadership/meetings or #/pricing/price. Also support:
   - #/setup for the Setup destination
   - a bare #/pricing, which must land on "Price a deal"
   - an unknown hash, or an unknown tab inside a known section, which falls back
     to that section's default tab rather than showing an error. There is no 404
     route.
   Opening any valid URL directly must land on the right tab, and the browser
   back button must work.

3a. IMPORTANT — accessibility fix. Make the tab rows fully keyboard operable:
   ArrowLeft and ArrowRight move between tabs, Home and End jump to the first
   and last, and Enter or Space activates. Give each tab panel role="tabpanel"
   and wire aria-controls to it. The existing production app has a roving
   tabindex with no arrow-key handler, which leaves inactive tabs unreachable by
   keyboard. Do not reproduce that — fix it.

4. Every tab body renders a designed placeholder for now: a centred card on the
   page canvas with the tab name, one line of muted explanatory text, and a
   single small accent-coloured mark. It must read as deliberate and calm, not
   as a broken or empty page.

5. Page shell: content is centred with a maximum width of 1200px and 21px side
   gutters, rising to 28px at 640px and above. The header is sticky with a
   hairline bottom border and a slightly translucent, blurred background.

   (Those gutter numbers look odd on purpose. The production app runs a 14px
   root font size with a rem-based spacing scale, so its nominal "24px" and
   "32px" gutters actually render at 21px and 28px. Use the real rendered
   values.)

6. Dark mode is class-driven: a `dark` class on the root html element re-points
   the colour custom properties. The choice persists in localStorage. Default
   is light. Do not auto-apply the OS preference.

CONSTRAINTS

- Use ONLY the colour and typography tokens from the attached tokens.css. Do
  not introduce any other colour, and do not use a purple or blue gradient.
- No drop shadows. Elevation is expressed through surface tone and hairline
  borders only.
- Do not build any of the actual screens yet. Shell only. I will ask for the
  screens one at a time.
- Do not add a sidebar, a footer, a search bar, a notification bell, or an
  onboarding modal. None of those exist in this product.
- Do not connect to any external API. Everything runs on local seed data.
- Icons: use lucide icons at 16px with a stroke width of 2.

BEFORE YOU BUILD

Tell me what you understood, list the sections and tabs back to me, and name
the colours you plan to use for canvas, surface, ink, muted ink, hairline and
accent. Wait for my confirmation before writing any code.
```

---

## Answering Emergent's planning questions

Emergent will ask a few things before it builds. Recommended answers:

| It asks | Say |
|---|---|
| Which LLM key — universal or your own? | Universal. This prototype has no AI features. |
| Do you need authentication? | No real auth. The role switcher is a plain dropdown with no login. |
| Design framework preference? | Tailwind CSS, using the custom properties from the attached tokens.css. No component library with its own opinions. |
| Should I add sample data? | Yes, but only from the attached seed fixtures. Do not generate your own sample data. |
| Ready to build? | Only after it has read the sections and tabs back to you correctly. If it gets the nav wrong, correct it before it builds — that mistake propagates into every screen. |

## What to do immediately after the shell builds

1. Open the preview. Click all five sections and every sub-tab.
2. Check the URL changes to `#/section/tab` and that pasting one back in works.
3. Toggle dark mode. Reload. It should still be dark.
4. Compare the colours against the real app's screenshots. If anything drifted,
   fix it now — before there are nine screens to fix it on.

Then move to `05-emergent-setup/02-prompt-library.md` and build the design
system, then the screens, one at a time.
