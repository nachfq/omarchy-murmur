pragma ComponentBehavior: Bound
import QtQuick
import qs.Ui as Ui
import qs.Commons

Ui.Panel {
    id: root
    moduleName: 'nachfq.murmur'
    manageIpc: false
    property Item anchorItem: null
    property var hostWidget: null
    property var mixer: null

    function close() {
        masterControl.dragging = false;
        for (var i = 0; i < soundControls.count; i++) {
            var control = soundControls.itemAt(i);
            if (control) control.dragging = false;
        }
        if (mixer) mixer.saveNow();
        controller.hide();
    }

    Ui.KeyboardPanel {
        id: popup
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: masterControl.focusItem
        contentWidth: popup.fittedContentWidth(Style.space(440))
        contentHeight: popup.fittedContentHeight(content.implicitHeight)

        FocusScope {
            anchors.fill: parent
            Keys.onEscapePressed: root.close()

            Flickable {
                anchors.fill: parent
                clip: true
                contentHeight: content.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: content
                    width: parent.width
                    spacing: Style.space(18)
                    enabled: root.mixer !== null

                    VolumeControl {
                        id: masterControl
                        width: parent.width
                        bar: root.bar
                        label: 'Master'
                        value: root.mixer ? root.mixer.master : 0
                        onEdited: function(value) { if (root.mixer) root.mixer.setMaster(value); }
                        onCommitted: if (root.mixer) root.mixer.scheduleSave()
                        onDraggingChanged: if (root.mixer) root.mixer.holdMaster(dragging)
                    }

                    Ui.PanelSeparator { width: parent.width }

                    Grid {
                        id: soundGrid
                        width: parent.width
                        columns: width < Style.space(300) ? 1 : 2
                        columnSpacing: Style.space(24)
                        rowSpacing: Style.space(14)
                        Repeater {
                            id: soundControls
                            model: 10
                            VolumeControl {
                                required property int index
                                readonly property var channel: root.mixer ? root.mixer.channels[index] : null
                                width: (soundGrid.width - soundGrid.columnSpacing * (soundGrid.columns - 1)) / soundGrid.columns
                                bar: root.bar
                                label: channel ? channel.name : ''
                                icon: channel ? channel.icon : ''
                                value: channel ? channel.current : 0
                                errorText: channel && root.mixer ? root.mixer.errors[channel.id] || '' : ''
                                enabled: errorText === ''
                                onEdited: function(value) { if (root.mixer) root.mixer.setLevel(index, value); }
                                onCommitted: if (root.mixer) root.mixer.scheduleSave()
                                onDraggingChanged: if (root.mixer) root.mixer.hold(index, dragging)
                            }
                        }
                    }

                    Ui.PanelSeparator { width: parent.width }

                    Row {
                        width: parent.width
                        spacing: Style.space(12)
                        Ui.Button {
                            width: (parent.width - parent.spacing) / 2
                            text: root.mixer && root.mixer.playing ? 'Pause' : 'Play'
                            iconText: root.mixer && root.mixer.playing ? '󰏤' : '󰐊'
                            focusable: true
                            bordered: true
                            // Hover and keyboard focus use the native outline;
                            // a filled background is reserved for a toggle's On state.
                            color: 'transparent'
                            enabled: root.mixer && root.mixer.canPlay
                            opacity: enabled ? 1 : 0.5
                            onClicked: root.mixer.togglePlayback()
                            Accessible.role: Accessible.Button
                            Accessible.name: text
                            Accessible.onPressAction: if (enabled) clicked()
                        }
                        Ui.Button {
                            width: (parent.width - parent.spacing) / 2
                            text: selected ? 'Randomize: On' : 'Randomize: Off'
                            iconText: '󰒟'
                            focusable: true
                            bordered: true
                            selected: root.mixer ? root.mixer.randomize : false
                            color: selected ? Style.selectedFillFor(foreground, accent) : 'transparent'
                            tooltipText: selected ? (root.mixer && root.mixer.playing ? 'Gentle volume drift is on' : 'Volume drift is on — press Play to start') : 'Gently vary active sounds'
                            onClicked: root.mixer.toggleRandomize()
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: 'Randomize'
                            Accessible.checkable: true
                            Accessible.checked: selected
                            Accessible.onToggleAction: clicked()
                        }
                    }
                }
            }
        }
    }
}
