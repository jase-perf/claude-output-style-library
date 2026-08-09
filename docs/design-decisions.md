# Design decisions

Why this library is shaped the way it is. The [README](../README.md) states the
conclusions; this file gives the reasoning and the sources.

A style file's body is injected verbatim into the system prompt at session
start. Every line it contains costs tokens and attention on every turn of every
session it is active, which is what makes these decisions worth writing down
rather than settling by taste.

## 1. No banned-word lists — but not for the reason everyone gives

Most style collections ship a list of forbidden words: never say "delve", never
say "it's worth noting". These styles describe the target voice instead,
following Anthropic's own guidance under *Control the format of responses* —
"**Tell Claude what to do instead of what not to do**".

The usual justification for that, which this library used to repeat, is that
banned words summon the banned words. **That is false for a model as capable as
Claude.** It has been measured once, in Castricato et al., *Suppressing Pink
Elephants with Direct Principle Feedback*
([arXiv:2402.07896](https://arxiv.org/abs/2402.07896)), Table 1 — rate of
mentioning a forbidden topic, without → with the prohibition:

| Model | Without | With ban | Effect |
|---|---|---|---|
| OpenHermes-7B | 0.33 | 0.36 | backfires, +3pp |
| OpenHermes-13B | 0.34 | 0.34 | none |
| Llama-2-13B-Chat | 0.33 | 0.25 | helps |
| GPT-4 | 0.33 | 0.13 | helps most, −61% relative |

*If you check that table against the paper:* its caption ("Rate at which the
model talks about the Pink Elephant, lower is better") and the bullet defining
the same column ("proportion of examples where the model successfully
refrained") point in opposite directions. The caption, the narrative text, and
the signed deltas in both Table 1 and the appendix all agree with each other, so
the reading above is the right one — but the contradiction is in the source, not
in this summary.

The backfire is real only in the weakest model tested, and it *reverses* with
capability. So prohibitions are not purged from these styles: a prohibition
stays wherever it states the constraint most exactly, and every safety
prohibition is unconditional. What changed is that the ones that remain are
written the way Anthropic writes theirs — **paired with the alternative in the
same breath**, and **given their reason**, since "Claude is smart enough to
generalize from the explanation."

The practical upshot: [claudisms-2026.md](claudisms-2026.md) is a field guide
you can read, rather than a banlist spending your session's system-prompt budget
in every conversation.

## 2. Eight styles, not nineteen — and the first attempt to cut them failed

Collections grow. This one reached nineteen styles across four tiers, most of
which nobody could choose between. Pruning turned out to be harder than it
looks, and the first attempt got the test wrong in a way worth describing,
because the same mistake is easy to make.

That round asked an adversary to *refute* each proposed merge by finding a
single prompt where two styles' rules produce different answers. That bar is
trivially easy to clear — five of six merges were refuted, almost nothing was
cut, and the library was still full of entries nobody could choose between.
Rules differing on paper is not the same as answers differing on screen.

The second round tested the output instead. The same four questions were written
out in all twelve remaining styles, with the invented details held identical so
style was the only variable, and the results compared side by side. Twelve
styles produced four or five distinguishable answers:

- **`caveman`** added no information across four prompts — it was the same
  answer with the articles removed. `short-answers` now covers that ground,
  keeping the compression discipline without the dropped-article register.
- **`smart-brevity`** came in at 178 words against `decision-brief`'s 178, same
  facts in the same order, differing only in which label sat above the list.

A separate test showed only the names and one-line descriptions to a reader who
could not see the rules, and asked them to pick a style for eight realistic
tasks. Names that produced confident wrong picks were the ones that got
replaced. That is why nothing here is named after a person, a book, or an
acronym any more.

Five persona styles — `street`, `gen-z`, `sportscaster`, `yoda`,
`bedtime-story` — were cut on a different test. Nothing is wrong with them; they
are simply the wrong default for a library people install at work.

Full record of what merged into what, and which rules survived each merge:
[CREDITS.md](CREDITS.md).

## 3. The hardest instruction to follow gets a countable check

*Analysing Zero-Shot Readability-Controlled Sentence Simplification*
([arXiv:2409.20246](https://arxiv.org/abs/2409.20246), COLING 2025) found that
"all tested models struggle to simplify sentences (especially to the lowest
levels)" — the exact thing `small-words` and `one-fact-per-sentence` ask for.

So no style here trusts its instructions to hold on their own. All eight carry a
`## Verify before sending` section with a countable self-check on the shape of
the draft ("any sentence over 20 words?", "is the analogy's breaking point
stated?"), and the two simplification styles are why that rule exists.

The check is deliberately about format only, never correctness. Anthropic's
Claude Opus 5 guidance says explicit verification instructions cause
over-verification and should be removed — and it is talking about correctness. A
shape check is a different thing and earns its place, because the measured
dominant failure mode is *silent omission* of a rule, which is exactly what a
shape check catches.

## 4. Sources are read at the source

Every citation above was read in the original, not through a summary of it.
Claims that reached this repo through research notes and did not survive that
check were removed rather than softened — including the ban-list claim in
section 1, which this project's own docs asserted for several weeks.

**What is not claimed:** no benchmark shows these styles produce measurably
better output than an unstyled Claude. The methods they implement — the Minto
Pyramid, ASD-STE100, the Feynman technique — are established practice with
decades of use behind them, credited to their authors in [CREDITS.md](CREDITS.md).
That is not evidence that this library's implementations of them work better
than the alternatives.

## 5. Why the repo carries tests at all

The invariants that make these styles safe would otherwise rest on an author's
discipline alone, and a style whose guardrails block quietly dropped the
security clause would install and run exactly like a correct one.

Writing the tests paid for itself immediately. They caught an untestable
`Write-Host` in `install.ps1 -List`, a broken list parser, and the fact that
`install.sh` died with an exit-9009 Microsoft Store advert on Windows instead of
falling back to its own python-free branch.

Line endings are pinned by [`.gitattributes`](../.gitattributes) for a related
reason: without it, a commit made on a Windows machine whose git has
`core.autocrlf=false` ships `install.sh` with a CR in the shebang, and every
macOS and Linux user gets `bad interpreter: /bin/sh^M`. CI checks for that on
every push.
