import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Lightweight panel lyric display: only the currently active line is rendered.
Item {
    id: root

    property var lines: []
    property var lineTimestamps: []
    property int currentLine: -1
    property font textFont: Kirigami.Theme.defaultFont
    property color textColor: Kirigami.Theme.textColor
    property int horizontalAlignment: Qt.AlignHCenter
    property bool seekEnabled: false
    property int animationMode: 0
    property color animationColor: Kirigami.Theme.highlightColor
    property int currentLineDuration: 0
    property real animationProgress: 1

    signal seekRequested(timestamp: double)

    function restartAnimation() {
        animationProgress = 0
        lineAnimation.duration = Math.max(200, Math.round(root.currentLineDuration * 0.7))
        lineAnimation.restart()
    }

    NumberAnimation {
        id: lineAnimation
        target: root
        property: "animationProgress"
        to: 1
        easing.type: Easing.Linear
    }

    readonly property string currentText: currentLine >= 0 && currentLine < lines.length
        ? String(lines[currentLine]) : ""
    readonly property double currentTimestamp: currentLine >= 0 && currentLine < lineTimestamps.length
        ? Number(lineTimestamps[currentLine]) : -1
    readonly property real contentImplicitWidth: contentMetrics.implicitWidth

    implicitHeight: Math.max(Kirigami.Units.gridUnit, textFont.pixelSize * 1.35)
    implicitWidth: label.implicitWidth

    Text {
        id: contentMetrics
        visible: false
        text: root.lines.join("\n")
        font: root.textFont
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
    }

    PlasmaComponents3.Label {
        id: label
        anchors.fill: parent
        text: root.currentText
        color: root.textColor
        font: {
            let font = root.textFont
            font.weight = Font.Bold
            return font
        }
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Item {
        id: animationLayer
        anchors.left: parent.left
        anchors.top: parent.top
        width: parent.width * root.animationProgress
        height: parent.height
        visible: root.animationMode === 1 && root.currentText.length > 0
        z: 1
        clip: true
        layer.enabled: visible
        layer.effect: OpacityMask {
            maskSource: Item {
                width: animationLayer.width
                height: animationLayer.height
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
            id: animationLabel
            width: root.width
            height: parent.height
            text: root.currentText
            color: root.animationColor
            font: root.textFont
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 1
        }

        Glow {
            anchors.fill: animationLabel
            source: animationLabel
            color: root.animationColor
            radius: 4
            samples: 8
            spread: 0.15
            opacity: 0.45
        }
    }

    TapHandler {
        enabled: root.seekEnabled && root.currentTimestamp >= 0
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onTapped: root.seekRequested(root.currentTimestamp)
    }

    onCurrentLineChanged: {
        if (animationMode === 1) restartAnimation()
    }

    onCurrentLineDurationChanged: {
        if (animationMode === 1) restartAnimation()
    }

    onAnimationModeChanged: {
        if (animationMode === 1) restartAnimation()
    }
}
