.pragma library
.import "Hangul.js" as Hangul
.import "Kana.js" as Kana
.import "Pinyin.js" as Pinyin

// Picks a romanizer for a set of lyric lines and applies it.
//
// Han characters alone are ambiguous: 名 is "míng" in a Chinese song and "na"
// or "mei" in a Japanese one. Kana disambiguates, but only some lines of a
// Japanese song contain any, so the script is decided once over the whole set
// of lines and then applied to each of them.

var SCRIPT_NONE = ""
var SCRIPT_KOREAN = "ko"
var SCRIPT_JAPANESE = "ja"
var SCRIPT_CHINESE = "zh"

function detect(lines) {
    var han = false
    for (var i = 0; i < lines.length; ++i) {
        var line = String(lines[i])
        if (Hangul.hasHangul(line)) return SCRIPT_KOREAN
        if (Kana.hasKana(line)) return SCRIPT_JAPANESE
        if (!han && Pinyin.hasHan(line)) han = true
    }
    return han ? SCRIPT_CHINESE : SCRIPT_NONE
}

function romanizeLine(line, script) {
    if (script === SCRIPT_KOREAN) return Hangul.romanize(line)
    if (script === SCRIPT_JAPANESE) return Kana.romanize(line)
    if (script === SCRIPT_CHINESE) return Pinyin.romanize(line)
    return line
}

// Returns a romanization for every entry of `lines`, empty where the line came
// back unchanged: break markers, latin lines, and Japanese lines written purely
// in kanji have nothing to show that the original does not already show.
function romanizeLines(lines) {
    var script = detect(lines)
    var out = []
    for (var i = 0; i < lines.length; ++i) {
        var line = String(lines[i])
        var romanized = script === SCRIPT_NONE ? line : romanizeLine(line, script)
        out.push(romanized === line ? "" : romanized)
    }
    return {script: script, lines: out}
}
