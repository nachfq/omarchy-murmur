import QtQuick
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
    property alias dragging: slider.dragging
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
            text: root.errorText ? '!' : Math.round(slider.liveValue * 100) + '%'
            color: root.bar ? root.bar.foreground : Color.foreground
            opacity: 0.6
            font.family: root.bar ? root.bar.fontFamily : root.fonts.family
            font.pixelSize: root.fonts.bodySmall
        }
    }

    Ui.PanelSlider {
        id: slider
        width: parent.width
        bar: root.bar
        value: root.value
        step: 0.02
        activeFocusOnTab: root.enabled
        onMoved: function(value) { root.edited(value); }
        onReleased: root.committed()

        function adjust(delta) {
            root.edited(Math.max(0, Math.min(1, value + delta)));
            root.committed();
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
