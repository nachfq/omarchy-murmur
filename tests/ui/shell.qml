pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import Quickshell
import qs.Ui as Ui

// Runs inside an isolated Quickshell window with the actual Omarchy UI files.
ShellRoot {
    id: root
    property var mixer: null
    Component { id: service; Service {} }
    QtObject {
        id: fakeShell
        property var barConfig: ({layout: {center: [{id: 'nachfq.murmur'}]}})
        property var writes: []
        function serviceFor(id) { return root.mixer; }
        function updateEntryInline(id, settings) {
            var entry = Object.assign({id: id}, settings);
            writes = writes.concat([JSON.parse(JSON.stringify(entry))]);
            barConfig = {layout: {center: [entry]}};
            return true;
        }
    }
    Ui.PluginBarApi {
        id: fakeBar
        pluginId: 'nachfq.murmur'
        moduleName: 'nachfq.murmur'
        shell: fakeShell
        barSize: 32
        foreground: '#eeeeee'
        barForeground: '#eeeeee'
        fontFamily: 'monospace'
    }
    FloatingWindow {
        implicitWidth: 500
        implicitHeight: 500
        visible: true
        BarWidget {
            id: barWidget
            bar: fakeBar
            y: 460
            width: implicitWidth
            height: implicitHeight
            z: 1
        }
        Flickable {
            id: flick
            anchors.fill: parent
            contentHeight: 850
            interactive: true
            Column {
                VolumeControl {
                    id: master
                    width: 440
                    label: 'Master'
                    value: root.mixer ? root.mixer.master : 0
                    onEdited: function(value) { root.mixer.setMaster(value); }
                    onDraggingChanged: if (root.mixer) root.mixer.holdMaster(dragging)
                    onCommitted: if (root.mixer) root.mixer.scheduleSave()
                }
                Grid {
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 14
                    Repeater {
                        id: controls
                        model: 10
                        VolumeControl {
                            required property int index
                            readonly property var channel: root.mixer ? root.mixer.channels[index] : null
                            width: 200
                            label: channel ? channel.name : ''
                            value: channel ? channel.current : 0
                            onEdited: function(value) { root.mixer.setLevel(index, value); }
                            onDraggingChanged: if (root.mixer) root.mixer.hold(index, dragging)
                            onCommitted: if (root.mixer) root.mixer.scheduleSave()
                        }
                    }
                }
            }
        }
        TestCase {
            name: 'MurmurGestures'
            when: true
            // Quickshell does not initialize qmltestrunner's logger. Export
            // QtTest's real counters so a failed gesture fails the runner.
            onCompletedChanged: if (completed)
                console.log('MURMUR_UI_RESULT ' + JSON.stringify({passed: qtest_results.passCount, failed: qtest_results.failCount}))
            function equal(actual, expected) {
                if (typeof actual === 'number' && typeof expected === 'number') {
                    if (Math.abs(actual - expected) > 0.000001)
                        console.warn('UI mismatch: ' + actual + ' expected ' + expected);
                    fuzzyCompare(actual, expected, 0.000001);
                } else {
                    if (actual !== expected) console.warn('UI mismatch: ' + actual + ' expected ' + expected);
                    compare(actual, expected);
                }
            }
            function init() {
                fakeShell.barConfig = {layout: {center: [{id: 'nachfq.murmur'}]}};
                fakeShell.writes = [];
                root.mixer = createTemporaryObject(service, flick, {shell: fakeShell});
                // These tests exercise input and model behavior. Audio has its
                // own native integration suite; do not open any output here.
                root.mixer.children.forEach(function(c) { if (c.soundId !== undefined) c.requested = false; });
                flick.contentY = 0;
                controls.itemAt(0).enabled = true;
                wait(50);
            }
            function cleanup() {
                console.log('MURMUR_UI_CASE ' + qtest_results.functionName + ' failed=' + qtest_results.failed);
                root.mixer.playing = false;
                master.dragging = false;
                for (var i = 0; i < 10; i++) controls.itemAt(i).dragging = false;
                root.mixer = null;
            }
            function test_allChannelsIndependent() {
                for (var i = 0; i < 10; i++) {
                    var s = controls.itemAt(i).focusItem;
                    var before = root.mixer.channels.map(c => c.base);
                    mousePress(s, 20, s.height / 2);
                    for (var x = 30; x <= 170; x += 20) {
                        mouseMove(s, x, s.height / 2, 5);
                        equal(controls.itemAt(i).value, x / 200);
                        equal(s.background.liveValue, x / 200);
                    }
                    mouseRelease(s, 170, s.height / 2);
                    equal(controls.itemAt(i).value, .85);
                    equal(s.background.liveValue, .85);
                    for (var j = 0; j < 10; j++) if (j !== i) equal(root.mixer.channels[j].base, before[j]);
                }
            }
            function test_crossingAnotherSliderKeepsGrab() {
                var a = controls.itemAt(0).focusItem, b = controls.itemAt(1).focusItem;
                mousePress(a, 30, a.height / 2);
                mouseMove(b, 90, b.height / 2, 30);
                equal(controls.itemAt(1).value, 0);
                mouseRelease(b, 90, b.height / 2);
                equal(controls.itemAt(0).value, 1);
                mouseClick(b, 100, b.height / 2);
                equal(controls.itemAt(1).value, .5);
                equal(controls.itemAt(0).value, 1);
            }
            function test_cancelThenHoverCannotEdit() {
                var c = controls.itemAt(0), s = c.focusItem;
                mousePress(s, 40, s.height / 2);
                mouseMove(s, 70, s.height / 2, 20);
                c.enabled = false;
                mouseRelease(s, 70, s.height / 2);
                c.enabled = true;
                var before = c.value;
                equal(c.dragging, false);
                equal(root.mixer.editing, false);
                mouseMove(s, 170, s.height / 2, 20);
                equal(c.value, before);
            }
            function test_scrollInterruptionReleasesGesture() {
                var c = controls.itemAt(0), s = c.focusItem;
                mousePress(s, 30, s.height / 2);
                mouseMove(s, 35, -45, 30);
                mouseMove(s, 35, -95, 30);
                mouseRelease(s, 35, -95);
                verify(!root.mixer.editing);
                verify(!c.dragging);
                var before = c.value;
                mouseMove(s, 160, s.height / 2, 20);
                equal(c.value, before);
            }
            function test_oldSettingsCannotRewindGesture() {
                var c = controls.itemAt(0), s = c.focusItem;
                mouseClick(s, 60, s.height / 2);
                wait(300);
                var old = fakeShell.writes[0];
                mouseClick(s, 80, s.height / 2);
                wait(300);
                mousePress(s, 90, s.height / 2);
                mouseMove(s, 170, s.height / 2, 20);
                fakeShell.barConfig = {layout: {center: [old]}};
                equal(c.value, .85);
                equal(s.background.liveValue, .85);
                verify(root.mixer.channels[0].held);
                mouseRelease(s, 170, s.height / 2);
                wait(300);
                fakeShell.barConfig = {layout: {center: [old]}};
                equal(c.value, .85);
                equal(fakeShell.writes[fakeShell.writes.length - 1].volumes.rain, .85);
            }
            function test_noWritesDuringMasterOrChannelDrag() {
                for (var i = 0; i < 2; i++) {
                    var s = i === 0 ? master.focusItem : controls.itemAt(0).focusItem;
                    var count = fakeShell.writes.length;
                    mousePress(s, s.width * .3, s.height / 2);
                    mouseMove(s, s.width * .7, s.height / 2, 20);
                    wait(350);
                    equal(fakeShell.writes.length, count);
                    mouseRelease(s, s.width * .7, s.height / 2);
                    wait(300);
                    equal(fakeShell.writes.length, count + 1);
                }
            }
            function test_keyboardFollowsClickedSlider() {
                var c = controls.itemAt(1), s = c.focusItem;
                mouseClick(s, 100, s.height / 2);
                verify(s.activeFocus);
                keyClick(Qt.Key_Right);
                equal(c.value, .52);
                equal(master.value, .5);
                mouseWheel(s, 100, s.height / 2, 0, 120);
                equal(c.value, .54);
                keyClick(Qt.Key_End);
                equal(c.value, 1);
                keyClick(Qt.Key_Home);
                equal(c.value, 0);
            }
            function test_randomCannotFightHeldSlider() {
                root.mixer.setLevel(1, .5);
                root.mixer.toggleRandomize();
                root.mixer.playing = true;
                var c = controls.itemAt(0), s = c.focusItem;
                mousePress(s, 160, s.height / 2);
                wait(500);
                equal(c.value, .8);
                equal(s.background.liveValue, .8);
                equal(root.mixer.channels[1].base, .5);
                mouseRelease(s, 160, s.height / 2);
                root.mixer.playing = false;
                equal(c.value, .8);
            }
            function test_zBarRevealAndPause() {
                equal(barWidget.width, 0);
                fakeBar.centerSectionRevealHeld = true;
                verify(barWidget.width > 0);
                var button = barWidget.children.find(function(c) { return c.activeText !== undefined; });
                tryCompare(button, 'opacity', .45);
                mouseClick(button, button.width / 2, button.height / 2);
                verify(barWidget.opened);
                fakeBar.centerSectionRevealHeld = false;
                verify(barWidget.width > 0);
                root.mixer.playing = true;
                tryCompare(button, 'opacity', 1);
                root.mixer.playing = false;
                verify(barWidget.width > 0); // Pause must not move the open panel's anchor.
                barWidget.close();
                equal(barWidget.width, 0);
                fakeBar.centerSectionRevealHeld = true;
                mouseClick(button, button.width / 2, button.height / 2);
                verify(barWidget.opened); // Paused controls remain reachable.
                barWidget.close();
                fakeBar._centerHoverRevealSuppressed = true;
                equal(barWidget.width, 0);
                fakeBar._centerHoverRevealSuppressed = false;
                fakeBar.centerSectionRevealHeld = false;
                root.mixer.playing = true;
                verify(barWidget.width > 0);
                root.mixer.playing = false;
                fakeBar.vertical = true;
                equal(barWidget.height, 0);
                fakeBar.centerSectionRevealHeld = true;
                verify(barWidget.height > 0);
                fakeBar.vertical = false;
                fakeBar.centerSectionRevealHeld = false;
            }
        }
    }
}
