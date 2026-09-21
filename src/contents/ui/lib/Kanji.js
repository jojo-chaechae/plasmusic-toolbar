.pragma library
.import "JMDictData.js" as JMDict

// A deliberately small Japanese word-reading dictionary.
//
// Kanji readings depend on the word they occur in, so this is keyed by words
// rather than individual characters. Longer entries win; unknown text is
// left in place for Kana.romanize() to render without guessing.

var OVERRIDES = {
    "ありがとうございます": "ありがとうございます",
    "おめでとう": "おめでとう",
    "大丈夫": "だいじょうぶ",
    "大切": "たいせつ",
    "本当に": "ほんとうに",
    "本当": "ほんとう",
    "分からない": "わからない",
    "知らない": "しらない",
    "忘れない": "わすれない",
    "変わらない": "かわらない",
    "何年": "なんねん",
    "名前": "なまえ",
    "名": "な",
    "世界": "せかい",
    "今日": "きょう",
    "明日": "あした",
    "昨日": "きのう",
    "時間": "じかん",
    "人生": "じんせい",
    "気持ち": "きもち",
    "愛してる": "あいしてる",
    "愛": "あい",
    "恋": "こい",
    "心": "こころ",
    "夢": "ゆめ",
    "空": "そら",
    "夜": "よる",
    "朝": "あさ",
    "人": "ひと",
    "君": "きみ",
    "僕": "ぼく",
    "私": "わたし",
    "何": "なに",
    "誰": "だれ",
    "歌": "うた",
    "声": "こえ",
    "光": "ひかり",
    "星": "ほし",
    "涙": "なみだ",
    "道": "みち",
    "手": "て",
    "目": "め",
    "言葉": "ことば",
    "言う": "いう",
    "行く": "いく",
    "来る": "くる",
    "見る": "みる",
    "思う": "おもう",
    "好き": "すき",
    "生きる": "いきる",
    "知る": "しる",
    "笑う": "わらう",
    "泣く": "なく"
}

var WORDS = {}
for (var generatedWord in JMDict.WORDS) WORDS[generatedWord] = JMDict.WORDS[generatedWord]
for (var overrideWord in OVERRIDES) WORDS[overrideWord] = OVERRIDES[overrideWord]

// A trie keeps lookup proportional to the length of the text being matched,
// rather than proportional to the size of the dictionary at every character.
var TRIE = {}
for (var word in WORDS) {
    var node = TRIE
    for (var characterIndex = 0; characterIndex < word.length; ++characterIndex) {
        var character = word.charAt(characterIndex)
        if (node[character] === undefined) node[character] = {}
        node = node[character]
    }
    node.reading = WORDS[word]
}

function toKana(text) {
    var out = ""
    for (var i = 0; i < text.length; ) {
        var match = null
        var matchLength = 0
        node = TRIE
        for (var j = i; j < text.length; ++j) {
            node = node[text.charAt(j)]
            if (node === undefined) break
            if (node.reading !== undefined) {
                match = node.reading
                matchLength = j - i + 1
            }
        }
        if (match !== null) {
            // Keep readings as separate kana runs so Kana can still apply
            // particle rules, especially は and を.
            out += " " + match + " "
            i += matchLength
        } else {
            out += text.charAt(i)
            i += 1
        }
    }
    return out
}
