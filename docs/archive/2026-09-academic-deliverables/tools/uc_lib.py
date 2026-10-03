# -*- coding: utf-8 -*-
"""مكتبة رسم مخططات حالات الاستخدام — النمط المعتمد من المالك (v2)"""

DEFS = '''<defs>
<marker id="tri" markerWidth="16" markerHeight="14" refX="15" refY="7" orient="auto"><path d="M1,1 L15,7 L1,13 Z" fill="white" stroke="#1A1D2E" stroke-width="1.3"/></marker>
<marker id="arr" markerWidth="12" markerHeight="10" refX="11" refY="5" orient="auto"><path d="M1,1 L11,5 L1,9" fill="none" stroke="#1A1D2E" stroke-width="1.3"/></marker>
</defs>'''

def head(w,h,title,sub):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" font-family="Segoe UI, Tahoma" direction="rtl">',
            DEFS, f'<rect width="{w}" height="{h}" fill="#FAFAFC"/>',
            f'<rect x="330" y="40" width="{w-510}" height="{h-90}" fill="white" stroke="#1A1D2E" stroke-width="1.6" rx="4"/>',
            f'<text x="{330+(w-510)//2}" y="72" text-anchor="middle" font-size="18" font-weight="bold" fill="#7C5CE6">{title}</text>',
            f'<text x="{330+(w-510)//2}" y="92" text-anchor="middle" font-size="12" fill="#666">{sub}</text>']

def actor(x,y,label,sub=""):
    s=f'''<g stroke="#1A1D2E" stroke-width="1.6" fill="none">
<circle cx="{x}" cy="{y}" r="13"/><line x1="{x}" y1="{y+13}" x2="{x}" y2="{y+48}"/>
<line x1="{x-20}" y1="{y+25}" x2="{x+20}" y2="{y+25}"/>
<line x1="{x}" y1="{y+48}" x2="{x-16}" y2="{y+75}"/><line x1="{x}" y1="{y+48}" x2="{x+16}" y2="{y+75}"/></g>
<text x="{x}" y="{y+94}" text-anchor="middle" font-size="13.5" font-weight="bold">{label}</text>'''
    if sub: s+=f'<text x="{x}" y="{y+110}" text-anchor="middle" font-size="11" fill="#555">{sub}</text>'
    return s

def uc(x,y,rx,ry,l1,fill="#E7F7EE",l2="",star=False,bell=False):
    pre=("⭐ " if star else "")+("🔔 " if bell else "")
    s=f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="#1A1D2E" stroke-width="1.3"/>'
    if l2:
        s+=f'<text x="{x}" y="{y-3}" text-anchor="middle" font-size="11.5" font-weight="bold">{pre}{l1}</text>'
        s+=f'<text x="{x}" y="{y+12}" text-anchor="middle" font-size="10">{l2}</text>'
    else:
        s+=f'<text x="{x}" y="{y+4}" text-anchor="middle" font-size="11.5" font-weight="bold">{pre}{l1}</text>'
    return s

def rel(x1,y1,x2,y2,kind,tx,ty):
    color = "#0E8F6E" if kind=="include" else "#C0392B"
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#1A1D2E" stroke-width="1.15" stroke-dasharray="6,4" marker-end="url(#arr)"/>'
            f'<text x="{tx}" y="{ty}" text-anchor="middle" font-size="11" font-style="italic" fill="{color}" font-weight="bold">&#171;{kind}&#187;</text>')

def gen(x1,y1,x2,y2):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#1A1D2E" stroke-width="1.3" marker-end="url(#tri)"/>'

def assoc(x1,y1,x2,y2,op=1.0,dash=""):
    d=f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#1A1D2E" stroke-width="1.15" stroke-opacity="{op}"{d}/>'

def legend(x,y):
    return f'''<g font-size="12"><rect x="{x}" y="{y}" width="270" height="150" rx="8" fill="white" stroke="#D0D3E0"/>
<text x="{x+135}" y="{y+22}" text-anchor="middle" font-weight="bold" fill="#7C5CE6">مفتاح القراءة</text>
<line x1="{x+15}" y1="{y+42}" x2="{x+60}" y2="{y+42}" stroke="#1A1D2E" stroke-dasharray="6,4" marker-end="url(#arr)"/><text x="{x+70}" y="{y+46}">&#171;include&#187; إلزامي دائمًا</text>
<line x1="{x+15}" y1="{y+67}" x2="{x+60}" y2="{y+67}" stroke="#1A1D2E" stroke-dasharray="6,4" marker-end="url(#arr)"/><text x="{x+70}" y="{y+71}">&#171;extend&#187; شرطي أحيانًا</text>
<line x1="{x+15}" y1="{y+92}" x2="{x+60}" y2="{y+92}" stroke="#1A1D2E" marker-end="url(#tri)"/><text x="{x+70}" y="{y+96}">generalization وراثة</text>
<text x="{x+15}" y="{y+121}">⭐ عمود فقري · 🔔 حدثية (G-6) · برتقالي = مشترَكة</text>
<text x="{x+15}" y="{y+140}" fill="#888">منقّط باهت = مشاهدة (observer)</text></g>'''
