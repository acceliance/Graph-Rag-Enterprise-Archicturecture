# Enterprise architecture Graph-RAG model

[`enterprise-architecture-model.json`](enterprise-architecture-model.json) is the stereotyped model (`schema_uml_model.json` format) for extracting an enterprise architecture knowledge graph from the documents in [`../samples/`](../samples/README.md). It was written by following the rules of [`Graph-Rag-Deploy/samples/prompts/generate-graphrag-model.md`](../../Graph-Rag-Deploy/samples/prompts/generate-graphrag-model.md) and extrapolated from what the 17 sample documents actually print.

## Domain block used (section 8 of the prompt)

| Item | Value |
|---|---|
| Documents | EA blueprints and plans, technical architecture documents (DAT), system design documents (SDD), software architecture documents (SAD), interface control documents (ICD) and interface specifications, IT master plans (SDSI), MITA self-assessments, IT audits, technology standards catalogs. English and French. Issued by government agencies, IT departments, hospitals, vendors. |
| Entities to question | Application systems and their components, the data exchanges between systems, the technologies and infrastructure they run on, the business capabilities they support, the organisations and people involved, the projects that change the landscape, the documents themselves and the principles they state. |
| Identifiers printed | System names and acronyms (STARS, MMIS, R-ICMS), process codes (EE01, CM07), document titles, versions and references (MMA.DDX.1502.04.5.1211, W103), component codes (SA-BS, MAP-UI), file and interface names, product names with versions, hostnames and role names, site names, person names in control tables. |
| Fixed lists | Organisation kind, technology category and status, site kind, node kind, environment, quality attribute, component kind, application kind, lifecycle status, hosting model, exchange mechanism, project status, document type, language. |
| Long texts to search | System purpose, component responsibility, capability description and gap analysis, requirement statements, decision rationale, exchange description, project objective, document purpose, principle statement. |
| Expected questions | Which systems exchange data with MMIS, and how? Which components of GovInfo run on Oracle? What infrastructure hosts Vitam and in which zones? Which capabilities does STARS support? Which systems are legacy or planned for replacement, by which project? Who approved the R-ICMS design document? Which documents describe the same system across versions? Which technologies are standard in Roseville? |

## Model overview

| Class | Domain | Kind | Identity | Match | Anchor | Group |
|---|---|---|---|---|---|---|
| Organisation | Governance | entity | name | fuzzy | | governance |
| Person | Governance | entity | fullName | fuzzy (0.94 / 0.80) | | governance |
| BusinessArea | Business | entity | name | fuzzy | | business |
| BusinessCapability | Business | entity | name | fuzzy | | business |
| Technology | Technology | entity | name | fuzzy (0.90 / 0.75) | | infrastructure |
| Site | Infrastructure | entity | name | fuzzy | | infrastructure |
| NetworkZone | Infrastructure | entity | name | exact | | infrastructure |
| InfrastructureNode | Infrastructure | entity | name | exact | | infrastructure |
| DataObject | Application | entity | name | fuzzy | | application |
| QualityRequirement | Application | value object of ApplicationSystem | | | | application |
| ArchitectureDecision | Application | value object of ApplicationSystem | | | | application |
| Component | Application | value object of ApplicationSystem | | | | application |
| ApplicationSystem | Application | entity | name | fuzzy | **true** | application |
| DataElement | Integration | value object of DataExchange | | | | integration |
| DataExchange | Integration | entity | name | exact | **true** | integration |
| Project | Governance | entity | name | fuzzy | | governance |
| DocumentRevision | Governance | value object of ArchitectureDocument | | | | governance |
| ArchitectureDocument | Governance | entity | title | exact | **true** | governance |
| ArchitecturePrinciple | Governance | entity | name | exact | | governance |

19 classes, 15 enumerations, 73 attributes, 46 relations, 5 extraction groups (one LLM call each: governance, business, infrastructure, application, integration).

### Main relations

```
ArchitectureDocument ──issuer──▶ Organisation      ──authors/approvers──▶ Person
                     ──describedSystems──▶ ApplicationSystem
                     ──revisions (1..n)──▶ DocumentRevision
ArchitecturePrinciple ──sourceDocument──▶ ArchitectureDocument

ApplicationSystem ──owner/vendor──▶ Organisation
                  ──capabilities──▶ BusinessCapability ──businessArea──▶ BusinessArea
                  ──technologies──▶ Technology ──vendor──▶ Organisation
                  ──hostedAt──▶ Site
                  ──masterOf──▶ DataObject
                  ──components (1..n)──▶ Component ──technologies──▶ Technology
                                                   ──hostedOn──▶ InfrastructureNode ──zone──▶ NetworkZone ──site──▶ Site
                                                                                      ──site──▶ Site
                                                                                      ──technology──▶ Technology
                  ──qualityRequirements (1..n)──▶ QualityRequirement
                  ──decisions (1..n)──▶ ArchitectureDecision

DataExchange ──source/target──▶ ApplicationSystem
             ──dataObjects──▶ DataObject
             ──dataElements (1..n)──▶ DataElement

Project ──sponsor──▶ Organisation
        ──affectedSystems──▶ ApplicationSystem
```

## Design decisions

- **Three anchors.** `ArchitectureDocument` (every PDF is one), `ApplicationSystem` (the subject of SDDs, SADs and DATs) and `DataExchange` (the subject of ICDs). Finding any of them proves a document belongs to the domain.
- **Components are value objects, not entities.** Names like "Admin" or "Data Store" recur across unrelated systems, so a global identity key would merge them wrongly. Each system owns its components through `components` (OneToMany). The price is that the two GovInfo editions (samples 05 and 06) each produce their own component set.
- **One document, many revisions.** `ArchitectureDocument` is identified by its title without the version, so successive editions merge into one entity whose `revisions` hold the version history. `version` and `publicationDate` on the entity describe the edition that was read.
- **Acronyms are attributes, not identity.** Documents switch between "State Titling and Registration System" and "STARS". The identity is the full name with fuzzy matching; the hint tells the extractor to use the acronym as the name only when nothing else is printed.
- **Products versus organisations.** `Technology` holds products, protocols and standards; vendors are `Organisation` entities linked through `vendor`, so "Microsoft" is one node whatever product is mentioned.
- **Field-level layouts are kept.** ICDs and interface specifications are mostly record-layout tables, which is what makes them useful for questions about what an exchange carries. `DataElement` rows belong to their `DataExchange`.
- **No self-references.** Hierarchies (parent organisation, parent capability, sub-component) are flattened: `BusinessArea` groups capabilities, and a component's parent goes in its `layer` attribute. This keeps every class ordered after the classes it references, as the prompt requires.
- **Groups.** Technology is extracted with the infrastructure group because standards catalogs and DATs print products and nodes together; DataObject goes with the application group because data models sit in SDDs.

## Validation

The model passes the schema and the product's checks (`validate_model` and the stereotype split from `graphrag-api/graphrag/model/`) with no errors or warnings, and the prompt's self-check list (ordering, value-object ownership, fuzzy and anchor rules, name patterns).

To re-check the schema layer:

```bash
check-jsonschema --schemafile ../../Graph-Rag-Deploy/schemas/schema_uml_model.json enterprise-architecture-model.json
```

Then upload it on the *Model* screen or send it to `POST /model/validate`.

## Next steps

- Load the model in Graph-RAG and ingest `../samples/` to see which hints need tuning; the field-level `DataElement` extraction on the 174-page Minnesota specification (sample 19) is the most expensive part and can be dropped from the model if it is not worth it.
- Relevance-gate thresholds are not in the model; set them per model version through `PUT /model/gate`.
