import QtQuick
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: 'nachfq.murmur'
    readonly property var hostBar: bar
    readonly property var mixer: hostBar && hostBar.shell ? hostBar.shell.serviceFor(moduleName) : null
    readonly property bool opened: panel.opened
    readonly property bool popoutSwitchClosing: panel.popoutSwitchClosing
    readonly property real openPanelIndicatorWidth: button.labelWidth

    function open() { panel.open(); }
    function close() { panel.close(); }
    function closeForPopoutSwitch() { panel.closeForPopoutSwitch(); }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    Ui.WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: '󰖚'
        dimmed: !root.mixer || !root.mixer.playing
        tooltipText: root.mixer && root.mixer.playing ? 'Murmur · Playing' : 'Murmur · Paused'
        onPressed: function(mouseButton) {
            if (mouseButton === Qt.LeftButton) panel.toggle();
        }
        Accessible.role: Accessible.Button
        Accessible.name: 'Murmur'
        Accessible.description: tooltipText
        Accessible.onPressAction: panel.toggle()
    }

    Panel {
        id: panel
        bar: root.bar
        anchorItem: button
        hostWidget: root
        mixer: root.mixer
    }
}
