import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var lines: []
    property int currentLine: -1
    property int lineCount: 3
    property font textFont: Kirigami.Theme.defaultFont
    property color textColor: Kirigami.Theme.textColor
    property bool scrollingEnabled: true
    property real lineHeight: Math.max(Kirigami.Units.gridUnit, textFont.pixelSize * 1.35)

    visible: lines.length > 0
    implicitHeight: lineCount * lineHeight
    Layout.fillWidth: true

    readonly property int firstLine: {
        if (lines.length <= lineCount) return 0
        const centered = currentLine - Math.floor(lineCount / 2)
        return Math.max(0, Math.min(centered, lines.length - lineCount))
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.lineCount
            delegate: ScrollingText {
                required property int index
                readonly property int lineIndex: root.firstLine + index
                readonly property bool active: lineIndex === root.currentLine

                Layout.fillWidth: true
                Layout.preferredHeight: root.lineHeight
                maxWidth: root.width
                text: lineIndex >= 0 && lineIndex < root.lines.length ? root.lines[lineIndex] : ""
                font: active
                    ? Qt.font(Object.assign({}, root.textFont, {weight: Font.Bold}))
                    : root.textFont
                color: root.textColor
                speed: plasmoid.configuration.fullViewTextScrollingSpeed
                scrollingEnabled: root.scrollingEnabled
                opacity: active ? 1.0 : (lineIndex < root.currentLine ? 0.45 : 0.7)
            }
        }
    }
}
