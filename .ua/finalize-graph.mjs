// Finalize: assemble full KnowledgeGraph (layers + tour + metadata) from assembled-graph.json.
import fs from 'fs';
import path from 'path';

const ROOT = process.cwd();
const UA = path.join(ROOT, '.ua');
const g = JSON.parse(fs.readFileSync(path.join(UA, 'intermediate/assembled-graph.json'), 'utf8'));
const scan = JSON.parse(fs.readFileSync(path.join(UA, 'intermediate/scan-result.json'), 'utf8'));

// ---- normalize nodes -------------------------------------------------------
const fileLevel = new Set(['file', 'config', 'document', 'service', 'pipeline', 'table', 'schema', 'resource', 'endpoint']);
const seen = new Set();
const nodes = [];
for (const n of g.nodes) {
  if (!n.id || seen.has(n.id)) continue;
  seen.add(n.id);
  nodes.push({
    ...n,
    type: n.type || 'file',
    name: n.name || (n.id.split(':').pop() || n.id),
    summary: n.summary || 'عقدة بدون وصف.',
    tags: (n.tags && n.tags.length) ? n.tags : ['غير-مصنف'],
  });
}
const nodeIds = new Set(nodes.map((n) => n.id));
const edges = (g.edges || []).filter((e) => e && nodeIds.has(e.source) && nodeIds.has(e.target) && e.source !== e.target);

// ---- layers (deterministic by path prefix, first match wins) ---------------
const L = (id, name, description, prefixes) => ({ id, name, description, prefixes });
const layerDefs = [
  L('layer:flutter-app-shell', 'هيكل تطبيق Flutter', 'نقطة الدخول، الهيكل العام للتنقل، التهيئة والتوجيه داخل app/lib/app ونواة main.dart.', ['app/lib/main.dart', 'app/lib/app/', 'app/lib/l10n/', 'app/lib/routing/', 'app/lib/bootstrap']),
  L('layer:flutter-core-design', 'نواة تطبيق Flutter ونظام التصميم', 'نظام التصميم العربي المشترك (مكوّنات، ثيم، ألوان) وأدوات app/lib/core المشتركة بين الميزات.', ['app/lib/core/']),
  L('layer:flutter-features', 'ميزات Flutter العمودية', 'الأنظمة الوظيفية n01–n25 (سلامة، وقت شاشة، مهام، تعلّم، محادثة...) بشاشاتها ومستودعاتها وطبقات سلطة الخادم.', ['app/lib/features/', 'app/lib/services/', 'app/lib/providers/', 'app/lib/data/', 'app/lib/']),
  L('layer:flutter-native-platform', 'المنصة الأصلية (Android/iOS)', 'تكامل أندرويد الأصلي: خدمات الأمان ومراقبة الاستخدام وإشعارات FCM وإعدادات Gradle، وملفات iOS.', ['app/android/', 'app/ios/']),
  L('layer:flutter-tests-tools', 'اختبارات وأدوات Flutter', 'اختبارات رحلات المستخدم في app/test وأدوات المطور في app/tool.', ['app/test/', 'app/tool/']),
  L('layer:backend-api', 'واجهة Family OS الخلفية (Node.js/Express)', 'خدمات REST في backend/src، عقود openapi، مخططات وهجرات PostgreSQL في backend/db، وسكربتات backend/scripts.', ['backend/src/', 'backend/contracts/', 'backend/db/', 'backend/scripts/', 'backend/server', 'backend/openapi']),
  L('layer:backend-tests', 'اختبارات الواجهة الخلفية', 'اختبارات العزل والتفويض والبوابات البيئية في backend/test.', ['backend/test/', 'backend/tests/']),
  L('layer:docs-knowledge', 'وثائق المعرفة والحوكمة', 'الخطة الرئيسية، خطة التنفيذ الحالية، سياسات الصدق والتشغيل، الوثائق المؤرشفة وأدلة السلامة.', ['docs/', 'README.md', 'CLAUDE.md', 'AGENTS.md', 'app/README.md', 'app/FRONTEND_FIRST_PLAN.md', 'app/PRODUCTION_READINESS_AUDIT.md', 'app/UI_UX_FIRST_PLAN.md', 'backend/README.md', 'backend/DEPLOY', 'infra/']),
  L('layer:prototype-registries', 'النموذج الأولي والسجلات المجمّدة', 'مرجع family-os وprototype: سجلات الشاشات والرحلات والخدمات (CSV) ونسخ الأرشيف HTML التي تستندها اختبارات Flutter.', ['family-os/', 'prototype/']),
  L('layer:tooling-ci-agents', 'الأدوات وخطوط CI ووكلاء المنصة', 'سكربتات tools وscripts، خطوط GitHub Actions، إعدادات .cursor وملفات وكلاء .agents، وملفات الجذر التقنية.', ['tools/', 'scripts/', '.github/', '.agents/', '.cursor/', '.windsurf/', '.githooks/', '.kilo/', '.vscode/']),
];
const layerOf = new Map();
for (const n of nodes) {
  if (!fileLevel.has(n.type)) continue;
  const p = n.filePath || n.id.replace(/^\w+:/, '');
  let hit = null;
  for (const def of layerDefs) {
    if (def.prefixes.some((pre) => p === pre || p.startsWith(pre))) { hit = def; break; }
  }
  if (!hit) hit = { id: 'layer:root-misc', name: 'ملفات الجذر المتفرقة', description: 'ملفات وإعدادات في جذر المشروع لم تُغطَّها طبقة أخرى.' };
  if (!layerOf.has(hit.id)) layerOf.set(hit.id, { id: hit.id, name: hit.name, description: hit.description, nodeIds: [] });
  layerOf.get(hit.id).nodeIds.push(n.id);
}
const layers = [...layerOf.values()];

// ---- tour ------------------------------------------------------------------
const pick = (...ids) => ids.filter((id) => nodeIds.has(id));
const tour = [
  {
    order: 1,
    title: 'نظرة عامة على المشروع',
    description: 'ابدأ من README لفهم Family OS: تطبيق عائلي شامل (Super App) يجمع السلامة والرقابة الأبوية والتعلم والمهام في منصة واحدة بتجربة عربية أولاً. البنية: تطبيق Flutter + واجهة Node.js/Express خلفية + PostgreSQL.',
    nodeIds: pick('document:README.md', 'document:app/README.md', 'document:backend/README.md'),
  },
  {
    order: 2,
    title: 'حوكمة المشروع وخطته',
    description: 'الخطة الرئيسية تحدد 14 وظيفة كاملة، وخطة التنفيذ الحالية تختار نظاماً واحداً في كل مرحلة. سياسة الصدق الزمني وقانون جاكوبس يحكمان تجربة الاستمرارية، والبوابتان (توصيل الأسطح وبوابة البيئة) تشترطان إثباتاً حقيقياً.',
    nodeIds: pick('document:docs/00_MASTER_PLAN.md', 'document:docs/CURRENT_EXECUTION_PLAN.md', 'document:docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md', 'document:docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md'),
  },
  {
    order: 3,
    title: 'الواجهة الخلفية: نقطة الدخول والخدمات',
    description: 'app.js يجمّع كل مسارات REST: وقت الشاشة، المهام، المناطق الآمنة، SOS، الدردشة، فلترة الويب وغيرها. postgres-foundation-store هو طبقة PostgreSQL، وكل قرار تفويض يبقى ملكاً للخادم لا للعميل.',
    nodeIds: pick('file:backend/src/app.js', 'file:backend/src/screen-time.js', 'file:backend/src/tasks.js', 'file:backend/src/store/postgres-foundation-store.js', 'file:backend/src/sos-emergency.js'),
  },
  {
    order: 4,
    title: 'قاعدة البيانات: مخطط PostgreSQL',
    description: 'جداول backend/db تبني بيانات العائلات والأعضاء والأجهزة ووقت الشاشة والمهام. بوابة البيئة تشترط أن تعمل الهجرات فعلياً على PostgreSQL حقيقي في CI قبل اعتماد أي عمل على SQL.',
    nodeIds: nodes.filter((n) => n.type === 'table').slice(0, 5).map((n) => n.id),
  },
  {
    order: 5,
    title: 'تطبيق Flutter: الدخول والهيكل',
    description: 'main.dart يقلع التطبيق و family_shell يوفر هيكل التنقل الرئيسي بالأدوار (ولي/طفل) مع دعم RTL/LTR واللغتين AR/EN.',
    nodeIds: pick('file:app/lib/main.dart', 'file:app/lib/app/family_shell.dart', 'config:app/pubspec.yaml'),
  },
  {
    order: 6,
    title: 'نظام التصميم العربي المشترك',
    description: 'مكوّنات app/lib/core/design تشكّل لغة بصرية موحدة: بطاقات، أشرطة تقدم، شارات صدق القدرات، حالات فارغة/خطأ/تحميل — تُستخدم في كل الميزات للحفاظ على استمرارية التجربة.',
    nodeIds: pick('file:app/lib/core/design/components/components.dart', 'file:app/lib/core/design/components/app_card.dart', 'file:app/lib/core/design/components/capability_honesty_badge.dart'),
  },
  {
    order: 7,
    title: 'مثال ميزة عمودية كاملة: المهام العائلية',
    description: 'رحلة واحدة تكشف النمط المعماري: شاشة + مستودع محلي (sqflite) + طبقة سلطة خادم + لوحة حالة الخادم. هذا النمط نفسه يتكرر في كل الميزات n01–n25.',
    nodeIds: pick('file:app/lib/features/n16_tasks/family_tasks_screen.dart', 'file:app/lib/features/n16_tasks/family_tasks_repository.dart', 'file:app/lib/features/n16_tasks/tasks_server_authority.dart', 'file:backend/src/tasks.js'),
  },
  {
    order: 8,
    title: 'الأصلية والاختبارات والبوابات',
    description: 'خدمات أندرويد الأصلية تنفذ قدرات الجهاز، واختبارات app/test تثبت رحلات الأوصياء بينما تثبت backend/test العزل والتفويض. ادعاء التحكم بالجهاز لا يُعدّ صادقاً إلا بإثبات على هاتف حقيقي.',
    nodeIds: pick('document:docs/safety_phase/PHONE_CHECKS.md', 'pipeline:.github/workflows/android_build.yml')
      .concat(nodes.filter((n) => n.type === 'file' && (n.filePath || '').startsWith('app/test/')).slice(0, 3).map((n) => n.id)),
  },
  {
    order: 9,
    title: 'سجل الشاشات والرحلات المجمّد',
    description: 'سجلات family-os/_REGISTRY (شاشات، رحلات، خدمات بصيغة CSV) هي المرجع المجمّد الذي تستهلكه اختبارات Flutter للتحقق من أن كل شاشة ورحلة موثقة فعلاً.',
    nodeIds: pick('document:family-os/_REGISTRY/screens.csv', 'document:family-os/_REGISTRY/journeys.csv', 'document:family-os/_REGISTRY/services.csv'),
  },
].map((s) => ({ ...s, nodeIds: [...new Set(s.nodeIds)] })).filter((s) => s.nodeIds.length > 0);

// ---- metadata ---------------------------------------------------------------
const meta = {
  version: '1.0.0',
  project: {
    name: scan.name || 'Family OS',
    languages: scan.languages || [],
    frameworks: (scan.frameworks && scan.frameworks.length) ? scan.frameworks : ['Flutter', 'Node.js/Express', 'PostgreSQL'],
    description: scan.description || 'نظام تشغيل عائلي شامل: سلامة، رقابة أبوية، تعلم، ومهام — تطبيق Flutter + واجهة Node.js/Express + PostgreSQL.',
    analyzedAt: new Date().toISOString(),
    gitCommitHash: process.argv[2] || '',
  },
  nodes,
  edges,
  layers,
  tour,
};

fs.writeFileSync(path.join(UA, 'intermediate/full-graph.json'), JSON.stringify(meta, null, 1), 'utf8');
const covered = layers.reduce((a, l) => a + l.nodeIds.length, 0);
const fileNodes = nodes.filter((n) => fileLevel.has(n.type)).length;
console.log(JSON.stringify({ nodes: nodes.length, edges: edges.length, layers: layers.length, layerNodeCount: covered, fileLevelNodes: fileNodes, tourSteps: tour.length }, null, 1));

