# Somani ⛩️

Somani turns Japanese material you actually encounter — a menu, a news
article, a photo of a sign — into vocabulary you can save, and then into
AI role-play conversations where you practice using that vocabulary, not
just recognizing it.

```
upload → extract text → match JLPT vocabulary → save words → practice in an adventure → words get credited
```

## How it works

**Upload** — attach a photo, PDF, or text of real Japanese material.
Gemini extracts the text and summarizes the topic. Every word in it that
matches the JLPT dictionary is highlighted and tappable so you can save it
with one click; unmatched taps still let you add a word manually, with
Gemini filling in a reading, meaning, and estimated level.

**Save words, set a goal** — saved words carry a target: how many times
you need to actually produce the word in conversation before it counts as
learned.

**Practice in an adventure** — start a role-play conversation with an AI
character (a news reporter, a coworker, a real-estate agent, a nurse — one
scene per character per JLPT level). The character steers the conversation
toward openings for your target words without just handing them to you.

**Get credited, not just graded** — a deterministic pass checks each
message you send for target-word usage the moment you send it; a second,
slower Gemini pass reviews the line for grammar, vocabulary, and nuance,
and can revoke a word's credit if it turns out you fumbled the word itself
rather than something else in the sentence. Credit sits as *pending* until
that review completes, so nothing is confirmed on a guess.

**Come back to it** — saved words get a `next_review_at` date, nudged
earlier for words that were credited then revoked (the near-misses) and
later for words that held up.

## Under the hood

- **Extraction & feedback**: Gemini (`gemini-ai` gem) — OCR on uploads,
  chat replies in adventures, per-message grammar/vocabulary/nuance
  review, and structured JSON output for word explanations and JLPT level
  estimates
- **Scene matching**: PostgreSQL + pgvector (`neighbor` gem) — each scene
  is embedded, and a new adventure is matched to the nearest scene for its
  target words by cosine distance
- **JLPT dictionary**: a seeded word/grammar/proverb list (~8k entries
  across N5–N1, `bin/rails jlpt:import`), with a background verifier that
  checks levels against jisho.org and corrects the seed data over time
  without touching a level a learner set themselves
- **Voice**: Azure Cognitive Services Neural TTS for character replies
- **Media storage**: Cloudinary
- **Background jobs**: Solid Queue
- **Real-time updates**: Hotwire (Turbo Streams) — the word tracker and
  goal banner update live as credit comes in
- **Auth & authorization**: Devise + Pundit

## Stack

Rails 8.1 · Ruby 3.3 · PostgreSQL + pgvector · Solid Queue / Cache ·
Hotwire (Turbo + Stimulus) · Devise + Pundit · Gemini, Azure TTS,
Cloudinary as external services · Heroku (`Procfile`: web / worker /
release)

## Getting started

```bash
bin/setup                  # bundle, prepare the database
cp .template.env .env      # then fill in the keys below
bin/rails jlpt:import      # seed the JLPT dictionary
bin/dev
```

`.template.env` currently lists `CLOUDINARY_URL` and `GEMINI_API_KEY`.
You'll also need to set `GEMINI_MODEL` yourself (it's read via
`ENV.fetch`, so the app raises without it) — check `app/services` and
`app/jobs` for the Gemini calls if you're unsure which model string to
use. Azure TTS keys are optional; without them, character voice playback
won't work but the rest of the app does.

## Known gaps

This is a fast-moving student project, and the README is meant to be
honest about where it currently stands rather than aspirational:

- No CI is configured yet — checks are run locally.
- Test coverage is uneven: models, jobs, and services central to the
  credit ledger and review pipeline have real tests, but the Pundit
  policy test files are still placeholder stubs with empty method bodies.
- Word-review scheduling currently has two separate code paths (a
  per-word manual review action, and an end-of-adventure scheduler) with
  their own hardcoded intervals rather than one shared scheduler.
- `GEMINI_MODEL` isn't in `.template.env` yet, so a fresh clone needs it
  added manually before the app will boot.

## Origin

Built on the [Le Wagon](https://www.lewagon.com) Rails template by
Cassandra Santoso, Rie Taylor, Nina Galindo, and James Grigson.
