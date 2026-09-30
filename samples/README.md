# Sample architecture documents

Public IT architecture documents found on the web and used as test data for the Graph RAG enterprise architecture agent. Each document in this folder describes a **real IT landscape**: named business capabilities, applications, the exchanges between them, and the infrastructure they run on. Together they stand in for the documents an IT department's architecture repository would hold.

Documents about *how to practise* enterprise architecture (frameworks, standards, templates) are deliberately left out. The numbering has gaps (02, 03, 11, 12, 15, 17) where documents were removed: frameworks, standards, templates and worked examples (02, 03, 11, 12), and two documents that are mostly practice or planning rather than a landscape (15: a state transformation plan, of which about 6 of 169 pages describe the current state; 17: an audit of a modernisation programme, whose findings and recommendations outweigh its description of the systems).

All files were downloaded on 2026-09-29. Page counts and dates come from the PDFs themselves.

## Coverage by architecture layer

✓ marks the layers each document describes in substance.

| # | Document | Business | Application | Exchanges / interfaces | Infrastructure | Lang |
|---|---|:-:|:-:|:-:|:-:|:-:|
| 01 | PBGC EA Blueprint | ✓ | ✓ | | ✓ | EN |
| 04 | City of Roseville technology standards | | ✓ | | ✓ | EN |
| 05 | GovInfo system design (GPO) | | ✓ | ✓ | ✓ | EN |
| 06 | FDsys system design (GPO) | | ✓ | ✓ | ✓ | EN |
| 07 | R-ICMS system design (Florida DOT) | | ✓ | ✓ | | EN |
| 08 | CREATE software architecture | | ✓ | | | EN |
| 09 | LocAdoc architecture | | ✓ | | ✓ | EN |
| 10 | RIT Co-op Evaluation System architecture | | ✓ | ✓ | | EN |
| 13 | VITAM technical architecture (DAT) | | ✓ | ✓ | ✓ | FR |
| 14 | Kash.click technical architecture (DAT) | | ✓ | | ✓ | FR |
| 16 | Vermont Medicaid MITA self-assessment | ✓ | ✓ | ✓ | | EN |
| 18 | Sud-Essonne hospital IT master plan (SDSI) | | ✓ | | ✓ | FR |
| 19 | Minnesota SSIS/MMIS interface specification | | | ✓ | | EN |
| 20 | CMS MBDSS interface control document | | | ✓ | | EN |
| 21 | Indiana Collections interface control document | | | ✓ | | EN |

## Overview

| # | File | Document type | Publisher | Date | Pages | Size |
|---|---|---|---|---|---|---|
| 01 | `01_EA-Blueprint_PBGC.pdf` | Enterprise architecture blueprint | Pension Benefit Guaranty Corporation (US federal) | 2010 | 106 | 2.4 MB |
| 04 | `04_EA-Tech-Standards_2026_City-of-Roseville.pdf` | Technology standards catalog | City of Roseville, California | Feb 2026 | 1 | 0.2 MB |
| 05 | `05_SDD_GovInfo-v7_GPO.pdf` | System design document | US Government Publishing Office | Jul 2023 | 101 | 2.6 MB |
| 06 | `06_SDD_FDsys-v5_GPO.pdf` | System design document | US Government Publishing Office | Sep 2016 | 96 | 2.6 MB |
| 07 | `07_SDD_R-ICMS_FDOT.pdf` | System design document | Florida DOT District 5 (with SwRI, Kapsch) | Oct 2018 | 180 | 4.9 MB |
| 08 | `08_SAD_CREATE_ITEA.pdf` | Software architecture document | ITEA 2 CREATE consortium | Aug 2012 | 20 | 1.2 MB |
| 09 | `09_SAD_LocAdoc.pdf` | Software architecture document | LocAdoc student team | 2017 | 9 | 1.7 MB |
| 10 | `10_SAD_Co-op-Evaluation-System_RIT.pdf` | Software architecture document | Rochester Institute of Technology | 2014 | 28 | 0.8 MB |
| 13 | `13_DAT_VITAM-Archivage-Numerique_FR.pdf` | Technical architecture document (DAT) | Programme Vitam (French government) | Jun 2026 | 220 | 7.9 MB |
| 14 | `14_DAT_Kash-Click-Caisse-SaaS_FR.pdf` | Technical architecture document (DAT) | Net-Assembly (Kash.click) | Jan 2026 | 30 | 0.9 MB |
| 16 | `16_Business-Systems-Assessment_MITA_Vermont-Medicaid.pdf` | Business and systems assessment | Vermont Agency of Human Services | 2023 | 399 | 3.4 MB |
| 18 | `18_SDSI_CH-Sud-Essonne-Hopital_FR.pdf` | IT master plan (SDSI) | Centre Hospitalier Sud Essonne | Sep 2021 | 9 | 1.2 MB |
| 19 | `19_Interface-Spec_SSIS-MMIS_Minnesota-DHS.pdf` | Interface specification | Minnesota Department of Human Services | Aug 2009 | 174 | 1.3 MB |
| 20 | `20_ICD_MBDSS-TBQ_CMS.pdf` | Interface control document | Centers for Medicare & Medicaid Services | Dec 2011 | 33 | 0.3 MB |
| 21 | `21_ICD_Collections-SFTP_Indiana.pdf` | Interface control document | Indiana Finance Authority (by ETC) | Feb 2022 | 36 | 1.2 MB |

## Documents

### Enterprise and IT landscape documents

**01 — PBGC Enterprise Architecture Blueprint (v2.0)**
A US federal agency's EA blueprint. It describes the agency's architecture domain by domain (business process, data, applications, infrastructure, common services, tools and repositories) together with the standards and shared components its systems must use.
Source: <https://www.pbgc.gov/documents/enterprisearchitectureblueprint.pdf>

**16 — Vermont MITA 3.0 State Self-Assessment, Detailed Report**
An assessment of Vermont's Medicaid enterprise. It lists the existing systems and components (Medicaid claims system MMIS, the ACCESS eligibility system, Vermont Health Connect, the EDI translator, provider and care management modules, the Vermont health information exchange and its connectivity), then gives a business capability matrix and process-by-process findings with as-is and to-be gap analysis. It is the strongest business architecture sample in the set.
Source: <https://bgs.vermont.gov/sites/bgs/files/files/purchasing-contracting/VT%20IES%20Documents/MITA%203.0%20State%20Self-Assessment%20Detailed%20Report_2023.pdf>

**18 — Centre Hospitalier Sud Essonne, Schéma directeur du SI 2021–2025** (French)
A hospital's IT master plan. It describes the current infrastructure (dual network core on two sites linked by a radio link, two server rooms, high availability), the application portfolio, and the target projects for 2021–2025.
Source: <https://www.ch-sudessonne.fr/sites/ch-sudessonne/files/u2280/schema_directeur_du_systeme_dinformation.pdf>

**04 — City of Roseville IT Enterprise Architecture Standards (2026)**
A one-page catalog of the products actually in use across infrastructure, security, applications and end-user devices (for example VMware vSphere, Cisco Nexus, Rubrik, Microsoft SQL Server, ESRI ArcGIS, Palo Alto, CrowdStrike). It is useful for testing extraction of products and vendors. The layout is multi-column, so plain text extraction mixes the columns together.
Source: <https://www.roseville.ca.gov/Documents/Departments/Information%20Technology/About/2026%20Enterprise%20Architecture%20Standards.pdf>

### System and technical architecture documents

**13 — VITAM, Architecture (DAT) v9.1.0** (French)
The technical architecture document of the French government's digital archiving system. It covers external interfaces (required and exposed), application architecture, data and multi-site architecture, business, operations and technical flows, network zoning, storage options (filesystem, Swift, S3, tape library), log processing, security, and a detailed section for each component. It is the most complete sample for application, exchange and infrastructure views together.
Source: <https://www.programmevitam.fr/ressources/DocCourante/pdf/vitam-architecture.9.1.0.pdf>

**14 — Kash.click, Dossier d'architecture technique v0.9.8** (French)
The technical architecture of a SaaS point-of-sale system: multi-instance hosting on Linux servers at Digital Ocean in European data centers, PHP and MySQL 8 with replication and backups, TLS flows, and the data structure of recorded transactions. Published under CC BY 4.0.
Source: <https://caisse.enregistreuse.fr/documentation/dossier_d'architecture_technique.pdf>

**05 — GovInfo System Design Document, Volume I (v7)**
The architecture of GPO's public document repository: three subsystems (content management, archival, access), the OAIS archival model, XML usage, the network diagram, and how the system fits into GPO's enterprise architecture.
Source: <https://www.govinfo.gov/media/GovInfo_Architecture_v7.pdf>

**06 — FDsys System Design Document, Volume I (v5)**
The 2016 edition of the same system under its former name. Most of its structure matches document 05, so the pair can be used to test versioning and change detection.
Source: <https://www.govinfo.gov/media/FDsys_Architecture_v5.pdf>

**07 — R-ICMS System Design Document (v1.0)**
A regional traffic corridor management system: context, third-party components, data drivers to external field systems, pipelines, data stores and services, a catalog of named business services, and user interface modules.
Source: <https://cflsmartroads.com/projects/ICM_RICMS/R-ICMS-System_Design_Description-SDD-1.0.pdf>

**08 — CREATE Software Architecture Document (Deliverable 2.1)**
An industrial automation platform documented with the "4+1" views, key user roles and non-functional constraints.
Source: <https://itea4.org/project/workpackage/document/download/862/D2.1.%20CREATE%20-%20Software%20Architecture.pdf>

**09 — LocAdoc System Architecture Design Document**
A mobile app's layered architecture and deployment, with its AWS dependencies (Cognito, DynamoDB, S3).
Source: <https://locadoc.github.io/LocAdoc/Project_Diary_Page/doc/System_Architecture_Document_LocAdoc.pdf>

**10 — RIT Co-op Evaluation System, Software Architecture Documentation**
A university application with logical and process views, element catalogs and interfaces, and its external systems (Shibboleth, the mail server, an Oracle database).
Source: <https://www.se.rit.edu/~co-operators/SoftwareArchitectureDocumentation.pdf>

### Interface and exchange documents

**19 — SSIS/MMIS Interface Specification**
The interfaces between Minnesota's Social Services Information System and the Medicaid claims system: an eligibility interface and a claiming interface, with record layouts, data definitions, remittance advice, and installation of the exchange tooling. The revision history records an extract being replaced by a data warehouse interface.
Source: <https://www.dhs.state.mn.us/main/groups/agencywide/documents/pub/dhs16_142427.pdf>

**20 — MBDSS Interface Control Document for Territory Beneficiary Query (v4.5)**
A file-based exchange in which states and territories query CMS for Medicare eligibility and receive a response file. It gives header, detail and trailer record layouts for both directions.
Source: <https://www.cms.gov/Medicare-Medicaid-Coordination/Medicare-and-Medicaid-Coordination/Medicare-Medicaid-Coordination-Office/Downloads/TBQData.pdf>

**21 — Indiana Collections Interface Control Document (v1.0)**
The exchanges between a toll back-office system and collection agencies: outbound and inbound SFTP files (placements, payments and adjustments, demographics) over VPN, process flows, field-level layouts, configuration and business rules.
Source: <https://www.in.gov/ifa/files/Collections-ICD-V1.0-02042027.pdf>

## Notes for the Graph RAG pipeline

- **Shared entities across documents.** Documents 16, 19 and 20 all involve Medicaid systems (claims system, eligibility, beneficiary data), which is useful for testing entity resolution across sources.
- **Two versions of one system.** Documents 05 and 06 describe the same system seven years apart.
- **French documents.** Documents 13, 14 and 18 are in French; the pipeline needs multilingual extraction or translation.
- **Hard extraction cases.** Document 04 has a multi-column layout. Many documents rely on diagrams and tables whose content is only partly in the text layer.

## Rights and usage

The publishers keep all rights to these documents. They are stored here only as test data for development. Before pushing them to a public repository, check each source's terms:

- **01, 05, 06, 20** are US federal government works and are generally in the public domain.
- **04, 07, 16, 19** are US state or local government publications; their reuse terms vary by publisher.
- **13** is published by a French government programme; **18** by a French public hospital.
- **14** is licensed CC BY 4.0 (attribution required).
- **21** is marked "Confidential and Proprietary" by its author, ETC, although the State of Indiana publishes it.
- **08** is marked "strictly confidential" under the ITEA 2 non-disclosure declaration, although it is publicly downloadable.
- **09, 10** are student project documents.

A safer option for a public repository is to commit only this README and a download script, and keep the PDFs out of git.
