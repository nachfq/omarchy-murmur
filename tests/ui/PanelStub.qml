import QtQuick

// Offscreen stand-in for the panel lifecycle, not a popup rendering test.
Item {
    property var bar: null
    property var anchorItem: null
    property var hostWidget: null
    property var mixer: null
    property bool opened: false
    property bool popoutSwitchClosing: false
    function open() { opened = true; }
    function close() { opened = false; }
    function toggle() { opened = !opened; }
    function closeForPopoutSwitch() { close(); }
}
