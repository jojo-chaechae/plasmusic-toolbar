import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// inspired by https://stackoverflow.com/a/49031115/2568933
Item {
    id: root

    property int maxWidth: root.width;
    readonly property bool overflow: {
        if (!root.maxWidth) {
            return false;
        }
        return root.maxWidth < staticLabel.implicitWidth;
    }

    width: fillAvailableWidth ? maxWidth : Math.min(maxWidth, staticLabel.implicitWidth)
    implicitHeight: staticLabel.implicitHeight
    implicitWidth: width

    enum OverflowBehaviour {
        AlwaysScroll,
        ScrollOnMouseOver,
        StopScrollOnMouseOver
    }

    enum TruncateStyle {
        Elide,
        FadeOut,
        None
    }

    property int overflowBehaviour: ScrollingText.OverflowBehaviour.AlwaysScroll
    property int truncateStyle: ScrollingText.TruncateStyle.None
    readonly property bool overflowElides: root.truncateStyle === ScrollingText.TruncateStyle.Elide
    readonly property bool overflowFades: root.truncateStyle === ScrollingText.TruncateStyle.FadeOut

    property bool scrollingEnabled: true
    property bool fillAvailableWidth: false
    property bool scrollResetOnPause: false
    property bool forcePauseScrolling: false

    readonly property bool pauseScrolling: {
        if (forcePauseScrolling) {
            return true;
        }
        if (overflowBehaviour === ScrollingText.OverflowBehaviour.AlwaysScroll) {
            return false;
        } else if (overflowBehaviour === ScrollingText.OverflowBehaviour.ScrollOnMouseOver) {
            return !mouse.hovered;
        } else if (overflowBehaviour === ScrollingText.OverflowBehaviour.StopScrollOnMouseOver) {
            return mouse.hovered;
        }
    }

    property alias font: staticLabel.font
    property alias color: staticLabel.color
    property alias horizontalAlignment: staticLabel.horizontalAlignment
    property string text: ""
    property int scrollDuration: 0
    readonly property string spacing: "     "
    readonly property string textAndSpacing: root.text + root.spacing
    property int speed: 5;
    readonly property int duration: root.scrollDuration > 0
        ? root.scrollDuration
        : (25 * (11 - speed) + 25) * textAndSpacing.length;

    clip: overflow

    HoverHandler {
        id: mouse
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    TextMetrics {
        id: textMetrics
        font: staticLabel.font
        text: root.text
    }

    TextMetrics {
        id: elidedTextMetrics
        font: staticLabel.font
        text: root.text
        elide: Text.ElideRight
        elideWidth: root.maxWidth
    }

    PlasmaComponents3.Label {
        id: staticLabel
        visible: !overflow || !scrollingEnabled
        anchors.fill: parent
        leftPadding: 0
        rightPadding: 0
        text: root.text
    }

    PlasmaComponents3.Label {
        id: scrollingLabel

        visible: overflow && scrollingEnabled

        text: (root.overflowElides && !scrollingAnimation.running) ? elidedTextMetrics.elidedText : root.text
        color: staticLabel.color
        font: staticLabel.font
        horizontalAlignment: Text.AlignLeft

        NumberAnimation on x {
            id: scrollingAnimation

            running: false
            from: 0
            to: Math.min(0, -(scrollingLabel.implicitWidth - root.width))
            duration: root.duration
            loops: 1

            function updateState() {
                const shouldRun = root.overflow && root.scrollingEnabled;
                if (!shouldRun) {
                    scrollingAnimation.stop();
                    scrollingLabel.x = 0;

                    return;
                }

                if (!scrollingAnimation.running) {
                    scrollingAnimation.start();
                }

                if (root.pauseScrolling) {
                    if (root.scrollResetOnPause) {
                        scrollingAnimation.stop();
                        scrollingLabel.x = 0;
                    } else {
                        scrollingAnimation.pause();
                    }
                } else if (scrollingAnimation.paused) {
                    scrollingAnimation.resume();
                }
            }
        }

        Connections {
            target: root
            function onOverflowChanged() {
                scrollingAnimation.updateState();
            }
            function onScrollingEnabledChanged() {
                scrollingAnimation.updateState();
            }
            function onScrollDurationChanged() {
                if (scrollingAnimation.running) scrollingAnimation.restart();
                scrollingAnimation.updateState();
            }
            function onPauseScrollingChanged() {
                scrollingAnimation.updateState();
            }

            function onTextChanged() {
                // Song is changed, restart the animation to avoid start from the middle of the text
                if (scrollingAnimation.running) {
                    scrollingAnimation.restart();
                }
                scrollingAnimation.updateState();
            }
        }

    }
    layer.enabled: overflow && overflowFades
    layer.effect: OpacityMask {
        invert: true
        maskSource: Item {
            width: root.width
            height: root.height
            LinearGradient {
                height: parent.height
                width: (textMetrics.width / textMetrics.text.length) * 2
                anchors.right: parent.right
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1.0,1.0,1.0,0.0) }
                    GradientStop { position: 0.5; color: Qt.rgba(1.0,1.0,1.0,0.5) }
                    GradientStop { position: 1.0; color: Qt.rgba(1.0,1.0,1.0,1.0) }
                    orientation: Gradient.Horizontal
                }
            }
        }
    }
}
