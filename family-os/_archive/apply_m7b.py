# -*- coding: utf-8 -*-
"""م٧ — نسخة مكيفة على البنية الفعلية (أزرار المدة قالب map)"""
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

# ═══ الحالة
rep("athkar: { done: 3, total: 10, session:'المساء' },",
    "athkar: { done: 3, total: 10, session:'المساء' },\n  timeReqMins: 30,")

# ═══ خ-١: قالب أزرار المدة — حي بالحالة
rep("${['١٥ دقيقة','٣٠ دقيقة','ساعة كاملة'].map((x,i)=>`<button class=\"btn ${i==1?'teal':'sec'}\" style=\"margin:0;padding:10px;font-size:12px\">${x}</button>`)",
    "${[['١٥ دقيقة',15],['٣٠ دقيقة',30],['ساعة كاملة',60]].map(([x,v])=>`<button class=\"btn ${S.timeReqMins===v?'teal':'sec'}\" style=\"margin:0;padding:10px;font-size:12px${S.timeReqMins===v?';font-weight:800':''}\" onclick=\"S.timeReqMins=${v};playSound('pop');render()\">${x}</button>`)")

# نص الطلب يقرأ الحالة
i=t.find('طلبت 30 دقيقة')
if i>=0:
    t=t[:i]+'طلبت ${AR(S.timeReqMins)} دقيقة'+t[i+len('طلبت 30 دقيقة'):]; R+=1

# ═══ خ-٢: زر النجدة CHD-005
i=t.find('نجدة🚨')
if i<0:
    i=t.find('نجدة')
    # داخل CHD-005
    s5=t.find("'CHD-005':{"); e5=t.find("'CHD-006':{")
    i=t.find('نجدة', s5, e5)
j=t.rfind('<button',0,i)
k=t.find('</button>',i)+9
btn=t[j:k]
assert 'onclick' not in btn, 'زر النجدة فيه onclick أصلا: '+btn[:90]
m=re.match(r'<button([^>]*)>',btn)
inner=btn[btn.find('>')+1:-9]
t=t[:j]+'<button'+m.group(1)+' onclick="playSound(\'pop\');toast(\'🚨 استمر بالضغط… ٣ · ٢ · ١ — انطلق البلاغ!\');go(\'CHD-006\')">'+inner+'</button>'+t[k:]
R+=1

# ═══ خ-٣: ◀ في CHD-008 + 🎙/🔊 في CHD-009
s8=t.find("'CHD-008':{"); e8=t.find("'CHD-009':{")
i=t.find('>◀</button>', s8, e8)
assert i>=0
j=t.rfind('<button', s8, i)
btn=t[j:i+11]
assert 'onclick' not in btn
m=re.match(r'<button([^>]*)>',btn)
t=t[:j]+'<button'+m.group(1)+' onclick="playSound(\'pop\');toast(\'📨 وصلت رسالتك لأبيك — سيرد عليك بسرعة 🤍\')">◀</button>'+t[i+11:]
R+=1
s9=t.find("'CHD-009':{"); e9=t.find("'CHD-010':{")
for ic,msg in [('🎙','🔇 كتمت صوتك مؤقتًا — اضغط مجددًا لإعادته'),('🔊','🔊 مكبر الصوت يعمل')]:
    i=t.find('>'+ic+'<', s9, e9)
    if i<0: continue
    j=t.rfind('<button', s9, i)
    if j<0: continue
    k=t.find('</button>', i)+9
    btn=t[j:k]
    if 'onclick' in btn: continue
    m=re.match(r'<button([^>]*)>',btn)
    inner=btn[btn.find('>')+1:-9]
    t=t[:j]+'<button'+m.group(1)+" onclick=\"playSound('pop');toast('"+msg+"')\">"+inner+'</button>'+t[k:]
    e9=t.find("'CHD-010':{")
    R+=1

# ═══ خ-٤+خ-٥: CHD-019 الرقم القياسي + خزانة الشارات
i=t.find('٧ شارات')
assert i>=0
k=t.find('</div>',i)+6
card="""
  <div class="card"><h3>🏆 نافس نفسك — لا أحد غيرك</h3>
   <div class="row"><span>🔥</span><div class="tx"><b>رقمك القياسي: ٩ أيام التزام متتالية</b><span>أنت الآن على ${AR(S.streak.days)} — اقترب موعد كسر رقمك! 💪</span></div></div>
   <p class="sml" style="margin-top:4px">منافستك الوحيدة هي أرقامك السابقة — وهذا سر الأبطال 🤍</p></div>
  <div class="card"><h3>🏅 خزانة شاراتي</h3>
   <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:6px">
    <span class="tag g">⭐ أول ورد ✓</span><span class="tag g">📿 أسبوع أذكار ✓</span><span class="tag g">🎯 ٥ جلسات تركيز ✓</span>
    <span class="tag" style="background:var(--border)">🌙 شهر التزام</span><span class="tag" style="background:var(--border)">👑 بطل العائلة</span></div>
   <p class="sml" style="margin-top:6px">٧ شارات محققة — والقادمة أجمل 🚀</p></div>"""
t=t[:k]+card+t[k:]
R+=1

# ═══ خ-٦: CHD-035 زر بدء التركيز
s35=t.find("'CHD-035':{"); e35=t.find("'CHD-036':{")
i=t.find('🧠 أصوات طبيعية ثابتة', s35, e35)
assert i>=0
j=t.rfind('<div class="banner', s35, i)
assert j>=0
btn='<button class="btn teal" style="padding:12px;margin-bottom:10px" onclick="playSound(\'pop\');go(\'CHD-018\')">ابدأ جلسة تركيز الآن 🎯 — والصوت معك</button>\n  '
t=t[:j]+btn+t[j:]
R+=1

# ═══ خ-٧: مرح المكالمة في FAT-023
old23='صوت وفيديو عبر LiveKit — بيانات وصفية فقط، لا تسجيل · 🔔 مكالمات الاطمئنان ترنّ عند الابن حتى لو كان جهازه صامتًا'
assert t.count(old23)==1
# المرساة داخل <p>؟ نعاين إغلاقها
i=t.find(old23)
close=t.find('</p>',i)
if close<0 or close-i>len(old23)+50:
    # قد تكون داخل عنصر آخر — نغلق البطاقة بعده مباشرة دون كسر
    insert=i+len(old23)
    add="""</p><div class="card" style="margin-top:12px;text-align:right"><h3>🎮 العبا معًا أثناء المكالمة</h3><div class="row"><span>🎨</span><div class="tx"><b>لوحة رسم مشتركة</b><span>ترسمان معًا في اللحظة نفسها — تقريب المسافات</span></div><button class="btn sec" style="width:auto;padding:8px 12px;margin:0;font-size:11.5px" onclick="toast('🎨 فُتحت اللوحة المشتركة — خالد يرى خطوطك لحظيًا')">افتح</button></div><div class="row"><span>❌⭕</span><div class="tx"><b>إكس-أو سريعة</b><span>جولة خفيفة وأنتما تتكلمان</span></div><button class="btn sec" style="width:auto;padding:8px 12px;margin:0;font-size:11.5px" onclick="toast('❌⭕ بدأت الجولة — دور خالد أولًا 😄')">العب</button></div></div><p style="display:none">"""
    t=t[:insert]+add+t[insert:]
else:
    insert=close+4
    add="""<div class="card" style="margin-top:12px;text-align:right"><h3>🎮 العبا معًا أثناء المكالمة</h3><div class="row"><span>🎨</span><div class="tx"><b>لوحة رسم مشتركة</b><span>ترسمان معًا في اللحظة نفسها</span></div><button class="btn sec" style="width:auto;padding:8px 12px;margin:0;font-size:11.5px" onclick="toast('🎨 فُتحت اللوحة المشتركة — خالد يرى خطوطك لحظيًا')">افتح</button></div><div class="row"><span>❌⭕</span><div class="tx"><b>إكس-أو سريعة</b><span>جولة وأنتما تتكلمان</span></div><button class="btn sec" style="width:auto;padding:8px 12px;margin:0;font-size:11.5px" onclick="toast('❌⭕ بدأت الجولة — دور خالد أولًا 😄')">العب</button></div></div>"""
    t=t[:insert]+add+t[insert:]
R+=1

open(p,'w',encoding='utf-8').write(t)
print(f'OK — {R} تعديلات حُفظت')
