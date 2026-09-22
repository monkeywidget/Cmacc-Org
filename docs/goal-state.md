# Goal state

- Where the CommonAccord modernization is heading
- Azure used as the example cloud throughout; not a final provider decision
- Diagrams show intent, not a finished design; open decisions listed at the end

## Goal state summary

- App fully containerized, deployed to managed Kubernetes
- App state in a managed database, only if the architecture requires it
- Templates stored as cloud objects
  - not checked into the repo
  - not baked into images
- Template generation tools usable by humans and agents
  - write to cloud storage under role-based access control
- Agents run inside the cluster, each with its own managed identity and permissions
- One API layer on the app server, exposed to agents through agent-safe, MCP-like tool gateways
- Template editing workflows run on a workflow engine (n8n or Temporal), hosted in the same managed cluster
- Template ingestion always ends in a human review step, with tooling built for it
- Chatbot front end for inference-generated answers about templates and form states
  - backed by n8n
  - reuses existing tools; no reimplemented functions

```mermaid
flowchart LR
  humans["Humans<br/>authors, reviewers, readers"]
  chat["Chat front end<br/>e.g. Slack"]

  subgraph cloud["Cloud (Azure as example)"]
    idp["Identity provider<br/>Entra ID"]
    subgraph k8s["Managed Kubernetes (AKS)"]
      ui["App UI + review tools"]
      gw["Agent-safe tool gateway<br/>MCP-like"]
      api["App API layer"]
      core["Renderer + template store"]
      agents["In-cluster agents<br/>own identities"]
      wf["Workflow engines<br/>n8n, Temporal"]
    end
    blob[("Template objects<br/>Blob Storage")]
    db[("App state<br/>managed DB, if needed")]
    llm["Inference service"]
  end

  humans --> idp
  humans --> ui --> api
  chat --> wf
  wf --> gw
  agents --> gw
  wf <--> agents
  gw --> api --> core
  core --> blob
  core -.-> db
  wf --> llm
  agents --> llm
```

## Tool API layer and agent-safe gateway

- One API layer: every app capability exposed once, used by UI, workflows, agents
- Gateway in front for all non-human callers; MCP-like
  - tool catalog: discoverable names, descriptions, input/output schemas
  - caller authenticated by its own identity; user context passed through when acting for a person
  - per-tool authorization from roles
  - input validation before anything reaches the app
  - side-effect classes: read, propose, publish
  - publish never available to agents; needs a human reviewer's identity
  - rate limits, timeouts, audit trail of every call
- Operations themselves not defined yet; this section fixes only the mechanism

```mermaid
flowchart LR
  subgraph callers["Callers"]
    n8nflows["n8n tool flows"]
    agents["Temporal agent workers"]
    other["Future agents"]
  end

  subgraph gateway["Agent-safe tool gateway"]
    catalog["Tool catalog<br/>schemas"]
    authn["Authenticate caller<br/>workload identity + user context"]
    authz{"Allowed for this<br/>caller and class?"}
    validate["Validate input"]
    audit[("Audit log")]
  end

  subgraph appapi["App API layer"]
    read["Read operations"]
    propose["Propose operations<br/>drafts, staging"]
    publish["Publish operations<br/>human approval required"]
  end

  store[("Template objects<br/>+ app state")]
  deny["Refuse + explain"]

  callers -->|"discover"| catalog
  callers -->|"invoke tool"| authn --> authz
  authz -->|"no"| deny
  authz -->|"yes"| validate
  validate --> read
  validate --> propose
  validate -.->|"reviewer identity only"| publish
  authn --> audit
  read --> store
  propose --> store
  publish --> store
```

## Workload identities and permissions

- Every in-cluster workload gets its own identity; no shared keys
- Azure example: Kubernetes service account → federated → its own user-assigned managed identity
- Permissions granted to identities, scoped as narrowly as each job needs
- Agents reach templates only through the gateway, never storage directly

```mermaid
flowchart LR
  subgraph aks["AKS"]
    sa1["App API<br/>service account"]
    sa2["Ingestion agent<br/>service account"]
    sa3["n8n<br/>service account"]
    sa4["Temporal<br/>service account"]
  end

  subgraph entra["Entra ID"]
    mi1["App identity"]
    mi2["Agent identity<br/>one per agent type"]
    mi3["n8n identity"]
    mi4["Temporal identity"]
  end

  blob[("Blob Storage")]
  gw["Tool gateway"]
  llm["Inference service"]
  db[("Managed DB")]

  sa1 -.->|"federated"| mi1
  sa2 -.->|"federated"| mi2
  sa3 -.->|"federated"| mi3
  sa4 -.->|"federated"| mi4

  mi1 -->|"read published,<br/>write staging"| blob
  mi2 -->|"read + propose tools"| gw
  mi2 -->|"inference"| llm
  mi3 -->|"tools per flow"| gw
  mi3 -->|"inference"| llm
  mi4 -->|"workflow history"| db
```

| Workload | Identity | May | May not |
|---|---|---|---|
| App API | own | read published, write staging, publish with recorded human approval | act without an authenticated caller |
| Ingestion agents | one per agent type | read and propose tools, inference | publish, touch storage directly |
| n8n | own | tools allowed for each flow, inference | touch storage directly |
| Temporal | own | its own workflow state | template content |
| Humans | Entra sign-in | per group: read, author, review, publish | — |

## Template workflow: humans adding or editing

- Authors edit drafts; nothing reaches published templates without review
- Workflow engine owns the process state: draft → validated → approved → published
- Validation = render with the app, check for missing fields and parser errors
- Published templates are versioned objects; the app reads published versions only

```mermaid
sequenceDiagram
  actor A as Author
  actor R as Reviewer
  participant T as App UI / template tools
  participant W as Workflow engine<br/>(n8n or Temporal)
  participant API as App API layer
  participant S as Template objects

  A->>T: sign in, open or create template
  T->>API: save draft (author role)
  API->>S: write draft version
  T->>W: start edit workflow
  W->>API: render draft
  API-->>W: output + missing fields + errors
  alt validation fails
    W-->>A: report problems, return to draft
  else validation passes
    W->>R: request review (diff + preview)
    R->>W: approve or request changes
    opt approved
      W->>API: publish (reviewer identity)
      API->>S: promote draft to published version
      W-->>A: published
    end
  end
```

## Template ingestion workflow: agents in Temporal

- Brings outside material into the corpus: existing corpus, upstream repos, contracts from users
- Temporal: durable, retryable steps; waits for the human decision as a signal
- Agents run as in-cluster Temporal workers under their own identities
  - call tools through the gateway: read, propose
  - write to staging only; cannot publish
- Every ingestion ends at human review

```mermaid
flowchart LR
  src["Source material<br/>legacy corpus, upstream, uploads"]
  llm["Inference service"]

  subgraph temporal["Temporal workflow (in cluster)"]
    fetch["Fetch source"]
    convert["Agent: convert to<br/>ProseObject structure"]
    validate["Render + check<br/>missing fields, errors"]
    compare["Compare with existing<br/>versions, if any"]
    wait{"Human review<br/>decision signal"}
  end

  subgraph appsvc["App service"]
    gw["Tool gateway"]
    api["App API layer"]
    staging[("Staging objects")]
    published[("Published objects")]
  end

  review["Review tooling<br/>human reviewer"]

  src --> fetch --> convert
  llm <-->|"inference"| convert
  convert -->|"propose"| gw --> api
  api --> staging
  api --> published
  validate -->|"render via tools"| gw
  convert --> validate
  validate -->|"fail: retry or<br/>hand to human"| convert
  validate -->|"pass"| compare --> wait
  wait -->|"open change proposal"| review
  review -->|"approve / changes / reject"| wait
  wait -->|"changes requested"| convert
  review -->|"publish, reviewer identity"| api
```

## Human review tooling

- Needed so ingestion (and agent-generated changes) can be judged by people
- Builds on ideas already in the CommonAccord material
  - plain-text objects so diff and code review work unchanged
  - access modeled as pull requests / push requests, governed by distribution lists
  - forking and convergence as the normal way templates improve
- A change proposal = pull-request-like package for one ingestion
  - source-level diff of the objects
  - rendered-text diff (same approach as the compatibility suite)
  - missing fields and parser errors
  - inheritance trace: which objects a rendered clause came from
  - provenance: source material, agent identity, model, prompts
- Decisions: approve, request changes (back to the agent loop), reject
- Every decision recorded with the reviewer's identity

```mermaid
sequenceDiagram
  participant W as Temporal workflow
  participant RT as Review tooling
  actor R as Reviewer
  participant G as Tool gateway
  participant API as App API layer

  W->>RT: open change proposal
  RT->>API: source diff, rendered diff,<br/>missing fields, trace
  API-->>RT: review package
  RT-->>R: notify: proposal ready
  R->>RT: inspect, comment
  alt request changes
    R->>RT: request changes + notes
    RT->>W: signal: changes requested
    W->>G: agent revises via propose tools
  else reject
    R->>RT: reject + reason
    RT->>W: signal: rejected
  else approve
    R->>RT: approve
    RT->>API: publish (reviewer identity)
    API-->>RT: published version
    RT->>W: signal: approved
  end
```

## Chatbot workflow: Slack front end, logic in n8n

- Questions about templates ("what does this clause cover?") and form states ("what is still missing?")
- Tool choice made by a LangChain agent running in an n8n node
  - sees the gateway's tool catalog
  - picks the tool (or asks a clarifying question) from the human prompt
- Chosen tool runs as its own n8n tool flow, which calls the gateway
- No logic reimplemented in n8n; all capabilities come from the app's tools
- Answers limited to what the asking user may read; cite the versions used

```mermaid
sequenceDiagram
  actor U as User
  participant S as Slack
  participant N as n8n workflow
  participant LC as LangChain agent node<br/>(in n8n)
  participant L as Inference service
  participant TF as n8n tool flow
  participant G as Tool gateway
  participant API as App API layer

  U->>S: question in channel or DM
  S->>N: event webhook
  N->>N: map Slack user → org identity + roles
  N->>LC: prompt + user context
  LC->>G: fetch tool catalog (allowed for this user)
  LC->>L: prompt + tool descriptions
  L-->>LC: chosen tool + arguments, or clarifying question
  alt clarification needed
    LC-->>S: ask the user
  else tool chosen
    LC->>TF: invoke tool flow
    TF->>G: call tool (n8n identity + user context)
    G->>API: authorized operation
    API-->>G: result
    G-->>TF: result
    TF-->>LC: result
    LC->>L: compose answer from result
    L-->>LC: answer
    LC-->>S: answer + cited versions, in thread
  end
```

## App server on AKS, templates as cloud objects

- App pods hold no templates; they read published objects from Blob Storage
- API layer is the only component with storage access
- n8n and agents reach capabilities through the gateway, never storage directly
- Every workload authenticates with its own managed identity; no stored secrets
- Managed DB only if app state (e.g. form states, sessions) needs it

```mermaid
flowchart LR
  user["Users"]
  slack["Slack"]

  subgraph azure["Azure subscription"]
    edge["Ingress + TLS<br/>+ sign-in gate"]

    subgraph aks["AKS cluster"]
      subgraph wfns["namespace: workflows"]
        n8n["n8n<br/>LangChain agent node<br/>+ tool flows"]
        tmp["Temporal"]
      end
      subgraph agns["namespace: agents"]
        workers["Ingestion<br/>agent workers"]
      end
      subgraph appns["namespace: app (the app service)"]
        ui["App UI +<br/>review tools"]
        gw["Agent-safe<br/>tool gateway"]
        api["App API layer"]
        core["Renderer +<br/>template store"]
      end
    end

    subgraph data["Azure data services"]
      blob[("Blob Storage<br/>published + staging")]
      pg[("PostgreSQL<br/>if needed")]
    end

    subgraph platform["Azure platform services"]
      llm["Inference service"]
      kv["Key Vault"]
      acr[("Container Registry")]
    end
  end

  user --> edge
  slack -->|"events"| edge
  edge --> ui
  edge -->|"webhook"| n8n
  tmp <-->|"task queues"| workers

  n8n ==>|"tool calls"| gw
  workers ==>|"tool calls"| gw
  ui --> api
  gw ==> api
  api --> core
  core ==>|"managed identity:<br/>only storage access"| blob
  core -.-> pg
  tmp -.-> pg

  n8n -.->|"inference"| llm
  workers -.->|"inference"| llm
  n8n -.->|"secrets"| kv
  acr -.->|"pull by digest"| aks
```

## Human user sign-in (Azure example)

- People sign in with Entra ID (OIDC), with organization policies such as MFA applied there
- Managed identities cover the workloads: the app uses its own identity to reach storage
- The app never holds user passwords or storage keys
- Roles from Entra groups decide read, author, review, publish

```mermaid
sequenceDiagram
  actor U as User
  participant B as Browser
  participant E as Ingress / sign-in gate
  participant ID as Entra ID
  participant A as App UI + API
  participant M as App managed identity
  participant S as Blob Storage

  U->>B: open site
  B->>E: request
  E-->>B: redirect to sign-in
  B->>ID: sign in (MFA, org policies)
  ID-->>B: ID token with group claims
  B->>E: request + token
  E->>A: request + verified identity and roles
  A->>M: get storage token (no secret)
  M-->>A: short-lived token
  A->>S: read published template
  S-->>A: template objects
  A-->>B: rendered page, filtered by role
```

## Admin deploying the system (Azure example)

- Admin elevates just in time; no standing owner rights
- Infrastructure as code creates cloud resources, identities, and role assignments; tool not chosen yet
- CI builds and validates images, pushes by digest
- Cluster changes applied from the repository (e.g. GitOps), not by hand
- Compatibility suite runs against the new deployment before traffic moves

```mermaid
sequenceDiagram
  actor Ad as Admin
  participant ID as Entra ID
  participant IaC as Infrastructure as code
  participant ARM as Azure Resource Manager
  participant CI as CI pipeline
  participant ACR as Container Registry
  participant K as AKS
  participant T as Compatibility suite

  Ad->>ID: sign in, elevate role (just in time)
  Ad->>IaC: apply environment definition
  IaC->>ARM: AKS, storage, registry, DB if needed
  IaC->>ARM: managed identity per workload,<br/>federation to service accounts, role assignments
  ARM-->>IaC: resources ready
  Ad->>CI: merge release change
  CI->>CI: build, test, record digests
  CI->>ACR: push images by digest
  CI->>K: apply manifests referencing digests
  K->>ACR: pull by digest (cluster identity)
  CI->>T: run suite against new deployment
  T-->>Ad: match / mismatch / error report
```

## Milestones

- Labels only; order and dependencies not decided

| Milestone | Outcome | Status |
|---|---|---|
| M1 Legacy on local Kubernetes | Pinned legacy image, corpus baked in, on local Kubernetes; developer tasks | Done |
| M2 Compatibility suite | Black-box tests outside the app; any renderer vs any renderer | Prototype: one case, tool + unit tests; public baseline blocked by site outage |
| M3 Deployment portability | Same image runs locally and on managed Kubernetes | Partial: probes, security context, limits, digest pinning; draft managed-cluster notes |
| M4 Template storage abstraction | Filesystem (compatibility) and object storage backends | Not started |
| M5 Python implementation | Python renderer; every template renders without error (parity not required); Perl stays in the legacy image | Design done |
| M6 Managed Kubernetes + identity | Managed cluster via infrastructure as code; human sign-in; per-workload managed identities | Not started |
| M7 Templates cloud-only | Corpus in object storage with versions and roles; out of images and repo | Not started; needs explicit approval |
| M8 Workflow engines | Human edit workflow; agent ingestion in Temporal; in-cluster agents | Not started |
| M9 Chatbot | Slack (example) → n8n → LangChain tool choice → tool flows | Not started |
| M10 API layer + tool gateway | One app API; agent-safe MCP-like gateway with catalog, authorization, audit | Not started |
| M11 Review tooling | Change proposals with source/rendered diffs, trace, provenance, decisions | Not started |

## Constraints

- Legacy PHP/Perl app and corpus remain the reference until the suite shows parity
- Removing templates from the repo and images changes the project's current contract
  - needs explicit approval at that point
  - filesystem backend stays as the compatibility option until then
- Current save endpoints write to the corpus; replaced by reviewed workflows before public exposure
- Agents never publish; a human decision is always recorded
- Nothing here requires installing PHP or Perl on a workstation

## Open decisions

- Cloud provider (Azure is the example)
- Workflow engine for human edit workflows: n8n or Temporal
- Whether app state needs a database, and which state
- Infrastructure-as-code tool; GitOps or pipeline-driven deploys
- Inference provider and model
- Gateway protocol: MCP itself or MCP-like
- Tool catalog: operations, schemas, side-effect classes per tool
- How chat identities map to org identities
- Review tooling form: part of the app UI, separate tool, or both
- Template versioning and object layout
- Role model: who can author, review, publish; agent limits
- Public read access vs signed-in only
- Chat front ends beyond Slack
