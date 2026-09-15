import QtQuick
import QtQuick.Controls as Controls
import qs.Ui as Ui
import qs.Commons

Column {
    id: root
    property var bar: null
    readonly property var fonts: Style.font
    property string label: ''
    property string icon: ''
    property real value: 0
    property string errorText: ''
    property alias dragging: slider.pressed
    property alias focusItem: slider
    signal edited(real value)
    signal committed()
    spacing: Style.space(3)
    opacity: enabled ? 1 : 0.5

    Row {
        width: parent.width
        spacing: Style.space(6)
        Text {
            id: glyph
            visible: root.icon !== ''
            text: root.icon
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : root.fonts.family
            font.pixelSize: root.fonts.body
        }
        Text {
            width: parent.width - percent.width - (glyph.visible ? glyph.width + parent.spacing : 0) - parent.spacing
            text: root.label
            elide: Text.ElideRight
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : root.fonts.family
            font.pixelSize: root.fonts.body
        }
        Text {
            id: percent
            width: Style.space(36)
            horizontalAlignment: Text.AlignRight
            text: root.errorText ? '!' : Math.round(slider.value * 100) + '%'
            color: root.bar ? root.bar.foreground : Color.foreground
            opacity: 0.6
            font.family: root.bar ? root.bar.fontFamily : root.fonts.family
            font.pixelSize: root.fonts.bodySmall
        }
    }

    Controls.Slider {
        id: slider
        width: parent.width
        implicitHeight: appearance.implicitHeight
        padding: 0
        from: 0
        to: 1
        value: root.value
        stepSize: 0
        live: true
        focusPolicy: Qt.StrongFocus
        activeFocusOnTab: root.enabled
        // Qt owns pointer grabs, cancellation, touch and keyboard focus.
        // Omarchy's PanelSlider supplies only the themed drawing.
        onMoved: root.edited(value)
        onPressedChanged: if (!pressed) root.committed()
        handle: null
        background: Ui.PanelSlider {
            id: appearance
            enabled: false
            bar: root.bar
            liveValue: slider.visualPosition
            dragging: slider.pressed
        }

        function adjust(delta) {
            root.edited(Math.max(0, Math.min(1, value + delta)));
            root.committed();
        }
        WheelHandler {
            target: null
            enabled: slider.activeFocus
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(event) {
                if (event.angleDelta.y === 0) { event.accepted = false; return; }
                slider.adjust(0.02 * event.angleDelta.y / 120);
                event.accepted = true;
            }
        }
        Keys.onLeftPressed: adjust(-0.02)
        Keys.onDownPressed: adjust(-0.02)
        Keys.onRightPressed: adjust(0.02)
        Keys.onUpPressed: adjust(0.02)
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                root.edited(event.key === Qt.Key_Home ? 0 : 1);
                root.committed();
                event.accepted = true;
            }
        }
        Accessible.role: Accessible.Slider
        Accessible.name: root.label
        Accessible.description: root.errorText || Math.round(value * 100) + '%'
        Accessible.onIncreaseAction: adjust(0.02)
        Accessible.onDecreaseAction: adjust(-0.02)

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            color: 'transparent'
            border.width: slider.activeFocus ? 1 : 0
            border.color: root.bar ? root.bar.foreground : Color.foreground
            radius: Style.cornerRadius
        }
    }
    Text {
        visible: root.errorText !== ''
        width: parent.width
        text: 'Audio unavailable'
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : root.fonts.family
        font.pixelSize: root.fonts.caption
        wrapMode: Text.WordWrap
    }
}
