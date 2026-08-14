import "../components"
import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import QtQuick.Dialogs as QtDialogs
import org.kde.plasma.core as PlasmaCore


KCM.SimpleKCM {
    id: fullConfigPage
    Layout.preferredWidth: form.implicitWidth;

    property alias cfg_desktopWidgetBg: desktopWidgetBackgroundRadio.value
    property alias cfg_albumPlaceholder: albumPlaceholderDialog.value
    property alias cfg_fullViewTextScrollingSpeed: fullViewTextScrollingSpeed.value
    property alias cfg_fullArtistsPosition: fullArtistsPosition.value
    property alias cfg_fullTitlePosition: fullTitlePosition.value
    property alias cfg_fullAlbumPosition: fullAlbumPosition.value
    property alias cfg_fullAlbumCoverAsBackground: fullAlbumCoverAsBackground.checked
    property alias cfg_fullAlbumCoverTintBackground: fullAlbumCoverTintBackground.checked
    property alias cfg_fullAlbumCoverTintOpacity: fullAlbumCoverTintOpacity.value
    property alias cfg_fullAlbumCoverTintGradient: fullAlbumCoverTintGradient.checked
    property alias cfg_fullAlbumCoverTintUseContrastText: fullAlbumCoverTintUseContrastText.checked
    property alias cfg_fullHideAlbumForSingles: fullHideAlbumForSingles.checked
    property alias cfg_fullViewThumbnailVisible: fullViewThumbnailVisible.checked
    property alias cfg_fullViewAlbumCoverClickToRaise: fullViewAlbumCoverClickToRaise.checked
    property alias cfg_fullViewProgressBarVisible: fullViewProgressBarVisible.checked
    property alias cfg_fullViewVolumeControlVisible: fullViewVolumeControlVisible.checked
    property alias cfg_fullViewShuffleVisible: fullViewShuffleVisible.checked
    property alias cfg_fullViewPlaybackControlsVisible: fullViewPlaybackControlsVisible.checked
    property alias cfg_fullViewLoopVisible: fullViewLoopVisible.checked
    property alias cfg_fullViewLyricsVisible: fullViewLyricsVisible.checked
    property alias cfg_fullViewMediaPosition: fullViewMediaPosition.value
    property alias cfg_fullViewMediaOrder: fullViewMediaOrder.value
    property alias cfg_fullViewPlaybackControlsFillWidth: fullViewPlaybackControlsFillWidth.checked
    property alias cfg_fullViewSongTextVisible: fullViewSongTextVisible.checked
    property alias cfg_fullViewSongTextAlignment: fullViewSongTextAlignment.value
    property alias cfg_fullViewVerticalOrder: verticalOrderControl.verticalOrderValue
    property alias cfg_fullViewMinWidth: fullViewMinWidth.value
    property alias cfg_fullViewMaxWidth: fullViewMaxWidth.value
    property alias cfg_fullViewMinHeight: fullViewMinHeight.value
    property alias cfg_fullViewMaxHeight: fullViewMaxHeight.value
    property alias cfg_showPlayerSelector: showPlayerSelector.checked
    property alias cfg_showPinButton: showPinButton.checked
    property alias cfg_fullAlbumCoverRounded: fullAlbumCoverRounded.checked
    property alias cfg_fullAlbumCoverRadius: fullAlbumCoverRadius.value
    property alias cfg_fullViewContentPadding: fullViewContentPadding.value
    property alias cfg_fullViewContentPaddingVertical: fullViewContentPaddingVertical.value
    property alias cfg_fullViewContentSpacing: fullViewContentSpacing.value
    property alias cfg_fullViewMediaPadding: fullViewMediaPadding.value
    property alias cfg_fullViewMediaSpacing: fullViewMediaSpacing.value
    property alias cfg_fullViewLyricsAlignment: fullViewLyricsAlignment.value
    property alias cfg_fullViewLyricsFontSize: fullViewLyricsFontSize.value
    property alias cfg_fullViewLyricsLineSpacing: fullViewLyricsLineSpacing.value
    property alias cfg_fullViewLyricsAnimation: fullViewLyricsAnimation.currentIndex
    property alias cfg_fullViewLyricsIntermissionThreshold: fullViewLyricsIntermissionThreshold.value
    property alias cfg_fullViewPlaybackSectionActionsVisible: fullViewPlaybackSectionActionsVisible.checked
    property alias cfg_fullViewPlaybackScriptButtonEnabled: fullViewPlaybackScriptButtonEnabled.checked
    property alias cfg_fullViewPlaybackScriptPath: fullViewPlaybackScriptPath.text
    property alias cfg_hideCanBeRaisedTooltip: hideCanBeRaisedTooltip.checked

    Kirigami.FormLayout {
        id: form

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Media")
        }

        CheckBox {
            id: fullViewThumbnailVisible
            Kirigami.FormData.label: i18n("Show album cover")
        }

        CheckBox {
            id: fullViewAlbumCoverClickToRaise
            Kirigami.FormData.label: i18n("Click album cover to bring player to front")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Album placeholder:")

            Button {
                text: i18n("Choose…")
                icon.name: "settings-configure"
                onClicked: {
                    albumPlaceholderDialog.open()
                }
            }

            Button {
                text: i18n("Clear")
                icon.name: "edit-delete"
                visible: albumPlaceholderDialog.value
                onClicked: {
                    albumPlaceholderDialog.value = ""
                }
            }
        }

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: albumPlaceholderDialog.value
            Image {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                Layout.alignment: Qt.AlignHCenter
                source: albumPlaceholderDialog.value
            }
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Round album cover")
            id: fullAlbumCoverRounded
        }

        Slider {
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            enabled: fullAlbumCoverRounded.checked
            id: fullAlbumCoverRadius
            from: 2
            to: 26
            stepSize: 2
            Kirigami.FormData.label: i18n("Album cover radius:")
        }

        SpinBox {
            id: fullViewMediaPadding
            Kirigami.FormData.label: i18n("Album art and lyrics padding:")
            from: 0
            to: 100
            stepSize: 1
        }

        SpinBox {
            id: fullViewMediaSpacing
            Kirigami.FormData.label: i18n("Spacing between album art and lyrics:")
            from: 0
            to: 100
            stepSize: 1
        }

        CheckBox {
            id: fullViewLyricsVisible
            Kirigami.FormData.label: i18n("Show mini-lyrics")
        }

        ButtonGroup {
            id: fullViewLyricsAlignment
            property int value: Qt.AlignHCenter
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Mini-lyrics alignment:")
            text: i18n("Left")
            checked: fullViewLyricsAlignment.value === Qt.AlignLeft
            onCheckedChanged: {
                if (checked) fullViewLyricsAlignment.value = Qt.AlignLeft
            }
            ButtonGroup.group: fullViewLyricsAlignment
        }

        RadioButton {
            text: i18n("Center")
            checked: fullViewLyricsAlignment.value === Qt.AlignHCenter
            onCheckedChanged: {
                if (checked) fullViewLyricsAlignment.value = Qt.AlignHCenter
            }
            ButtonGroup.group: fullViewLyricsAlignment
        }

        RadioButton {
            text: i18n("Right")
            checked: fullViewLyricsAlignment.value === Qt.AlignRight
            onCheckedChanged: {
                if (checked) fullViewLyricsAlignment.value = Qt.AlignRight
            }
            ButtonGroup.group: fullViewLyricsAlignment
        }

        SpinBox {
            id: fullViewLyricsFontSize
            Kirigami.FormData.label: i18n("Mini-lyrics font size (0 = default):")
            from: 0
            to: 72
            stepSize: 1
        }

        Slider {
            id: fullViewLyricsLineSpacing
            Kirigami.FormData.label: i18n("Mini-lyrics line spacing:")
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            from: 1.0
            to: 2.5
            stepSize: 0.05
        }

        ComboBox {
            id: fullViewLyricsAnimation
            Kirigami.FormData.label: i18n("Mini-lyrics animation (experimental):")
            model: [
                i18n("None"),
                i18n("Glow sweep")
            ]
        }

        SpinBox {
            id: fullViewLyricsIntermissionThreshold
            Kirigami.FormData.label: i18n("Intermission threshold (seconds):")
            from: 1
            to: 30
            stepSize: 1
        }

        ButtonGroup {
            id: fullViewMediaPosition
            property int value: 0
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Album art and lyrics position:")
            text: i18n("Above playback section")
            checked: fullViewMediaPosition.value === 0
            onCheckedChanged: {
                if (checked) fullViewMediaPosition.value = 0
            }
            ButtonGroup.group: fullViewMediaPosition
        }

        RadioButton {
            text: i18n("Below playback section")
            checked: fullViewMediaPosition.value === 1
            onCheckedChanged: {
                if (checked) fullViewMediaPosition.value = 1
            }
            ButtonGroup.group: fullViewMediaPosition
        }

        ButtonGroup {
            id: fullViewMediaOrder
            property int value: 0
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Album art and lyrics order:")
            text: i18n("Album art first")
            checked: fullViewMediaOrder.value === 0
            onCheckedChanged: {
                if (checked) fullViewMediaOrder.value = 0
            }
            ButtonGroup.group: fullViewMediaOrder
        }

        RadioButton {
            text: i18n("Lyrics first")
            checked: fullViewMediaOrder.value === 1
            onCheckedChanged: {
                if (checked) fullViewMediaOrder.value = 1
            }
            ButtonGroup.group: fullViewMediaOrder
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Playback Section")
        }

        CheckBox {
            id: fullViewProgressBarVisible
            Kirigami.FormData.label: i18n("Show progress bar")
        }

        ButtonGroup {
            id: fullViewSongTextAlignment
            property int value: Qt.AlignHCenter
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Song text alignment:")
            text: i18n("Left")
            enabled: fullViewSongTextVisible.checked
            checked: fullViewSongTextAlignment.value == Qt.AlignLeft
            onCheckedChanged: () => {
                if (checked) {
                    fullViewSongTextAlignment.value = Qt.AlignLeft
                }
            }
            ButtonGroup.group: fullViewSongTextAlignment
        }

        RadioButton {
            text: i18n("Center")
            enabled: fullViewSongTextVisible.checked
            checked: fullViewSongTextAlignment.value == Qt.AlignHCenter
            onCheckedChanged: () => {
                if (checked) {
                    fullViewSongTextAlignment.value = Qt.AlignHCenter
                }
            }
            ButtonGroup.group: fullViewSongTextAlignment
        }

        RadioButton {
            text: i18n("Right")
            enabled: fullViewSongTextVisible.checked
            checked: fullViewSongTextAlignment.value == Qt.AlignRight
            onCheckedChanged: () => {
                if (checked) {
                    fullViewSongTextAlignment.value = Qt.AlignRight
                }
            }
            ButtonGroup.group: fullViewSongTextAlignment
        }

        CheckBox {
            id: fullViewSongTextVisible
            Kirigami.FormData.label: i18n("Show song text")
        }

        CheckBox {
            id: fullViewVolumeControlVisible
            Kirigami.FormData.label: i18n("Show volume control")
        }

        CheckBox {
            id: fullViewShuffleVisible
            Kirigami.FormData.label: i18n("Show shuffle control")
        }

        CheckBox {
            id: fullViewPlaybackControlsVisible
            Kirigami.FormData.label: i18n("Show playback controls")
        }

        CheckBox {
            id: fullViewLoopVisible
            Kirigami.FormData.label: i18n("Show loop control")
        }

        CheckBox {
            id: fullViewPlaybackSectionActionsVisible
            Kirigami.FormData.label: i18n("Show playback section actions")
        }

        CheckBox {
            id: fullViewPlaybackScriptButtonEnabled
            Kirigami.FormData.label: i18n("Show custom script button")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Custom script path:")

            TextField {
                id: fullViewPlaybackScriptPath
                Layout.preferredWidth: 20 * Kirigami.Units.gridUnit
                placeholderText: i18n("Path to an executable script")
            }

            Button {
                text: i18n("Browse…")
                icon.name: "document-open"
                onClicked: scriptPathDialog.open()
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Fill available space with playback controls")
            CheckBox {
                id: fullViewPlaybackControlsFillWidth
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n(
                    "When enabled, playback controls are spread across the full width of the widget. When disabled, they are grouped together in the center."
                )
            }
        }

        SpinBox {
            id: fullViewMinWidth
            Kirigami.FormData.label: i18n("Minimum resizable width:")
            from: 100
            to: fullViewMaxWidth.value
            stepSize: 10
        }

        SpinBox {
            id: fullViewMaxWidth
            Kirigami.FormData.label: i18n("Maximum resizable width:")
            from: fullViewMinWidth.value
            to: 2000
            stepSize: 10
        }

        SpinBox {
            id: fullViewMinHeight
            Kirigami.FormData.label: i18n("Minimum resizable height:")
            from: 100
            to: fullViewMaxHeight.value
            stepSize: 10
        }

        SpinBox {
            id: fullViewMaxHeight
            Kirigami.FormData.label: i18n("Maximum resizable height:")
            from: fullViewMinHeight.value
            to: 2000
            stepSize: 10
        }

        ColumnLayout {
            id: verticalOrderControl
            Kirigami.FormData.label: i18n("Playback section order:")
            spacing: Kirigami.Units.smallSpacing

            property string verticalOrderValue: ""

            ListModel {
                id: orderModel
            }

            property bool updatingModel: false

            function displayName(key) {
                switch (key) {
                case "song": return i18n("Song text");
                case "progress": return i18n("Progress bar");
                case "volume": return i18n("Volume control");
                case "controls": return i18n("Playback controls");
                }
                return key;
            }

            function rebuildModel() {
                updatingModel = true;
                orderModel.clear();
                const keys = (verticalOrderValue || "").split(",");
                for (let i = 0; i < keys.length; i++) {
                    if (keys[i] && keys[i] !== "lyrics") orderModel.append({key: keys[i]});
                }
                updatingModel = false;
            }

            function syncValue() {
                updatingModel = true;
                const arr = [];
                for (let i = 0; i < orderModel.count; i++) {
                    arr.push(orderModel.get(i).key);
                }
                verticalOrderValue = arr.join(",");
                updatingModel = false;
            }

            onVerticalOrderValueChanged: {
                if (!updatingModel) rebuildModel();
            }

            Component.onCompleted: rebuildModel()

            ListView {
                id: orderList
                Layout.preferredWidth: 20 * Kirigami.Units.gridUnit
                Layout.preferredHeight: contentHeight
                model: orderModel
                interactive: false
                delegate: RowLayout {
                    width: orderList.width
                    spacing: Kirigami.Units.smallSpacing
                    Label {
                        text: verticalOrderControl.displayName(model.key)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Button {
                        enabled: index > 0
                        flat: true
                        icon.name: "arrow-up"
                        icon.width: Kirigami.Units.iconSizes.small
                        icon.height: Kirigami.Units.iconSizes.small
                        onClicked: {
                            orderModel.move(index, index - 1, 1);
                            verticalOrderControl.syncValue();
                        }
                    }
                    Button {
                        enabled: index < orderModel.count - 1
                        flat: true
                        icon.name: "arrow-down"
                        icon.width: Kirigami.Units.iconSizes.small
                        icon.height: Kirigami.Units.iconSizes.small
                        onClicked: {
                            orderModel.move(index, index + 1, 1);
                            verticalOrderControl.syncValue();
                        }
                    }
                }
            }
        }

        RowLayout{
            Kirigami.FormData.label: i18n("Show media player selector")
            CheckBox {
                id: showPlayerSelector
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n(
                    "Disabled when a preferred player is selected under General > Playback Source. Only works when 'Choose automatically' is selected."
                )
            }
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Show pin (keep open) button")
            id: showPinButton
        }

        SpinBox {
            id: fullViewContentPadding
            Kirigami.FormData.label: i18n("Playback section side padding:")
            from: 0
            to: 50
            stepSize: 2
        }

        SpinBox {
            id: fullViewContentPaddingVertical
            Kirigami.FormData.label: i18n("Playback section vertical padding:")
            from: 0
            to: 50
            stepSize: 2
        }

        SpinBox {
            id: fullViewContentSpacing
            Kirigami.FormData.label: i18n("Vertical spacing in playback section:")
            from: 0
            to: 50
            stepSize: 1
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Song Text Customization")
        }

        // group for title

        ButtonGroup {
            id: fullTitlePosition
            property int value: SongAndArtistText.TextPosition.FirstLine
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Song title position:")
            text: i18n("Hidden")
            checked: fullTitlePosition.value == SongAndArtistText.TextPosition.Hidden
            onCheckedChanged: () => {
                if (checked) {
                    fullTitlePosition.value = SongAndArtistText.TextPosition.Hidden
                }
            }
            ButtonGroup.group: fullTitlePosition
        }

        RadioButton {
            text: i18n("First line")
            checked: fullTitlePosition.value == SongAndArtistText.TextPosition.FirstLine
            onCheckedChanged: () => {
                if (checked) {
                    fullTitlePosition.value = SongAndArtistText.TextPosition.FirstLine
                }
            }
            ButtonGroup.group: fullTitlePosition
        }

        RadioButton {
            text: i18n("Second line")
            checked: fullTitlePosition.value == SongAndArtistText.TextPosition.SecondLine
            onCheckedChanged: () => {
                if (checked) {
                    fullTitlePosition.value = SongAndArtistText.TextPosition.SecondLine
                }
            }
            ButtonGroup.group: fullTitlePosition
        }


        // group for artists

        Item {
            // adds spacing between the groups
            height: 0.5 * Kirigami.Units.gridUnit
        }

        ButtonGroup {
            id: fullArtistsPosition
            property int value: SongAndArtistText.TextPosition.SecondLine
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Artists position:")
            text: i18n("Hidden")
            checked: fullArtistsPosition.value == SongAndArtistText.TextPosition.Hidden
            onCheckedChanged: () => {
                if (checked) {
                    fullArtistsPosition.value = SongAndArtistText.TextPosition.Hidden
                }
            }
            ButtonGroup.group: fullArtistsPosition
        }

        RadioButton {
            text: i18n("First line")
            checked: fullArtistsPosition.value == SongAndArtistText.TextPosition.FirstLine
            onCheckedChanged: () => {
                if (checked) {
                    fullArtistsPosition.value = SongAndArtistText.TextPosition.FirstLine
                }
            }
            ButtonGroup.group: fullArtistsPosition
        }

        RadioButton {
            text: i18n("Second line")
            checked: fullArtistsPosition.value == SongAndArtistText.TextPosition.SecondLine
            onCheckedChanged: () => {
                if (checked) {
                    fullArtistsPosition.value = SongAndArtistText.TextPosition.SecondLine
                }
            }
            ButtonGroup.group: fullArtistsPosition
        }

        // group for album
        Item {
            // adds spacing between the groups
            height: 0.5 * Kirigami.Units.gridUnit
        }

        ButtonGroup {
            id: fullAlbumPosition
            property int value: SongAndArtistText.TextPosition.SecondLine
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Album title position:")
            text: i18n("Hidden")
            checked: fullAlbumPosition.value == SongAndArtistText.TextPosition.Hidden
            onCheckedChanged: () => {
                if (checked) {
                    fullAlbumPosition.value = SongAndArtistText.TextPosition.Hidden
                }
            }
            ButtonGroup.group: fullAlbumPosition
        }

        RadioButton {
            text: i18n("First line")
            checked: fullAlbumPosition.value == SongAndArtistText.TextPosition.FirstLine
            onCheckedChanged: () => {
                if (checked) {
                    fullAlbumPosition.value = SongAndArtistText.TextPosition.FirstLine
                }
            }
            ButtonGroup.group: fullAlbumPosition
        }

        RadioButton {
            text: i18n("Second line")
            checked: fullAlbumPosition.value == SongAndArtistText.TextPosition.SecondLine
            onCheckedChanged: () => {
                if (checked) {
                    fullAlbumPosition.value = SongAndArtistText.TextPosition.SecondLine
                }
            }
            ButtonGroup.group: fullAlbumPosition
        }

        RowLayout{
            Kirigami.FormData.label: i18n("Hide album name for singles:")
            CheckBox{
                id: fullHideAlbumForSingles
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n(
                    "If the album name and the track title match, the album name will be hidden."
                )
            }
        }

        Slider {
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            id: fullViewTextScrollingSpeed
            from: 1
            to: 10
            stepSize: 1
            Kirigami.FormData.label: i18n("Text scroll speed:")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Background")
        }

        ButtonGroup {
            id: desktopWidgetBackgroundRadio
            property int value: PlasmaCore.Types.StandardBackground
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background (desktop widget only):")
            RadioButton {
                text: i18n("Standard")
                checked: desktopWidgetBackgroundRadio.value == PlasmaCore.Types.StandardBackground
                onCheckedChanged: () => {
                    if (checked) {
                        desktopWidgetBackgroundRadio.value = PlasmaCore.Types.StandardBackground
                    }
                }
                ButtonGroup.group: desktopWidgetBackgroundRadio
            }
            Kirigami.ContextualHelpButton {
                toolTipText: (
                    "The standard background from the theme."
                )
            }
        }
        RadioButton {
            text: i18n("Transparent")
            checked: desktopWidgetBackgroundRadio.value == PlasmaCore.Types.NoBackground
            onCheckedChanged: () => {
                if (checked) {
                    desktopWidgetBackgroundRadio.value = PlasmaCore.Types.NoBackground
                }
            }
            ButtonGroup.group: desktopWidgetBackgroundRadio
        }
        RowLayout {
            RadioButton {
                text: i18n("Transparent (Shadow content)")
                checked: desktopWidgetBackgroundRadio.value == PlasmaCore.Types.ShadowBackground
                onCheckedChanged: () => {
                    if (checked) {
                        desktopWidgetBackgroundRadio.value = PlasmaCore.Types.ShadowBackground
                    }
                }
                ButtonGroup.group: desktopWidgetBackgroundRadio
            }
            Kirigami.ContextualHelpButton {
                toolTipText: (
                    "The applet won't have a background but a drop shadow of its content done via a shader. The text color will also invert."
                )
            }
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Use album cover as background")
            id: fullAlbumCoverAsBackground
            text: i18n("(Experimental feature)")
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Use album cover color as tinted background")
            id: fullAlbumCoverTintBackground
        }

        Slider {
            Layout.preferredWidth: 10 * Kirigami.Units.gridUnit
            enabled: fullAlbumCoverTintBackground.checked
            id: fullAlbumCoverTintOpacity
            from: 0.05
            to: 0.8
            stepSize: 0.05
            value: 0.2
            Kirigami.FormData.label: i18n("Background tint opacity:")
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Use album-derived gradient")
            enabled: fullAlbumCoverTintBackground.checked
            id: fullAlbumCoverTintGradient
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Use album-derived text color")
            enabled: fullAlbumCoverTintBackground.checked
            id: fullAlbumCoverTintUseContrastText
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Hover tooltip")
        }

        CheckBox{
            id: hideCanBeRaisedTooltip
            Kirigami.FormData.label: i18n("Hide album art tooltip")
        }
    }

    QtDialogs.FileDialog {
        id: albumPlaceholderDialog
        property var value: null
        onAccepted: value = selectedFile
    }

    QtDialogs.FileDialog {
        id: scriptPathDialog
        title: i18n("Choose a script")
        fileMode: QtDialogs.FileDialog.OpenFile
        onAccepted: {
            const url = String(selectedFile)
            fullViewPlaybackScriptPath.text = url.indexOf("file://") === 0
                ? decodeURIComponent(url.replace(/^file:\/\//, ""))
                : url
        }
    }
}
