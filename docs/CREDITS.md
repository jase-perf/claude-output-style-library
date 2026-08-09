# Credits

Full attribution for every adapted style. These lines used to live inside the
style files; they moved here so the prompts stay pure instructions (see
[format-guide.md](format-guide.md)). **This file is the authoritative location
for the copyright notices MIT requires be preserved** — the style bodies no
longer carry credit lines, so there is nowhere else for them to live.

## Copyright notices preserved under MIT

Reproduced from [LICENSE](../LICENSE), each verbatim as that project's own
LICENSE file states it. Where the notice uses a handle, the person's name
follows in parentheses. The bracket names the style that adapts the work.

- Copyright (c) 2026 Serge Shima (`smixs`, [awesome-claude-output-styles](https://github.com/smixs/awesome-claude-output-styles)) — earlier versions of this collection
- Copyright (c) 2026 Matt Pocock ([mattpocock/skills](https://github.com/mattpocock/skills)) — [`one-fact-per-sentence`]
- Copyright (c) 2026 Julius Brussee ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)) — [`short-answers`]
- Copyright (c) 2026 Carlos Mello (Carlos Duplar Mello, [carlosduplar/caveman-output-style-claude-code](https://github.com/carlosduplar/caveman-output-style-claude-code)) — [`short-answers`]
- Copyright (c) 2026 Ayoub Ghriss ([ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)) — [`where-we-are`]
- Copyright (c) 2026 AminBlg (Amin Boulegroun, [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish)) — [`one-fact-per-sentence`]
- Copyright (c) 2026 Peter Yang ([petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop)) — [`plain-prose`]
- Copyright (c) 2025 Siqi Chen ([blader/humanizer](https://github.com/blader/humanizer)) — [`plain-prose`]
- Copyright (c) 2026 Conor Bronsdon ([conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing)) — [`plain-prose`]
- Copyright (c) 2025 Hardik Pandya ([hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop)) — [`plain-prose`]
- Copyright (c) 2025 Sruthi Reddy ([sruthir28/enterprise-ai-skills](https://github.com/sruthir28/enterprise-ai-skills)) — [`decision-brief`]

## People credited below who appear elsewhere only as repo handles

Named here so attribution does not depend on a reader resolving a GitHub slug
to a person: **Siqi Chen** (`@blader`), **Conor Bronsdon**
(`@ConorBronsdon`), **Joe Cotellese**, **Sruthi Reddy** (`sruthir28`),
**Hardik Pandya** (`@hvpandya`), **Eric Evans** (*Domain-Driven Design*),
**Reijnierse et al.** (JCOM 2025).

## Understand

- **one-fact-per-sentence** — the [ASD-STE100 standard](https://www.asd-ste100.org/),
  aerospace's controlled language since 1983; popularized for AI agents by
  [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish) and
  [Matt Pocock's wait-what](https://github.com/mattpocock/skills) (both MIT).
  Ubiquitous language — use the project's own vocabulary — is Eric Evans,
  *Domain-Driven Design*, by way of Pocock's skill. This style absorbed
  `wait-what` in August 2026: ASD-STE100 was the whole of that style's rule 2
  and the two shipped near-identical worked examples. Pocock's grounding and
  re-pitch rules were left out, because `wait-what` began as a skill for
  re-explaining output that already exists, which is not this style's job.
- **one-analogy** — grounded in IEEE ProComm on
  source/target/grounds/tension; Reijnierse et al. (JCOM 2025) on
  single-domain metaphors; the CMU "Communicating Technical Ideas" metaphor
  checklist. This style absorbed `eli15` in August 2026 and inherits its
  lineage — ELI5 prompt research and the r/explainlikeimfive house rules —
  along with the length bound that kept an explanation to something you could
  paste into a message. `eli15` ran the same method less thoroughly; the only
  variable a reader could perceive between them was length.
- **your-turn** — Richard Feynman's technique; the AI "skeptical student"
  variant popularized by Feynman-prompt guides in the prompting community.
- **small-words** — Randall Munroe:
  [Up Goer Five](https://xkcd.com/1133/), *Thing Explainer*, and the
  [Simple Writer](https://xkcd.com/simplewriter/) checker.
- *(removed August 2026)* **ladder** adapted the progressive-explanation
  pattern from r/PromptEngineering ("explain like I'm 5, then 15, then a
  professional"). It was cut as a concatenation of `small-words`,
  `one-analogy` and a plain answer, at three times the length. No rule of it
  survives elsewhere, so nothing here is claimed on its behalf.

## Business

- **decision-brief** — Barbara Minto's
  [Pyramid Principle](https://www.barbaraminto.com/); BLUF (US military
  doctrine); consulting-skill formulations by
  [sruthir28/enterprise-ai-skills](https://github.com/sruthir28/enterprise-ai-skills)
  (MIT) and Joe Cotellese's BLUF-for-Claude-Code writeup.
- *(removed August 2026)* **smart-brevity** adapted Smart Brevity by Jim
  VandeHei, Mike Allen and Roy Schwartz (Axios). Across four bake-off prompts
  it and `decision-brief` opened with the same claim, listed the same facts in
  the same order, and closed on the same point, differing only in which labels
  sat over the list. `decision-brief` implements Minto rather than Axios, so
  no rule of Smart Brevity is claimed to survive in it.

## Terse

- **short-answers** — the compression discipline of
  [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (the
  original skill, MIT) and
  [carlosduplar/caveman-output-style-claude-code](https://github.com/carlosduplar/caveman-output-style-claude-code)
  (the output-style formulation, MIT), which this style absorbed in August
  2026. What carried over is the part that did the work: a real answer-length
  budget, answer-then-reason-then-next-step, whole words over invented
  abbreviations, and the closing line naming what was not checked. What was
  left behind is the caveman grammar — the dropped articles and bare
  noun-verb fragments — which four bake-off prompts showed added no
  information to the answer.
- **where-we-are** — [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)
  (MIT), itself adapted from *The Adult ADHD Tool Kit* (Ramsay & Rostain).
- **plain-prose** — Joe Cotellese's generic-sentence test; the pattern taxonomies
  of [blader/humanizer](https://github.com/blader/humanizer) and
  [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing)
  (both MIT). This style absorbed `no-ai-slop` in August 2026, so three rules
  here are Peter Yang's ([no-ai-slop](https://github.com/petergyang/no-ai-slop),
  [@petergyang](https://x.com/petergyang), MIT): show-don't-tell with a number
  in place of an adjective, active voice with the subject doing the action, and
  "open it up, don't dumb it down". Yang's portability test and this style's
  generic-sentence test were already the same test under two names. His
  commit-to-one-recommendation rule was deliberately not carried over: this
  style governs how a sentence is built, not what position to take. A
  human-readable field guide to the 2026 Claude-isms it displaces:
  [claudisms-2026.md](claudisms-2026.md).

  It also absorbed `coach` in August 2026, and with it one rule — criticism
  arrives holding the fix. `coach` adapted Hemingway App's operationalized
  rules, Paul Graham's
  ["Write Like You Talk"](https://paulgraham.com/talk.html), and the
  scoring-gate idea from
  [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) (MIT),
  whose notice now sits against this style. Its other mechanics were already
  here or in `decision-brief`; what was left after subtracting them was a
  register, and a register is not something a user can pick between.

---

*(removed August 2026)* The five persona styles this collection once carried —
**street**, **gen-z**, **sportscaster**, **yoda**, **bedtime-story** — were cut
as the wrong default for a library people install at work. No rule of them
survives elsewhere here, so nothing is claimed on their behalf.
