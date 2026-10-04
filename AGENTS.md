# Family OS Global Super-App Constitution (The Execution Guard)

## 1. The Grand Vision
Family OS is not a simple app; it is a **Global Super App** for families, designed to replace fragmented single-purpose apps (e.g., Life360 for security, Qustodio for parental control, NotebookLM/Duolingo for education). It must anticipate every family need and provide a seamless, incredibly flexible, and beautiful user experience that matches or beats top global competitors.

## 2. The True Meaning of "Polishing" (عملية الصقل)
- **The Prototype is the Target:** The initial rich, colorful UI prototype is our ultimate goal. It is a "promise" to the user, not a draft to be discarded.
- **Do Not Delete, BUILD:** If a beautiful UI feature relies on mock data, **DO NOT delete the UI**. Instead, build the actual backend, database, and native device services to make that UI *real*.
- **Competitive UX Completion:** Polishing means analyzing top competitors, identifying what our UX lacks, designing those missing cards/buttons beautifully to fit our design system, and wiring them to the real backend.
- **Runtime Truth:** The application must never lie to the user with fake data in production. We solve fake data by building the real data pipeline, not by stripping down the UI.

## 3. Execution Strategy: System by System (نظام بنظام)
Development MUST proceed vertically, **System by System**, NOT screen by screen. This ensures deep focus, engineering sanity, and market readiness.
For every System (e.g., Security, Education, Operations), the workflow is:
1. **Domain Selection:** Lock focus on one specific system.
2. **Competitive Analysis:** Analyze top global apps in this domain to extract best-in-class features.
3. **UX Gap Analysis:** Add missing buttons, states, and flows to our prototype to beat competitors.
4. **The Real Engine:** Build the complete vertical slice (PostgreSQL -> Go Backend API -> Native Android Background Services -> Flutter UI) to make the system 100% real.
5. **Lock & Ship:** Finalize the system completely before moving to the next domain.

## 4. Hard Guards
- **No Scattered Development:** Do not jump between unrelated systems. Finish the active system first.
- **No Mock Persistence:** Do not persist mock data into production states. All data presented to the user must originate from the authoritative backend servers or real native device telemetry.
- **Maintain Flexibility:** The platform must remain highly adaptable to future AI and structural features.
- **Security & Secrets:** Do not expose secrets, tokens, or raw payloads in source code or CI. Keep authorization strictly server-owned.

> **Historical Note:** The previous "Foundation Wave" policies (which advocated for stripping down the UI to match minimal backend capabilities) are now superseded by this Global Super App Constitution. We now build the backend to meet the UI's demands.
