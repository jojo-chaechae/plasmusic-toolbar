.pragma library

// Revised Romanization of Korean (국어의 로마자 표기법).
//
// Hangul syllables are composed arithmetically, so a syllable decomposes into
// its lead/vowel/tail jamo without any lookup table. The romanization itself is
// not that simple: a syllable's tail and the next syllable's lead assimilate,
// which is why 독립 is "dongnip" and not "doknip". Those junctions live in
// JUNCTIONS below; anything not listed there is just TAILS[tail] + LEADS[lead].

var SYLLABLE_START = 0xAC00
var SYLLABLE_END = 0xD7A3
var VOWEL_COUNT = 21
var TAIL_COUNT = 28

var LEADS = ["g", "kk", "n", "d", "tt", "r", "m", "b", "pp", "s", "ss", "",
             "j", "jj", "ch", "k", "t", "p", "h"]
var VOWELS = ["a", "ae", "ya", "yae", "eo", "e", "yeo", "ye", "o", "wa", "wae",
              "oe", "yo", "u", "wo", "we", "wi", "yu", "eu", "ui", "i"]
// Tails take their pronounced value: only seven sounds end a Korean syllable.
var TAILS = ["", "k", "k", "k", "n", "n", "n", "t", "l", "k", "m", "l", "l",
             "l", "p", "l", "m", "p", "p", "t", "t", "ng", "t", "t", "k", "t",
             "p", "t"]
// The same tails when a following ㅇ pulls them into the next syllable's onset:
// 좋아 is "joa" (the ㅎ drops), 국이 is "gugi" (the ㄱ voices to g).
var LIAISONS = ["", "g", "kk", "ks", "n", "nj", "n", "d", "r", "lg", "lm", "lb",
                "ls", "lt", "lp", "r", "m", "b", "bs", "s", "ss", "ng", "j",
                "ch", "k", "t", "p", ""]

var LEAD_G = 0, LEAD_N = 2, LEAD_D = 3, LEAD_R = 5, LEAD_M = 6, LEAD_S = 9
var LEAD_SILENT = 11, LEAD_J = 12, LEAD_H = 18
var TAIL_D = 7, TAIL_T = 25
var VOWEL_I = 20

var JUNCTIONS = {}

function _junction(tails, lead, value) {
    for (var i = 0; i < tails.length; ++i) JUNCTIONS[tails[i] + "," + lead] = value
}

// Obstruents nasalize before a nasal, and a following ㄹ becomes that nasal too:
// 독립 dongnip, 몇 명 myeon myeong, 십리 simni.
_junction([1, 2, 3, 9, 24], LEAD_N, "ngn")
_junction([1, 2, 3, 9, 24], LEAD_M, "ngm")
_junction([1, 2, 3, 9, 24], LEAD_R, "ngn")
_junction([7, 19, 20, 22, 23, 25, 27], LEAD_N, "nn")
_junction([7, 19, 20, 22, 23, 25, 27], LEAD_M, "nm")
_junction([7, 19, 20, 22, 23, 25, 27], LEAD_R, "nn")
_junction([14, 17, 18, 26], LEAD_N, "mn")
_junction([14, 17, 18, 26], LEAD_M, "mm")
_junction([14, 17, 18, 26], LEAD_R, "mn")

// ㄴ and ㄹ meeting in either order give a long l: 신라 Silla, 설날 seollal.
_junction([4], LEAD_R, "ll")
_junction([8, 15], LEAD_N, "ll")
_junction([8, 15], LEAD_R, "ll")
// ㅁ and ㅇ turn a following ㄹ into ㄴ: 종로 Jongno, 심리 simni.
_junction([16], LEAD_R, "mn")
_junction([21], LEAD_R, "ngn")

// A tail ㅎ aspirates the next consonant instead of being pronounced: 놓고 noko.
// The clusters ㄶ and ㅀ do the same while keeping their first jamo: 않고 anko.
var ASPIRATED = [[LEAD_G, "k"], [LEAD_D, "t"], [LEAD_J, "ch"], [LEAD_S, "s"], [LEAD_H, "h"]]
for (var a = 0; a < ASPIRATED.length; ++a) {
    JUNCTIONS["27," + ASPIRATED[a][0]] = ASPIRATED[a][1]
    JUNCTIONS["6," + ASPIRATED[a][0]] = "n" + ASPIRATED[a][1]
    JUNCTIONS["15," + ASPIRATED[a][0]] = "l" + ASPIRATED[a][1]
}

function isSyllable(code) {
    return code >= SYLLABLE_START && code <= SYLLABLE_END
}

function hasHangul(text) {
    for (var i = 0; i < text.length; ++i) {
        var code = text.charCodeAt(i)
        // Syllables, plus the compatibility jamo block for stray letters.
        if (isSyllable(code) || (code >= 0x3131 && code <= 0x318E)) return true
    }
    return false
}

function _decompose(code) {
    var index = code - SYLLABLE_START
    return {
        lead: Math.floor(index / (VOWEL_COUNT * TAIL_COUNT)),
        vowel: Math.floor(index / TAIL_COUNT) % VOWEL_COUNT,
        tail: index % TAIL_COUNT
    }
}

// Romanizes one run of adjacent hangul syllables. Assimilation stops at a word
// boundary, so callers hand over one run at a time.
function _romanizeRun(syllables) {
    var out = ""
    for (var i = 0; i < syllables.length; ++i) {
        var current = syllables[i]
        var next = i + 1 < syllables.length ? syllables[i + 1] : null

        out += i === 0 ? LEADS[current.lead] : ""
        out += VOWELS[current.vowel]

        if (!next) {
            out += TAILS[current.tail]
            continue
        }

        if (next.lead === LEAD_SILENT) {
            // ㄷ/ㅌ before an -i syllable palatalize: 굳이 guji, 같이 gachi.
            if (next.vowel === VOWEL_I && current.tail === TAIL_D) out += "j"
            else if (next.vowel === VOWEL_I && current.tail === TAIL_T) out += "ch"
            else out += LIAISONS[current.tail]
            continue
        }

        var junction = JUNCTIONS[current.tail + "," + next.lead]
        out += junction !== undefined ? junction : TAILS[current.tail] + LEADS[next.lead]
    }
    return out
}

// Romanizes hangul anywhere in `text`, leaving every other character in place.
function romanize(text) {
    var out = ""
    var run = []

    function flush() {
        if (run.length) {
            out += _romanizeRun(run)
            run = []
        }
    }

    for (var i = 0; i < text.length; ++i) {
        var code = text.charCodeAt(i)
        if (isSyllable(code)) {
            run.push(_decompose(code))
        } else {
            flush()
            out += text.charAt(i)
        }
    }
    flush()
    return out
}
