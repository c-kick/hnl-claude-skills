---
name: user-review
description: >
  Simulate an objective first-time user review of a webpage or UI from the perspective
  of the target audience — no prior project context, no insider knowledge. Use this skill
  when the user asks things like "what would a user think of this page", "review this as
  a visitor", "give me a first-impression review", "pretend you're a patient/customer/prospect
  looking at this", "user test this page", or any variant of "look at this through fresh eyes".
  Also use proactively when the user shares a URL and seems to want qualitative UX or
  communication feedback rather than technical analysis. Requires the browser-eyeballs
  skill (Puppeteer MCP).
---

# User Review

A first-impression user review of a webpage or UI, conducted from the perspective of the prototype target audience — someone with no project knowledge, no brand familiarity, and no insider context. This skill borrows the visual access mechanism of `browser-eyeballs` but redirects its output through a structured, persona-driven UX lens.

## When to Use

- User asks for a "user perspective", "fresh eyes review", or "first impression" of a page/UI
- User wants to know if their target audience would understand, trust, or be compelled by a page
- User shares a URL and wants qualitative communication or UX feedback (not technical analysis)
- You've just built or modified a frontend and want to reality-check it against its intended audience

## Dependencies

Requires the `browser-eyeballs` skill. Before starting, confirm that some browser automation or screenshot capability is available in the active agent session. If not, halt and advise the user to configure browser inspection for the current agent (see browser-eyeballs/SKILL.md).

---

## Step 1 — Define the Persona

Before looking at anything, establish **who** is visiting this page. Two paths:

### A) User specifies the audience

Use their description literally. Example: *"someone with obesity looking for treatment options"*, *"a GP considering a referral"*, *"a procurement manager comparing vendors"*.

### B) Infer from context or the page itself

If the user doesn't specify:

1. Ask once: *"Who's the intended visitor — can you give me a one-liner on the target audience?"*
2. If they don't answer or say "figure it out", load the page first (Step 2), take a screenshot, infer the audience from the page's messaging, then proceed.

**Persona must include:**

- Role / situation (who they are, why they landed here)
- What they probably want to know or do
- What they do NOT know (no brand history, no internal context, no technical background unless it's a dev tool)
- Their likely emotional register (anxious, skeptical, curious, comparison-shopping, etc.)

Document the persona briefly at the top of the review output. This is the lens everything else is seen through.

---

## Step 2 — Load and Observe

Use `browser-eyeballs` to navigate to the target URL and take an initial screenshot. Follow the launch sequence from that skill (include `launchOptions` on the first call in the session).

After the first screenshot:

- Set viewport to `1440x900` (standard desktop, unless the target audience is likely mobile — then use `390x844`)
- Wait for any obvious loading states to resolve
- Scroll down to capture below-the-fold content if the page is long (use `puppeteer_evaluate` to scroll, then screenshot again)

Do not start analyzing until you have at least one above-the-fold and one scrolled screenshot.

---

## Step 3 — The Review

Conduct the review **strictly from inside the persona**. You have no knowledge of:

- The organization's internal naming conventions
- What the page is *supposed* to say
- Decisions made during design or development
- Other pages on the site

You are a first-time visitor. You have been on this page for about 10 seconds.

### Review Structure

Output the review under these headings. Keep each section tight — 2-5 sentences or a focused bullet list, no filler.

---

#### Who am I looking at?

*Within 5 seconds of arrival, can a visitor tell who this is and what they do/offer?*

State plainly what a first-time visitor would understand (or not understand) about the organization and its purpose, based only on the above-the-fold content.

---

#### What am I supposed to do here?

*Is the primary call-to-action clear? Is the intended next step obvious?*

Evaluate whether the page has a clear primary action and whether the persona would know what to do next. Note if there are competing CTAs, or if the CTA copy is vague ("more info", "contact us") vs. specific and benefit-driven.

---

#### What questions do I still have?

*What would a target visitor want to know that the page doesn't clearly answer?*

List the 2-5 most likely unanswered questions from the persona's perspective. These are the information gaps that create hesitation or cause people to leave.

---

#### Do I trust this?

*Does the page signal credibility, safety, and legitimacy to someone unfamiliar with the brand?*

Evaluate trust signals: professional design quality, certifications, social proof, recognizable affiliations, contact information, privacy indicators. Note anything that might raise a red flag for a cautious first-time visitor.

---

#### What's getting in my way?

*Friction, confusion, or cognitive load — anything that slows down or blocks the visitor.*

Cover: confusing terminology, jargon the persona wouldn't know, unclear navigation, too much text before any value is established, layout issues that obscure priority content, or anything that demands more effort than a first-time visitor would spend.

---

#### What's working?

*At least 2 things the page does well from the persona's perspective.*

Be specific — not "the design looks clean" but "the headline immediately addresses the visitor's likely pain point before asking them to do anything."

---

#### Verdict

A one-paragraph summary from the persona's POV. Would they stay, convert, or leave? What's the single most impactful thing to fix?

---

## Output Format

Start with:

```
**Persona:** [one-sentence description of the reviewer]
**URL reviewed:** [URL]
**Viewport:** [width x height]
```

Then the review sections above.

End with an optional **Technical aside** (kept separate from the review) if you noticed issues that the persona wouldn't see but the developer/operator would care about — e.g., broken elements, layout bugs at the tested viewport, missing alt text, visible console errors inferred from behavior.

---

## Tone and Voice

Write the review **as an analyst describing the persona's experience** — not as the persona speaking in first person. Keep it direct and specific. No hedging like "it might be possible that...". State what works, what doesn't, and why, from the persona's frame of reference.

Avoid:

- Complimenting design choices that don't serve the persona
- Generic UX advice not grounded in what you actually saw
- Softening findings out of politeness — this is an honest assessment, not a client presentation

---

## Notes

- If the page requires authentication and you can't get past a login screen, report that plainly and review the login experience itself from the persona's angle
- If the page is not yet live (localhost / staging), note it and apply the same review process
- For multi-page flows (e.g., a conversion funnel), review each step separately and note drop-off risk at each transition
- Mobile vs desktop: if the target audience is likely mobile-dominant, always switch to mobile viewport and explicitly note any differences in experience
