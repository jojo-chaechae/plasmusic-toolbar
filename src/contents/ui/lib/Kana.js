.pragma library

// Hepburn romanization of Japanese kana.
//
// Kana is a syllabary, so this is a table walk plus three context rules:
// sokuon (っ doubles the next consonant), the moraic ん (which needs an
// apostrophe before a vowel so that しんや reads "shin'ya" and not "shinya"),
// and the katakana長音 ー (which lengthens the preceding vowel to a macron).
//
// Kanji are left untouched: mapping them to readings needs a morphological
// dictionary, which is deliberately out of scope here.

var HIRAGANA_START = 0x3041
var HIRAGANA_END = 0x3096
var KATAKANA_START = 0x30A1
var KATAKANA_END = 0x30F6
var KATAKANA_OFFSET = 0x60
var SOKUON = "っ"
var LONG_MARK = "ー"

var BASE = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "ゐ": "i", "ゑ": "e", "を": "o", "ん": "n", "ゔ": "vu",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
    "ゃ": "ya", "ゅ": "yu", "ょ": "yo", "ゎ": "wa", "ゕ": "ka", "ゖ": "ke"
}

// Palatalized morae: き + ゃ is "kya", but し + ゃ is "sha", not "shya".
var YOUON_IRREGULAR = {"shi": "sh", "chi": "ch", "ji": "j"}
var SMALL_Y = {"ゃ": "a", "ゅ": "u", "ょ": "o"}
// Foreign sounds written as a full kana plus a small vowel: ファ, ティ, ウォ…
var SMALL_VOWEL = {"ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o"}
var FOREIGN_STEMS = {
    "ふ": "f", "ゔ": "v", "う": "w", "て": "t", "で": "d", "と": "t", "ど": "d",
    "し": "sh", "じ": "j", "ち": "ch", "つ": "ts", "く": "k", "ぐ": "g"
}
var MACRONS = {"a": "ā", "i": "ī", "u": "ū", "e": "ē", "o": "ō"}
var VOWELS = "aiueo"

function _toHiragana(char) {
    var code = char.charCodeAt(0)
    if (code >= KATAKANA_START && code <= KATAKANA_END) {
        return String.fromCharCode(code - KATAKANA_OFFSET)
    }
    return char
}

function isKana(char) {
    var code = char.charCodeAt(0)
    return (code >= HIRAGANA_START && code <= HIRAGANA_END)
        || (code >= KATAKANA_START && code <= KATAKANA_END)
        || char === LONG_MARK
}

function hasKana(text) {
    for (var i = 0; i < text.length; ++i) {
        if (isKana(text.charAt(i))) return true
    }
    return false
}

// Reads one mora starting at `index`, returning its romaji and how many
// characters it consumed.
function _mora(chars, index) {
    var char = _toHiragana(chars[index])
    var next = index + 1 < chars.length ? _toHiragana(chars[index + 1]) : ""
    var base = BASE[char]
    if (base === undefined) return null

    if (SMALL_Y[next] !== undefined) {
        var irregular = YOUON_IRREGULAR[base]
        if (irregular !== undefined) {
            // sha/shu/sho, cha/chu/cho, ja/ju/jo.
            return {text: irregular + SMALL_Y[next], length: 2}
        }
        if (base.length === 2 && base.charAt(1) === "i") {
            return {text: base.charAt(0) + "y" + SMALL_Y[next], length: 2}
        }
    }
    if (SMALL_VOWEL[next] !== undefined && FOREIGN_STEMS[char] !== undefined) {
        return {text: FOREIGN_STEMS[char] + SMALL_VOWEL[next], length: 2}
    }
    return {text: base, length: 1}
}

// Romanizes one uninterrupted run of kana. Gemination and the moraic ん look at
// their neighbours, and a kanji in between hides what that neighbour sounds
// like, so runs are converted independently of each other.
function _romanizeRun(run) {
    // A lone は or へ between other words is the particle, read "wa" and "e".
    if (run === "は") return "wa"
    if (run === "へ") return "e"

    var chars = run.split("")
    var out = ""
    var pendingSokuon = false

    for (var i = 0; i < chars.length; ) {
        var char = chars[i]
        var hiragana = _toHiragana(char)

        if (hiragana === SOKUON) {
            pendingSokuon = true
            i += 1
            continue
        }
        if (char === LONG_MARK) {
            var last = out.charAt(out.length - 1)
            if (MACRONS[last] !== undefined) out = out.slice(0, -1) + MACRONS[last]
            else out += LONG_MARK
            i += 1
            continue
        }

        if (char === "を") {
            // Hiragana を only ever marks an object, so it stands apart from
            // its verb. Katakana ヲ is a stylistic spelling, not a particle.
            out += " o "
            i += 1
            continue
        }

        var mora = _mora(chars, i)
        if (mora === null) {
            out += char
            pendingSokuon = false
            i += 1
            continue
        }

        var romaji = mora.text
        if (hiragana === "ん") {
            // n before a vowel or y would read as a different mora entirely.
            var after = i + 1 < chars.length ? _mora(chars, i + 1) : null
            var following = after ? after.text.charAt(0) : ""
            if (following !== "" && (VOWELS.indexOf(following) !== -1 || following === "y")) {
                romaji = "n'"
            }
        }
        if (pendingSokuon) {
            // っち is "tchi" in Hepburn, everything else doubles its consonant.
            romaji = (romaji.indexOf("ch") === 0 ? "t" : romaji.charAt(0)) + romaji
            pendingSokuon = false
        }
        out += romaji
        i += mora.length
    }
    return out
}

function _isIdeograph(char) {
    var code = char.charCodeAt(0)
    return (code >= 0x3400 && code <= 0x9FFF) || (code >= 0xF900 && code <= 0xFAFF)
        || char === "々" || char === "〆"
}

// Romanizes kana anywhere in `text`, leaving every other character in place.
// Kanji stay as they are, so a space keeps them from running into the romaji
// beside them: 君の名は is "君 no 名 wa", not "君no名wa".
function romanize(text) {
    var segments = []
    for (var i = 0; i < text.length; ++i) {
        var char = text.charAt(i)
        var kana = isKana(char)
        var previous = segments.length ? segments[segments.length - 1] : null
        if (previous !== null && previous.kana === kana) previous.source += char
        else segments.push({kana: kana, source: char})
    }

    var out = ""
    for (var s = 0; s < segments.length; ++s) {
        var segment = segments[s]
        var rendered = segment.kana ? _romanizeRun(segment.source) : segment.source.split("・").join(" ")
        var neighbour = s > 0 ? segments[s - 1] : null
        if (neighbour !== null) {
            var boundary = segment.kana
                ? _isIdeograph(neighbour.source.charAt(neighbour.source.length - 1))
                : _isIdeograph(segment.source.charAt(0))
            if (boundary) out += " "
        }
        out += rendered
    }
    // Particles introduce spaces of their own; tidy up where they meet others.
    return out.replace(/ +/g, " ").replace(/^ | $/g, "")
}
