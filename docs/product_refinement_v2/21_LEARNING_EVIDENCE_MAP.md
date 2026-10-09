# Learning & Growth Evidence Map — LEARN-G1-DISCOVERY

> **Status:** Evidence baseline complete; product conclusions are documented separately in G1 direction.
> **Inspected:** 2026-09-29
> **Purpose:** Separate visible Flutter/local-domain evidence from future claims about learning delivery, content ingestion, assessment, AI, or speech/camera capability.

## 1. Current inventory evidence

- The registry records **65 education services** across **9 systems**, with parent and child journeys across lessons, assignments, assessment, tutoring, adaptive plans, rewards, Quran, focus, and Parent Studio.
- Current Flutter source contains substantial parent Studio and child-learning surfaces, including lessons, assignments, quizzes, results, tutor, focus, rewards, Quran/memorization/recitation, interactive stories, learning plans, and progress reports.
- `main.dart` binds local assignment and learning-result persistence through the shared SQLite/session foundation when available. The application remains local/mock-first, not a multi-device education service.
- Education source includes local repositories, mock/seam repositories, approved-content models, and local bridges. It is valuable UX/domain evidence, not proof of remote classroom, content-provider, grading, or AI delivery.
- The codebase has dedicated widget/repository tests for most Studio, child-learning, Quran, task, calendar, and focus surfaces. This review did not execute Flutter tests because the SDK is intentionally absent from this workspace.

## 2. System-by-system evidence

| Learning system | Observed UI/domain evidence | Local/test evidence | Production gap to resolve |
|---|---|---|---|
| Subjects & lessons | Parent materials/lessons screen; child home and lesson surfaces; source reference and approved-pack models. | Local assignment/result repositories and screen tests. | Content catalog, source licensing/provenance, remote sync, curriculum/grade metadata, download/offline rules. |
| Homework | Parent create-assignment, child homework/task, assignment status/result patterns. | Local assignment persistence and child/parent widget tests. | Multi-device assignment delivery, attachment/submission storage, due-date/time-zone behavior, guardian notifications, review workflow. |
| Tests & assessment | Parent create-assignment/test surfaces, child quiz/result screens, result repositories. | Local result models/persistence and quiz/result tests. | Assessment engine, question integrity, scoring/rubric model, accessibility accommodations, remote result sync. |
| Intelligent tutor | Child tutor, lesson, quiz, interactive-story surfaces with guided-learning language. | Mock/repository seams and UI tests. | Model/provider, age/subject guardrails, source-grounding, answer policy, conversation storage/visibility, evaluation and cost controls. |
| Adaptive learning | Child smart plan/daily review, learning path, results/follow-up surfaces. | Local plan/result patterns. | Skill graph, mastery evidence, recommendation engine, spaced-review scheduler, confidence and “insufficient data” logic. |
| Motivation & rewards | Child wallet, challenges, gifts, streak/reward-related views; parent attribution/reward flow. | Local models/repositories and widget tests. | Unified non-financial reward ledger, policy connection to time privilege, fairness/conflict rules, abuse prevention, cross-device sync. |
| Quran & Islamic education | Quran local bridge, recitation, ward plan, child memorization/ward/smart-tilawah/adhkar, parent Quran progress. | Local bridge/repositories and screen tests. | Content source/provenance, optional language/translation context, audio/recitation capability, respectful personalization, cross-device progress. |
| Focus & study environment | Child focus/focus sounds, parent focus report, smart modes, calendar/task/security connections. | Local focus sound repository and UI tests. | Real focus state/device coordination, schedule conflict handling, sound/media rights/offline strategy, verified parent report data. |
| Parent Studio | Studio board, source intake, camera surface, generated-output, review/approve, paths, projects, community library, reward attribution. | Local/mock repositories and broad widget coverage. | Real camera/file/link/voice intake, OCR/import, generation service, content moderation, community governance, provenance, storage, publishing/rollback. |

## 3. Capability truth discovered in source

### Observed local/UX foundations

- SQLite/local persistence is used for learning assignments and results where the local database is available.
- Parent Studio, child learning, Quran and focus have strongly developed screen and model surfaces.
- The Studio camera screen explicitly uses a `FakeCameraPermissionSeam` by default and navigates to mocked generation output; it is not real capture/OCR.
- Source intake presents camera, link, file, topic, voice, and library options as UI pathways; the app dependency/source audit does not demonstrate production file picker, remote fetching, camera capture, speech-to-text, OCR, or generation transport.
- Tutor, adaptive, scoring, generation, recitation correction, and community library surfaces exist as product concepts/local state; no live AI/provider or remote content system is evidenced.

### Not currently evidenced

- A remotely synchronized child learning record.
- Real assignment delivery across parent and child devices.
- Real file or link ingestion, camera OCR, voice capture/transcription, or external content import.
- AI model calls, model safety/quality evaluation, content grounding, chat history service, or teacher/guardian review service.
- Automated grading with valid subject-specific scoring policy.
- Speech/recitation recognition or correction.
- A community publishing/moderation/licensing/provenance system.
- Payment, allowance, wallet, or financial reward integration.

## 4. Journey reconciliation work

Three registered education services currently do not appear in a registered user journey:

- `S-EDU-006` — video library.
- `S-EDU-010` — AI-assisted automatic grading.
- `S-EDU-046` — parent focus report.

They remain active analysis items. Learning refinement must give each a closed journey, merge it with another approved surface, defer it as an existing system, or explicitly retire it later.

## 5. Competitive evidence baseline

| Reference | Product lesson for Family OS |
|---|---|
| [Khan Academy Parent Dashboard](https://support.khanacademy.org/hc/en-us/articles/360039664491-What-can-I-do-from-the-Khan-Academy-Parent-Dashboard) | Parents can connect a child, assign work, follow progress, and access learning support—without needing a teacher-admin interface. |
| [Khan Academy app](https://play.google.com/store/apps/details?id=org.khanacademy.android&hl=en_US) | Lessons, practice, quizzes, feedback, tailored next steps, and continuation across devices establish global learner expectations. |
| [Khanmigo for parents](https://www.khanmigo.ai/parents) | A family AI tutor should guide rather than answer, use guardrails, and give guardians appropriate visibility/alerts. |
| [Google Classroom](https://edu.google.com/workspace-for-education/products/classroom/) | Assignment lifecycle, feedback/rubrics, insight, guardian summaries, and parent/teacher communication are mature expectations. |
| [Google guardian controls](https://support.google.com/edu/classroom/answer/7017326?hl=en) | Guardian visibility should be deliberate and scoped, not identical to teacher/admin access. |
| [Duolingo streak design](https://blog.duolingo.com/streak-milestone-design-animation/) | Streaks and celebrations can create durable habits when they celebrate effort, not guilt or harmful comparison. |

## 6. Discovery implications

1. The product already has broad education UX coverage; the G2 goal is to reconcile it into one Learning Hub and one child learning rhythm—not to add disconnected screens.
2. Parent Studio is strategically distinctive but has the largest truth gap: source intake and AI/content workflows need a real content lifecycle before they can make production claims.
3. AI tutor, adaptive paths, auto-grading, recitation correction, and generation must be judged by learning outcome, guardian/child trust, and actual capability—not by an AI label.
4. Focus is a cross-pillar advantage because its product loop already intersects time controls, school mode, calendar, and child routines.
5. Quran is an existing registered learning system and can become a powerful elective, culturally flexible learning track. It must remain respectful and never be treated as a generic gamification attachment.
