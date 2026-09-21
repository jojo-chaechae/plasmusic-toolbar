// WorkerScript files are plain JavaScript. They cannot use QML's .import
// syntax, so the small runtime bundle is assembled with Qt.include().
Qt.include("lib/Hangul.js")
var Hangul = {hasHangul: hasHangul, romanize: romanize}

Qt.include("lib/Kana.js")
var Kana = {hasKana: hasKana, romanize: romanize}

Qt.include("lib/PinyinData.js")
var Data = {
    BLOCK_START: BLOCK_START,
    BLOCK_END: BLOCK_END,
    MAX_PHRASE: MAX_PHRASE,
    CHARS: CHARS,
    PHRASES: PHRASES
}
Qt.include("lib/Pinyin.js")
var Pinyin = {hasHan: hasHan, romanize: romanize}

Qt.include("lib/JMDictData.js")

var WORKER_WORDS = {}
for (var generatedWord in WORDS) WORKER_WORDS[generatedWord] = WORDS[generatedWord]
var OVERRIDES = {
    "名": "な", "君": "きみ", "僕": "ぼく", "私": "わたし",
    "何": "なに", "誰": "だれ", "声": "こえ"
}
for (var overrideWord in OVERRIDES) WORKER_WORDS[overrideWord] = OVERRIDES[overrideWord]

var TRIE = {}
for (var word in WORKER_WORDS) {
    var node = TRIE
    for (var characterIndex = 0; characterIndex < word.length; ++characterIndex) {
        var character = word.charAt(characterIndex)
        if (node[character] === undefined) node[character] = {}
        node = node[character]
    }
    node.reading = WORKER_WORDS[word]
}

function toKana(text) {
    var out = ""
    for (var i = 0; i < text.length; ) {
        var match = null
        var matchLength = 0
        var node = TRIE
        for (var j = i; j < text.length; ++j) {
            node = node[text.charAt(j)]
            if (node === undefined) break
            if (node.reading !== undefined) {
                match = node.reading
                matchLength = j - i + 1
            }
        }
        if (match !== null) {
            out += " " + match + " "
            i += matchLength
        } else {
            out += text.charAt(i)
            i += 1
        }
    }
    return out
}

function detect(lines) {
    var han = false
    for (var i = 0; i < lines.length; ++i) {
        var line = String(lines[i])
        if (Hangul.hasHangul(line)) return "ko"
        if (Kana.hasKana(line)) return "ja"
        if (!han && Pinyin.hasHan(line)) han = true
    }
    return han ? "zh" : ""
}

function romanizeLine(line, script) {
    if (script === "ko") return Hangul.romanize(line)
    if (script === "ja") return Kana.romanize(toKana(line))
    if (script === "zh") return Pinyin.romanize(line)
    return line
}

function romanizeLines(lines) {
    var script = detect(lines)
    var out = []
    for (var i = 0; i < lines.length; ++i) {
        var line = String(lines[i])
        var romanized = script === "" ? line : romanizeLine(line, script)
        out.push(romanized === line ? "" : romanized)
    }
    return out
}

WorkerScript.onMessage = function(message) {
    WorkerScript.sendMessage({
        id: message.id,
        lines: romanizeLines(message.lines)
    })
}
