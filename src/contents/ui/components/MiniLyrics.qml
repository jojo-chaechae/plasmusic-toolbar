import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import Qt5Compat.GraphicalEffects

Item {
    id: root

    enum LyricsAnimation {
        None,
        Glow
    }

    property var lines: []
    property var lineTimestamps: []
    property int currentLine: -1
    property int currentLineDuration: 0
    property font textFont: Kirigami.Theme.defaultFont
    property color textColor: Kirigami.Theme.textColor
    property bool scrollingEnabled: true
    property int horizontalAlignment: Qt.AlignHCenter
    property int fontSize: 0
    property real lineSpacing: 1.35
    property int animationMode: LyricsAnimation.None
    property color animationColor: Kirigami.Theme.highlightColor
    property bool seekEnabled: true

    signal seekRequested(timestamp: double)
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

    function centerCurrentLine(animate) {
        if (currentLine < 0 || !lines.length) return

        const target = Math.max(0, Math.min(
            currentLine * lineHeight - (height - lineHeight) / 2,
            flickable.contentHeight - height
        ))
        if (animate) {
            centerAnimation.stop()
            centerAnimation.from = flickable.contentY
            centerAnimation.to = target
            centerAnimation.start()
        } else {
            flickable.contentY = target
        }
    }

    function timestampForLine(index) {
        if (!lineTimestamps || index < 0 || index >= lineTimestamps.length) return -1
        return Number(lineTimestamps[index])
    }

    NumberAnimation {
        id: centerAnimation
        target: flickable
        property: "contentY"
        duration: 350
        easing.type: Easing.OutCubic
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
                delegate: Item {
                    id: lineItem
                    required property int index
                    required property string modelData
                    readonly property bool active: index === root.currentLine
                    readonly property bool intermission: root.timestampForLine(index) < 0
                    readonly property real restingOpacity: active ? 1.0 : (index < root.currentLine ? 0.45 : 0.7)
                    property real animationProgress: 1

                    width: flickable.width
                    height: root.lineHeight
                    opacity: restingOpacity

                    function restartLineAnimation() {
                        lineAnimation.stop()
                        animationProgress = 1
                        if (active && !intermission && root.animationMode !== MiniLyrics.LyricsAnimation.None) {
                            animationProgress = 0
                            lineAnimation.duration = Math.max(200, Math.round(root.currentLineDuration * 0.7))
                            lineAnimation.restart()
                        }
                    }

                    Component.onCompleted: {
                        restartLineAnimation()
                    }

                    onActiveChanged: {
                        if (active) Qt.callLater(restartLineAnimation)
                    }

                    Connections {
                        target: root
                        function onAnimationModeChanged() {
                            if (lineItem.active) Qt.callLater(lineItem.restartLineAnimation)
                        }
                        function onCurrentLineDurationChanged() {
                            if (lineItem.active) lineItem.restartLineAnimation()
                        }
                    }

                    NumberAnimation {
                        id: lineAnimation
                        target: lineItem
                        property: "animationProgress"
                        to: 1
                        easing.type: Easing.Linear
                    }

                    ScrollingText {
                        id: lineText
                        anchors.fill: parent
                        maxWidth: parent.width
                        text: modelData
                        font: {
                            let font = root.lyricFont
                            if (lineItem.active) font.weight = Font.Bold
                            return font
                        }
                        color: root.textColor
                        speed: plasmoid.configuration.fullViewTextScrollingSpeed
                        scrollingEnabled: root.scrollingEnabled && lineItem.active && !lineItem.intermission
                        scrollDuration: lineItem.active ? root.currentLineDuration : 0
                        horizontalAlignment: root.horizontalAlignment
                    }

                    Item {
                        id: animationViewport
                        visible: lineItem.active
                                 && !lineItem.intermission
                                 && root.animationMode !== MiniLyrics.LyricsAnimation.None
                                 && !lineText.overflow
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: parent.width * lineItem.animationProgress
                        height: parent.height
                        clip: true
                        layer.enabled: visible
                        layer.effect: OpacityMask {
                            maskSource: Item {
                                width: animationViewport.width
                                height: animationViewport.height
                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "white" }
                                        GradientStop { position: 0.8; color: "white" }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                            }
                        }

                        PlasmaComponents3.Label {
                            id: animationText
                            width: lineItem.width
                            height: lineItem.height
                            text: modelData
                            color: root.animationColor
                            font: {
                                let font = root.lyricFont
                                if (lineItem.active) font.weight = Font.Bold
                                return font
                            }
                            horizontalAlignment: root.horizontalAlignment
                            verticalAlignment: Text.AlignTop
                        }

                        Glow {
                            anchors.fill: animationText
                            source: animationText
                            color: root.animationColor
                            radius: 4
                            samples: 8
                            spread: 0.15
                            opacity: 0.45
                        }
                    }

                    TapHandler {
                        enabled: root.seekEnabled && root.timestampForLine(index) >= 0
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onTapped: {
                            root.seekRequested(root.timestampForLine(index))
                        }
                    }
                }
            }
        }
    }

    onCurrentLineChanged: centerCurrentLine(true)
    onHeightChanged: centerCurrentLine(false)
    onLinesChanged: Qt.callLater(() => centerCurrentLine(false))
}
