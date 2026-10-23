// Understand-Anything batch generator (deterministic, offline).
// Regenerates missing/empty batch-<i>.json files from batches.json + source files.
// Writes ONLY inside .ua/intermediate/. Never touches application source.
import fs from 'fs';
import path from 'path';

const ROOT = process.cwd();
const UA = path.join(ROOT, '.ua');
const batches = JSON.parse(fs.readFileSync(path.join(UA, 'intermediate/batches.json'), 'utf8'));

const idxs = process.argv.slice(2).map(Number).filter(Number.isFinite);
const want = idxs.length ? new Set(idxs) : null;

// ---- helpers -------------------------------------------------------------
const norm = (p) => p.replace(/\\/g, '/');
const linesOf = (src) => src.split(/\r?\n/);

function braceDepthTracker(lines) {
  const depth = new Array(lines.length).fill(0);
  let d = 0;
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    line = line.replace(/'([^'\\]|\\.)*'/g, "''").replace(/"([^"\\]|\\.)*"/g, '""');
    for (const ch of line) {
      if (ch === '{') d++;
      else if (ch === '}') d--;
    }
    depth[i] = d;
  }
  return depth;
}

function complexityFor(n) {
  if (n < 80) return 'simple';
  if (n < 300) return 'moderate';
  return 'complex';
}

function scanRangeEnd(lines, depth, i) {
  const before = i > 0 ? depth[i - 1] : 0;
  let end = i;
  for (let j = i; j < lines.length; j++) {
    if (j > i && depth[j] <= before) { end = j; break; }
    end = j;
  }
  return end;
}

// ---- Dart analysis --------------------------------------------------------
function analyzeDart(filePath, src) {
  const lines = linesOf(src);
  const depth = braceDepthTracker(lines);
  const symbols = [];
  const seenSym = new Set();

  const typeRe = /^(\s*)(?:abstract\s+)?(?:final\s+)?(?:sealed\s+)?(?:base\s+)?(?:interface\s+)?(class|enum|mixin|extension)\s+([A-Za-z_]\w*)/;
  for (let i = 0; i < lines.length && symbols.length < 15; i++) {
    const m = lines[i].match(typeRe);
    if (!m) continue;
    const name = m[3];
    if (seenSym.has(name)) continue;
    seenSym.add(name);
    symbols.push({ kind: 'class', name, lineRange: [i + 1, scanRangeEnd(lines, depth, i) + 1] });
  }

  const fnRe = /^([A-Za-z_][\w<>,?\s*]*\s+)?(?:get\s+)?([A-Za-z_]\w*)\s*\(([^)]*)\)\s*(?:async\s*)?(?:\{|=>)/;
  const getRe = /^([A-Za-z_][\w<>,?\s*]*\s+)?get\s+([A-Za-z_]\w*)\s*(?:=>|\{)/;
  for (let i = 0; i < lines.length && symbols.length < 15; i++) {
    const prevDepth = i > 0 ? depth[i - 1] : 0;
    if (prevDepth !== 0) continue;
    const line = lines[i].trim();
    if (!line || /^(import|export|part |\/\/|@|class |enum |mixin |extension |abstract)/.test(line)) continue;
    let name = null;
    const m = line.match(fnRe);
    const mg = line.match(getRe);
    if (m && !['if', 'for', 'while', 'switch', 'return'].includes(m[2])) name = m[2];
    else if (mg) name = mg[2];
    if (!name || seenSym.has(name)) continue;
    seenSym.add(name);
    symbols.push({ kind: 'function', name, lineRange: [i + 1, scanRangeEnd(lines, depth, i) + 1] });
  }

  const targets = [];
  const impRe = /^(?:import|export)\s+'([^']+)'/gm;
  let mm;
  while ((mm = impRe.exec(src)) !== null) targets.push(mm[1]);
  return { symbols, importTargets: targets, lineCount: lines.length };
}

// ---- JS analysis ----------------------------------------------------------
function analyzeJs(filePath, src) {
  const lines = linesOf(src);
  const depth = braceDepthTracker(lines);
  const symbols = [];
  const seenSym = new Set();
  const reClass = /^(?:export\s+)?(?:default\s+)?class\s+([A-Za-z_]\w*)/;
  const reFn = /^(?:export\s+)?(?:default\s+)?(?:async\s+)?function\s*\*?\s*([A-Za-z_]\w*)/;
  const reConst = /^(?:export\s+)?(?:const|let|var)\s+([A-Za-z_]\w*)\s*=\s*(?:async\s*)?(?:\([^)]*\)|[A-Za-z_]\w*)\s*=>/;
  for (let i = 0; i < lines.length && symbols.length < 15; i++) {
    if ((i > 0 ? depth[i - 1] : 0) !== 0) continue;
    const line = lines[i];
    let kind = null, name = null, m;
    if ((m = line.match(reClass))) { kind = 'class'; name = m[1]; }
    else if ((m = line.match(reFn))) { kind = 'function'; name = m[1]; }
    else if ((m = line.match(reConst))) { kind = 'function'; name = m[1]; }
    if (!name || seenSym.has(name)) continue;
    seenSym.add(name);
    symbols.push({ kind, name, lineRange: [i + 1, scanRangeEnd(lines, depth, i) + 1] });
  }
  const targets = [];
  let mm;
  const reqRe = /require\('([^']+)'\)/g;
  const impRe = /import\s+(?:[^']+from\s+)?'([^']+)'/g;
  while ((mm = reqRe.exec(src)) !== null) targets.push(mm[1]);
  while ((mm = impRe.exec(src)) !== null) targets.push(mm[1]);
  return { symbols, importTargets: targets, lineCount: lines.length };
}

// ---- import resolution ----------------------------------------------------
let scanSet = null;
try {
  const sr = JSON.parse(fs.readFileSync(path.join(UA, 'intermediate/scan-result.json'), 'utf8'));
  scanSet = new Set((sr.files || []).map((f) => (typeof f === 'string' ? f : f.path)));
} catch { scanSet = null; }

function resolveTarget(fromFile, spec) {
  spec = spec.trim();
  if (spec.startsWith('dart:') || spec.startsWith('package:') ) return null;
  if (spec.startsWith('.')) return norm(path.join(path.dirname(fromFile), spec));
  return null;
}

function idForPath(p) {
  if (/\.(yaml|yml|json|properties|env|toml)$/.test(p)) return 'config:' + p;
  if (/\.(md|rst|txt|csv)$/.test(p)) return 'document:' + p;
  if (p.startsWith('.github/workflows/')) return 'pipeline:' + p;
  return 'file:' + p;
}

// ---- Arabic role descriptions ---------------------------------------------
function featureOf(p) {
  const m = p.match(/features\/(?:n\d+_)?([^/]+)\//);
  return m ? m[1].replace(/_/g, ' ') : null;
}

function dartRoleSummary(p, symbols) {
  const base = path.basename(p);
  const feat = featureOf(p);
  const featPart = feat ? ` لميزة «${feat}»` : '';
  const mainClass = symbols.find((s) => s.kind === 'class');
  const classNames = symbols.filter((s) => s.kind === 'class').map((s) => s.name).slice(0, 3).join('، ');

  if (p.includes('/design/components/')) {
    return `مكوّن واجهة «${mainClass ? mainClass.name : base.replace('.dart', '')}» من نظام التصميم المشترك لتطبيق Family OS${featPart}.`;
  }
  if (base.endsWith('_screen.dart')) {
    return `شاشة Flutter${featPart}: تنفّذ ${mainClass ? 'الصنف ' + mainClass.name : 'واجهة تفاعلية'} وتعرض الحالة والتحكم للمستخدم.`;
  }
  if (base.endsWith('_repository.dart')) {
    return `مستودع بيانات${featPart}: يدير قراءة وكتابة البيانات${classNames ? ' بأصناف مثل ' + classNames : ''}.`;
  }
  if (base.endsWith('_models.dart')) {
    return `نماذج بيانات${featPart}: تعرّف الأصناف والقيم ${classNames ? 'مثل ' + classNames : 'المستخدمة في الواجهة والمستودعات'}.`;
  }
  if (base.endsWith('_authority.dart')) {
    return `طبقة سلطة الخادم${featPart}: تنسّق طلبات REST مع الواجهة الخلفية وتفصل قرار التفويض عن العميل.`;
  }
  if (base.endsWith('_panel.dart')) {
    return `لوحة حالة${featPart}: تعرض بيانات الخادم داخل الشاشة${classNames ? ' (صنف ' + classNames + ')' : ''}.`;
  }
  if (base.endsWith('_persistence.dart')) {
    return `طبقة تخزين محلي${featPart}: توفّر حفظ واستعادة الحالة.`;
  }
  if (p.startsWith('app/lib/core/')) {
    return `أداة أساسية في نواة التطبيق: ${classNames ? 'تعرّف ' + classNames : 'تقدّم منطقاً مشتركاً'} ضمن app/lib/core.`;
  }
  if (p.includes('/services/') || p.includes('/providers/')) {
    return `خدمة تطبيق${featPart}: ${classNames ? 'تعرّف ' + classNames : 'تغلّف منطقاً تشغيلياً'} وتخدم الشاشات والمستودعات.`;
  }
  return `ملف شفرة Dart ضمن تطبيق Family OS${featPart}${classNames ? ': يعرّف ' + classNames : ''}.`;
}

function docSummary(p, src) {
  const base = path.basename(p);
  if (base.endsWith('.csv')) {
    const kind = /screens/.test(base) ? 'الشاشات' : /journeys/.test(base) ? 'رحلات المستخدم' : /services/.test(base) ? 'الخدمات' : 'سجلات';
    return `سجل مرجعي (CSV) لـ${kind} ضمن ${path.dirname(p)} — مرجع مجمّد تستهلكه اختبارات Flutter.`;
  }
  for (const l of linesOf(src).slice(0, 30)) {
    const m = l.match(/^#\s+(.+)/);
    if (m) return `وثيقة: «${m[1].trim()}» (${base}).`;
  }
  return `وثيقة مرجعية (${base}) ضمن مشروع Family OS.`;
}

function xmlSummary(p) {
  const base = path.basename(p);
  if (/strings/.test(base)) return 'مورد أندرويد: نصوص الواجهة والترجمات (values/strings.xml).';
  if (/styles/.test(base)) return 'مورد أندرويد: أنماط السمة الافتراضية للتطبيق (values/styles.xml).';
  if (/colors/.test(base)) return 'مورد أندرويد: ألوان الإشعارات والعلامات (values/*.xml).';
  return `ملف إعدادات/مورد (${base}).`;
}

// ---- main -----------------------------------------------------------------
let generated = 0;
for (const entry of batches.batches) {
  const bi = entry.batchIndex;
  if (want && !want.has(bi)) continue;

  const outPath = path.join(UA, `intermediate/batch-${bi}.json`);
  if (fs.existsSync(outPath)) {
    try {
      const prev = JSON.parse(fs.readFileSync(outPath, 'utf8'));
      if ((prev.nodes || []).length > 0) { console.log(`skip ${bi} (existing non-empty)`); continue; }
    } catch { /* regenerate */ }
  }
  const parts = fs.readdirSync(path.join(UA, 'intermediate'))
    .filter((f) => new RegExp(`^batch-${bi}-part-\\d+\\.json$`).test(f));
  if (parts.length > 0) { console.log(`skip ${bi} (parts exist)`); continue; }

  const nodes = [];
  const edges = [];
  const bid = entry.batchImportData || {};

  for (const f of entry.files) {
    const p = norm(f.path);
    let src = null;
    try { src = fs.readFileSync(path.join(ROOT, p), 'utf8'); } catch { src = null; }
    const lineCount = src ? linesOf(src).length : (f.sizeLines || 1);
    const lang = f.language || 'unknown';
    const cat = f.fileCategory || 'code';

    let fileNodeType = 'file';
    if (/\.(md|txt|csv|rst)$/.test(p)) fileNodeType = 'document';
    else if (/\.(xml|json|properties|env|yaml|yml|toml|lock)$/.test(p)) fileNodeType = 'config';
    else if (p.startsWith('.github/workflows/')) fileNodeType = 'pipeline';

    let summary = '';
    let tags = [];
    let symbols = [];
    let importTargets = [];

    if (lang === 'dart' && src !== null) {
      const a = analyzeDart(p, src);
      symbols = a.symbols; importTargets = a.importTargets;
      summary = dartRoleSummary(p, symbols);
      tags = ['شفرة', 'dart', 'تطبيق'];
    } else if (/\.m?js$/.test(p) && src !== null) {
      const a = analyzeJs(p, src);
      symbols = a.symbols; importTargets = a.importTargets;
      summary = `ملف شفرة JavaScript ضمن ${path.dirname(p)}${symbols.length ? ': يعرّف ' + symbols.slice(0, 3).map((s) => s.name).join('، ') : ''}.`;
      tags = ['مصدر', 'javascript', 'code'];
    } else if (cat === 'docs' || fileNodeType === 'document') {
      summary = src !== null ? docSummary(p, src) : `وثيقة (${path.basename(p)}).`;
      tags = ['توثيق', 'معرفة-المشروع', 'مرجع'];
    } else if (fileNodeType === 'config') {
      summary = src !== null && /\.xml$/.test(p) ? xmlSummary(p) : `ملف إعدادات (${path.basename(p)}).`;
      tags = ['إعدادات', 'تكوين'];
    } else if (fileNodeType === 'pipeline') {
      summary = `تعريف خط أنابيب CI/CD (${path.basename(p)}).`;
      tags = ['بنية-تحتية', 'ci'];
    } else if (/\.html$/.test(p)) {
      summary = `صفحة نموذج أولي/نسخة احتياطية (${path.basename(p)}) من مرجع family-os المجمّد.`;
      tags = ['نموذج-أولي', 'أرشيف', 'مرجع'];
    } else if (src !== null) {
      summary = `ملف ${lang === 'unknown' ? 'مساعد' : lang} ضمن ${path.dirname(p)}.`;
      tags = ['ملف', 'مساعد'];
    } else {
      summary = `ملف ضمن ${path.dirname(p)} (تعذر القراءة).`;
      tags = ['ملف'];
    }

    const fileId = `${fileNodeType}:${p}`;
    nodes.push({
      id: fileId,
      type: fileNodeType,
      name: path.basename(p),
      filePath: p,
      summary,
      tags,
      complexity: complexityFor(lineCount),
    });

    for (const s of symbols) {
      const sid = `${s.kind}:${p}:${s.name}`;
      nodes.push({
        id: sid,
        type: s.kind,
        name: s.name,
        filePath: p,
        lineRange: s.lineRange,
        summary: s.kind === 'class'
          ? `يمثل الصنف ${s.name} مسؤولية منظمة داخل ${path.basename(p)}.`
          : `ينفّذ ${s.name} سلوكاً محدداً ضمن ${path.basename(p)}.`,
        tags: s.kind === 'class' ? ['صنف', 'منطق', 'بنية'] : ['دالة', 'منطق', 'تنفيذ'],
        complexity: complexityFor(s.lineRange[1] - s.lineRange[0]),
      });
      edges.push({ source: fileId, target: sid, type: 'contains', direction: 'forward', weight: 1 });
      if (!s.name.startsWith('_')) {
        edges.push({ source: fileId, target: sid, type: 'exports', direction: 'forward', weight: 0.8 });
      }
    }

    let resolved = (bid[p] || []).slice();
    if (resolved.length === 0 && importTargets.length > 0) {
      for (const t of importTargets) {
        const r = resolveTarget(p, t);
        if (r) resolved.push(r);
      }
    }
    const seenT = new Set();
    for (const t of resolved) {
      const tp = norm(t);
      if (tp === p || seenT.has(tp)) continue;
      seenT.add(tp);
      if (scanSet && !scanSet.has(tp)) continue;
      edges.push({ source: fileId, target: idForPath(tp), type: 'imports', direction: 'forward', weight: 0.7 });
    }
  }

  fs.writeFileSync(outPath, JSON.stringify({ nodes, edges }, null, 1), 'utf8');
  generated++;
  console.log(`batch ${bi}: nodes=${nodes.length} edges=${edges.length}`);
}
console.log(`generated ${generated} batch file(s)`);



