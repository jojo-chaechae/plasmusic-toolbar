import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool pinVisible: true
    property bool keepOpen: false
    property bool albumCoverVisible: true
    property bool scriptButtonEnabled: false
    property string scriptPath: ""
    property bool copyTrackInfoVisible: false
    property string copyTrackInfo: ""

    signal keepOpenToggled()
    signal albumCoverToggled()
    signal scriptRequested()
    signal settingsRequested()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    Layout.fillWidth: true

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            id: keepOpenButton
            visible: root.pinVisible
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
            display: PlasmaComponents3.AbstractButton.IconOnly
            checkable: true
            icon.name: "window-pin"
            icon.color: checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            text: checked ? i18n("Keep player open") : i18n("Allow player to close automatically")

            Binding {
                target: keepOpenButton
                property: "checked"
                value: root.keepOpen
            }

            PlasmaComponents3.ToolTip.text: text
            PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
            Accessible.name: text

            onClicked: root.keepOpenToggled()
        }

        PlasmaComponents3.ToolButton {
            id: albumCoverButton
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
            display: PlasmaComponents3.AbstractButton.IconOnly
            checkable: true
            icon.name: checked ? "view-visible" : "view-hidden"
            icon.color: checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            text: checked ? i18n("Hide album cover") : i18n("Show album cover")

            Binding {
                target: albumCoverButton
                property: "checked"
                value: root.albumCoverVisible
            }

            PlasmaComponents3.ToolTip.text: text
            PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
            Accessible.name: text

            onClicked: root.albumCoverToggled()
        }

        PlasmaComponents3.ToolButton {
            id: scriptButton
            visible: root.scriptButtonEnabled
            enabled: root.scriptPath.trim().length > 0
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
            display: PlasmaComponents3.AbstractButton.IconOnly
            icon.name: "system-run"
            text: enabled ? i18n("Run custom script") : i18n("Configure a script path")

            PlasmaComponents3.ToolTip.text: text
            PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
            Accessible.name: text

            onClicked: root.scriptRequested()
        }

        PlasmaComponents3.ToolButton {
            id: settingsButton
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
            display: PlasmaComponents3.AbstractButton.IconOnly
            icon.name: "settings-configure"
            text: i18n("Open widget settings")

            PlasmaComponents3.ToolTip.text: text
            PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
            Accessible.name: text

            onClicked: root.settingsRequested()
        }

        PlasmaComponents3.ToolButton {
            id: copyButton
            visible: root.copyTrackInfoVisible
            enabled: root.copyTrackInfo.trim().length > 0
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
            display: PlasmaComponents3.AbstractButton.IconOnly
            icon.name: "edit-copy"
            text: i18n("Copy track info to clipboard")

            PlasmaComponents3.ToolTip.text: text
            PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
            Accessible.name: text

            onClicked: {
                clipboardField.text = root.copyTrackInfo
                clipboardField.selectAll()
                clipboardField.copy()
            }
        }
    }

    // Hidden field used to write the track info to the system clipboard.
    PlasmaComponents3.TextField {
        id: clipboardField
        visible: false
        width: 0
        height: 0
    }
}
