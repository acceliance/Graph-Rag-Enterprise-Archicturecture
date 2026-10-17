<!-- Copied from graph-rag-application/Specifications/ai-model-recommendations.md (commit ed68a70) by sync-model-recommendations.ps1. Edit the source, then run the script again. -->

# AI model recommendations — OpenAI & Anthropic

*Measured on 2026-10-17 on the dev stack, with list prices checked the same day. This doc picks models that do the job well at low token cost for the two LLM slots, **Extraction** and **Chat (agent)**.*

## TL;DR

| Slot | Best value (default) | Cheapest that still works | When quality matters more than cost |
|---|---|---|---|
| **Extraction** (also runs the relevance gate) | **`gpt-5.6-luna`**: ≈ $0.09 / 33-page doc, rich graph | `gpt-6-luna` ≈ $0.04 · `claude-haiku-5-5` ≈ $0.05 | `claude-sonnet-5-5`: richest graph, ≈ 20× the cost |
| **Chat (agent)** | **`claude-haiku-5-5`**: ≈ $0.01 / question, fully cited | `gpt-5.6-luna` ≈ $0.02 | `claude-sonnet-5-5` ≈ $0.15 / question |
| **Embedding** | keep on-prem `bge-m3` (no token cost) | `text-embedding-3-small` $0.02 / 1M | `text-embedding-3-large` $0.13 / 1M |

The recommended setup is **Chat = `claude-haiku-5-5`, Extraction = `gpt-5.6-luna`**. Extraction is temporarily on `claude-haiku-5-5` because the OpenAI account has no credits left (see §2b). Anthropic has no embedding model; the provider for that slot is OpenAI, Voyage AI or on-prem.

## 1. Extraction benchmark

Each model re-ingested the same document, `20_ICD_MBDSS-TBQ_CMS.pdf` (33 pages, 54 chunks, 30 extraction windows), from scratch. Prompt and ontology were identical for every run. Cost = measured tokens × list price, with no prompt caching.

| Model | Entities | Relations | Wall time | Tokens in / out | **Cost / doc** | Cost / page |
|---|---:|---:|---:|---:|---:|---:|
| `claude-sonnet-5-5` | **351** | **90** | 7 min 46 s | 494 k / 84.5 k | $1.83 | $0.056 |
| `gpt-5.6-luna` ⭐ | 290 | 79 | 3 min 10 s | 280 k / 25.8 k | **$0.087** | $0.0026 |
| `gpt-5.4-mini` | 304 | 41 | 2 min 33 s | 280 k / 26.7 k | $0.33 | $0.010 |
| `gpt-4.1-mini` | 279 | 5 | 1 min 48 s | 280 k / 15.9 k | $0.14 | $0.0042 |
| `gpt-6-luna` | 161 | 84 | 2 min 25 s | 280 k / 15.3 k | **$0.036** | $0.0011 |
| `claude-haiku-5-5` | 103 | 32 | **1 min 08 s** | 415 k / 14.6 k | $0.049 | $0.0015 |

**How to read it.** For a knowledge graph, *relations* matter as much as entities. Without them the graph is a list.
- `gpt-5.6-luna` gives about 80 % of Sonnet's graph for about 5 % of the price. That's the best ratio, so it's the default.
- `gpt-6-luna` is the cheapest. It finds fewer entities but links them well. Use it for bulk or low-value corpora.
- `claude-haiku-5-5` is the fastest and very cheap, but it extracts the thinnest graph. It's fine for triage or short documents.
- `gpt-4.1-mini` finds plenty of entities but almost no relations (5). Not recommended.
- `gpt-5.4-mini` costs nearly 4× more than `gpt-5.6-luna` for a weaker graph.
- `claude-sonnet-5-5` gives the best result, but at $1.83 and 8 min per 33 pages it's for high-value documents only.

Anthropic input counts run higher than OpenAI's on the same text (415–494 k vs 280 k), because the tokenizer differs and the forced-tool schema is resent on every call. That's already reflected in the costs.

## 2. Chat (agent) benchmark

Every model got the same question on the ingested corpus: *"Which files does a state exchange with CMS in the MBDSS TBQ interface, over which transfer mechanism, and what record types do they contain?"* Every answer was checked for the key facts: MMATBQ / MMATBQR files, EFT over MDCN, and header/detail/trailer records.

| Model | Correct | Citations | LLM calls | Time | Tokens in / out | **Cost / question** |
|---|:---:|---:|---:|---:|---:|---:|
| `claude-haiku-5-5` ⭐ | ✅ | 8 | 4 | 20 s | 83.5 k / 4.2 k | **$0.010** |
| `gpt-5.6-luna` | ✅ | 7 | 5 | 15 s | 85.0 k / 1.4 k | $0.019 |
| `gpt-4.1-mini` | ✅ | **0** | 3 | 8 s | 31.7 k / 1.0 k | $0.014 |
| `gpt-5.6-terra` | ✅ | 3 | 3 | 9 s | 39.9 k / 1.0 k | $0.092 |
| `gpt-6-luna` | ✅ (no trailer record) | 8 | **26** | 47 s | 952 k / 2.4 k | $0.096 |
| `claude-sonnet-5-5` | ✅ | 8 | 3 | 24 s | 57.8 k / 3.1 k | $0.146 |

- `claude-haiku-5-5` gives a complete, fully cited answer at the lowest cost. It's the default.
- `gpt-5.6-luna` is just as good and the best OpenAI choice.
- `gpt-4.1-mini` answered with **no citations**, which is unacceptable for a grounded RAG.
- `gpt-6-luna` looped through 26 tool calls and read about 1 M input tokens for one question.
- `claude-sonnet-5-5` writes the most thorough answers. Use it when answer quality is worth about 15× the cost.

## 2b. Real corpus run: 11 sample documents (`samples/source-docs`)

The single-document benchmark was confirmed at scale. The OpenAI credits ran out partway through the run, so four documents finished on `claude-haiku-5-5`.

| Document | Pages | Extraction model | Entities / relations | Tokens in / out | Cost |
|---|---:|---|---:|---:|---:|
| 01_EA-Blueprint_PBGC | 106 | `gpt-5.6-luna` | 396 / 232 | 405 k / 50 k | $0.14 |
| 06_SDD_FDsys-v5_GPO | 96 | `gpt-5.6-luna` | 335 / 246 | 307 k / 50 k | $0.12 |
| 08_SAD_CREATE_ITEA | 20 | `gpt-5.6-luna` | 59 / 34 | 46 k / 6.5 k | $0.017 |
| 09_SAD_LocAdoc | 9 | `gpt-5.6-luna` | 33 / 41 | 27 k / 4.8 k | $0.011 |
| 13_DAT_VITAM (FR) | 220 | `gpt-5.6-luna` | 768 / 466 | 1.13 M / 121 k | $0.37 |
| 16_MITA_Vermont-Medicaid | 399 | `gpt-5.6-luna` | 853 / 361 | 2.10 M / 197 k | $0.66 |
| 18_SDSI_CH-Sud-Essonne (FR) | 9 | `gpt-5.6-luna` | 37 / 19 | 28 k / 4.7 k | $0.011 |
| 05_SDD_GovInfo-v7_GPO | 101 | `claude-haiku-5-5` | 186 / 67 | 500 k / 31 k | $0.065 |
| 07_SDD_R-ICMS_FDOT | 180 | `claude-haiku-5-5` | 349 / 101 | 1.33 M / 58 k | $0.16 |
| 19_Interface-Spec_SSIS-MMIS | 174 | `claude-haiku-5-5` | 339 / 88 | 1.70 M / 53 k | $0.20 |
| 21_ICD_Collections-SFTP | 36 | `claude-haiku-5-5` | 100 / 46 | (resumed run, partial count) | – |

- **`gpt-5.6-luna`** extracted 859 pages for **$1.33**: about **$0.0015 per page**, with 2.9 entities and 1.6 relations per page.
- **`claude-haiku-5-5`** extracted 455 pages for **$0.42**: about **$0.0009 per page**, with 1.9 entities and 0.56 relations per page.
- Haiku costs about 40 % less per page but yields roughly 1/3 the relations, so the gpt-5.6-luna default stands. Haiku is the fallback when OpenAI is unavailable or out of credits. To bring 05/07/19/21 up to the same depth, re-ingest them once OpenAI credits are restored.
- French documents (13, 18) extracted as well as English ones.

## 3. List prices (USD per 1M tokens, standard tier)

**Anthropic** (official price table, cached 2026-10-06):

| Model | Input | Output | Context | Notes |
|---|---:|---:|---|---|
| `claude-haiku-5-5` | 0.10 | 0.50 | 1M | $0.50 / $2.50 beyond 100 K prompt tokens |
| `claude-sonnet-5-5` | 2.00 | 10.00 | 1M | cache reads $0.20 |
| `claude-opus-5-5` | 4.00 | 20.00 | 1M | not needed for this job |
| `claude-haiku-4-5` | 1.00 | 5.00 | 200K | 10× Haiku 5.5's price, so skip it |

**OpenAI** (developers.openai.com/api/docs/pricing, read 2026-10-17):

| Model | Input | Cached in | Output | Notes |
|---|---:|---:|---:|---|
| `gpt-6-luna` | 0.10 | 0.01 | 0.50 | reasoning model |
| `gpt-5.6-luna` | 0.20 | 0.02 | 1.20 | reasoning model |
| `gpt-5-nano` | 0.05 | 0.005 | 0.40 | not benchmarked |
| `gpt-4.1-nano` | 0.10 | 0.025 | 0.40 | not benchmarked |
| `gpt-4.1-mini` | 0.40 | 0.10 | 1.60 | no reasoning step |
| `gpt-5.4-mini` | 0.75 | 0.075 | 4.50 | |
| `gpt-5.6-terra` | 2.00 | 0.20 | 12.00 | |
| `gpt-6.1-sol` / `gpt-6-sol` | 2.00 | 0.10 / 0.20 | 10.00 | ⚠ no function tools on Chat Completions |
| `text-embedding-3-small` / `-large` | 0.02 / 0.13 | – | – | |

Batch and Flex are 50 % off on OpenAI, and the Batch API is 50 % off on Anthropic. Ingestion isn't latency-sensitive, so batching it would halve extraction costs, but the app doesn't support that yet.

## 4. Models to avoid in this app

| Model | Why |
|---|---|
| `gpt-3.5-turbo` | 16 k context, 4,096 max output: extraction fails (`max_tokens is too large`) |
| `gpt-4` | 8 k context: extraction fails (`context_length_exceeded`), and it costs $30 / $60 |
| `claude-3-5-haiku-latest` | retired (404) |
| `gpt-6.1-sol`, `gpt-6-astra` (chat slot) | OpenAI disallows function tools on Chat Completions for them, and the agent needs tools |
| `gpt-4.1-mini` (chat slot) | answers without citations |
| `gpt-6-luna` (chat slot) | tool-call loops multiply the input tokens |

## 5. Compatibility fixes this relies on (2026-10-17)

These fixes in `graphrag-api/graphrag/ai/` let every model above run:

- **Anthropic repair round** now answers the rejected `tool_use` with a `tool_result`. It used to return a 400.
- **Sonnet / Opus 5.5** reject forced `tool_choice`. Extraction now falls back to `auto` with the instruction "answer only by calling the tool".
- **OpenAI models without Structured Outputs** step down from `json_schema` to `json_object` to a plain completion. The answer is then validated, with one repair round.
- **OpenAI reasoning models (GPT-5 and later)** get the right parameters automatically, remembered per model: `max_completion_tokens` (plus 4,096 tokens of reasoning headroom), no `temperature`, and `reasoning_effort: low`, or `none` when function tools are sent.
- **An entity's `confidence` is optional** in the extraction schema (it defaults to 0.5). Previously, `gpt-5.6-luna` occasionally leaving it out failed the whole 180-page document.
- **Nested arrays sent as JSON strings** (`"entities": "[…]"`, seen with Haiku 5.5) are decoded before validation instead of being rejected.

## 6. Caveats

- The extraction numbers come from one document and the agent numbers from one question. Use them to rank models, not as a guarantee.
- Entity and relation counts measure *coverage*, not accuracy. Spot-check the graph (Review screen) before switching a production corpus.
- Prices change. OpenAI's GPT-5.6 Sol carries promotional pricing "at least through November 21, 2026".
- Prompt caching wasn't measured. It would lower agent costs (the system prompt and tool definitions repeat on every call) on both providers.
