#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص اتساق التوثيق الأكاديمي ضد مصادر الحقيقة (قانون ٧ — وثيقة 44)"""
import re, csv, sys, glob, os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCHEMA = os.path.join(ROOT, 'family-os/_CONTRACTS/schema.sql')
REG = os.path.join(ROOT, 'family-os/_REGISTRY')
errors, checks = [], 0

schema = open(SCHEMA, encoding='utf-8').read()
tables = set(re.findall(r'CREATE TABLE (\w+)', schema))
screens = {r[0] for r in csv.reader(open(os.path.join(REG,'screens.csv'), encoding='utf-8-sig')) if r and r[0].startswith('SCR')}
services = {r[0] for r in csv.reader(open(os.path.join(REG,'services.csv'), encoding='utf-8-sig')) if r and r[0].startswith('S-')}

for ch in glob.glob(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'chapters/*.md')):
    txt = open(ch, encoding='utf-8').read()
    for scr in re.findall(r'SCR-(?:FAT|CHD|SHR)-\d{3}', txt):
        checks += 1
        if scr not in screens: errors.append(f"{os.path.basename(ch)}: شاشة غير موجودة في السجل: {scr}")
    for svc in re.findall(r'S-[A-Z]{3}-\d{3}', txt):
        checks += 1
        if svc not in services: errors.append(f"{os.path.basename(ch)}: خدمة غير موجودة: {svc}")
    for tbl in re.findall(r'جدول `(\w+)`', txt):
        checks += 1
        if tbl not in tables: errors.append(f"{os.path.basename(ch)}: جدول غير موجود في schema: {tbl}")

print(f"فحوصات: {checks} | أخطاء: {len(errors)}")
for e in errors: print("❌", e)
sys.exit(1 if errors else 0)
