# Acceliance Graph-RAG — Image Licence

**Version 1.0 — 22 September 2026**

This licence governs the use of the Acceliance Graph-RAG container images published by
Acceliance ("Acceliance") on Docker Hub under the names `acceliance/graphrag-api` and
`acceliance/graphrag-web`, in any tag (the "Images"). It does **not** govern the files of
this repository, which are licensed under the Apache License 2.0 (see [`LICENSE`](LICENSE)),
nor the third-party software listed in section 6, which remains under its own licences.

By pulling, running or otherwise using the Images, you accept these terms. If you do not
accept them, do not use the Images.

## 1. Grant

Acceliance grants you a **free of charge, non-exclusive, worldwide, non-transferable,
revocable** licence to:

- pull the Images from Docker Hub or from a registry you operate;
- copy the Images into a private registry you control, for the sole purpose of deploying them
  in your own environments (including air-gapped ones);
- run the Images, in any number of instances, for your internal purposes or to provide
  services to your own customers, including commercial services;
- configure the Images through the means the product provides: environment variables, the
  `/data` volume, the administration screens and the API, including your own data models,
  prompt overrides and profiles.

No fee is due for this licence. Acceliance may offer support, warranty or additional services
under a separate agreement; nothing in this licence obliges it to.

## 2. Restrictions

Except to the extent that applicable law expressly permits it despite this restriction, you
shall not, and shall not allow a third party to:

1. **Reverse-engineer** the Images or the software they contain: decompile, disassemble,
   de-obfuscate, decrypt or otherwise attempt to derive source code, prompts, extraction
   logic, schemas or other constants embedded in the compiled modules;
2. **Extract** any component of the Images (compiled modules, prompts, product schemas,
   front-end bundles) for use outside the Images;
3. **Redistribute** the Images, or images derived from them, to third parties, or make them
   available on a public registry or download location — copying them into your own private
   registry as permitted by section 1 is not redistribution;
4. **Modify** the Images or build derivative images that alter the product's code; adding
   configuration through the supported means of section 1 is not a modification;
5. **Remove or alter** any copyright, licence or attribution notice contained in the Images;
6. **Circumvent** any technical measure of the product, including the read-only guardrails,
   the MCP key gate or the authentication of the administration screens;
7. Use the Images in violation of applicable law, or to process data you have no right to
   process.

## 3. Ownership

The Images and the software they contain are the property of Acceliance and are protected
by copyright and other intellectual-property laws. This licence grants you no title and no
right other than those expressly stated in section 1. All rights not expressly granted are
reserved.

**Your data stays yours.** Everything you put under the `/data` volume — documents, extracted
graphs, models, prompts, profiles, accounts, configuration — belongs to you. Acceliance claims
no right over it and has no access to it: the Images send nothing to Acceliance.

## 4. Third-party AI providers

The product sends document content and extracted values to the AI providers **you** configure
(Anthropic, OpenAI, or an on-premises server). Your use of those providers is governed by
your agreement with them. Acceliance is not a party to it and is not responsible for their
processing of your data.

## 5. No warranty, limitation of liability

THE IMAGES ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY
OF EXTRACTED DATA OR ANSWERS, AND NON-INFRINGEMENT. Output produced with the help of AI
models may be incorrect; you remain responsible for verifying it before relying on it.

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, ACCELIANCE SHALL NOT BE LIABLE FOR ANY
INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR PUNITIVE DAMAGES, NOR FOR ANY LOSS OF DATA,
PROFITS, REVENUE OR BUSINESS, ARISING OUT OF OR IN CONNECTION WITH THE IMAGES OR THIS
LICENCE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. ACCELIANCE'S TOTAL LIABILITY
UNDER THIS LICENCE SHALL NOT EXCEED ONE HUNDRED EUROS (€100). Nothing in this licence
excludes liability that cannot be excluded under applicable law.

## 6. Third-party software in the stack

The deployment kit orchestrates, next to the Images, software that is **not** covered by this
licence and remains under its own terms:

| Component | Licence | Note |
|---|---|---|
| Neo4j Community Edition (`neo4j:*-community`) | GNU GPL v3 | Separate image from Neo4j, Inc.; the product talks to it over the Bolt protocol and does not embed or link it |
| Qdrant (`qdrant/qdrant`) | Apache License 2.0 | Separate image from Qdrant Solutions GmbH |
| nginx, Tesseract OCR, `ocrmypdf` and the other open-source components contained in the Images | Their respective licences (BSD-2, Apache 2.0, MPL 2.0, MIT, …) | Notices are included in the Images under `/licenses`; the open-source components keep their licences, which this licence does not restrict |

## 7. Term and termination

This licence is effective from your first use of the Images and remains in force until
terminated. It terminates automatically if you breach section 2; Acceliance may also
terminate it for a given tag by withdrawing that tag from publication, with at least six
months' notice on this repository, without effect on instances already running. Upon
termination for breach you must stop using the Images and delete your copies. Sections 3, 4,
5 and 8 survive termination.

## 8. General

- **Updates.** Acceliance may publish new versions of this licence with new Images. The
  version that applies to an Image is the one published in this repository at the time the
  Image's tag is published; using a new tag means accepting the licence that goes with it.
- **Governing law.** This licence is governed by French law. Any dispute that cannot be
  settled amicably shall be brought before the competent courts of Paris, France.
- **Severability.** If a provision is held unenforceable, the remainder stays in force and the
  provision is replaced by an enforceable one closest to its intent.
- **Entire agreement.** This licence is the entire agreement between you and Acceliance
  concerning the Images, unless a signed agreement between you and Acceliance states
  otherwise, in which case that agreement prevails.

---

Acceliance — SAS 122 ave de la Résstance 93340 Le Raincy France —
contact: through the issues of this repository or the address published on acceliance.fr.
