# -*- coding: utf-8 -*-
"""محطة م٧: الإصلاحات خ-١..خ-٧ — كل استبدال مؤكد العدّ"""
import re
p='family_os_app.html'
t=open(p,encoding='utf-8').read()
R=0
def rep(old,new,n=1):
    global t,R
    c=t.count(old)
    assert c==n, f'count {c}!={n}: {old[:60]!r}'
    t=t.replace(old,new)
    R+=1

# ═══ خ-١: أزرار المدة في CHD-020 حية
seg_start=t.find("'CHD-020':{"); seg_end=t.find("'CHD-021':{")
seg=t[seg_start:seg_end]
# الحالة
rep("athkar: { done: 3, total: 10, session:'المساء' },",
    "athkar: { done: 3, total: 10, session:'المساء' },\n  timeReqMins: 30,")
# الأزرار الثلاثة داخل CHD-020
old15=seg[seg.find('<button',seg.find('١٥ دقيقة')-200):seg.find('</button>',seg.find('١٥ دقيقة'))+9]
assert '١٥ دقيقة' in old15 and 'onclick' not in old15, old15[:80]
new_btns_pat=None
# نستبدل النمط العام: الثلاثة أزرار بلا onclick
for label,mins in [('١٥ دقيقة',15),('٣٠ دقيقة',30),('ساعة كاملة',60)]:
    i=t.find(label, seg_start, seg_end)
    j=t.rfind('<button', seg_start, i)
    k=t.find('</button>', i)+9
    btn=t[j:k]
    assert 'onclick' not in btn, btn[:80]
    m=re.match(r'<button([^>]*)>',btn)
    attrs=m.group(1)
    newbtn=('<button'+attrs+' onclick="S.timeReqMins='+str(mins)+';playSound(\'pop\');render()" '
            'style="${S.timeReqMins==='+str(mins)+'?\'border:2px solid var(--teal);font-weight:800\':\'\'}">'+label+'</button>')
    t=t[:j]+newbtn+t[k:]
    seg_end=t.find("'CHD-021':{")
    R+=1
# نص «طلبت 30 دقيقة» يقرأ الحالة
i=t.find('طلبت 30 دقيقة', seg_start)
if i>=0:
    t=t[:i]+'طلبت ${AR(S.timeReqMins)} دقيقة'+t[i+len('طلبت 30 دقيقة'):]
    R+=1

# ═══ خ-٢: زر النجدة CHD-005 حي
i=t.find('نجدة🚨')
if i<0: i=t.find('>نجدة')
j=t.rfind('<button',0,i)
k=t.find('</button>',i)+9
btn=t[j:k]
assert 'onclick' not in btn, btn[:100]
m=re.match(r'<button([^>]*)>',btn)
inner=btn[btn.find('>')+1:-9]
newbtn=('<button'+m.group(1)+' onclick="playSound(\'pop\');toast(\'🚨 استمر بالضغط… ٣ · ٢ · ١\');go(\'CHD-006\')">'+inner+'</button>')
t=t[:j]+newbtn+t[k:]
R+=1

# ═══ خ-٣: زر الإرسال ◀ في CHD-008 + 🎙/🔊 في CHD-009
s8=t.find("'CHD-008':{"); e8=t.find("'CHD-009':{")
i=t.find('>◀</button>', s8, e8)
j=t.rfind('<button', s8, i)
btn=t[j:i+11]
assert 'onclick' not in btn
m=re.match(r'<button([^>]*)>',btn)
t=t[:j]+'<button'+m.group(1)+' onclick="playSound(\'pop\');toast(\'📨 وصلت رسالتك لأبيك — سيرد عليك بسرعة 🤍\')">◀</button>'+t[i+11:]
R+=1
s9=t.find("'CHD-009':{"); e9=t.find("'CHD-010':{")
for ic,msg in [('🎙','🔇 كتمت صوتك — اضغط مجددًا لإعادته'),('🔊','🔊 مكبر الصوت يعمل')]:
    i=t.find('>'+ic+'</button>', s9, e9)
    if i<0: continue
    j=t.rfind('<button', s9, i)
    btn=t[j:i+len('>'+ic+'</button>')]
    if 'onclick' in btn: continue
    m=re.match(r'<button([^>]*)>',btn)
    t=t[:j]+'<button'+m.group(1)+" onclick=\"playSound('pop');toast('"+msg+"')\">"+ic+'</button>'+t[i+len('>'+ic+'</button>'):]
    e9=t.find("'CHD-010':{")
    R+=1

# ═══ خ-٤+خ-٥: الرقم القياسي وخزانة الشارات في CHD-019
anchor='🔥 ٥ أيام التزام'
i=t.find(anchor)
if i<0:
    anchor2=t.find('أيام التزام')
    i=anchor2
# نضيف بعد بطاقة الرصيد مباشرة: نجد نهاية السطر «٧ شارات»
i=t.find('٧ شارات')
assert i>=0
k=t.find('</div>',i)+6
card="""
  <div class="card"><h3>🏆 نافس نفسك — لا أحد غيرك</h3>
   <div class="row"><span>🔥</span><div class="tx"><b>رقمك القياسي: ${AR(9)} أيام التزام متتالية</b><span>أنت الآن على ${AR(S.streak.days)} — باقي ${AR(9-S.streak.days)} أيام وتكسر رقمك! 💪</span></div></div>
   <p class="sml" style="margin-top:4px">منافستك الوحيدة هي أرقامك السابقة — وهذا سر الأبطال 🤍</p></div>
  <div class="card"><h3>🏅 خزانة شاراتي</h3>
   <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:6px">
    <span class="tag g">⭐ أول ورد ✓</span><span class="tag g">📿 أسبوع أذكار ✓</span><span class="tag g">🎯 ٥ جلسات تركيز ✓</span>
    <span class="tag" style="background:var(--border)">🌙 شهر التزام</span><span class="tag" style="background:var(--border)">👑 بطل العائلة</span></div>
   <p class="sml" style="margin-top:6px">٧ شارات محققة — والقادمة أجمل 🚀</p></div>"""
t=t[:k]+card+t[k:]
R+=1

# ═══ خ-٦: CHD-035 → زر بدء جلسة تركيز
s35=t.find("'CHD-035':{"); e35=t.find("'CHD-036':{")
i=t.find('🧠 أصوات طبيعية ثابتة', s35, e35)
j=t.rfind('<div class="banner', s35, i)
btn='<button class="btn teal" style="padding:12px;margin-bottom:10px" onclick="playSound(\'pop\');go(\'CHD-018\')">ابدأ جلسة تركيز الآن 🎯 — والصوت معك</button>\n  '
t=t[:j]+btn+t[j:]
R+=1

# ═══ خ-٧: مرح المكالمة في شاشة مكالمة الأب FAT-023
old23='صوت وفيديو عبر LiveKit — بيانات وصفية فقط، لا تسجيل · 🔔 مكالمات الاطمئنان ترنّ عند الابن حتى لو كان جهازه صامتًا'
assert t.count(old23)==1
new23=old23+"""</p>
  <div class="card" style="margin-top:12px"><h3>🎮 العبا معًا أثناء المكالمة</h3>
   <div class="row"><span>🎨</span><div class="tx"><b>لوحة رسم مشتركة</b><span>ترسمان معًا في اللحظة نفسها — تقريب المسافات</span></div><button class="btn sec" style="width:auto;padding:8px 12px;margin:0;font-size:11.5px" onclick="toast('🎨 فُتحت اللوحة المشتركة — خالد يرى خطوطك لحظيًا')">افتح</button></div>
   <div class="row"><span>❌⭕</span><div class="tx"><b>إكس-أو سريعة</b><span>جولة خفيفة وأنتما تتكلمان</span></div><button class="btn sec" style="width:auto;padding:8px 12px;margin:0;font-size:11.5px" onclick="toast('❌⭕ بدأت الجولة — دور خالد أولًا 😄')">العب</button></div>
  </div><p style="display:none">"""
t=t.replace(old23,new23,1)
R+=1

open(p,'w',encoding='utf-8').write(t)
print(f'OK — {R} تعديلات حُفظت')
