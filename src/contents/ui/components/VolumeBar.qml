import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: container
    property real volume: 0.5;
    property real iconSize: Kirigami.Units.iconSizes.small;
    property color accentColor: Kirigami.Theme.highlightColor
    readonly property real minVolume: 0.0;
    readonly property real maxVolume: 1.0;
    readonly property real clampedVolume: clampVolume(volume);

    signal setVolume(newVolume: real)
    signal volumeUp()
    signal volumeDown()

    function clampVolume(value) {
        return Math.max(minVolume, Math.min(maxVolume, value));
    }

    Layout.fillWidth: true
    Layout.preferredHeight: row.implicitHeight
    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    RowLayout {
        id: row
        anchors.fill: parent

        CommandIcon {
            size: iconSize;
            onClicked: () => {
                if (container.volume > container.minVolume) container.volumeDown();
            }
            source: 'audio-volume-low';
        }

        PlasmaComponents3.Slider {
            id: volumeSlider
            Layout.fillWidth: true
            from: container.minVolume
            to: container.maxVolume
            value: container.clampedVolume
            Kirigami.Theme.highlightColor: container.accentColor

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                width: volumeSlider.availableWidth
                height: 4
                radius: height / 2
                color: Qt.rgba(Kirigami.Theme.textColor.r,
                               Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.25)

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: container.accentColor
                }
            }

            property bool changingVolume: false

            onPressedChanged: () => {
                if (!pressed) {
                    volumeSlider.moved()
                }
            }
            onMoved: {
                if (pressed) {
                    return
                }

                changingVolume = true
                container.setVolume(container.clampVolume(value))
                changingVolume = false
            }

            MouseAreaWithWheelHandler {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheelUp: () => {
                    if (container.volume < container.maxVolume) container.volumeUp();
                }
                onWheelDown: () => {
                    if (container.volume > container.minVolume) container.volumeDown();
                }
            }

        }

        CommandIcon {
            size: iconSize;
            onClicked: () => {
                if (container.volume < container.maxVolume) container.volumeUp();
            }
            source: 'audio-volume-high';
        }
    }
}
