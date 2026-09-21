#!/usr/bin/env node
// Tests for the lyric romanization libraries in src/contents/ui/lib.
//
// They are QML JS resources, so the .pragma/.import directives are stripped and
// the dependencies injected by hand; everything below that is plain JS.
//
//   node tools/test-romanization.mjs

import fs from "fs"
import vm from "vm"

const LIB = "src/contents/ui/lib"

function load(name, deps = {}) {
    const source = fs.readFileSync(`${LIB}/${name}`, "utf8")
        .split("\n")
        .map(line => (/^\s*\.(pragma|import)\b/.test(line) ? "" : line))
        .join("\n")
    const context = vm.createContext({...deps, console})
    vm.runInContext(source, context, {filename: name})
    return context
}

const Hangul = load("Hangul.js")
const Kana = load("Kana.js")
const Data = load("PinyinData.js")
const Pinyin = load("Pinyin.js", {Data})
const Romanize = load("Romanize.js", {Hangul, Kana, Pinyin})

const CASES = [
    // Korean: syllable liaison and the consonant assimilations that make the
    // difference between a transcription and a spelling-out.
    [Hangul, "안녕하세요", "annyeonghaseyo"],
    [Hangul, "감사합니다", "gamsahamnida"],
    [Hangul, "좋아해", "joahae"],
    [Hangul, "독립문", "dongnimmun"],
    [Hangul, "신라", "silla"],
    [Hangul, "설날", "seollal"],
    [Hangul, "종로", "jongno"],
    [Hangul, "백마", "baengma"],
    [Hangul, "학년", "hangnyeon"],
    [Hangul, "밥물", "bammul"],
    [Hangul, "왕십리", "wangsimni"],
    [Hangul, "놓고", "noko"],
    [Hangul, "많이", "mani"],
    [Hangul, "앉아", "anja"],
    [Hangul, "같이", "gachi"],
    [Hangul, "굳이", "guji"],
    [Hangul, "없다", "eopda"],
    [Hangul, "여덟", "yeodeol"],
    [Hangul, "읽어", "ilgeo"],
    [Hangul, "사랑해", "saranghae"],
    [Hangul, "벚꽃", "beotkkot"],
    [Hangul, "Hello 사랑", "Hello sarang"],

    // Japanese: gemination, the moraic ん, long marks, particles, and kanji
    // left in place with a space so they do not run into the romaji.
    [Kana, "こんにちは", "konnichiha"],
    [Kana, "きって", "kitte"],
    [Kana, "まっちゃ", "matcha"],
    [Kana, "しんや", "shin'ya"],
    [Kana, "しんぶん", "shinbun"],
    [Kana, "きゃく", "kyaku"],
    [Kana, "しゃしん", "shashin"],
    [Kana, "じょうず", "jouzu"],
    [Kana, "つき", "tsuki"],
    [Kana, "ラーメン", "rāmen"],
    [Kana, "コーヒー", "kōhī"],
    [Kana, "ファイト", "faito"],
    [Kana, "ジェット", "jetto"],
    [Kana, "ヲタク", "otaku"],
    [Kana, "君の名は", "君 no 名 wa"],
    [Kana, "さよならを言えなくて", "sayonara o 言 enakute"],
    [Kana, "I LOVE ユー", "I LOVE yū"],

    // Chinese: polyphones resolved by the word list, everything else by the
    // per-character table.
    [Pinyin, "我们的爱情", "wǒ men de ài qíng"],
    [Pinyin, "长大", "zhǎng dà"],
    [Pinyin, "长发", "cháng fà"],
    [Pinyin, "不是", "bú shì"],
    [Pinyin, "一个", "yí gè"],
    [Pinyin, "音乐", "yīn yuè"],
    [Pinyin, "快乐", "kuài lè"],
    [Pinyin, "重要", "zhòng yào"],
    [Pinyin, "重新", "chóng xīn"],
    [Pinyin, "银行", "yín háng"],
    [Pinyin, "夜空中最亮的星", "yè kōng zhōng zuì liàng de xīng"],
    [Pinyin, "你好，世界！", "nǐ hǎo，shì jiè！"],
    [Pinyin, "Hello 世界", "Hello shì jiè"],
]

// The script is decided once per song: a Japanese line of pure kanji must not
// be mistaken for Chinese because the kana are on the next line.
const DETECTION = [
    [["♪", "좋아해", "Baby I love you"], "ko"],
    [["歌詞", "無理", "だから"], "ja"],
    [["我们", "爱情"], "zh"],
    [["Hello darkness"], ""],
]

let failures = 0

for (const [module, input, expected] of CASES) {
    const actual = module.romanize(input)
    if (actual !== expected) {
        failures += 1
        console.log(`FAIL  ${input}\n        got  ${actual}\n        want ${expected}`)
    }
}

for (const [lines, expected] of DETECTION) {
    const actual = Romanize.detect(lines)
    if (actual !== expected) {
        failures += 1
        console.log(`FAIL  detect(${JSON.stringify(lines)}): got "${actual}", want "${expected}"`)
    }
}

// Lines with nothing to transliterate come back empty so the view can skip them.
const skipped = Romanize.romanizeLines(["♪", "Baby I love you", "좋아해"])
if (skipped.lines[0] !== "" || skipped.lines[1] !== "" || skipped.lines[2] === "") {
    failures += 1
    console.log(`FAIL  untransliterable lines should come back empty: ${JSON.stringify(skipped.lines)}`)
}

const total = CASES.length + DETECTION.length + 1
console.log(failures ? `${failures} of ${total} failing` : `all ${total} passing`)
process.exit(failures ? 1 : 0)
