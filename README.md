# Claude Output Style Library

[![CI](https://github.com/jase-perf/claude-output-style-library/actions/workflows/ci.yml/badge.svg)](https://github.com/jase-perf/claude-output-style-library/actions/workflows/ci.yml)
[![license](https://img.shields.io/github/license/jase-perf/claude-output-style-library?style=flat)](LICENSE)

**Eight ways to change how Claude Code writes to you. One command each.**

Claude's answers arrive packed with jargon and abbreviations you have to decode,
and they come out the same shape whatever you ask. Install one of these files
and Claude does the same work, in a voice you picked: plain paragraphs, or under
100 words, or the verdict first.

An output style is a Claude Code feature: a markdown file that Claude Code loads
into its system prompt, where it sets how Claude writes for the whole session.
That is why it holds when a "be concise" line in CLAUDE.md stops working. Keep
CLAUDE.md for your project's rules, and delete any tone lines from it so Claude
is not told the same thing twice.

A style changes prose and nothing else. It never changes which tools Claude
runs, which edits it makes, or when it stops to ask you something. Code,
commands, error messages, file paths and numbers come through exactly as
written, and security warnings drop the style for plain, complete sentences.

[The styles](#the-styles) · [Install](#install)

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

These are real runs, not mock-ups. [docs/examples.md](docs/examples.md) records
the command, the version, and how consistently each style held.

## The styles

**If you install one, install `plain-prose`.** It changes the voice without
imposing a format, so it is the one that is safe to leave on permanently.

**Everyday answers** — [`plain-prose`](output-styles/plain-prose.md),
[`short-answers`](output-styles/short-answers.md).

**Work documents**, for answers that leave your terminal — a PR description, a
status update, a message to someone who was not in the session —
[`decision-brief`](output-styles/decision-brief.md),
[`where-we-are`](output-styles/where-we-are.md).

**Explaining something**, for unfamiliar code, onboarding, and any answer you
need to understand rather than skim —
[`one-fact-per-sentence`](output-styles/one-fact-per-sentence.md),
[`small-words`](output-styles/small-words.md),
[`one-analogy`](output-styles/one-analogy.md),
[`your-turn`](output-styles/your-turn.md).

`where-we-are` overlaps Claude Code's built-in `/recap`; [when you want
both](docs/examples.md#when-you-want-this-and-recap-is-not-enough).

Who wrote the method behind each style: [docs/CREDITS.md](docs/CREDITS.md).

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

Or clone it and run it yourself:

```bash
git clone https://github.com/jase-perf/claude-output-style-library
cd claude-output-style-library && ./install.sh --all
```

### Windows (PowerShell)

Windows uses [`install.ps1`](install.ps1) instead:

```powershell
# One style, installed and activated
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.ps1))) -Style plain-prose

# Everything, with the per-turn reminder hook
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.ps1))) -All -Enforce
```

From a local clone: `.\install.ps1 -All -Enforce`.

### Restart, then pick

> [!IMPORTANT]
> **Nothing changes until you restart Claude Code, or run `/clear`.** A style is
> read once, when the session starts.

If you installed a single style, it is already active. If you installed all
eight: `/config` → **Output style** → pick one. (`/output-style` was removed in
Claude Code v2.1.91.)

<p align="center">
  <img src="docs/assets/Claude_Code_Config_Styles.gif" alt="Picking an output style: /config, then Output style, then choose from the list">
</p>

Everything is written under `~/.claude/`, and no project file is read or
written. Both installers merge into `~/.claude/settings.json` rather than
overwriting it, so re-running is safe. A style costs about 875 tokens once per
session. To switch it off: `/config` → **Output style** → `Default`. To remove
it, delete the file from `~/.claude/output-styles/`.

<details>
<summary><b>Installer flags, and the files written</b></summary>

| `install.sh` | `install.ps1` | Effect |
| --- | --- | --- |
| `<name> [<name>…]` | `-Style <name> [<name>…]` | Install the named styles. A single one is also **activated**. |
| `--all` | `-All` | Install all 8 plus the `style-maker` skill. Activates nothing. |
| `--enforce` | `-Enforce` | Also install the per-turn reminder hook. |
| `--list` | `-List` | Print the available style names. |

```
~/.claude/output-styles/<name>.md   the style file(s)
~/.claude/skills/style-maker/       only with --all or `style-maker`
~/.claude/hooks/style-reminder.*    only with --enforce
~/.claude/settings.json             edited only to activate a style or
                                    add the hook
```

</details>

### Make it stick: `--enforce`

A style is read once per session, so a long conversation can drift back toward
Claude's default voice. Add `--enforce` (bash) or `-Enforce` (PowerShell) to any
command above, and a hook re-states your active style every turn for about 17
tokens. Turn it on if you notice your style fading;
[docs/enforce-hook.md](docs/enforce-hook.md) covers the rest.

## Make your own: style-maker

If none of the eight fit, `style-maker` interviews you and writes a ninth.
Install it the same way:

```bash
curl -fsSL https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.sh | bash -s -- style-maker
```

Then tell Claude **"make my output style"**. It asks ~10 questions (audience,
length, jargon level, tone, samples of writing you like and hate), writes the
style file, shows you a live demo, and activates it.

## Other collections

- [nattergabriel/claude-code-output-styles](https://github.com/nattergabriel/claude-code-output-styles)
  — 13 well-crafted styles (Socratic, Roast, Ship It…).
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
  — the canonical Claude Code index, with an Output Styles category.

## Contributing

One style per PR, following [docs/format-guide.md](docs/format-guide.md), with
the method credited in [docs/CREDITS.md](docs/CREDITS.md). Run the suite before
you open it:

```bash
sh tests/check-styles.sh && sh tests/test-hook.sh && sh tests/test-install.sh
```

Why there are eight styles and not nineteen, and how each one is checked:
[docs/design-decisions.md](docs/design-decisions.md).

If you're the original author of a methodology adapted here and want changes,
open an issue; you outrank us.

## License

[MIT](LICENSE). Adapted styles preserve their sources' copyright notices in
[NOTICE](NOTICE); who each person is and which style adapts their work is in
[docs/CREDITS.md](docs/CREDITS.md).

---

<sub><strong>Docs:</strong> <a href="docs/examples.md">Full examples</a> · <a href="docs/format-guide.md">Format guide</a> · <a href="docs/design-decisions.md">Design decisions</a> · <a href="docs/claudisms-2026.md">Claudisms field guide</a> · <a href="docs/enforce-hook.md">Enforce hook</a> · <a href="skills/style-maker/SKILL.md">style-maker</a> · <a href="https://github.com/jase-perf/claude-output-style-library/issues">Issues</a></sub>
