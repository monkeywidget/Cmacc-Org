# Access control: roles, groups, and permissions

- Who can do what, for people; agents are covered in [agent-identities.md](agent-identities.md)
- All identities live in Microsoft Entra ID; nobody gets a local account
- Permissions come from group membership and per-template grants, never from individuals being named in code or config
- One installation per firm; the firm's people are granted accounts
- Signed-in only: no anonymous access to any page
- Sign-in happens before the app (Entra ID via a sign-in proxy); the app never handles passwords or tokens
- Status: proposal; open questions at the end

## Roles

| Role | Who | Can | Granted by |
|---|---|---|---|
| End user | members of the firm with an account | read published templates they may see; fill forms; use the chatbot | Entra group |
| Template viewer | per template or folder | read that template, including drafts and history | a template admin of that template, or a global template admin |
| Template editor | per template or folder | propose edits to drafts; cannot publish (templates are curated) | a template admin of that template, or a global template admin |
| Template admin (per template) | per template or folder | edit, review editors' proposals, publish; grant viewer/editor/admin on that template | a global template admin |
| Template admin (global) | legal users who manage the corpus | everything a per-template admin can, on all templates; assign per-template roles | Entra group |
| System admin | platform operators | run and change the platform; no template decisions | Entra group (sub-roles below) |

- Per-template roles apply to a template or a folder, and are inherited by everything under that folder
- Grants name Entra users or groups
- Template roles and system roles are separate: operating the platform does not grant template rights, and the reverse

## Where each permission is checked

```mermaid
flowchart LR
  people["People<br/>(Entra ID)"] --> proxy["Sign-in proxy<br/>(before the app)"]
  proxy -->|"user + groups"| app
  people --> groups["Entra groups"]
  groups --> app["App<br/>template roles:<br/>end user, viewer, editor, admin"]
  groups --> k8s["Kubernetes<br/>(Azure RBAC for Kubernetes)"]
  groups --> azure["Azure resources<br/>(Azure RBAC)"]
  grants[("Per-template grants<br/>database")] --> app
  app --> gw["API layer + tool gateway<br/>checks every call"]
```

- **Sign-in:** an Entra ID sign-in proxy (oauth2-proxy) runs beside the app in every pod
  - redirects to Entra ID, requires membership of the installation's user group, then passes the user and groups to the app
  - uses workload identity: no client secret stored anywhere
  - the app accepts identity only from its own proxy, never from the outside
  - one exception: a health route open without sign-in for liveness checks; page smoke tests sign in with a dedicated test account
- **App:** reads the signed-in user and groups from the proxy; the API layer checks the global role and the per-template grants on every request
- **Kubernetes:** AKS Automatic uses Entra ID with Azure RBAC for cluster access; no Kubernetes-local accounts
- **Azure resources:** Azure RBAC on the resource group, registry, and state storage

## Changing a template: who may do what

- Editors propose; template admins review and publish; every step is checked against the grants and audited

```mermaid
sequenceDiagram
  actor Ed as Template editor
  actor Ad as Template admin
  participant P as Sign-in proxy
  participant A as App / API layer
  participant DB as Grants database
  participant S as Template store
  participant L as Azure Monitor Logs

  Ed->>P: propose an edit
  P->>A: request + editor's identity
  A->>DB: editor (or admin) on this template or folder?
  A->>S: save as a proposal (draft)
  A->>L: audit: proposal
  Ad->>P: review the proposal
  P->>A: request + admin's identity
  A->>DB: admin on this template or folder?
  alt approve
    A->>S: publish
    A->>L: audit: publish
  else request changes
    A-->>Ed: returned with notes
  end
```

## System admin sub-roles

| Sub-role | Does | Azure roles (proposed, built-in) | Scope |
|---|---|---|---|
| Devops | runs Terraform; sets secret values (over VPN) | Contributor; Role Based Access Control Administrator (limited to the roles Terraform assigns); Storage Blob Data Contributor; Key Vault Secrets Officer | resource group; state storage container; key vault |
| Deployer | build and release | AcrPush; Azure Kubernetes Service Cluster User Role; Azure Kubernetes Service RBAC Writer | registry; cluster; app namespace only |
| Cluster admin | emergencies | Azure Kubernetes Service RBAC Cluster Admin | cluster; just-in-time only |
| Operator (read) | troubleshooting | Reader; Azure Kubernetes Service RBAC Reader | resource group; cluster |

- Devops includes the deployer sub-role today (one team); the split lets the future deploy cluster hold only deployer rights
- Cluster admin is time-limited elevation (Entra Privileged Identity Management), not standing membership
- The cluster's own identity only pulls images (AcrPull); it has no other rights

```mermaid
flowchart LR
  admin["System admin"] -->|"sign in (MFA)"| entra["Entra ID"]
  entra -->|"group membership<br/>(approved by admins)"| roles["Azure roles<br/>per sub-role"]
  entra -.->|"just-in-time elevation<br/>(PIM, time-limited)"| cadmin["Cluster admin"]
  roles -->|"devops"| rg["Resource group<br/>+ Terraform state"]
  roles -->|"deployer"| acr[("Registry: push")]
  roles -->|"deployer"| ns["Cluster: app namespace"]
  roles -->|"devops, over VPN"| kv[("Key Vault: secrets")]
  roles -->|"operator"| read["Read-only views"]
  cadmin --> cluster["Whole cluster"]
```

## Groups (proposed names)

- `cmacc-users`: end users; membership is required to sign in
- `cmacc-template-admins`: global template admins
- `cmacc-devops`, `cmacc-deployers`, `cmacc-operators`: system admin sub-roles
- `cmacc-cluster-admins`: eligible for just-in-time cluster admin
- Per-template grants reference these groups or individual users; they are rows in the app database, not groups
- Membership of every group is approved by admins (for now)

## Audit

- Recorded with who, what, when: sign-ins, per-template grants and removals, publishes, role elevation, deployments
- Stored in Azure Monitor Logs (the installation's Log Analytics workspace)
- System changes (Terraform, releases) are also recorded in the repository history

```mermaid
flowchart LR
  proxy["Sign-in proxy<br/>sign-ins"] --> logs[("Azure Monitor Logs")]
  app["App / API layer<br/>grants, proposals, publishes"] --> logs
  gw["Tool gateway<br/>agent actions"] --> logs
  entra["Entra ID<br/>sign-ins, role elevation"] --> logs
  kv["Key Vault<br/>secret reads, changes"] --> logs
  rel["Rollout script<br/>releases"] --> logs
```

## Sign-in flow

```mermaid
sequenceDiagram
  actor U as Person
  participant G as Gateway
  participant P as Sign-in proxy (in the pod)
  participant E as Entra ID
  participant A as App

  U->>G: request
  G->>P: forward (stable or canary track)
  alt no session
    P-->>U: redirect to Entra ID
    U->>E: sign in (firm account, MFA per firm policy)
    E-->>P: tokens with group claims
    P->>P: member of the user group? else refuse
  end
  P->>A: request + signed-in user and groups
  A-->>U: page, filtered by global role and per-template grants
```

## Open questions

- Save endpoints: the app does not check roles on saves yet, so any signed-in user could save; disable saves or enforce the editor and admin roles before users get access
- People in more than 200 groups: the proxy needs consent to read their full group list from Microsoft Graph
