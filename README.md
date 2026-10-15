# Graph-RAG enterprise architecture agent

[![Maintained by Acceliance](https://img.shields.io/badge/maintained%20by-Acceliance-0072C6)](https://github.com/acceliance)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-success)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/acceliance/Graph-Rag-Enterprise-Archicturecture?label=last%20commit)](https://github.com/acceliance/Graph-Rag-Enterprise-Archicturecture/commits/main)
[![Docker Hub](https://img.shields.io/badge/images-Docker%20Hub-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/repositories/acceliance)
[![Neo4j](https://img.shields.io/badge/graph-Neo4j-4581C3?logo=neo4j&logoColor=white)](https://neo4j.com/)
[![Qdrant](https://img.shields.io/badge/vectors-Qdrant-DC244C)](https://qdrant.tech/)
[![Modelio](https://img.shields.io/badge/model-Modelio%205.4-5A8F29)](https://www.modelio.org/)

> **First time here?** Follow the [**tutorial**](docs/tutorial/README.md): seven illustrated steps, from starting the stack to asking the *Enterprise Architect* agent about the 15 sample documents.
>
> **New to the application?** Start with the [**User manual**](https://github.com/acceliance/Graph-Rag-Deploy/blob/main/USER-MANUAL.md): it walks through every screen of the web application, from asking questions to profiles and prompts, once the stack is running.

Ask questions about an IT department's architecture documents and get answers from a **typed knowledge graph**. The PDFs (enterprise architecture blueprints, technical architecture documents, system design documents, interface control documents, IT master plans) are read by [Acceliance Graph-RAG](https://github.com/acceliance/Graph-Rag-Deploy), which extracts the systems, the exchanges between them, the infrastructure they run on and the business capabilities they support into **Neo4j**, keeps the evidence (chunks and pages) in **Qdrant**, and answers through a web agent, a REST API and an **MCP** endpoint for external AI hosts.

This repository holds everything to run that agent for enterprise architecture: the data model, the Modelio project that governs it, sample documents, and the Docker deployment kit.

## What you can ask

- Which systems exchange data with the Medicaid claims system, and over which protocol?
- Which components of a system run on Oracle, and on which infrastructure?
- Which servers, network zones and sites host a system?
- Which business capabilities does an application support, and in which business area?
- Which systems are legacy or planned for replacement, and by which project?
- Which documents describe the same system, and how did it change between editions?

## What is in this repository

| Folder | Content |
|---|---|
| [`model/`](model/README.md) | The enterprise architecture data model, [`enterprise-architecture-model.json`](model/enterprise-architecture-model.json): 19 classes, 15 enumerations, 46 relations in six domains (business, application, integration, infrastructure, technology, governance), plus the **Modelio project** that governs it |
| [`samples/`](samples/README.md) | [`source-docs/`](samples/source-docs/): 15 public PDFs that describe real IT landscapes, with their sources and rights (application, infrastructure and business architecture, system design, interface control documents, in English and French); [`profiles/`](samples/profiles/): the *Enterprise Architect* agent profile that infers the landscape from them |
| [`docker-compose.yaml`](docker-compose.yaml), [`.env.example`](.env.example), [`scripts/`](scripts/) | The deployment kit: four services (web, API, Neo4j, Qdrant) pulled as images, start and backup scripts |
| [`reverse-proxy/`](reverse-proxy/) | nginx and Apache examples for putting HTTPS in front |
| [`schemas/`](schemas/README.md) | JSON Schemas for the model, the ingestion ledger and the prompt files |
| [`modelio/`](modelio/) | The GraphRag module for Modelio (`GraphRag_5.4.01.jmdac`) that declares the Graph-RAG stereotypes |
| [`DEPLOY.md`](DEPLOY.md) | The full deployment guide: sizing, HTTPS, AI provider settings, backup, upgrade, troubleshooting |

## Quick start

The product runs from two images, `acceliance/graphrag-api` and `acceliance/graphrag-web`, published on the [Acceliance Docker Hub organisation](https://hub.docker.com/repositories/acceliance); the Compose file pulls them, nothing is built here. You need Docker Desktop (Windows, macOS), Docker Engine 24+ with Compose v2, or on Windows WSL 3.0.1+ with its built-in `wslc` container CLI (below), and an AI provider key for the chat, extraction and embedding roles (entered in the application, never in a file).

```powershell
.\scripts\up.ps1        # Windows
```

```bash
scripts/up.sh           # Linux, macOS
```

The script creates `.env` with generated secrets, pulls the images, starts the stack and prints the URL, `http://localhost:8080` by default. Then:

1. Create the administrator account on the first visit.
2. Enter your AI provider settings under **Admin ▸ AI settings**.
3. On the **Model** screen, upload [`model/enterprise-architecture-model.json`](model/enterprise-architecture-model.json), then *Validate* and *Initialise*.
4. Upload the PDFs from [`samples/source-docs/`](samples/source-docs/) (or your own).
5. On the **Profiles** screen, click **New profile**, name it `enterprise-architect` and paste [`samples/profiles/enterprise-architect.md`](samples/profiles/enterprise-architect.md); then select it on the **Agent** screen and ask questions.

The same steps, with a screenshot of each screen, are in the [tutorial](docs/tutorial/README.md).

For a pilot over plain HTTP set `AUTH_COOKIE_SECURE=false` in `.env`; production needs HTTPS through a reverse proxy. See [`DEPLOY.md`](DEPLOY.md).

### Windows without Docker Desktop: WSL containers (`wslc`)

WSL 3.0.1 and later run Linux containers natively with the `wslc` command, so you don't need Docker Desktop. In an administrator PowerShell, install or update WSL and check the version:

```powershell
wsl --install --no-distribution
```

```powershell
wsl --update
```

```powershell
wsl --version
```

```powershell
wslc version
```

`wsl --install` is needed only when WSL is not installed yet (restart Windows afterwards). `wsl --version` must show 3.0.1 or later. Then, from the repository folder, start the server:

```powershell
.\scripts\wslc.ps1
```

`wslc` has no Compose support yet, so this script starts the four containers of [`docker-compose.yaml`](docker-compose.yaml) one by one with `wslc container run`, with the same images, secrets and volumes. Stop them with `.\scripts\wslc.ps1 Stop`; pull newer images with `.\scripts\wslc.ps1 Update`. The full procedure (memory settings, proxy, the individual `wslc` commands, differences from Compose) is in [`DEPLOY.md` §2a](DEPLOY.md#2a-windows-without-docker-desktop-wsl-containers-wslc).

## The model

Every extracted fact fits one of nineteen classes. Three anchor the relevance gate: `ArchitectureDocument` (each PDF is one), `ApplicationSystem` and `DataExchange`.

```mermaid
flowchart LR
    Doc[ArchitectureDocument] -->|describes| App[ApplicationSystem]
    App -->|supports| Cap[BusinessCapability]
    App -->|built from| Comp[Component]
    App -->|uses| Tech[Technology]
    Comp -->|hosted on| Node[InfrastructureNode]
    Node -->|in| Zone[NetworkZone]
    Node -->|at| Site[Site]
    Exch[DataExchange] -->|from| App
    Exch -->|to| App
    Exch -->|carries| Data[DataObject]
    Proj[Project] -->|changes| App
```

The complete class diagram, the design decisions and the extraction rules are in [`model/README.md`](model/README.md). The model is designed in **Modelio**, and the Modelio project is the reference: change the model there, export it, validate it, then upload it. The process is described in the *Modelio project* section of that file.

## Sample documents

[`samples/source-docs/`](samples/source-docs/) holds 15 public documents, chosen because they describe an actual landscape (named systems, interfaces, infrastructure, business processes) and not how to practise enterprise architecture. They range from a system design document of 100 pages to a one-page technology catalogue, and from US government systems to a French hospital IT master plan. [`samples/README.md`](samples/README.md) describes each of them.

[`samples/profiles/enterprise-architect.md`](samples/profiles/enterprise-architect.md) is the agent profile for this corpus: it reasons along the model's relations, consolidates systems that several documents describe, compares the two GovInfo/FDsys editions, reports undocumented systems as gaps, and labels every inference with the cited facts it rests on. Its body lists questions to try, layer by layer.

The publishers keep the rights to these documents. Check [the rights notes](samples/README.md#rights-and-usage) before publishing this repository, and see the *Modelio* notes in the model README about the size of the Modelio project.

## Licence

The files of this repository (Compose file, scripts, schemas, model, documentation) are under the [Apache License 2.0](LICENSE). The product images ([Docker Hub](https://hub.docker.com/repositories/acceliance)) are free of use under their own licence, described in [`LICENSE-IMAGES.md`](LICENSE-IMAGES.md). The sample PDFs are **not** covered by this licence: see [`samples/README.md`](samples/README.md#rights-and-usage).
