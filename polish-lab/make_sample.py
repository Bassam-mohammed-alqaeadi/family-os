#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مولّد عينات الصقل — ينسخ شاشات محطة واحدة فقط من النموذج الرئيسي إلى ملف عينة معزول.
الاستخدام: python3 make_sample.py <اسم_الملف.html> <شاشة_البداية> <قائمة معرفات مفصولة بفواصل> "<عنوان المحطة>"
بعد اكتمال الصقل في العينة تُطبَّق نفس التعديلات على family_os_app.html (النموذج الأصلي هو المرجع)."""
import sys, re

MASTER='/home/user/familyArena/family-os/family_os_app.html'

def build(out, start, ids, title):
    t=open(MASTER,encoding='utf-8').read()
    # العنوان والراية
    t=re.sub(r'<title>.*?</title>', f'<title>🔬 مختبر الصقل — {title}</title>', t, count=1)
    t=re.sub(r'(نموذج تفاعلي حيّ|النموذج البصري الكامل)[^<]*<b[^>]*>[^<]*</b>[^<]*<b[^>]*>[^<]*</b>[^·]*·[^·]*·[^<]*',
             f'🔬 عينة صقل معزولة — {title} · {len(ids)} شاشة · تُطبَّق التعديلات على النموذج الأصلي بعد اعتمادك ', t, count=1)
    # حقن وضع العينة قبل الإقلاع
    inject = f"""
/* ═══════ وضع عينة الصقل (مولَّد آليًا — لا يُحرَّر يدويًا) ═══════ */
const SAMPLE_IDS={ids!r};
Object.keys(SCREENS).forEach(k=>{{ if(!SAMPLE_IDS.includes(k)) delete SCREENS[k]; }});
S.screen='{start}'; S.hist=[]; S.role='parent';
const _goOrig=go;
go=function(id,push=true){{
  if(!SCREENS[id]){{ if(S.role!=='parent'){{S.role='parent';}}
    toast('🔬 هذه الوجهة خارج عينة المحطة — موجودة في النموذج الكامل'); render(); return; }}
  _goOrig(id,push); }};
render();
"""
    t=t.replace('render(); tickClock();', inject+'tickClock();',1)
    open(out,'w',encoding='utf-8').write(t)
    print(f"✓ {out}: {len(ids)} شاشة · تبدأ من {start}")

if __name__=='__main__':
    out,start,ids,title=sys.argv[1],sys.argv[2],sys.argv[3].split(','),sys.argv[4]
    build(out,start,ids,title)
