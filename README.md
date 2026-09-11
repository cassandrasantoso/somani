# Somani ⛩️

**Learn Japanese from your own world.** Upload a photo of a menu, a news
article, a sign — Somani turns it into vocabulary, role-play adventures
with AI characters, and timed reading drills. What you study is what you
actually encountered.

```
upload → extract → collect words → practice in conversation → read faster
```

## The three loops

**Collect** — upload any Japanese media (photo, PDF, text, audio). Text is
extracted, every JLPT word in it is highlighted and tappable, and a
character + scene is generated from the topic so the library grows with
what learners read.

**Practice** — chat your way through adventures: replies stream in with
furigana readings, characters speak with natural voices, and the words you
saved get engineered into the conversation. Every line you write is
reviewed — grammar, vocabulary, nuance — and credited toward your goals.
Mastered words flow into spaced repetition.

**Read** — every upload is a speed-reading drill (速読): read the passage
against a live timer, answer comprehension questions, and chase a target
10% above your best pace — armed only while comprehension stays above 70%.
Or listen instead: the passage plays as audio and the text never shows.

## Retention, on purpose

- **Spaced repetition** — an SM-2 style scheduler (again / good / easy,
  ease factors, growing intervals) driven by real production evidence:
  words you fumbled in conversation come back sooner
- **Streaks** — consecutive active days, shown on the home card
- **Reminders** — daily review nudges, delivered in each learner's own
  time zone
- **Friends** — a weekly leaderboard ranked by words credited

## Under the hood

| Concern | How |
|---|---|
| LLM calls | One `Llm` facade; **one call per chat turn** (down from three), streaming, JSON-mode structured output |
| Prompt caching | System prompts are byte-stable per adventure so Gemini's implicit caching (75% off cached tokens) actually hits |
| Cost telemetry | Every call records model, tokens, duration and cached tokens to `llm_calls`; `bin/rails llm:usage` reports estimated spend |
| Providers | Swap Gemini for any OpenAI-compatible API (OpenAI, OpenRouter, Groq, Ollama…) with env vars — see [PROVIDERS.md](PROVIDERS.md) |
| JLPT leveling | Seeded dictionary + LLM estimation for unknown words + automated jisho.org verification; corrections propagate to every saved word |
| Scene library | 9 bundled characters, plus scenes generated from upload topics (cosine-deduped) — content compounds across all users |
| Guardrails | Per-user daily quotas, per-IP rate limits (Rack::Attack), server-side grading, prompt-injection delimiting |
| Observability | Sentry (no-op without a DSN), 125-test suite, GitHub Actions CI (RuboCop, Brakeman, bundler-audit, importmap audit) |

## Stack

Rails 8 · Hotwire (Turbo + Stimulus) · PostgreSQL + pgvector · Solid
Queue / Cache / Cable · Sidecar services: Gemini (chat + embeddings),
Azure TTS, Cloudinary · Devise + Pundit · Kamal for deploys

## Getting started

```bash
bin/setup                  # bundle, prepare the database
cp .template.env .env      # then fill in the keys
bin/rails jlpt:import      # seed the JLPT dictionary (~8k words)
bin/dev
```

You'll need `GEMINI_API_KEY` at minimum; Azure TTS and Cloudinary keys
unlock audio and media storage (see `.template.env` for everything).
A sample menu on the upload page runs the full pipeline without any
Japanese material of your own.

## Testing & CI

```bash
bin/rails test             # 125 tests
bin/rubocop && bin/brakeman
```

CI runs on every PR with a pgvector Postgres service. macOS note: run
local test suites with `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` to avoid
an ObjC fork crash in parallel workers.

## Deploying

See [DEPLOY.md](DEPLOY.md) — a full Kamal runbook including the pgvector
Postgres accessory, the secrets list, and post-deploy checks.

## Origin

Built on the [Le Wagon](https://www.lewagon.com) Rails template, then
grown far beyond it.
