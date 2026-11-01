#!/usr/bin/env python3
"""Generate a compact surface-form -> pronunciation table from UniDic lex.csv.

Usage:
    python3 tools/gen-unidic-data.py lex.csv > src/contents/ui/lib/UniDicData.js

UniDic's CSV columns used here are:
  0 surface, 3 token cost, 12 orthographic form, 13 surface pronunciation.
"""

import csv
import json
import re
import sys

KANJI = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff々〆]")
JAPANESE_WORD = re.compile(r"[\u3040-\u309f\u30a0-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff々〆ー]+")
MAX_COST = 7000


def hiragana(text):
    return "".join(
        chr(ord(char) - 0x60) if 0x30A1 <= ord(char) <= 0x30F6 else char
        for char in text
    )


words = {}
with open(sys.argv[1], encoding="utf-8", newline="") as source:
    for row in csv.reader(source):
        if len(row) < 14:
            continue
        surface, cost, orth, pronunciation = row[0], row[3], row[12], row[13]
        if surface != orth or not pronunciation:
            continue
        if not KANJI.search(surface) or not JAPANESE_WORD.fullmatch(surface):
            continue
        try:
            score = int(cost)
        except ValueError:
            continue
        if score > MAX_COST:
            continue
        reading = hiragana(pronunciation)
        current = words.get(surface)
        if current is None or score < current[0]:
            words[surface] = (score, reading)

data = {word: reading for word, (_, reading) in sorted(words.items())}
print(".pragma library")
print("// Generated from UniDic 2.1.2; see THIRD_PARTY_LICENSES.md.")
print("var WORDS = " + json.dumps(data, ensure_ascii=False, separators=(",", ":")))
print("// Entries: " + str(len(data)))
