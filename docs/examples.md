# Real answers, all eight styles

The [README](../README.md#see-the-difference) shows excerpts. These are the full
answers, unedited.

## How these were generated

One question, asked once per style plus once with no style at all, through
Claude Code itself:

```bash
claude -p "Should I use a UUID or an auto-increment integer for a primary key?" \
  --settings '{"outputStyle":"<Style Name>"}'
```

- **Claude Code 2.1.225**, default model, 9 August 2026.
- Run from a directory whose `.claude/output-styles/` held this repo's current
  style files, so the answers reflect the styles as they ship today.
- The machine's user-level `CLAUDE.md` was moved aside for the duration. Without
  that it injected its own instructions into every answer, and the point here is
  to show what the *style* does, not what one person's memory file does.
- Nothing below is edited. No text was cut, reordered, or tidied.

**Two disclosures, because the point of this page is that the examples are real:**

1. `one-analogy` and `one-fact-per-sentence` were each run twice. On the first
   run both reverted to Claude's default register — no analogy at all in one, no
   20-word sentences in the other. The second run of each is what appears below.
   Style adherence is not deterministic, and pretending otherwise would be the
   kind of claim this library exists to stop.
2. `where-we-are` holds its format on roughly a third of runs, even after being
   rewritten to demand a literal marker. Its section answers the same question
   as everyone else, then shows the same style on a question with work actually
   in flight, and carries the full adherence numbers plus how it relates to
   Claude Code's built-in `/recap`.

## The question

> Should I use a UUID or an auto-increment integer for a primary key?

---

## no style (Claude Code's default)

The baseline, run identically with `--settings '{"outputStyle":"default"}'`.

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

314 words. Worth being honest about: this is a good answer. It leads with the
recommendation, it does not hedge, and it does not restate the question. The
default register is not broken, and a library that claimed otherwise would be
making exactly the kind of unfalsifiable complaint `plain-prose` exists to stop.

What it does do is reach for one shape — bold lead-in, bulleted middle, bold
recap — and spend 314 words on it. Every style below reaches the same
conclusion. They differ in the shape they arrive in, and in whether you picked
that shape.

---

## plain-prose

> Default to a bigint auto-increment, and reach for a UUID only when you need one of the three things it buys you.
>
> The integer wins on storage and index behavior. It's 8 bytes against a UUID's 16, and every foreign key and secondary index repeats the primary key, so the size difference multiplies across the schema. More importantly, sequential values append to the right edge of the B-tree, while random UUIDv4s land on random pages — in a clustered-index engine like InnoDB or SQL Server that means page splits, a cold buffer pool, and inserts that slow down as the table grows.
>
> A UUID earns its cost in three situations: rows are created on clients or across multiple writers before the database is reachable, so you can't wait for the sequence; you merge or shard data across databases, where sequences collide; or the ID appears in URLs and a sequential value would let people enumerate your records or read your growth rate off the numbers.
>
> If any of those apply, two fixes avoid the index problem. Use UUIDv7 instead of v4 — its leading bits are a timestamp, so inserts stay roughly sequential and the B-tree behaves. Or keep the bigint as the internal primary key and add a separate unique UUID column that only the outside world sees; joins stay cheap and the public IDs stay unguessable.
>
> So: single Postgres or MySQL database, IDs not exposed in URLs — bigint, done. Distributed writes or public IDs — UUIDv7, or bigint plus a public UUID column.

256 words. No template, no word budget, and every claim is a number or a
mechanism rather than an adjective.

---

## short-answers

> Default to a `BIGINT` auto-increment: it's half the size of a UUID, keeps B-tree inserts append-only, and makes debugging easier. Choose a UUID when clients must generate IDs offline, when rows merge across databases or shards, or when the ID appears in URLs and you don't want to leak row counts or invite enumeration. If you do, prefer UUIDv7 — random v4 keys scatter inserts across the index and hurt cache locality. A common middle path: integer primary key internally, separate UUID column for anything public-facing.
>
> Not checked: your database and whether IDs are ever exposed externally — that decides the tradeoff.

102 words against a 100-word budget, and it closes on what it could not check —
both rules holding under a real question.

---

## decision-brief

> **Default to a `bigint` auto-increment key, and switch to UUIDv7 only when a specific need forces it** — distributed ID generation, publicly exposed IDs, or merging data across databases. This is a question where the right answer depends on three concrete trade-offs:
>
> 1. **Write and index performance favors integers.** Random UUIDs (v4) scatter inserts across the B-tree, fragmenting the primary index and blowing out cache — on clustered-index databases like MySQL/InnoDB this can cut insert throughput several-fold at scale. Sequential integers (and time-ordered UUIDv7) always append to the right edge, so the hot pages stay in memory.
> 2. **Size compounds everywhere.** A UUID is 16 bytes versus 8 for a bigint, and the primary key is duplicated into every secondary index and every foreign key that references it. On a large schema that's a real difference in index size and join speed, not a rounding error.
> 3. **UUIDs win when the ID leaves the database.** Sequential IDs are guessable and leak business volume (`/orders/10432` tells a competitor your order count — this is the classic enumeration problem). UUIDs also let clients, mobile apps, or multiple services mint IDs without a round-trip to one database, and they merge cleanly across shards or environments.
>
> Two refinements worth knowing: if you do choose UUIDs, use **UUIDv7** (time-ordered, standardized in RFC 9562), not v4 — it keeps the distributed-generation and non-guessability benefits while fixing the index-locality problem. And a common hybrid is a bigint primary key internally plus a separate unique UUID column for anything exposed in URLs or APIs, which gets you fast joins and unguessable public IDs at the cost of one extra index.
>
> So: single database, IDs never shown to users → bigint identity. Client-generated IDs, public URLs, or multi-region writes → UUIDv7. If you tell me the database and the app's shape, I can make the call more specifically.

The answer is the first sentence, the reasons sit underneath it, and it closes by
naming what it needs from you to decide — the Minto pyramid, intact.

---

## one-fact-per-sentence

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

Every sentence carries one fact and stays under 20 words — ASD-STE100's
specification, applied to a database question. **Second run;** the first came
back in ordinary prose with 30-word sentences.

---

## small-words

> Short answer: if one fact-store *(the database — the computer thing that holds your rows)* makes every row, use a number that grows by one each time (auto-increment, as a `bigint`). If rows get made in many places, or the ID is shown to the outside world, use a UUID — and pick UUIDv7, not UUIDv4.
>
> Here is why. The growing number is small — 8 bytes instead of 16 — and each new row lands at the end of the fast look-up list the store keeps *(hard word: index — a sorted list that helps find rows fast)*. Landing at the end is the fast case, so writes stay quick and the list stays lean. The numbers are also easy for a human to read, say out loud, and chase when something breaks. But there are two costs. First, only the store itself can hand out the next number, so a row born on a phone with no line to the store, or in a second store, has to wait — and if you ever join two stores, their numbers fight. Second, the numbers tell on you: an outsider can see row 1042 today and row 2042 next week and learn how fast you grow, or try nearby numbers to peek at rows that are not theirs.
>
> A UUID is a long ID picked mostly by chance. Any computer can make one on its own, with close to no chance that two are ever the same, so no one has to ask the store first — great when many services, phones, or stores all create rows, or when you show the ID in a web address. The costs: it is twice as big, and the fully-by-chance kind (UUIDv4) drops each new row at some random spot in the look-up list instead of at the end. That makes writes slower and the list fat and full of holes. UUIDv7 fixes most of this: it starts with the time it was made, so new IDs still mostly land at the end of the list. PostgreSQL 18 has a `uuidv7()` function built in; on older versions or other stores, a small library can make them.
>
> A common middle path also works well: use the growing number as the key inside the store, where it is fast and small, and give each row a second, by-chance ID that the outside world sees. That way strangers cannot count or walk your rows, and your store keeps its speed.
>
> So: one store, IDs kept inside — growing `bigint` number. Many makers of rows, or IDs shown to strangers — UUIDv7.

"Fact-store" for database, "the fast look-up list" for index, and the real term
supplied in a `*(hard word: …)*` marker whenever the plain version would cost
precision. Note that `uuidv7()` and `bigint` survive byte-exact — the guardrail
holding while the register is at its most playful.

---

## one-analogy

> Think of the table's primary-key index as a library's shelves, and each row as a book being shelved.
>
> - **Auto-increment integer** is shelving by arrival number: every new book goes at the end of the last shelf. Inserts are fast and the shelves stay tightly packed (good B-tree locality, small 8-byte keys, and every index card that cites the book — foreign keys, secondary indexes — stays short). But the number itself leaks information: catalog #48,201 tells anyone how many books you own and lets them guess #48,202 (enumeration in URLs, visible business volume). And two library branches can't number books independently — they'd collide, so only the central desk (the database) can assign numbers, meaning you can't know a book's number until it's checked in.
> - **UUIDv4** is stamping each book with a random code: any branch, even a patron at home (client-side, offline), can label a book with no coordination, and the code reveals nothing. But shelving now means wedging every new book into a random spot mid-shelf — constant reshuffling (page splits, index fragmentation, poor cache locality) and the codes are twice as long (16 bytes) on every index card that references them.
> - **UUIDv7** is a code that begins with a timestamp: still generatable by any branch with no coordination, but because new codes sort after old ones, new books still land at the end of the shelf.
>
> Where the analogy breaks: in a library, a badly placed book is merely slow to find later. In a database, random inserts hurt *at write time* — every insert dirties a random page and splits full ones — and in MySQL's InnoDB the entire row is stored in primary-key order, so the reshuffling cost hits the whole table, not just the catalog. Postgres stores rows in a heap, so it only pays the cost in the index — painful, but less so.
>
> The plain answer: for a single database where IDs never appear in public URLs, use a `bigint` auto-increment (identity) column — it's the smallest, fastest, simplest option. If you need client-generated IDs, merging data across services or shards, or IDs safe to expose publicly, use **UUIDv7** (RFC 9562; Postgres 18 has `uuidv7()` built in, and most languages have libraries). Avoid UUIDv4 as a primary key, especially in MySQL. A common hybrid is a bigint internal PK plus a separate UUID column for external exposure, but UUIDv7 alone usually makes that unnecessary now.

One domain, sustained: shelves, books, catalog numbers, branches, the central
desk. Then the two things the style insists on — where the analogy stops being
true, and the real answer in real terms. **Second run;** the first produced no
analogy whatsoever.

---

## your-turn

> Short answer: default to an auto-increment integer (a `BIGINT` the database numbers 1, 2, 3, … for you). Reach for a UUID — a 128-bit identifier any machine can generate without asking the database — only when you need one of its two real advantages: IDs that can be created outside the database (offline clients, multiple servers writing independently), or IDs that outsiders can't guess. And if you do go UUID, prefer UUIDv7, a newer version whose first bits are a timestamp, over the fully random UUIDv4.
>
> Here's the one concept that decides most of this. A primary key is the column that uniquely identifies each row, and the database stores an index on it — a B-tree, which is a structure that keeps all keys physically sorted so lookups are fast. With an auto-increment key, every new row has the largest key so far, so every insert lands in the same place: the rightmost page of the tree. That page stays in memory, stays warm, and just appends. A random UUIDv4 lands somewhere different in the sorted order every single time, so inserts touch random pages all over the tree, forcing the database to constantly fetch cold pages from disk and split full ones. UUIDv7 fixes this by putting a timestamp first, so new keys still sort to the right edge like integers do.
>
> The counterintuitive bit: UUIDs' insert cost has almost nothing to do with them being bigger than integers — it's that *randomness* destroys the "always insert at the right edge" pattern the B-tree is fast at. Size is a footnote; ordering is the story.
>
> The other axis is exposure: sequential IDs in URLs (`/orders/1041`) tell strangers how many orders you have and invite guessing `/orders/1042` — but you can also solve that with an integer key inside and a separate random public ID outside.
>
> Quick check: your app runs on a single Postgres server, and order IDs never appear in URLs — which key would you pick, and what's the one future change that should make you reconsider? Say "just tell me" and I'll answer it outright.

Every term defined where it first appears, the hard part named out loud, and it
stops on a question with the exit printed next to it.

---

## where-we-are

This style answers a different question and needs the most explanation, so it
gets a section rather than a caption.

### The same question as everyone else

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

281 words, the same recommendation as the other eight, and the state line
handles the awkward case honestly: nothing has happened yet, so it says so.

### The same style with work actually in flight

The state line has more to do when there is state. Asked instead about a
migration already running:

> We are partway through switching the orders table to UUIDv7 primary keys. The
> backfill is about 60% done and insert latency has roughly doubled. What now?

It answered:

> Pause or heavily throttle the backfill and watch insert p99 for 10–15 minutes — that single measurement splits the problem in two and costs you almost nothing at 60% done.
>
> Where we are: backfill ~60% complete, insert latency ~2x baseline, cause not yet isolated; nothing has been changed yet, and nothing here says revert — at 60% done, pushing through is almost always cheaper than backing out unless you're breaching SLO right now.
>
> The two possible causes, and what each means:
>
> 1. **If latency recovers when the backfill pauses**, it's contention: the backfill is competing with live inserts for I/O, buffer pool, and WAL bandwidth. This is transient and ends when the backfill ends. Resume at a lower rate — smaller batches (1k–10k rows), a short sleep between batches, walk the table in existing primary-key order for locality, and shift the heavy portion off-peak. Also check checkpoint frequency (`checkpoints_req` climbing in `pg_stat_bgwriter` means WAL pressure — raising `max_wal_size` for the migration window helps).
> 2. **If latency stays doubled while paused**, the cost is structural — it's the migration scaffolding, not the backfill. The usual suspects, in order of likelihood:
>     - **The unique index on the new UUID column already exists during backfill.** In Postgres this is the classic trap: updating an indexed column disqualifies HOT updates, so every backfilled row rewrites entries in *every* index on `orders`, and every live insert maintains one more index than before. If you can, drop that index now and build it with `CREATE UNIQUE INDEX CONCURRENTLY` after the backfill finishes.
>     - **A dual-write trigger** adding per-insert cost — check its body for anything that does a lookup rather than a pure computation.
>     - **Autovacuum falling behind** the update churn — check `n_dead_tup` on `orders`; a manual `VACUUM (ANALYZE)` between backfill phases is cheap insurance.
>
> One assumption to flag: this is written for Postgres. If you're on MySQL/InnoDB the index-maintenance point still holds but the HOT-update mechanics don't — tell me the engine and I'll adjust.
>
> (Separate topic worth deciding soon but not today: whether the old PK index survives cutover or gets dropped — that's where the doubled write amplification permanently goes away.)

Nearly every rule fires here: the next action on line one, the `Where we are:`
line under it, numbered steps, a time cost in minutes rather than "quickly", and
the tangent parked in a single parenthetical instead of derailing the answer.

### It is also the least reliable of the eight, and that is measured

The state line originally read "restate current state in one line each turn". It
never once appeared. Rewriting it to demand the literal string `Where we are:`
helped, and did not fix it:

| Wording | Produced the line |
| --- | --- |
| "Restate current state in one line each turn" | 0 of 3 runs |
| Literal `Where we are:` required, as rule 2 | 2 of 4 runs |
| …plus an explicit carve-out from the no-preamble rule | 1 of 4 runs |
| Merged with the next-action rule into rule 1 (what ships) | 2 of 5 runs |

Roughly 38% across thirteen runs of the strengthened wordings, against zero
before. The three strengthened variants are indistinguishable at this sample
size; the one that ships was chosen for being the shortest and for putting both
signature behaviours in the first rule, not because the numbers separated it.

Two caveats that cut in this style's favour. Every run above is a single
`claude -p` call, which is the worst case for a style whose whole premise is
accumulated state — there is no previous turn to summarise. And none of these
runs used the [`--enforce` hook](enforce-hook.md), which re-states the active
style every turn and exists for exactly this failure mode; in a one-shot call it
has nothing to reinforce across.

### When you want this and `/recap` is not enough

Claude Code has a built-in [session
recap](https://code.claude.com/docs/en/interactive-mode#session-recap): a
one-line summary of where the session stands, on by default, generated in the
background after at least three minutes away from an unfocused terminal, in
sessions of at least three turns, never twice in a row. `/recap` forces one.
For "I stepped away, what was I doing" it is better than this style — it is real
code with real triggers, not an instruction a model has to remember.

This style covers what recap does not:

- **Every answer, not after a three-minute absence.** Recap is built for
  returning; this is built for reading the answer in front of you.
- **In the response text, so it travels.** Recap is terminal UI. The
  `Where we are:` line is part of the answer, so it survives a paste into a PR
  description, a Slack message, or a handover note.
- **Outside the terminal.** Recap does not surface in the IDE extensions, and
  the documentation states it is always skipped in non-interactive mode — so
  `claude -p`, scripted runs, and CI never see one. A style is system prompt and
  applies everywhere.

Use both. They fail in different directions.
