# Family Intelligence Evidence Map — INTELLIGENCE-G1-DISCOVERY

> **Status:** Evidence baseline complete; product decisions are documented in G1 direction.
> **Inspected:** 2026-09-29
> **Purpose:** Separate existing advisor/safety UI and local-domain models from real model inference, cross-device knowledge, provider integration, delegation or autonomous execution.

## 1. Current evidence summary

- The registry contains 34 intelligence services across six systems, with existing parent-facing surfaces for patterns, knowledge maps, weekly reports, assistant, alerts, voice, and agent action log.
- Flutter contains advisor hub/suggestions, family patterns, individual timeline, knowledge maps, weekly report, voice, mother AI feed, brain controls, rule editor, platform monitoring and smart-alert surfaces.
- The source has valuable local offline-AI safety-domain models: signed manifest concepts, typed safety signals, confidence/severity/provenance, redacted preview, ticket/suggestion/audit structures, and explicit “suggest-only” handoff intent.
- These are local SQLite/domain/UI evidence. No live LLM/model provider, remote model deployment, cross-device family knowledge backend, voice transport, real image analysis, or autonomous agent execution was found.

## 2. System-by-system evidence

| System | Observed UI/domain evidence | Current truth gap |
|---|---|---|
| Signal engine | Local safety classifier/store/service, alert hub/detail, platform monitoring and smart-alert models. | Real source ingestion, supported content/image signals, model deployment/update, server event pipeline, provider evaluation. |
| Patterns & anomalies | Family patterns, timeline, knowledge-map screens/models and confidence concepts. | Real baseline/window computation, cross-device data, data sufficiency, trend quality, false-positive feedback. |
| Family knowledge store | Local advisor memory, timeline/knowledge maps, family data lifecycle/forget concepts. | Render-authoritative knowledge graph/event store, visibility/consent, correction/delete propagation, retrieval quality. |
| Advisor & reports | Advisor suggestions, weekly report, family moments, education/studio-adjacent advice surfaces. | Real report aggregation, recommendation evidence, quality/confidence, provider/model grounding, content/recitation analysis. |
| Interactive assistant | My Advisor and voice UI/repository seams. | Natural-language backend, role-aware retrieval, voice I/O, source citations, guardrails, cost/rate limiting, audit. |
| Delegated agent | Brain control, rule editor, agent action log and action models. | Delegation policy executor, permitted command contracts, authorization, real undo, notification, durable audit. |

## 3. Explicit capability truth

- The local `offline_ai_safety` domain explicitly treats safety output as a typed fact/signal, not final policy, and models suggestion-only handoff. This supports the V2 direction but does not prove a production classifier.
- Local AI safety storage is SQLite/memory-backed. It cannot represent synchronized family knowledge or a production model-control plane.
- No HTTP/LLM SDK/model provider, speech service, camera/image-analysis adapter, Render service, Firebase AI integration, or delegated action backend is currently implemented.
- Existing advisor/voice/agent screens are not evidence of real AI reasoning, voice conversation, generation, correction, automation or audit durability beyond local/mock models.

## 4. Journey reconciliation work

Three registered intelligence services lack a registered user journey:

- `S-AIC-004` — sensitive-image detection.
- `S-AIC-005` — updateable rule list.
- `S-AIC-021` — Studio content generation.

Each must gain a closed journey, merge, defer, or retire explicitly. Their visible screen presence does not establish production support.

## 5. Discovery implications

1. Intelligence can become the platform’s connective tissue only after Security, Learning and Connection events become real Render-authoritative data.
2. The strongest current design asset is the separation of signal, certainty, redacted context, suggestion and audit. G2 must generalize this across every intelligence surface.
3. Agent delegation is the highest-risk system and belongs after underlying policy/command/audit infrastructure—not before it.
4. Image/content analysis, Studio generation, homework correction, recitation analysis and voice conversation are distinct capability programmes. They must not be bundled under a single “AI” promise.
