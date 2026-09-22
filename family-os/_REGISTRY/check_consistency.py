#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
مدقّق التناقضات — يمنع عودة أي قرار ملغى إلى الوثائق.
الاستخدام:  python3 _REGISTRY/check_consistency.py
يعمل من أي مجلد. يخرج بـ exit 1 عند وجود تناقض حاجز.
"""
import io, os, glob, re, sys, csv

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (نمط ممنوع, سبب, ملفات مستثناة)
BANNED = [
    (r'اختيار الدور',            'شاشة «اختيار الدور» ملغاة بـADR-018',
     ['20_MOTHER_PERMISSIONS.md', '02_DECISION_LOG.md']),
    (r'SCR-SHR-004',             'المعرّف محذوف بـADR-018',
     ['20_MOTHER_PERMISSIONS.md', '02_DECISION_LOG.md']),
    (r'تطبيقان منفصلان|تطبيقين منفصلين', 'نموذج التطبيقين ملغى بـADR-017',
     ['19_DUAL_MODE.md', '18_PLATFORM_GATES.md', '02_DECISION_LOG.md']),
    (r'#059669|هدوء المستشفى',   'نظام التصميم v1 ملغى بـADR-013',
     ['02_DECISION_LOG.md']),
    (r'٢٣٧ خدمة|237 خدمة',       'العدد الصحيح ٢٤٠ خدمة',
     ['02_DECISION_LOG.md', 'README.md']),
    (r'١٣٨ خدمة',                'العدد الصحيح ١٧٦ خدمة P0',
     ['02_DECISION_LOG.md']),
]

# الملفات التي يجب أن تحمل رأس الحالة
NEED_BANNER = [f for f in glob.glob(os.path.join(ROOT, '*.md'))
               if not os.path.basename(f).startswith(('README', '17_'))]


def main():
    errors, warns = [], []

    # ١) الأنماط الممنوعة
    for path in sorted(glob.glob(os.path.join(ROOT, '*.md')) +
                       glob.glob(os.path.join(ROOT, '*.html'))):
        name = os.path.basename(path)
        text = io.open(path, encoding='utf-8').read()
        for pat, why, skip in BANNED:
            if name in skip:
                continue
            for m in re.finditer(pat, text):
                line = text[:m.start()].count('\n') + 1
                errors.append(f'{name}:{line} — «{m.group()}» — {why}')

    # ٢) رأس الحالة
    for path in NEED_BANNER:
        name = os.path.basename(path)
        if '🧭 حالة هذا الملف' not in io.open(path, encoding='utf-8').read():
            warns.append(f'{name} — ينقصه رأس الحالة')

    # ٣) تطابق الأرقام مع السجل
    sp = os.path.join(ROOT, '_REGISTRY', 'services.csv')
    scp = os.path.join(ROOT, '_REGISTRY', 'screens.csv')
    nsvc = len(list(csv.reader(io.open(sp, encoding='utf-8')))) - 1
    nscr = len(list(csv.reader(io.open(scp, encoding='utf-8')))) - 1

    ar = str.maketrans('0123456789', '٠١٢٣٤٥٦٧٨٩')
    svc_ar, scr_ar = str(nsvc).translate(ar), str(nscr).translate(ar)

    rd = io.open(os.path.join(ROOT, 'README.md'), encoding='utf-8').read()
    if svc_ar not in rd:
        warns.append(f'README.md — لا يذكر العدد الحالي للخدمات ({svc_ar})')
    if scr_ar not in rd:
        warns.append(f'README.md — لا يذكر العدد الحالي للشاشات ({scr_ar})')

    # ===== التقرير =====
    print('=' * 58)
    print('  🔍 مدقّق التناقضات — Family OS')
    print('=' * 58)
    print(f'  السجل: {nsvc} خدمة · {nscr} شاشة\n')

    if errors:
        print(f'  ❌ تناقضات حاجزة ({len(errors)}):')
        for e in errors:
            print(f'     • {e}')
        print()
    if warns:
        print(f'  ⚠️  ملاحظات ({len(warns)}):')
        for w in warns:
            print(f'     • {w}')
        print()
    if not errors and not warns:
        print('  ✅ لا تناقضات — التوثيق متسق تمامًا.')
    elif not errors:
        print('  ✅ لا تناقضات حاجزة.')

    print('=' * 58)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
