import QtQuick
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: 'nachfq.yuragi'
    readonly property var hostBar: bar
    readonly property var mixer: hostBar && hostBar.shell ? hostBar.shell.serviceFor(moduleName) : null
    readonly property bool opened: panel.opened
    readonly property bool popoutSwitchClosing: panel.popoutSwitchClosing
    readonly property real openPanelIndicatorWidth: button.glyphPaintedWidth

    function open() { panel.open(); }
    function close() { panel.close(); }
    function closeForPopoutSwitch() { panel.closeForPopoutSwitch(); }

    implicitWidth: !vertical && button.concealed ? 0 : button.implicitWidth
    implicitHeight: vertical && button.concealed ? 0 : button.implicitHeight

    // Use the public bar reveal state and Omarchy's own indicator drawing.
    // Keeping an open panel's anchor visible also makes Pause stable.
    QtObject {
        id: revealState
        readonly property bool revealInactiveIndicators: root.opened || (root.hostBar
            && root.hostBar.centerSectionRevealHeld && !root.hostBar.centerHoverRevealSuppressed)
    }

    Ui.BarIndicator {
        id: button
        anchors.fill: parent
        bar: root.bar
        indicatorHost: revealState
        activeText: '󰖚'
        active: !!root.mixer && root.mixer.playing
        activeTooltipText: 'Yuragi · Playing'
        inactiveTooltipText: 'Yuragi · Paused'
        onPressed: function(mouseButton) {
            if (mouseButton === Qt.LeftButton) panel.toggle();
        }
        Accessible.role: Accessible.Button
        Accessible.name: 'Yuragi'
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
