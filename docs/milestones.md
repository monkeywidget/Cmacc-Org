# Milestones

- Status of the modernization; the target architecture is in the goal-state document
- Order not fixed; dependencies noted where they exist
- Updated: 2026-09-22

## Status

| # | Milestone | Status | Notes |
|---|---|---|---|
| M1 | Legacy on local Kubernetes | ✅ Done | |
| M2 | Compatibility suite | ✅ Done | Gate = every template renders without error; sweeps for both renderers |
| M3 | Deployment portability | 🟡 Mostly done | Left: lock image digests; publish to ACR with the first AKS deploy |
| M4 | Template storage | ✅ Done | Templates image + init container; store location from settings |
| M5 | Python implementation | ✅ Done | 5,236 templates, 0 errors, 0 timeouts; runs locally next to legacy |
| M6 | Managed Kubernetes + identity | ⬜ Not started | First deploy to AKS; CI platform chosen then |
| M7 | Templates cloud-only | ⬜ Not started | Needs M6 and explicit approval |
| M8 | Workflow engines | ⬜ Not started | Needs M10 |
| M9 | Chatbot | ⬜ Not started | Needs M10 |
| M10 | API layer + tool gateway | ⬜ Not started | Can start locally on the Python app |
| M11 | Review tooling | ⬜ Not started | Needs M10 |

## What each milestone delivers

- **M1 Legacy on local Kubernetes:** pinned legacy image with the corpus baked in, on local Kubernetes; developer and diagnostic tasks
- **M2 Compatibility suite:** render sweep over the whole corpus as the gate; public-parity comparison optional, not a gate
- **M3 Deployment portability:** same image runs locally and on AKS; no hardcoded hosts, paths, or architecture; no new CDN-hosted assets
- **M4 Template storage:** templates shipped as their own image, deployed alongside the server; object storage later by configuration
- **M5 Python implementation:** Python renderer for every view; parity with Perl not required; Perl stays in the legacy image
- **M6 Managed Kubernetes + identity:** AKS via infrastructure as code; images in ACR; human sign-in; per-workload managed identities; CI
- **M7 Templates cloud-only:** corpus in object storage with versions and roles; out of images and repo
- **M8 Workflow engines:** human edit workflow; agent ingestion in Temporal; in-cluster agents
- **M9 Chatbot:** Slack (example) → n8n → LangChain tool choice → tool flows
- **M10 API layer + tool gateway:** one app API; agent-safe MCP-like gateway with catalog, authorization, audit
- **M11 Review tooling:** change proposals with source and rendered diffs, trace, provenance, decisions

## Decided

- Cloud: Azure; first managed deploy to AKS
- Registry: Azure Container Registry (ACR)
- CI: platform chosen with the first AKS deploy; none before then

## Out of scope

- Corpus content, including broken or missing references: owned by the legal users
- New CDN-hosted assets
