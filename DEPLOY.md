# Acceliance Graph-RAG — deployment kit

[![Maintained by Acceliance](https://img.shields.io/badge/maintained%20by-Acceliance-0072C6)](https://github.com/acceliance)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-success)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/acceliance/Graph-Rag-Deploy?label=last%20commit)](https://github.com/acceliance/Graph-Rag-Deploy/commits/main)
[![Docker Hub](https://img.shields.io/badge/images-Docker%20Hub-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/u/acceliance)

Turn a folder of PDFs into a **typed knowledge graph** you can question. You declare a data
model once (classes, attributes, relations, enumerations); the product extracts matching data
from every PDF into **Neo4j**, keeps the evidence (chunks and pages) in **Qdrant**, and answers
questions with both — through a web agent, a REST API and an **MCP** endpoint for external AI
hosts. Works with Claude, OpenAI, or an **on-premises** OpenAI-compatible server (Ollama,
vLLM, Open WebUI…).

This repository is the **deployment kit only**: a Compose file, an environment template, start
and backup scripts, reverse-proxy examples and samples. It builds nothing; it pulls the
published images. **Free to deploy**: the kit is open source (Apache 2.0) and the product
images are **free of use and free of charge** under their own licence — see *Licence* at the
end, and *Licensing* (§9a) for how to let Acceliance know you're a customer.

> **Status.** The product images referenced in `.env.example` (`acceliance/graphrag-api`,
> `acceliance/graphrag-web`) are published with the first release, on the Acceliance Docker Hub
> organisation: [hub.docker.com/u/acceliance](https://hub.docker.com/u/acceliance). Until that
> release is published, `docker compose pull` will fail on those two images — the kit itself is
> final.

---

## 1. Prerequisites

- Docker Engine 24+ with the Compose v2 plugin (Linux), or Docker Desktop (Windows, macOS).
- 4 vCPU / 16 GB RAM for the v1 target corpus (10 000 documents); 2 vCPU / 8 GB is enough
  to try it. See *Sizing*.
- Network access to Docker Hub (the four images) and to your AI provider — or none at all if
  every model runs on-premises.
- An AI provider for three roles: **chat** (agent), **extraction** (structured output) and
  **embeddings**. Anthropic serves no embedding model, so embeddings come from OpenAI or an
  on-premises server. Keys are entered in the application after start-up, never in a file.

## 2. Quick start

```bash
git clone https://github.com/acceliance/Graph-Rag-Deploy.git
cd Graph-Rag-Deploy
scripts/up.sh
```

```powershell
git clone https://github.com/acceliance/Graph-Rag-Deploy.git
cd Graph-Rag-Deploy
.\scripts\up.ps1
```

The script checks Docker, creates `.env` from `.env.example` with **generated secrets**,
creates `./data`, pulls the pinned images, starts the stack and waits until the web edge is
healthy. Then open **http://localhost:8080**.

Doing it by hand instead:

```bash
cp .env.example .env        # set NEO4J_PASSWORD and QDRANT_API_KEY (both required)
docker compose pull
docker compose up -d
docker compose ps
```

Never run `docker compose up --build` here: there is no source tree and no `build:` section.

## 3. First start, step by step

1. **Administrator.** The first visit shows the bootstrap screen: create the first account.
   There is no seeded account and nothing is reachable anonymously.
2. **AI settings** (*Admin ▸ AI settings*). Choose a provider and a model for each of the
   three slots, enter the key or the on-premises URL, press *Test*. For an on-premises server
   also set the context window the model was loaded with. Keys are stored under `./data/api`
   and re-read on every request — no restart.
3. **Model** (*Model*). Upload a model JSON, or click *Load the sample* (billing model). Check
   its Graph-RAG settings: which attributes identify an instance of each class, how to
   normalise them, which classes drive the relevance gate. They are GraphRag stereotypes inside
   the model, so a ModelioUtils export annotated with the GraphRag module arrives filled in;
   what you change in the editor is written back into the model. *Initialise*. The model is
   projected into Neo4j as a metamodel and rendered as a Mermaid diagram. No model yet? Design
   it in Modelio and export it with its stereotypes ([§3a](#3a-designing-the-model-in-modelio)),
   or draft one with an AI assistant from the schema and the sample
   ([`schemas/README.md`](schemas/README.md)). Relevance-gate thresholds are set per model version afterwards
   (*AI settings*).
4. **Documents.** Drop PDFs. Each one is parsed (OCR for scanned pages), checked for relevance
   against the model (a cooking recipe against a billing model is rejected with a reason),
   extracted, written to the graph and indexed. Try `samples/pdf/` — see
   [`samples/README.md`](samples/README.md) for what to expect.
5. **Agent.** Ask. Every factual sentence carries a citation `[document p.N]` that opens the
   page. Pick a **profile** (*financial analyst*, *enterprise architect*, or your own) to change
   the agent's role and persona; import the two samples from *Admin ▸ Profiles*. To write your
   own profile, draft its prompt with the Acceliance prompt generator at
   <https://masterprompter.acceliance.fr>, then transcribe the generated fields into the
   profile's front-matter (see [`schemas/README.md`](schemas/README.md)).

## 3a. Designing the model in Modelio

Instead of writing the model JSON by hand, design it as a UML class model in
[Modelio](https://www.modelio.org/) 5.4 and let two Modelio modules generate the file: the
**GraphRag** module declares the Graph-RAG stereotypes, and **ModelioUtils** exports the model,
stereotypes included, in the exact format the *Model* screen uploads
([`schemas/schema_uml_model.json`](schemas/schema_uml_model.json)).

**Once per Modelio installation**

1. Build and install **ModelioUtils** 5.4.01 from
   [gitlab.com/jose.torres.acceliance/modelioutils](https://gitlab.com/jose.torres.acceliance/modelioutils).
   GraphRag requires it.
2. Add [`modelio/GraphRag_5.4.01.jmdac`](modelio/) to the catalog: *Configuration ▸ Modules
   catalog ▸ Add a module to the catalog…*.

**Once per Modelio project**

3. In the **Modules** view, deploy ModelioUtils, then GraphRag.
4. Still in the **Modules** view, select ModelioUtils and set its parameter **Enable Model
   Export** to true (it is off by default, and also enables the import).

**Designing the model**

5. Model the domain in one package: classes (with a `domain`), attributes, relations and
   enumerations. Describe each of them: the descriptions are exported and help the extraction.
6. Apply the stereotypes and fill their tagged values in the element's properties:
   - `GraphRagIdentity` on each attribute that identifies an instance (with
     `graphRagNormalise`, and `graphRagIdentityOrder` for a composite key);
   - `GraphRagEntity` on a class for its matching, anchor, extraction hints and extraction
     group;
   - `GraphRagEmbed` on a long String attribute to index on its own (applied once on the class
     that declares it, subclasses inherit it).

   [`schemas/README.md`](schemas/README.md) lists every tagged value and its allowed values;
   [`samples/model/billing-model-stereotyped.json`](samples/model/billing-model-stereotyped.json)
   shows a complete example.

**Generating the model file**

7. Right-click the package ▸ **Export Model** (ModelioUtils), choose the output folder,
   *Export*. The JSON file holds the model and every GraphRag stereotype applied to it.
8. Upload that file on the *Model* screen. The settings editor opens already filled in from the
   stereotypes; *Validate*, then *Initialise* (or *Upgrade* for a new version of a model in use).

**The way back.** A setting changed in the Graph-RAG editor is written into the model as a
stereotype. *Model ▸ Settings ▸ Download the model* returns the file; right-click the package ▸
**Import Model** (ModelioUtils) brings the changes back into Modelio, so the Modelio project
stays the reference. The import needs the GraphRag module deployed in the project, since it
checks each stereotype property's name and type against it.

## 4. Configuration reference

All variables live in [`.env.example`](.env.example), with comments. The ones that matter:

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `NEO4J_PASSWORD` | **yes** | none | Neo4j auth. No fallback: the stack refuses to start without it |
| `QDRANT_API_KEY` | **yes** | none | Qdrant auth on the internal network |
| `GRAPHRAG_API_IMAGE`, `GRAPHRAG_WEB_IMAGE` | yes | pinned `vX.Y.Z` | Product images; update both together |
| `GRAPHRAG_HTTP_BIND`, `GRAPHRAG_HTTP_PORT` | no | `0.0.0.0`, `8080` | The only published port; bind `127.0.0.1` behind a reverse proxy |
| `AUTH_COOKIE_SECURE` | no | `true` | Requires HTTPS; `false` only for an HTTP pilot |
| `NEO4J_HEAP_MAX`, `NEO4J_PAGECACHE`, `QDRANT_ON_DISK_VECTORS` | no | `2G`, `1G`, `false` | Sizing |
| `GRAPHRAG_MAX_UPLOAD_MB`, `GRAPHRAG_MAX_PAGES` | no | `50`, `500` | Upload limits |
| `GRAPHRAG_OCR_LANGS` | no | `fra+eng` | OCR languages (packs shipped: French, English) |
| `GRAPHRAG_RETENTION_DAYS` | no | `0` | Auto-purge documents older than N days |
| `MCP_ENABLED`, `MCP_ALLOWED_HOSTS` | when MCP is used | unset | See *MCP* |

**Not in `.env`, on purpose:** AI provider keys, on-premises URLs and model names. They are
entered from the application and stored under `./data/api`, so no deployment input ever holds a
secret.

## 5. Network, TLS and reverse proxy

The stack publishes **one** plain-HTTP port. Neo4j and Qdrant are never reachable from the
network. For anything beyond a pilot on a trusted LAN:

1. Set `GRAPHRAG_HTTP_BIND=127.0.0.1` in `.env` and restart (`scripts/up.sh`).
2. Put a TLS-terminating reverse proxy in front: [`reverse-proxy/nginx.conf.example`](reverse-proxy/nginx.conf.example)
   or [`reverse-proxy/apache.conf.example`](reverse-proxy/apache.conf.example). Both keep the
   `Host` header with its port (needed by the MCP allow-list), forward `X-Forwarded-Proto`, allow
   uploads of at least `GRAPHRAG_MAX_UPLOAD_MB`, and wait 300 s for the agent.
3. Keep `AUTH_COOKIE_SECURE=true`.

## 6. MCP — connecting an external AI host

The graph and its evidence can be queried by Claude Desktop, Claude Code, Copilot Studio or
your own agents through the Model Context Protocol, **read-only**, **off by default**, and
**key-gated** (without a key, nothing is served).

1. *Admin ▸ MCP*: switch on, issue a key (shown once), set the result cap.
2. In `.env`, set `MCP_ALLOWED_HOSTS` to the host and port your clients use
   (`graphrag.example.com:*`) and restart. Without it, every non-localhost client gets `421`.
3. Endpoint `https://<host>/api/mcp`, transport *streamable HTTP*, header
   `Authorization: Bearer <key>`. Have the host read `graphrag://schema/model` first.
4. *Admin ▸ MCP ▸ Last connections* shows who called what.

`MCP_ENABLED=false` in `.env` locks the feature for the whole deployment.

## 7. Day-2 operations

### Updating the product

```bash
# edit GRAPHRAG_API_IMAGE / GRAPHRAG_WEB_IMAGE in .env to the new release tag, then
scripts/up.sh          # pulls and restarts; ./data is never touched by an image
```

The API migrates its own data layout at start-up when needed and refuses to start on data
written by a newer version (downgrade guard). A release that needs a re-index says so in its
notes and registers a job you start from *Jobs*.

### Upgrading the data model

*Model ▸ Upgrade* shows a diff (added, removed, renamed classes and attributes, identity-key
changes) and the cost of re-indexing before you apply. The previous version stays queryable
until the re-index completes; *Abandon* returns to it at any time. With Modelio
([§3a](#3a-designing-the-model-in-modelio)), change the model there, export it again and
upload the new file in *Model ▸ Upgrade*.

### Backup and restore

Cold backup, consistent by construction (stops the containers for the duration):

```bash
scripts/backup.sh            # → backups/graphrag-<UTC stamp>.tar.gz  (data/ + .env)
```

```powershell
.\scripts\backup.ps1         # → backups\graphrag-<UTC stamp>.zip
```

Restore: `docker compose down`, replace `./data` (and `.env`) from the archive, `scripts/up.sh`.
On start the API reconciles its ledgers against both stores and reports any orphan on *About*.

### Rebuild from originals

`./data/api` alone (PDFs, ledgers, model, prompts, users) is enough to rebuild both stores:
*About ▸ Rebuild* replays every document. With *reuse extraction* it costs no LLM call.

### Sizing

| Corpus (20-page PDFs) | Host | Notes |
|---|---|---|
| 1 000 documents | 2 vCPU / 8 GB | defaults are fine |
| 10 000 documents | 4 vCPU / 16 GB | set `QDRANT_ON_DISK_VECTORS=true` under 16 GB |
| OCR-heavy corpora | +1 vCPU during ingestion | OCR renditions double the size of originals |

Ingestion speed is bound by the extraction model, not by the stores.

## 8. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `required variable NEO4J_PASSWORD is missing a value` | `.env` missing or the line empty. Run `scripts/up.sh`, or set both secrets by hand |
| `graphrag-api` restarts, log says `/data` not writable | Linux bind-mount ownership: `sudo chown -R 10001:10001 data/api` |
| `docker compose pull` fails on `acceliance/graphrag-*` | The release is not published yet, or the tag in `.env` does not exist. Check the tag on [Docker Hub](https://hub.docker.com/u/acceliance) |
| `toomanyrequests` from Docker Hub | Anonymous limit (100 pulls / 6 h per IP). `docker login` with a free account raises it |
| Login page never appears, cookie warnings in the browser | Serving over plain HTTP with `AUTH_COOKIE_SECURE=true`. Use HTTPS, or set it to `false` for a pilot |
| MCP client gets `421` | `MCP_ALLOWED_HOSTS` does not include the host:port used by the client |
| MCP client gets `404` | MCP is off, or no key has been issued — by design indistinguishable |
| Port `8080` already in use | Change `GRAPHRAG_HTTP_PORT` in `.env` |
| A document is `REJECTED` | The relevance gate found none of the model's anchor classes; read the reason on the row. An admin can *Force* it |

Logs: `docker compose logs -f graphrag-api graphrag-web`. Application logs are also in
*Admin ▸ Logs*.

## 9. Security notes

- One published port; databases on the internal network only; Qdrant behind an API key;
  Neo4j password required.
- Accounts managed by the application, first-administrator bootstrap, session cookie
  `HttpOnly` / `SameSite=Lax` / `Secure`.
- MCP off by default, key hashed at rest, host allow-list.
- The product images are compiled and constant-hidden; they contain no customer data and no
  secret. Everything mutable is under `./data`, which you own.
- Chunks and extracted values are sent to the AI providers you configure. For sensitive
  corpora, configure an on-premises provider for all three slots: nothing then leaves your
  network.

## 9a. Licensing

Graph-RAG is **free to use and free of charge**. There is no paid tier, no seat limit, no
feature you need to unlock. A licence, if you get one, does not change what the product does —
it only tells Acceliance that you are running it.

- **Request a free-of-charge licence by e-mail at contact@acceliance.fr.** Acceliance wants to
  keep track of which customers use its free-of-use tools; that is the only reason to ask.
- The licence file you receive contains **nothing but your organisation's name** — no
  expiry, no seat count, no limitation of use of any kind.
- **Without a licence, ingestion is capped at 50 PDF documents.** Drop the `.lic` file
  Acceliance sends you at `./data/api/licence.lic` — no restart needed — and the cap lifts.
- Check the current state any time: `curl http://localhost:8080/api/licence` reports whether a
  licence is installed and for whom.

## 10. Layout of this repository

```
docker-compose.yaml          the stack (pull only, no build)
.env.example                 every variable, commented
scripts/up.sh · up.ps1       preflight, secrets, pull, start, wait
scripts/backup.sh · .ps1     cold backup of ./data + .env
reverse-proxy/               nginx and Apache TLS front-door examples
schemas/                     JSON Schema for the model, ledger and prompt files — see schemas/README.md
samples/model/               billing model (Graph-RAG settings as GraphRag stereotypes)
samples/pdf/                 two invoices (one references a missing contract) + one recipe
samples/profiles/            financial-analyst.md · enterprise-architect.md
modelio/                     GraphRag_<version>.jmdac, the Modelio module of the GraphRag stereotypes (§3a)
data/                        created at first start, never committed
```

Specifications of the product live in the private application repository. Issues and
questions: open an issue on this repository.

## 11. Licence

Two licences apply, on purpose, to two different things:

| What | Licence | In short |
|---|---|---|
| The files of this repository: Compose file, `.env.example`, scripts, reverse-proxy examples, samples (model, PDFs, profiles) | [Apache License 2.0](LICENSE) | Use, modify, redistribute freely, including in your own deployment tooling |
| The product images `acceliance/graphrag-api` and `acceliance/graphrag-web` | [Acceliance Graph-RAG Image Licence](LICENSE-IMAGES.md) | Free of charge to pull, mirror privately and run, for internal or commercial use; no reverse-engineering, no redistribution, no derivative images. Your data under `./data` is yours |
| Neo4j Community, Qdrant and the open-source components inside the images | Their own licences (GPL v3, Apache 2.0, …) | Unchanged by either licence above |

A free `.lic` licence file (see *Licensing*, §9a) is provided upon asking by e-mail at
contact@acceliance.fr. Without it, ingestion is limited to 50 PDF documents; installing the
free licence unlocks the limit.
