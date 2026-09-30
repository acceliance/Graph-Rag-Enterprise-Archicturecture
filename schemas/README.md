# Schemas

JSON Schema for every file format this deployment kit's users create, upload or read.
This folder, including this README, is synced verbatim from `graph-rag-application\Schemas`
(the source of truth) by `Sync-SchemasToDeployKit.ps1`, which also copies the schemas into
the API image. Edit files there, not in `Graph-Rag-Deploy\schemas`; a re-sync overwrites any
local change. Relative links below resolve in the `Graph-Rag-Deploy` layout.

| File | Draft | Validates | Used for |
|---|---|---|---|
| `schema_uml_model.json` | 2020-12 | The data model JSON uploaded from *Model* (e.g. [`samples/model/billing-model-stereotyped.json`](../samples/model/billing-model-stereotyped.json)) | Classes, attributes, relations, enumerations, and stereotypes; the GraphRag stereotypes carry the Graph-RAG settings (identity keys, normalisation, fuzzy matching, anchor classes, extraction hints, extraction groups, indexed attributes) |
| `ingestion-ledger.schema.json` | 2020-12 | The per-document ledger the API writes to `./data/api/ingestion/<docId>.json` | Reading a ledger by hand — audit trail, retry/resume, and the input of re-index and rebuild jobs |
| `ai-prompt-markdown-schema.json` | Draft-07 | A Markdown prompt or profile file after `gray-matter` front-matter parsing (e.g. [`samples/profiles/`](../samples/profiles/)) | Front-matter structure of a custom agent profile or prompt override |

**Not published here:** `users.schema.json`, the application's internal account store.
It is an implementation detail of the API, never a file a deployment kit user authors.

## Editor support

Each schema is published at a stable URL (its `$id`), and the model schema accepts a
`$schema` key at the root. Put it first in your file and VS Code, JetBrains IDEs and most
JSON editors validate as you type and complete property names and enum values:

```json
{
  "$schema": "https://raw.githubusercontent.com/acceliance/Graph-Rag-Deploy/main/schemas/schema_uml_model.json",
  "classes": [ ]
}
```

The sample carries this key. The product ignores it.

## The model and its Graph-RAG settings

One file describes the model and how Graph-RAG treats it. The settings are stereotypes applied
to the model's classes and attributes, recognised by their **name**:

| Stereotype | On | Tagged values (`valueAsString`) |
|---|---|---|
| `GraphRagEntity` | a class | `graphRagMatch` (`exact` \| `fuzzy`), `graphRagFuzzyThreshold` and `graphRagReviewBand` (0–1), `graphRagAnchor` (`auto` \| `true` \| `false`), `graphRagExtractionHints` (text), `graphRagGroup` (extraction group) |
| `GraphRagIdentity` | an attribute of the identity key | `graphRagIdentityOrder` (1-based, composite keys), `graphRagNormalise` (`trim`, `casefold`, `digits`, `date`, `amount`, `none`) |
| `GraphRagEmbed` | a String attribute | — (indexed on its own for semantic search) |

A model without stereotypes is valid too: every class is then a value object until identity
keys are set in the editor.

### Designing the model with Modelio

The model may be designed with [Modelio](https://www.modelio.org/), using the tooling of
[acceliance/ModelioForDataGovernance](https://github.com/acceliance/ModelioForDataGovernance).
A Modelio user installs the **GraphRag** module, applies these stereotypes, and uploads the
ModelioUtils JSON export as is. The *Model* screen reads the settings into its editor; what is
changed there is written back into the model as stereotypes, so the stored model stays the one
file that says everything. *Model ▸ Settings ▸ Download the model* returns it, ready for
ModelioUtils' import. The step-by-step setup, with the module file shipped in
[`modelio/`](../modelio/), is in [the deployment kit README, §3a](../README.md#3a-designing-the-model-in-modelio).

### `GraphRagEmbed` and extraction groups

The two settings act at different steps of ingestion:

- **Extraction, per group.** Each `graphRagGroup` value is one extraction schema sent to the
  LLM; every group runs on every accepted document. A class without `graphRagGroup` joins the
  group named after its `domain` (or `default`). Inside a group, relations between its classes
  are extracted as full entities; a relation to a class of *another* group is extracted as a
  reference to that class's identity key only.
- **Indexing, per entity.** After resolution, each `GraphRagEmbed` attribute of each extracted
  entity that has a non-empty value becomes its own search point, next to the document chunks
  (payload `kind: "attribute"`, `classes: [<class>]`, `attr: <attribute>`). The group is not
  recorded: searches narrow by class, never by group.

What follows for a model author:

1. **An attribute is indexed only where its class is documented.** A class reached only through
   a relation from another group becomes a *stub* — identity key, no other attributes — and
   stubs get no attribute points. In the sample, `Contract.scope` carries `GraphRagEmbed` and
   `Contract` is in the `contracts` group; the two sample invoices (group `billing`) reference
   `CT-77`, which stays a stub, so no `scope` point exists until a document that states the
   contract itself is ingested.
2. **Changing a class's group adds or removes no attribute points by itself.** It changes which
   classes the LLM extracts alongside it, and so which values it finds; put an embedded class in
   the group of the documents that actually carry its text, and describe where that text is in
   `graphRagExtractionHints`.
3. **Subclasses inherit it.** Apply `GraphRagEmbed` once, on the attribute in the class that
   declares it (type `String`, checked at load); instances of every subclass get an attribute
   point for it too. Do not repeat it on a subclass: an inherited attribute carries no
   stereotype of its own, and the editor's download drops one with a warning.

**Not in the model:** relevance-gate thresholds (`similarityFloor`, `coverageFloor`,
`confidenceThreshold`). They calibrate the embedding model rather than describe the domain, so
they are settings of each model version: *AI settings ▸ Relevance gate of model v<n>*, or
`PUT /model/gate`. They carry over to the next version on upgrade.

## Writing a model with an AI assistant

The model can be drafted by Claude, ChatGPT or any assistant that accepts file attachments. The
schema is self-contained and every property carries a description, so the assistant has what it
needs. What it does not know are the conventions stated in the [prompt](#prompt); give them, or the
output will fail the checks of the *Model* screen.

Only the model is authored. The ingestion ledger is written by the API and is never uploaded,
so its schema is a reading aid, not an input for generation. Agent profiles are Markdown files
with front-matter; start from [`samples/profiles/`](../samples/profiles/) rather than from the
prompt schema. To ease writing the prompt itself, draft it with the Acceliance prompt
generator at <https://masterprompter.acceliance.fr>, then transcribe the generated fields into the
profile's front-matter.

1. Attach two files: `schema_uml_model.json` and
   [`samples/model/billing-model-stereotyped.json`](../samples/model/billing-model-stereotyped.json).
2. Send the [prompt](#prompt) with its domain block filled in.
3. Paste the answer into *Model* (file or text). The screen validates against the schema, then
   runs the checks a schema cannot express: names are unique, every `mother` and relation
   `target` resolves, no inheritance cycle, enumeration targets carry `OneToOne`, tagged values
   are well formed, identity attributes are not `Boolean`, `graphRagFuzzyThreshold` is above
   `graphRagReviewBand`. Errors come with a JSON path; paste them back to the assistant and
   iterate. The settings can also be finished in the screen's editor.
4. *Initialise* only when the screen reports no error. Warnings about value objects (classes
   without identity) are expected for classes that live inside one document, such as a line.

### Prompt

The prompt is in [`samples/prompts/generate-graphrag-model.md`](../samples/prompts/generate-graphrag-model.md).
It gives the assistant the `modelStereotypes` block to copy verbatim, then the rules the *Model*
screen enforces:

- where each GraphRag stereotype may be applied, and the allowed tagged values;
- naming, enumerations, class ordering and inheritance;
- entity or value object, and the resulting identity, normalisation, matching, anchor, group
  and embed settings;
- a self-check list the assistant runs before answering.

It ends with a template for your domain.

### Validating outside the product

Any validator of the listed draft works. With Python:

```bash
pip install check-jsonschema
check-jsonschema --schemafile schemas/schema_uml_model.json model.json
```

This is the schema layer only. The checks of the tagged values and of the references between
classes run in the product: *Model* screen or `POST /model/validate`.
