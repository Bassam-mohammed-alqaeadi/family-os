#!/usr/bin/env node
//
// Family OS — فحص الاستيرادات الميتة في Dart.
//
//   node tools/harness/check_dart_imports.mjs
//
// لماذا وُجد هذا الفحص: `unused_import` أسقط بوابة `analyze-test` مرّتين، وفي المرّتين
// كان الاستيراد زائداً في ملف اختبار كُتب حديثاً. المحلّل هو الحكم، لكنه لا يعمل محلياً
// في كل جلسة (Flutter غير متاح في صندوق التطوير)، فالسقوط يُكتشف بعد دفع وبعد سبع دقائق.
// هذه الأداة تشغّل نسخة متحفّظة جداً من نفس القاعدة قبل الدفع، بلا اعتماد على Flutter.
//
// المتحفّظة مقصودة: الإنذار الكاذب يُفسد الثقة في البوابة أكثر من عدم وجودها. لذلك
// تُفحَص فقط الاستيرادات التي **يستحيل** أن يكون استعمالها غير مرئي:
//   • الملف الهدف لا يحمل `extension` ولا getter ولا `part of` (استعمالها قد لا يُسمّي شيئاً).
//   • الاستيراد بلا `deferred as`.
//   • يلزم أن يكون الهدف قد عرّف رمزاً واحداً على الأقل يمكن استخراجه.
// ثم: إن لم يظهر أي من رموز الهدف في الملف المستورِد، فالاستيراد ميت — وهذا ما يرفضه
// المحلّل بـ`unused_import` تحت `--fatal-infos`.
//
// Exit: 0 = نظيف، 1 = استيراد ميت (يُذكر الملف والسطر والهدف).

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, normalize, relative, resolve } from 'node:path';

const ROOT = resolve(process.argv[2] ?? '.');
const APP = join(ROOT, 'app');
const SCAN_DIRS = ['lib', 'test', 'tool'].map((d) => join(APP, d));

function walk(dir, out = []) {
  let entries;
  try {
    entries = readdirSync(dir);
  } catch {
    return out;
  }
  for (const entry of entries) {
    const full = join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) {
      if (entry === '.dart_tool' || entry === 'build') continue;
      walk(full, out);
    } else if (entry.endsWith('.dart')) {
      out.push(full);
    }
  }
  return out;
}

/** الرموز العلوية القابلة للاستخراج من ملف Dart. */
function declaredSymbols(source) {
  const names = new Set();
  const add = (m) => {
    if (m) names.add(m);
  };
  // class / enum / mixin / typedef — بعددٍ من النعوت غير محدود (abstract final class …)
  for (const m of source.matchAll(/^(?:(?:abstract|sealed|final|base|interface|mixin|augment)\s+)*(?:class|enum|mixin|typedef)\s+([A-Za-z_]\w*)/gm)) {
    add(m[1]);
  }
  // دوال ومُهيّئات علوية: سطر يبدأ بعمود صفر وينتهي بـ`(` بعد نوع (قد يكون عاماً).
  for (const m of source.matchAll(/^(?!return|if|for|while|switch|assert|await|case|else)[A-Za-z_][\w<>?,\s[\].]*\s([A-Za-z_]\w*)\s*\(/gm)) {
    add(m[1]);
  }
  // ثوابت ومتغيّرات علوية
  for (const m of source.matchAll(/^(?:const|final|var|late)\s+[^=;]*?\b([A-Za-z_]\w*)\s*=/gm)) {
    add(m[1]);
  }
  // ومتغيّرات علوية بنوع صريح بلا كلمة مفتاحية: `InMemoryChildAppsRepository stage1ChildAppsRepository = …`
  for (const m of source.matchAll(/^(?!return|if|for|while|switch|assert|await|case|else)[A-Za-z_][\w<>?,\s[\].]*\s([A-Za-z_]\w*)\s*=/gm)) {
    add(m[1]);
  }
  return names;
}

/** هل استعمال رموز هذا الملف قد يكون غير مرئي في نصّ المستورِد؟ */
function usageMayBeImplicit(source) {
  return (
    /^\s*extension\s+/m.test(source) ||
    /^\s*[A-Za-z_][\w<>?,\s[\].]*\sget\s+[A-Za-z_]\w*/m.test(source) ||
    /^\s*part of\b/m.test(source) ||
    /^\s*export\s+/m.test(source)
  );
}

function resolveImport(fromFile, uri) {
  if (uri.startsWith('dart:') || uri.startsWith('package:') && !uri.startsWith('package:family_os/')) {
    return null;
  }
  if (uri.startsWith('package:family_os/')) {
    return join(APP, 'lib', uri.slice('package:family_os/'.length));
  }
  return normalize(join(dirname(fromFile), uri));
}

const files = SCAN_DIRS.flatMap((dir) => walk(dir));
const cache = new Map();
const sourceOf = (file) => {
  if (!cache.has(file)) {
    try {
      cache.set(file, readFileSync(file, 'utf8'));
    } catch {
      cache.set(file, null);
    }
  }
  return cache.get(file);
};

const findings = [];
let importsChecked = 0;
let lanesSkipped = 0;

for (const file of files) {
  const source = sourceOf(file);
  if (source === null) continue;
  for (const m of source.matchAll(/^import\s+'([^']+)'(?:\s+(?:as\s+([A-Za-z_]\w*)|show\s+([^;]+)|deferred\s+as\s+[A-Za-z_]\w*))?[^;]*;/gm)) {
    const uri = m[1];
    if (/deferred\s+as/.test(m[0])) continue;
    const target = resolveImport(file, uri);
    if (target === null) continue;
    const targetSource = sourceOf(target);
    if (targetSource === null) continue;
    importsChecked += 1;
    if (usageMayBeImplicit(targetSource)) {
      lanesSkipped += 1;
      continue;
    }
    if (m[2]) continue; // alias: الاستعمال يظهر بالاسم المستعار، وتحقّقه يعني محاكاة المحلّل
    const shown = m[3] ? new Set(m[3].split(',').map((s) => s.trim()).filter(Boolean)) : null;
    const symbols = declaredSymbols(targetSource);
    if (shown) {
      for (const s of [...shown]) if (!symbols.has(s)) symbols.add(s);
    }
    if (symbols.size === 0) continue;
    const body = source.replace(m[0], '');
    const used = [...symbols].some((name) => new RegExp(`\\b${name}\\b`).test(body));
    if (!used) {
      const line = source.slice(0, m.index).split('\n').length;
      findings.push({ file: relative(ROOT, file), line, uri, symbols: [...symbols].slice(0, 4) });
    }
  }
}

if (findings.length > 0) {
  for (const f of findings) {
    const detail = `الهدف يعرّف: ${f.symbols.join(', ')}`;
    console.log(`::error file=${f.file},line=${f.line}::استيراد ميت: '${f.uri}' — ${detail}`);
  }
  console.log(`\n${findings.length} استيراد ميت — المحلّل سيسقط بـunused_import.`);
  process.exit(1);
}

console.log(
  `Dart imports: ${importsChecked} استيراداً فُحص، ${lanesSkipped} تُخطّي (استعمال قد يكون ضمنياً عبر extension/getter) — 0 ميت.`,
);
