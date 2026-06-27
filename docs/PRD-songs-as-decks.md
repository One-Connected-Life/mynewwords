# Songs as decks

Turn a beloved song into a study deck: its vocabulary, verb conjugations, and a few
example sentences — with a one-tap link to **listen** to the original. Shipped 2026-06-27.

## Why
A song is vocabulary you already half-know by heart. Drilling the words of a song you can
hum is far stickier than a cold topic list — and it ties listening (real Dutch, real
rhythm) to practice.

## What a song deck is
A normal `Deck` (so the FSRS drill engine practices it for free) plus song metadata:
- `listen_url` (a youtube.com watch link — plays in YouTube Music too), `artist`, `year`.
- Vocabulary as `kind: "word"` terms (so they count in stats and the "all words" drill).
- **Verbs carry a conjugation table** — present / past / future × all six pronouns
  (ik, jij, hij, wij, jullie, zij) — stored as JSON on the nl `Translation#conjugation`.
- A handful of `kind: "sentence"` terms — **original** beginner sentences themed on the
  song, which the drill sprinkles between word cards.

## The copyright line (load-bearing)
The repo is public (AGPL); song lyrics are copyrighted. So **no verbatim lyrics are stored
anywhere** — not in the repo, not in the DB. We store individual words (not copyrightable),
factual conjugation tables, and our own example sentences. The real lyrics are one tap away
via the ▶︎ Listen link.

## How the content is built
- `SongDeckGenerator` (Sonnet — conjugation accuracy matters) produces a song's content
  once, via `rake songs:generate[slug]`. Output is committed as `db/songs/<slug>.json`.
- `SongCatalog` holds the metadata + reads those JSON files. Because content is **static and
  committed**, adding a song to your account is **instant and offline** — no API call, no
  per-build cost, deterministic. Re-adding a song you already have is a no-op (idempotent on
  `listen_url`).

## Where it surfaces
- **Add tab → 🎵 From a song → `/songs`** — catalogue with ▶︎ Listen + "Add deck" / "Drill →".
- **Home** — a song deck row shows a ▶︎ Listen button (instead of "+ words").
- **Word page** (`/terms/:id`) — a verb shows its full conjugation table.
- **Drill reveal** — a verb's conjugation table appears on the answer beat, beside
  etymology/mnemonic.

## The starter catalogue (3 older Dutch classics)
| Song | Artist | Year | Words | Verbs | Sentences |
|---|---|---|--:|--:|--:|
| Het Dorp | Wim Sonneveld | 1974 | 38 | 15 | 8 |
| Zij gelooft in mij | André Hazes | 1981 | 35 | 13 | 8 |
| 't Is een nacht | Guus Meeuwis | 1995 | 32 | 11 | 8 |
| **Total** | | | **105** | **39** | **24** |

**129 cards total** (105 words + 24 sentences), 39 of them with full conjugation tables.

## Adding more songs
1. Add a metadata row to `SongCatalog::SONGS` (slug, title, artist, year, listen_url).
2. `set -a; . ./.env; set +a && rake songs:generate[slug]` → writes `db/songs/<slug>.json`.
3. Spot-check conjugations, commit the JSON. It appears in the catalogue automatically.

## Tasks
- `rake songs:generate[slug]` — (re)generate one song's content (omit slug → all).
- `rake songs:counts` — print per-song + total word/verb/sentence counts.
- `rake "songs:seed[email]"` — add all catalogue songs to a user's account (testing).

## Possible follow-ups
- A "verb" `kind` + drilling individual conjugated forms (today verbs drill as the lemma;
  the table is a teaching panel, not separate cards).
- Per-song listen link to YouTube **Music** specifically, or an Apple Music / buy link.
- "Practice this line" — line-level cards (needs a licensing answer for verbatim lyrics).
- Let a user paste any song and auto-build a deck (reuses `SongDeckGenerator`).
