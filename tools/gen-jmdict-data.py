#!/usr/bin/env python3
"""Generate the compact Japanese word-reading table used by the widget.

Usage:
    python3 tools/gen-jmdict-data.py /path/to/JMdict_e > src/contents/ui/lib/JMDictData.js

The source file is the uncompressed JMdict XML distributed by EDRDG. Only
Japanese headword -> kana reading pairs are retained; meanings and metadata
never enter the widget package.
"""

import json
import re
import sys
import xml.etree.ElementTree as ET

KANJI = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff々〆]")
KATAKANA = re.compile(r"[\u30a1-\u30f6]")
JAPANESE_WORD = re.compile(r"[\u3040-\u309f\u30a0-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff々〆ー]+")


def hiragana(text):
    return "".join(
        chr(ord(char) - 0x60) if KATAKANA.fullmatch(char) else char
        for char in text
    )


def priority(tags):
    """Return a lower-is-better score for JMdict's frequency markers."""
    best = 1000
    for tag in tags:
        if tag in {"news1", "ichi1", "spec1", "gai1"}:
            best = min(best, 0)
        elif tag in {"news2", "ichi2", "gai2"}:
            best = min(best, 1)
        elif tag.startswith("nf") and tag[2:].isdigit():
            best = min(best, 10 + int(tag[2:]))
    return best


def generate(path):
    words = {}
    for _, entry in ET.iterparse(path, events=("end",)):
        if entry.tag != "entry":
            continue

        readings = []
        for element in entry.findall("r_ele"):
            reading = element.findtext("reb")
            if reading is None:
                continue
            readings.append({
                "text": hiragana(reading),
                "restrictions": {node.text for node in element.findall("re_restr")},
                "score": priority([node.text for node in element.findall("re_pri")]),
            })

        for element in entry.findall("k_ele"):
            word = element.findtext("keb")
            if not word or not KANJI.search(word) or len(word) < 2 or not JAPANESE_WORD.fullmatch(word):
                continue
            # A phrase such as 君の名 is not useful as one replacement: the
            # kana connector の would disappear into the reading and the
            # particle rules could no longer see the individual words.
            if len(KANJI.findall(word)) > 1 and re.search(r"[\u3040-\u30ff]", word):
                continue
            word_score = priority([node.text for node in element.findall("ke_pri")])
            candidates = [
                reading for reading in readings
                if not reading["restrictions"] or word in reading["restrictions"]
            ]
            if not candidates:
                continue
            if word_score == 1000 and all(reading["score"] == 1000 for reading in candidates):
                continue
            candidate = min(candidates, key=lambda item: (min(word_score, item["score"]), item["score"]))
            score = min(word_score, candidate["score"])
            current = words.get(word)
            if current is None or score < current[0]:
                words[word] = (score, candidate["text"])

        entry.clear()

    return {word: reading for word, (_, reading) in sorted(words.items())}


if len(sys.argv) != 2:
    raise SystemExit("usage: gen-jmdict-data.py JMdict_e")

data = generate(sys.argv[1])
print(".pragma library")
print("// Generated from JMdict_e; see THIRD_PARTY_LICENSES.md.")
print("var WORDS = " + json.dumps(data, ensure_ascii=False, separators=(",", ":")))
print("// Entries: " + str(len(data)))
