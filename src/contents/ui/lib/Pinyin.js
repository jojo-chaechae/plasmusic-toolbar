.pragma library
.import "PinyinData.js" as Data

// Hanyu Pinyin for Chinese text, with tone marks.
//
// Roughly a sixth of the characters in the block are polyphonic: 长 is "cháng"
// in 长发 but "zhǎng" in 长大, and a per-character table has to guess. So the
// walk is greedy longest-match against a word list of exactly those cases that
// the per-character table would get wrong, falling back to the character's most
// common reading.
//
// Word boundaries are not recoverable without a segmenter, so syllables are
// emitted space separated rather than grouped into words.

var _chars = null
var _phrases = null

function _load() {
    if (_chars !== null) return
    _chars = Data.CHARS.split(" ")
    _phrases = {}
    var entries = Data.PHRASES.split(";")
    for (var i = 0; i < entries.length; ++i) {
        var separator = entries[i].indexOf(":")
        if (separator > 0) {
            _phrases[entries[i].substring(0, separator)] = entries[i].substring(separator + 1)
        }
    }
}

function _isHan(code) {
    return code >= Data.BLOCK_START && code <= Data.BLOCK_END
}

function hasHan(text) {
    for (var i = 0; i < text.length; ++i) {
        if (_isHan(text.charCodeAt(i))) return true
    }
    return false
}

function _reading(char) {
    return _chars[char.charCodeAt(0) - Data.BLOCK_START] || ""
}

function _isLatin(char) {
    return /[A-Za-z0-9]/.test(char)
}

function romanize(text) {
    _load()

    var tokens = []
    for (var i = 0; i < text.length; ) {
        if (!_isHan(text.charCodeAt(i))) {
            tokens.push({text: text.charAt(i), syllable: false})
            i += 1
            continue
        }

        var matched = false
        for (var length = Data.MAX_PHRASE; length >= 2 && !matched; --length) {
            var phrase = _phrases[text.substr(i, length)]
            if (phrase === undefined) continue
            var syllables = phrase.split(" ")
            for (var s = 0; s < syllables.length; ++s) {
                tokens.push({text: syllables[s], syllable: true})
            }
            i += length
            matched = true
        }
        if (matched) continue

        var reading = _reading(text.charAt(i))
        // Characters the table does not cover stay as they are.
        tokens.push({text: reading || text.charAt(i), syllable: reading !== ""})
        i += 1
    }

    // Separate syllables from each other and from any latin text they touch,
    // but never introduce a space in front of punctuation.
    var out = ""
    for (var t = 0; t < tokens.length; ++t) {
        var token = tokens[t]
        var previous = t > 0 ? tokens[t - 1] : null
        if (previous !== null && (token.syllable || previous.syllable)) {
            var left = previous.text.charAt(previous.text.length - 1)
            var right = token.text.charAt(0)
            var joins = (previous.syllable || _isLatin(left)) && (token.syllable || _isLatin(right))
            if (joins) out += " "
        }
        out += token.text
    }
    return out
}
