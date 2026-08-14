import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var lines: []
    property int currentLine: -1
    property int currentLineDuration: 0
    property font textFont: Kirigami.Theme.defaultFont
    property color textColor: Kirigami.Theme.textColor
    property bool scrollingEnabled: true
    property int horizontalAlignment: Qt.AlignHCenter
    property int fontSize: 0
    property real lineSpacing: 1.35
    readonly property font lyricFont: {
        if (fontSize <= 0) return textFont
        let font = textFont
        font.pointSize = -1
        font.pixelSize = fontSize
        return font
    }
    property real lineHeight: Math.max(Kirigami.Units.gridUnit, lyricFont.pixelSize * lineSpacing)

    visible: lines.length > 0
    implicitHeight: lineHeight
    Layout.fillWidth: true
    anchors.fill: parent

    readonly property int visibleLineCount: Math.max(1, Math.floor(height / lineHeight))

    function centerCurrentLine() {
        if (currentLine < 0 || !lines.length) return

        const target = currentLine * lineHeight - (height - lineHeight) / 2
        flickable.contentY = Math.max(0, Math.min(target, flickable.contentHeight - height))
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: lyricsColumn.height

        Column {
            id: lyricsColumn
            width: flickable.width
            height: root.lines.length * root.lineHeight

            Repeater {
                model: root.lines
                delegate: ScrollingText {
                    required property int index
                    required property string modelData
                    readonly property bool active: index === root.currentLine

                    width: flickable.width
                    height: root.lineHeight
                    maxWidth: flickable.width
                    text: modelData
                    font: {
                        let font = root.lyricFont
                        if (active) font.weight = Font.Bold
                        return font
                    }
                    color: root.textColor
                    speed: plasmoid.configuration.fullViewTextScrollingSpeed
                    scrollingEnabled: root.scrollingEnabled && active
                    scrollDuration: active ? root.currentLineDuration : 0
                    horizontalAlignment: root.horizontalAlignment
                    opacity: active ? 1.0 : (index < root.currentLine ? 0.45 : 0.7)
                }
            }
        }
    }

    onCurrentLineChanged: centerCurrentLine()
    onHeightChanged: centerCurrentLine()
    onLinesChanged: Qt.callLater(centerCurrentLine)
}
