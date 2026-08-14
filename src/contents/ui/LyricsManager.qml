import QtQuick

QtObject {
    id: root

    property bool enabled: false
    property string title: ""
    property string artists: ""
    property string album: ""
    property double songLength: 0 // microseconds
    property double songPosition: 0 // microseconds

    // Public lyrics contract used by the mini-lyrics view.
    property var lines: []
    property var lineTimestamps: [] // milliseconds from the start of the track
    property int currentLine: -1
    property int currentLineDuration: 0 // active duration for the current lyric line, in milliseconds
    property bool inBreak: false
    property int intermissionThreshold: 6 // seconds
    readonly property int breakThreshold: Math.max(1, intermissionThreshold) * 1000 // milliseconds
    property bool available: false
    property var _timedLines: []
    property var _displayLineIndices: []

    property bool loading: false
    property string _lastQuery: ""
    property int _requestId: 0
    property var _activeRequest: null

    property var debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: root._fetchLyrics()
    }

    onEnabledChanged: _scheduleFetch()
    onTitleChanged: _scheduleFetch()
    onArtistsChanged: _scheduleFetch()
    onAlbumChanged: _scheduleFetch()
    onSongLengthChanged: _scheduleFetch()
    onSongPositionChanged: syncPosition()
    onLinesChanged: syncPosition()
    onIntermissionThresholdChanged: {
        if (_timedLines.length) {
            _buildDisplayLines()
            syncPosition()
        }
    }

    function _queryKey() {
        return JSON.stringify([title, artists, album, Math.round(songLength / 1000000)])
    }

    function _scheduleFetch() {
        if (!enabled || !title || !artists) {
            _clear()
            return
        }

        const query = _queryKey()
        if (query === _lastQuery) return

        _abortActiveRequest()
        _lastQuery = query
        lines = []
        lineTimestamps = []
        _timedLines = []
        _displayLineIndices = []
        currentLine = -1
        currentLineDuration = 0
        inBreak = false
        available = false
        loading = true
        debounceTimer.restart()
    }

    function _clear() {
        debounceTimer.stop()
        _abortActiveRequest()
        _lastQuery = ""
        lines = []
        lineTimestamps = []
        _timedLines = []
        _displayLineIndices = []
        currentLine = -1
        currentLineDuration = 0
        inBreak = false
        available = false
        loading = false
    }

    function _abortActiveRequest() {
        _requestId++
        if (!_activeRequest) return

        const request = _activeRequest
        _activeRequest = null
        request.onreadystatechange = function() {}
        request.abort()
    }

    function _isCurrent(requestId, query) {
        return enabled && requestId === _requestId && query === _lastQuery
    }

    function _fetchLyrics() {
        if (!enabled || !title || !artists) {
            _clear()
            return
        }

        _abortActiveRequest()
        const query = _lastQuery
        const requestId = _requestId
        const duration = Math.round(songLength / 1000000)
        let url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(artists)
            + "&track_name=" + encodeURIComponent(title)
            + "&album_name=" + encodeURIComponent(album)
        if (duration > 0) url += "&duration=" + duration

        _request(url, requestId, query, function(status, responseText) {
            if (status === 200) {
                if (_useResponse(responseText, requestId, query)) return
            }
            if (status === 404 || status === 200) {
                _searchLyrics(requestId, query)
            } else if (_isCurrent(requestId, query)) {
                loading = false
            }
        })
    }

    function _searchLyrics(requestId, query) {
        if (!_isCurrent(requestId, query)) return

        const url = "https://lrclib.net/api/search?track_name=" + encodeURIComponent(title)
            + "&artist_name=" + encodeURIComponent(artists)
        _request(url, requestId, query, function(status, responseText) {
            if (!_isCurrent(requestId, query)) return

            if (status === 200) {
                try {
                    const results = JSON.parse(responseText)
                    for (let i = 0; i < results.length; ++i) {
                        if (_setLyrics(results[i].syncedLyrics)) return
                    }
                } catch (error) {
                    // Treat malformed responses as unavailable lyrics.
                }
            }
            loading = false
        })
    }

    function _request(url, requestId, query, callback) {
        const request = new XMLHttpRequest()
        let finished = false
        _activeRequest = request
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE || finished) return
            finished = true
            if (!_isCurrent(requestId, query)) return
            if (_activeRequest === request) _activeRequest = null
            callback(request.status, request.responseText)
        }
        request.onerror = function() {
            if (finished) return
            finished = true
            if (!_isCurrent(requestId, query)) return
            if (_activeRequest === request) _activeRequest = null
            callback(0, "")
        }
        request.ontimeout = request.onerror
        request.open("GET", url)
        request.setRequestHeader("X-User-Agent", "plasmusic-toolbar")
        request.timeout = 10000
        request.send()
    }

    function _useResponse(responseText, requestId, query) {
        if (!_isCurrent(requestId, query)) return true

        try {
            const response = JSON.parse(responseText)
            if (_setLyrics(response.syncedLyrics)) return true
        } catch (error) {
            // Fall back to the search endpoint below.
        }
        return false
    }

    function _setLyrics(lrc) {
        if (!lrc) return false
        const parsed = _parseLrc(lrc)
        if (parsed.length === 0) return false

        _timedLines = parsed
        _buildDisplayLines()
        available = true
        loading = false
        syncPosition()
        return true
    }

    function _buildDisplayLines() {
        const parsed = _timedLines
        const displayLines = []
        const displayTimestamps = []
        const displayIndices = []
        for (let i = 0; i < parsed.length; ++i) {
            if (i > 0 && parsed[i].time - parsed[i - 1].time > root.breakThreshold) {
                displayLines.push("♪")
                displayTimestamps.push(-1)
            }
            displayIndices.push(displayLines.length)
            displayLines.push(parsed[i].text)
            displayTimestamps.push(parsed[i].time)
        }
        _displayLineIndices = displayIndices
        lines = displayLines
        lineTimestamps = displayTimestamps
    }

    function _parseLrc(lrc) {
        const parsed = []
        const sourceLines = lrc.split(/\r?\n/)
        for (const sourceLine of sourceLines) {
            const matches = sourceLine.match(/\[(\d+):(\d{2})[.:](\d{2,3})\]\s*(.*)/)
            if (!matches) continue

            const fraction = matches[3].length === 2
                ? Number(matches[3]) * 10
                : Number(matches[3])
            const time = Number(matches[1]) * 60000 + Number(matches[2]) * 1000 + fraction
            const text = matches[4].trim()
            if (text) parsed.push({time: time, text: text})
        }
        parsed.sort((a, b) => a.time - b.time)
        return parsed
    }

    function syncPosition() {
        if (!lines.length) {
            currentLine = -1
            currentLineDuration = 0
            inBreak = false
            return
        }
        const position = songPosition / 1000
        let index = -1
        for (let i = 0; i < _timedLines.length; ++i) {
            if (_timedLines[i].time > position) break
            index = i
        }
        if (index < 0) {
            currentLine = -1
            currentLineDuration = 0
            inBreak = false
            return
        }

        const currentTime = _timedLines[index].time
        const nextTime = index + 1 < _timedLines.length
            ? _timedLines[index + 1].time
            : Math.round(songLength / 1000)
        const gap = nextTime > currentTime ? nextTime - currentTime : 5000
        const isBreak = gap > root.breakThreshold
        const duration = isBreak ? root.breakThreshold : gap

        if (isBreak && position >= currentTime + duration) {
            currentLine = _displayLineIndices[index] + 1
            currentLineDuration = 0
            inBreak = true
            return
        }

        currentLine = _displayLineIndices[index]
        inBreak = false
        currentLineDuration = Math.max(500, Math.min(60000, duration))
    }
}
