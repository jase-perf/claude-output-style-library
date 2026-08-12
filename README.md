# Claude Output Style Library

[![CI](https://github.com/jase-perf/claude-output-style-library/actions/workflows/ci.yml/badge.svg)](https://github.com/jase-perf/claude-output-style-library/actions/workflows/ci.yml)
[![license](https://img.shields.io/github/license/jase-perf/claude-output-style-library?style=flat)](LICENSE)

**Make Claude Code speak in a style that is easier to understand and better
suited to your project.**

Claude's default way of speaking gets crowded with jargon, abbreviations, and
shorthand you have to decode, and it reaches for the same shape whatever you
ask. These eight files let you pick a different voice, and change nothing else
about how Claude works.

An output style is a Claude Code feature: a markdown file that replaces part of
the system prompt, so a voice instruction lands in the same slot as Claude's own
built-in styles instead of competing for attention in your context window. That
is why it holds when a "be concise" line in CLAUDE.md stops working. Each of the
eight here is built on a published writing method — the Minto Pyramid,
ASD-STE100 controlled English, the Feynman technique — and credited to whoever
wrote it down.

[The styles](#the-styles) · [Install](#install) ·
[Why this works](#why-this-works-when-a-claudemd-rule-doesnt) ·
[How it's built](#how-this-library-is-built)

---

## See the difference

One question, put to Claude Code once with each style active, and once with
none. **Every answer below is complete and unedited** — nothing is trimmed, so
the lengths are yours to compare. They run from 102 words to 435.

> **Should I use a UUID or an auto-increment integer for a primary key?**

<table>
<tr><th width="22%" align="left">Style</th><th align="left">The complete answer it gave</th></tr>

<tr><td valign="top">

**no style**

Claude Code with nothing installed, for comparison. A good answer — dense, and written for a reader who already knows the words.

<sub>314 words</sub>

</td><td valign="top">

> For most applications, use an auto-increment integer (a `bigint` identity column) as the primary key, and only reach for UUIDs when you have a specific reason. Here's the reasoning.
>
> Auto-increment integers are smaller (8 bytes vs 16), faster to join and index, and inserts append to the end of the index rather than scattering across it. That last point matters more than people expect: random UUIDv4 values cause index fragmentation and poor cache locality, which degrades write throughput as tables grow — especially on MySQL/InnoDB, where the primary key is the clustered index and every secondary index carries a copy of it.
>
> UUIDs earn their cost in a few situations:
>
> - **Keys must be generated before hitting the database** — offline clients, distributed services, or batch imports where you can't wait for the database to assign an ID.
> - **Merging data across databases or shards**, where sequential IDs from different sources would collide.
> - **You expose IDs publicly and don't want them enumerable.** Sequential IDs leak information (`/orders/10432` tells competitors your volume, and invites people to try `/orders/10433`).
>
> If you do go with UUIDs, use **UUIDv7**, not v4. It's time-ordered, so it keeps the append-mostly insert pattern that makes integer keys fast, while still being globally unique and non-colliding. Postgres 18 generates them natively (`uuidv7()`); on earlier versions or other databases, generate them in the application. Store them in a native `uuid` type, never as a 36-character string.
>
> A common middle path if your only concern is enumerable public IDs: keep the bigint primary key internally, and add a separate unique column (UUID, or a short random slug) for external URLs and APIs. You get fast joins internally and opaque identifiers publicly, at the cost of one extra index.
>
> So: bigint by default, UUIDv7 when clients generate keys or data merges across systems, and the two-column approach when you just don't want IDs guessable.

</td></tr>

<tr><td valign="top">

**[`plain-prose`](output-styles/plain-prose.md)**

For everyday questions: paragraphs instead of bullet lists, and no set length. Install this one if you install only one.

<sub>256 words</sub>

</td><td valign="top">

> Default to a bigint auto-increment, and reach for a UUID only when you need one of the three things it buys you.
>
> The integer wins on storage and index behavior. It's 8 bytes against a UUID's 16, and every foreign key and secondary index repeats the primary key, so the size difference multiplies across the schema. More importantly, sequential values append to the right edge of the B-tree, while random UUIDv4s land on random pages — in a clustered-index engine like InnoDB or SQL Server that means page splits, a cold buffer pool, and inserts that slow down as the table grows.
>
> A UUID earns its cost in three situations: rows are created on clients or across multiple writers before the database is reachable, so you can't wait for the sequence; you merge or shard data across databases, where sequences collide; or the ID appears in URLs and a sequential value would let people enumerate your records or read your growth rate off the numbers.
>
> If any of those apply, two fixes avoid the index problem. Use UUIDv7 instead of v4 — its leading bits are a timestamp, so inserts stay roughly sequential and the B-tree behaves. Or keep the bigint as the internal primary key and add a separate unique UUID column that only the outside world sees; joins stay cheap and the public IDs stay unguessable.
>
> So: single Postgres or MySQL database, IDs not exposed in URLs — bigint, done. Distributed writes or public IDs — UUIDv7, or bigint plus a public UUID column.

</td></tr>

<tr><td valign="top">

**[`short-answers`](output-styles/short-answers.md)**

For quick questions when you do not want an essay: it aims for 100 words, then names what it did not check.

<sub>102 words</sub>

</td><td valign="top">

> Default to a `BIGINT` auto-increment: it's half the size of a UUID, keeps B-tree inserts append-only, and makes debugging easier. Choose a UUID when clients must generate IDs offline, when rows merge across databases or shards, or when the ID appears in URLs and you don't want to leak row counts or invite enumeration. If you do, prefer UUIDv7 — random v4 keys scatter inserts across the index and hurt cache locality. A common middle path: integer primary key internally, separate UUID column for anything public-facing.
>
> Not checked: your database and whether IDs are ever exposed externally — that decides the tradeoff.

</td></tr>

<tr><td valign="top">

**[`decision-brief`](output-styles/decision-brief.md)**

For an answer you will paste into a status update or hand to someone who was not there: the verdict first, then numbered reasons under it.

<sub>309 words</sub>

</td><td valign="top">

> **Default to a `bigint` auto-increment key, and switch to UUIDv7 only when a specific need forces it** — distributed ID generation, publicly exposed IDs, or merging data across databases. This is a question where the right answer depends on three concrete trade-offs:
>
> 1. **Write and index performance favors integers.** Random UUIDs (v4) scatter inserts across the B-tree, fragmenting the primary index and blowing out cache — on clustered-index databases like MySQL/InnoDB this can cut insert throughput several-fold at scale. Sequential integers (and time-ordered UUIDv7) always append to the right edge, so the hot pages stay in memory.
>
> 2. **Size compounds everywhere.** A UUID is 16 bytes versus 8 for a bigint, and the primary key is duplicated into every secondary index and every foreign key that references it. On a large schema that's a real difference in index size and join speed, not a rounding error.
>
> 3. **UUIDs win when the ID leaves the database.** Sequential IDs are guessable and leak business volume (`/orders/10432` tells a competitor your order count — this is the classic enumeration problem). UUIDs also let clients, mobile apps, or multiple services mint IDs without a round-trip to one database, and they merge cleanly across shards or environments.
>
> Two refinements worth knowing: if you do choose UUIDs, use **UUIDv7** (time-ordered, standardized in RFC 9562), not v4 — it keeps the distributed-generation and non-guessability benefits while fixing the index-locality problem. And a common hybrid is a bigint primary key internally plus a separate unique UUID column for anything exposed in URLs or APIs, which gets you fast joins and unguessable public IDs at the cost of one extra index.
>
> So: single database, IDs never shown to users → bigint identity. Client-generated IDs, public URLs, or multi-region writes → UUIDv7. If you tell me the database and the app's shape, I can make the call more specifically.

</td></tr>

<tr><td valign="top">

**[`where-we-are`](output-styles/where-we-are.md)**

For work that runs over days or gets handed to someone else: it asks for a line in every answer saying where things stand — here, that nothing has been done yet.

<sub>281 words</sub>

</td><td valign="top">

> Default to a 64-bit auto-increment integer (`BIGINT`/`bigserial`/identity column) unless something specific pushes you to UUIDs — it's smaller (8 bytes vs 16), faster to join and index, and inserts append to the end of the B-tree instead of splattering across it.
>
> Where we are: no code touched — this is a design recommendation, based on your question alone.
>
> Reach for a UUID when one of these is actually true:
>
> 1. IDs must be generated outside the database — client-side, offline-first apps, or multiple writers/services minting IDs without coordinating.
> 2. You'll merge data across databases or shards, where sequences would collide.
> 3. IDs are exposed publicly and must not be guessable or enumerable (`/orders/10412` leaks volume and invites `/orders/10413`).
>
> If you do use UUIDs, use **UUIDv7**, not v4. v4 is random, so every insert lands at a random spot in the primary index — on MySQL/InnoDB (which clusters rows by PK) that means page splits, cache misses, and a bloated index; Postgres suffers less but still pays in index size and WAL. v7 is time-ordered, so inserts stay roughly sequential and you keep most of the integer key's insert performance.
>
> The hybrid worth knowing: `BIGINT` primary key internally (cheap joins, all foreign keys reference it) plus a UUID column with a unique index as the public identifier in URLs and APIs. That's the usual answer when the only reason for UUIDs is "don't expose sequential IDs" — you get the security property without making every join and index pay 16 bytes.
>
> So: single database, IDs not publicly exposed or enumerability doesn't matter → integer. Distributed generation or merge-ability → UUIDv7. Just hiding IDs from users → integer PK + UUID external ID.

</td></tr>

<tr><td valign="top">

**[`one-fact-per-sentence`](output-styles/one-fact-per-sentence.md)**

For a reader new to the subject, or reading in a second language: one fact per sentence, and no sentence over 20 words.

<sub>309 words</sub>

</td><td valign="top">

> The short answer: use an auto-increment integer by default. Use a UUID only when a real need exists.
>
> A UUID is a 128-bit identifier, usually random. An auto-increment integer is a number that the database creates in sequence.
>
> **Why the integer wins for most apps:**
>
> - The database creates each key. Your code does nothing.
> - An integer key uses 8 bytes (as `bigint`). A UUID key uses 16 bytes.
> - The key also appears in every index and every foreign key. A small key keeps all of them small.
> - New integer keys are sequential. Sequential keys keep index writes fast and compact.
> - Random UUID keys (version 4) scatter writes across the index. Inserts and caches become slower at scale.
> - Humans can read integer keys. Support work and debugging become easier.
>
> **When a UUID is the correct choice:**
>
> - The client must create the key before it reaches the server. Example: an offline-first mobile app.
> - Many databases or services create keys at the same time. Integers would then collide.
> - You must merge rows from separate databases. UUID keys do not collide.
> - The key appears in a public URL. A sequential integer there lets attackers enumerate rows. It also reveals your row counts.
>
> **If you choose a UUID, choose version 7.** Version 7 starts with a timestamp. The timestamp keeps new keys nearly sequential. So version 7 removes most of the scattered-write cost of version 4. PostgreSQL 18, and libraries in most languages, can create version 7 values.
>
> **A common middle path:** keep an integer primary key inside the database. Add a separate, indexed UUID column for public exposure. You then get fast joins inside and safe identifiers outside. The cost is one extra column and one extra index.
>
> If you tell me your database and your scale, I can give a firmer answer.

</td></tr>

<tr><td valign="top">

**[`small-words`](output-styles/small-words.md)**

For explaining something to someone outside your field: everyday words instead of jargon, with the real term given right beside the plain one. Runs longer than Claude normally would, not shorter.

<sub>435 words</sub>

</td><td valign="top">

> Short answer: if one fact-store *(the database — the computer thing that holds your rows)* makes every row, use a number that grows by one each time (auto-increment, as a `bigint`). If rows get made in many places, or the ID is shown to the outside world, use a UUID — and pick UUIDv7, not UUIDv4.
>
> Here is why. The growing number is small — 8 bytes instead of 16 — and each new row lands at the end of the fast look-up list the store keeps *(hard word: index — a sorted list that helps find rows fast)*. Landing at the end is the fast case, so writes stay quick and the list stays lean. The numbers are also easy for a human to read, say out loud, and chase when something breaks. But there are two costs. First, only the store itself can hand out the next number, so a row born on a phone with no line to the store, or in a second store, has to wait — and if you ever join two stores, their numbers fight. Second, the numbers tell on you: an outsider can see row 1042 today and row 2042 next week and learn how fast you grow, or try nearby numbers to peek at rows that are not theirs.
>
> A UUID is a long ID picked mostly by chance. Any computer can make one on its own, with close to no chance that two are ever the same, so no one has to ask the store first — great when many services, phones, or stores all create rows, or when you show the ID in a web address. The costs: it is twice as big, and the fully-by-chance kind (UUIDv4) drops each new row at some random spot in the look-up list instead of at the end. That makes writes slower and the list fat and full of holes. UUIDv7 fixes most of this: it starts with the time it was made, so new IDs still mostly land at the end of the list. PostgreSQL 18 has a `uuidv7()` function built in; on older versions or other stores, a small library can make them.
>
> A common middle path also works well: use the growing number as the key inside the store, where it is fast and small, and give each row a second, by-chance ID that the outside world sees. That way strangers cannot count or walk your rows, and your store keeps its speed.
>
> So: one store, IDs kept inside — growing `bigint` number. Many makers of rows, or IDs shown to strangers — UUIDv7.

</td></tr>

<tr><td valign="top">

**[`one-analogy`](output-styles/one-analogy.md)**

For getting your head around something unfamiliar: one comparison carried through the whole answer, then the point where it stops being true.

<sub>406 words</sub>

</td><td valign="top">

> Think of the table's primary-key index as a library's shelves, and each row as a book being shelved.
>
> - **Auto-increment integer** is shelving by arrival number: every new book goes at the end of the last shelf. Inserts are fast and the shelves stay tightly packed (good B-tree locality, small 8-byte keys, and every index card that cites the book — foreign keys, secondary indexes — stays short). But the number itself leaks information: catalog #48,201 tells anyone how many books you own and lets them guess #48,202 (enumeration in URLs, visible business volume). And two library branches can't number books independently — they'd collide, so only the central desk (the database) can assign numbers, meaning you can't know a book's number until it's checked in.
> - **UUIDv4** is stamping each book with a random code: any branch, even a patron at home (client-side, offline), can label a book with no coordination, and the code reveals nothing. But shelving now means wedging every new book into a random spot mid-shelf — constant reshuffling (page splits, index fragmentation, poor cache locality) and the codes are twice as long (16 bytes) on every index card that references them.
> - **UUIDv7** is a code that begins with a timestamp: still generatable by any branch with no coordination, but because new codes sort after old ones, new books still land at the end of the shelf.
>
> Where the analogy breaks: in a library, a badly placed book is merely slow to find later. In a database, random inserts hurt *at write time* — every insert dirties a random page and splits full ones — and in MySQL's InnoDB the entire row is stored in primary-key order, so the reshuffling cost hits the whole table, not just the catalog. Postgres stores rows in a heap, so it only pays the cost in the index — painful, but less so.
>
> The plain answer: for a single database where IDs never appear in public URLs, use a `bigint` auto-increment (identity) column — it's the smallest, fastest, simplest option. If you need client-generated IDs, merging data across services or shards, or IDs safe to expose publicly, use **UUIDv7** (RFC 9562; Postgres 18 has `uuidv7()` built in, and most languages have libraries). Avoid UUIDv4 as a primary key, especially in MySQL. A common hybrid is a bigint internal PK plus a separate UUID column for external exposure, but UUIDv7 alone usually makes that unnecessary now.

</td></tr>

<tr><td valign="top">

**[`your-turn`](output-styles/your-turn.md)**

For learning something rather than just getting past it: the answer in full, then a question handed back for you to try.

<sub>351 words</sub>

</td><td valign="top">

> Short answer: default to an auto-increment integer (a `BIGINT` the database numbers 1, 2, 3, … for you). Reach for a UUID — a 128-bit identifier any machine can generate without asking the database — only when you need one of its two real advantages: IDs that can be created outside the database (offline clients, multiple servers writing independently), or IDs that outsiders can't guess. And if you do go UUID, prefer UUIDv7, a newer version whose first bits are a timestamp, over the fully random UUIDv4.
>
> Here's the one concept that decides most of this. A primary key is the column that uniquely identifies each row, and the database stores an index on it — a B-tree, which is a structure that keeps all keys physically sorted so lookups are fast. With an auto-increment key, every new row has the largest key so far, so every insert lands in the same place: the rightmost page of the tree. That page stays in memory, stays warm, and just appends. A random UUIDv4 lands somewhere different in the sorted order every single time, so inserts touch random pages all over the tree, forcing the database to constantly fetch cold pages from disk and split full ones. UUIDv7 fixes this by putting a timestamp first, so new keys still sort to the right edge like integers do.
>
> The counterintuitive bit: UUIDs' insert cost has almost nothing to do with them being bigger than integers — it's that *randomness* destroys the "always insert at the right edge" pattern the B-tree is fast at. Size is a footnote; ordering is the story.
>
> The other axis is exposure: sequential IDs in URLs (`/orders/1041`) tell strangers how many orders you have and invite guessing `/orders/1042` — but you can also solve that with an integer key inside and a separate random public ID outside.
>
> Quick check: your app runs on a single Postgres server, and order IDs never appear in URLs — which key would you pick, and what's the one future change that should make you reconsider? Say "just tell me" and I'll answer it outright.

</td></tr>

</table>

All nine reached the same recommendation — an integer key by default, UUIDv7
when the ID has to be created outside the database or shown to strangers.
**That is the point.** A style does not make Claude smarter, more correct, or
even shorter: three of the eight came back longer than the no-style answer.
What changes is the shape the answer arrives in, and whether that shape is one
you chose.

Two things that table is honest about. `where-we-are` is the least reliable of
the eight, producing its state line on roughly a third of runs, which is why
its description says it *asks for* one. And `one-analogy` and
`one-fact-per-sentence` each reverted to the default register on their first
run and held on the second. Adherence is strong, not deterministic, which is
what the optional [`--enforce`](#make-it-stick---enforce) hook exists for.
[docs/examples.md](docs/examples.md) records the exact command, the version,
the measurements, and a second `where-we-are` answer taken with work actually
in flight.

## Why this works when a CLAUDE.md rule doesn't

If you have put "be concise, skip the preamble" in your CLAUDE.md and watched it
hold for a few turns and then quietly stop mattering, rewording it will not help.
The instruction is on the wrong layer.

**CLAUDE.md is context.** It arrives alongside your files, your last twenty
messages, and every tool result, all competing for the model's attention — and
the competition gets worse as the session fills up.

**An output style is the system prompt.** Claude Code injects it verbatim into
the same slot that holds its own built-in styles — Explanatory, Learning,
Proactive — so it reframes who the agent is rather than adding one more request
to a crowded window.

Your CLAUDE.md keeps working. A style sets voice; CLAUDE.md keeps carrying your
project rules, conventions, and commands. If your CLAUDE.md already has tone
instructions, you can delete those lines — otherwise Claude is being told the
same thing twice, from two places.

### What a style will not change

A style changes prose and nothing else. Every one here sets
`keep-coding-instructions: true`, so Claude Code's software-engineering
instructions stay intact, and every one carries an explicit clause: it changes
how an answer is written, never which tools run, which edits are made, or when
Claude stops to ask you something.

Code, commands, error messages, file paths, identifiers, and numbers are
reproduced byte-for-byte, never stylized. For security warnings,
destructive-action confirmations, and order-critical instructions, the styles
drop their register and switch to full, plain sentences. The one exception is
deliberate: `one-fact-per-sentence` stays on, because controlled aerospace
English is already the clearest thing to read in exactly those moments.

CI fails the build if any style stops carrying that guardrails block.

## The styles

**If you install one, install `plain-prose`.** It fixes the default register
without imposing a format, which makes it the one style that is safe to leave on
permanently.

What each one does is shown above, in its own words. Grouped here by the job
you'd reach for it on, with the method behind it:

### Everyday answers

| Style | Method · author |
|---|---|
| [`plain-prose`](output-styles/plain-prose.md) | [Siqi Chen](https://github.com/blader/humanizer) · [Peter Yang](https://github.com/petergyang/no-ai-slop) · [Conor Bronsdon](https://github.com/conorbronsdon/avoid-ai-writing) · [Hardik Pandya](https://github.com/hardikpandya/stop-slop) · Joe Cotellese |
| [`short-answers`](output-styles/short-answers.md) | [Julius Brussee](https://github.com/JuliusBrussee/caveman) · [Carlos Duplar Mello](https://github.com/carlosduplar/caveman-output-style-claude-code) |

### Work documents

For output that leaves your terminal — a PR description, a status update, a
message to someone who was not in the session.

| Style | Method · author |
|---|---|
| [`decision-brief`](output-styles/decision-brief.md) | Barbara Minto's [Pyramid Principle](https://www.barbaraminto.com/) · BLUF · [Sruthi Reddy](https://github.com/sruthir28/enterprise-ai-skills) · [Joe Cotellese](https://joecotellese.com) |
| [`where-we-are`](output-styles/where-we-are.md) | [Ayoub Ghriss](https://github.com/ayghri/i-have-adhd) · Ramsay & Rostain (*The Adult ADHD Tool Kit*) |

> [!NOTE]
> **`where-we-are` overlaps a built-in, so check you need it.** Claude Code
> ships [session recap](https://code.claude.com/docs/en/interactive-mode#session-recap):
> a one-line summary of where the session stands, on by default, generated after
> you have been away three minutes or so, and available on demand with `/recap`.
> If you only want *"I stepped away, what was I doing"*, use that — it is real
> code with real triggers rather than an instruction the model has to remember.
>
> Reach for the style when you need what recap does not give you: the state on
> **every** answer rather than after an absence, **inside the response text** so
> it survives a paste into a PR or a handover note, and **outside the terminal**
> — recap does not surface in the IDE extensions, and the docs state it is
> always skipped in non-interactive mode, so `claude -p`, scripts, and CI never
> see one. The two fail in different directions; running both is reasonable.

### Explaining to someone

For unfamiliar code, onboarding, and any answer you need to understand rather
than skim.

| Style | Method · author |
|---|---|
| [`one-fact-per-sentence`](output-styles/one-fact-per-sentence.md) | [ASD-STE100](https://www.asd-ste100.org/) (aerospace, 1983) · [Amin Boulegroun](https://github.com/AminBlg/SimpleEnglish) · [Matt Pocock](https://github.com/mattpocock/skills) |
| [`small-words`](output-styles/small-words.md) | [Randall Munroe](https://xkcd.com/1133/) (xkcd, *Thing Explainer*) |
| [`one-analogy`](output-styles/one-analogy.md) | IEEE ProComm · Reijnierse et al. (JCOM 2025) · CMU metaphor checklist |
| [`your-turn`](output-styles/your-turn.md) | Richard Feynman's technique |

Full attribution for every adapted method: [docs/CREDITS.md](docs/CREDITS.md).

## Install

### macOS / Linux

One style, installed **and** activated:

```bash
curl -fsSL https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.sh | bash -s -- plain-prose
```

All eight plus the `style-maker` skill (activates nothing; pick later in `/config`):

```bash
curl -fsSL https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.sh | bash -s -- --all
```

Rather read it before running it? The installer is one file and works from a
clone:

```bash
git clone https://github.com/jase-perf/claude-output-style-library
cd claude-output-style-library && ./install.sh --all
```

### Windows (PowerShell)

Windows has its own installer, [`install.ps1`](install.ps1) — the same commands,
using only built-in PowerShell: no curl, no bash, no python.

```powershell
# One style, installed and activated
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.ps1))) -Style plain-prose

# Everything, with the per-turn reminder hook
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.ps1))) -All -Enforce
```

From a local clone: `.\install.ps1 -All -Enforce`. Requires PowerShell 5.1
(ships with Windows) or later; `pwsh` works too.

> [!NOTE]
> The `& ([scriptblock]::Create(...))` wrapper is how a remote script receives
> arguments. Plain `irm ... | iex` runs too, but `iex` cannot forward
> parameters — it will just print usage.

<details>
<summary><b>Flags, and why Windows has its own installer</b></summary>

| `install.sh` | `install.ps1` | Effect |
| --- | --- | --- |
| `<name> [<name>…]` | `-Style <name> [<name>…]` | Install the named styles. A single one is also **activated**. |
| `--all` | `-All` | Install all 8 plus the `style-maker` skill. Activates nothing. |
| `--enforce` | `-Enforce` | Also install and register the per-turn reminder hook. |
| `--list` | `-List` | Print the available style names. |

`install.sh` needs bash, and uses `python3` to edit `settings.json` when one is
available. Both are unreliable on Windows:

- **`bash` on PATH is normally WSL** (`C:\Windows\system32\bash.exe`), where
  `$HOME` is `/home/<user>` — not `C:\Users\<user>`. The style files land in the
  WSL filesystem, which Claude Code for Windows never reads, and the script
  reports success.
- **`python3` is normally a 0-byte Microsoft Store stub** that satisfies
  `command -v` and then exits 9009. `install.sh` guards against this by checking
  that `python3` actually runs, so it no longer dies there — but it falls back
  to printing manual instructions instead of activating your style.

[`install.ps1`](install.ps1) has neither dependency and edits `settings.json`
through PowerShell's own JSON support.

</details>

### What it writes, and how to undo it

```
~/.claude/output-styles/<name>.md   the style file(s)
~/.claude/skills/style-maker/       only with --all or `style-maker`
~/.claude/hooks/style-reminder.*    only with --enforce
~/.claude/settings.json             edited only to activate a style or
                                    register the hook
```

Nothing else is touched, and no project files are read or written. Both
installers **merge** into `~/.claude/settings.json` rather than overwriting it,
so existing hooks, permissions, and plugins survive; re-running is safe, and the
hook registers once, not once per run. `install.ps1` also copies the file to
`settings.json.bak` first.

**To undo:** `/config` → **Output style** → `Default` switches it off
immediately. To remove it entirely, delete the file from
`~/.claude/output-styles/` and, if you used `--enforce`, the `UserPromptSubmit`
entry in `~/.claude/settings.json`.

**What it costs:** each style body is capped at 3500 characters — roughly 875
tokens — added to the system prompt once per session. There is no per-turn cost
unless you add `--enforce`, which is about 17 tokens a turn.

### After install

Nothing changes until Claude Code restarts (or you run `/clear`). If you
installed a single style, that is all — it is already active. If you used
`--all`, then: `/config` → **Output style** → pick one.

<p align="center">
  <img src="docs/assets/Claude_Code_Config_Styles.gif" alt="Picking an output style: /config, then Output style, then choose from the list">
</p>

> [!TIP]
> The old `/output-style` command was removed in Claude Code v2.1.91 — most
> guides online still mention it and are outdated. `/config` is the way.

### Make it stick: `--enforce`

A custom style is read once, at session start, so a long conversation can drift
away from it. Append `--enforce` (bash) or `-Enforce` (PowerShell) to any
install command above and a small `UserPromptSubmit` hook re-states the active
style every turn, for about 17 tokens.

The hook resolves your active style through the same settings precedence Claude
Code uses — `settings.local.json`, then the project's `settings.json`, then
`~/.claude/settings.json` — reading the project directory from its own stdin
payload. It stays silent for built-in styles and for `default`, and every code
path exits 0, so a missing or malformed settings file degrades to the next one
down rather than breaking a turn. Details:
[docs/enforce-hook.md](docs/enforce-hook.md).

> [!NOTE]
> **This ships opt-in because the evidence conflicts.** Claude Code's
> [output styles docs](https://code.claude.com/docs/en/output-styles) say
> "**All** output styles trigger reminders for Claude to adhere to the output
> style instructions during the conversation," which would make the hook
> redundant. Against that: reading the shipped binary shows the reminder
> consumer looking up a built-ins-only table and returning nothing for a custom
> style, and no such reminder has been observed in practice. We have not run a
> controlled test, so we are not claiming the docs are wrong. Turn it on if you
> notice your style fading.

## Make your own: style-maker

If none of the eight fit, `style-maker` interviews you and writes a ninth.
Install it the same way:

```bash
curl -fsSL https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.sh | bash -s -- style-maker
```

Then tell Claude **"make my output style"**. It asks ~10 questions (audience,
length, jargon level, tone, samples of writing you like and hate), generates a
style file following this repo's conventions — countable specs, positive
framing, safety guardrails — shows you a live demo, and activates it.

## How this library is built

A style file is not documentation. Its body is injected verbatim into the system
prompt, so every line it contains costs tokens and attention on every turn of
every session it is active. A careless sentence in a README is noise; a careless
sentence in a style file is a standing instruction.

**The shared conventions** (full guide: [docs/format-guide.md](docs/format-guide.md)):
specs rather than adjectives, because "no sentence over 20 words" is checkable
and "be clear" is not; positive framing that describes the target voice;
byte-exact guardrails; ceremony cut but never reasoning; and a 3500-character
ceiling per style, because every byte is system prompt on every turn — a guard
against bloat rather than a measured threshold.

**Every style is machine-checked.** A style that quietly lost its security
clause would install and behave exactly like a correct one.
[`tests/check-styles.sh`](tests/check-styles.sh) is what notices:

| The check | Why it exists |
| --- | --- |
| Guardrails name all four carve-outs | A style silently missing the destructive-action clause installs and runs like a correct one |
| `## Rules` has its own heading | Otherwise the guardrails section runs on and the carve-out checks can be satisfied by rule text instead |
| Body under 3500 characters | Growth should be deliberate; the number moves when a rule earns the room |
| Frontmatter `name` slugifies to the filename | If they disagree, `install.sh <slug>` activates a style the user cannot find in `/config` |
| No agent tool-call markup in the body | One style shipped with `</invoke>` as its last line and passed CI |
| Every style is credited, and the README table matches what ships | Attribution and docs cannot rot silently |

**Every style is adversarially reviewed.** Each one is reviewed by a second
agent briefed to break it, not to approve it. Reviewers build a sandbox copy of
the repo, run the suite in it, count the body themselves, and diff against the
previous version for undeclared deletions; an approval without those artifacts
does not count. That process caught a verify clause changed from "at most one
concept per answer" to "exactly one" — which removes permission for a short
factual reply and pushes every turn toward a mini-lecture — and a fabricated
claim about React `useMemo` that would otherwise have entered the system prompt
of every session.

**Why it is eight styles and not nineteen**, why there are no banned-word lists,
and what the research does and does not support:
[docs/design-decisions.md](docs/design-decisions.md).

**What is not claimed.** No benchmark shows these styles produce measurably
better output than an unstyled Claude. The tests verify structure, the reviews
verify craft, and the citations support specific design choices. None of that is
an efficacy result, and calling it one would be the exact failure the
`plain-prose` style exists to prevent.

## The wider catalog

Every method adapted here is credited to its author in
[docs/CREDITS.md](docs/CREDITS.md), with links to the original projects — most
of which are worth installing directly. Two more collections beyond those:

- [nattergabriel/claude-code-output-styles](https://github.com/nattergabriel/claude-code-output-styles)
  — 13 well-crafted styles (Socratic, Roast, Ship It…).
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
  — the canonical Claude Code index, with an Output Styles category.

## Contributing

PRs welcome. One style per PR, following
[docs/format-guide.md](docs/format-guide.md): built-in prompt structure
(identity line, `Style Active` header), countable specs, positive framing, the
shared guardrails block, one positive example, a verify clause, and credits in
[docs/CREDITS.md](docs/CREDITS.md) rather than in the style body. Run the suite
before you open it:

```bash
sh tests/check-styles.sh && sh tests/test-hook.sh && sh tests/test-install.sh
```

CI runs the hook and installer suites on Ubuntu, macOS and Windows; the style
invariants, `shellcheck`, PSScriptAnalyzer, and a check that no `.sh` file has
acquired a CR run on Ubuntu. Checks that cannot run in an environment report
`SKIP` with a reason rather than passing silently.

If you're the original author of a methodology adapted here and want changes,
open an issue; you outrank us.

## License

[MIT](LICENSE). Adapted styles preserve their sources' copyright notices in
[NOTICE](NOTICE); who each person is and which style adapts their work is in
[docs/CREDITS.md](docs/CREDITS.md).

---

<sub><strong>Docs:</strong> <a href="docs/examples.md">Full examples</a> · <a href="docs/format-guide.md">Format guide</a> · <a href="docs/design-decisions.md">Design decisions</a> · <a href="docs/claudisms-2026.md">Claudisms field guide</a> · <a href="docs/enforce-hook.md">Enforce hook</a> · <a href="skills/style-maker/SKILL.md">style-maker</a> · <a href="https://github.com/jase-perf/claude-output-style-library/issues">Issues</a></sub>
