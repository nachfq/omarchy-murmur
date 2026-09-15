pragma ComponentBehavior: Bound
import QtQuick
import "Model.js" as Model

// One instance is owned by the shell, shared by every bar/monitor.
Item {
    id: root
    property var shell: null
    property var channels: Model.channels(Model.preferences({}))
    property real master: 0.5
    property bool randomize: false
    property bool playing: false
    property var errors: ({})
    property var sourceSettings: ({})
    property string savedState: ""
    readonly property bool canPlay: channels.some(function(c) { return c.base > 0 && !root.errors[c.id]; })
    readonly property bool settling: channels.some(function(c) { return c.duration > 0; })
    readonly property bool animating: drift.running

    function loadSettings(values) {
        sourceSettings = values || {};
        var prefs = Model.preferences(values);
        var encoded = JSON.stringify(prefs);
        if (encoded === savedState) return;
        savedState = encoded;
        master = prefs.master;
        randomize = prefs.randomize;
        channels = Model.channels(prefs);
    }

    function readSettings() {
        var layout = shell && shell.barConfig ? shell.barConfig.layout : null;
        if (!layout) return;
        var sections = ['left', 'center', 'right'];
        for (var s = 0; s < sections.length; s++) {
            var entries = layout[sections[s]] || [];
            for (var i = 0; i < entries.length; i++) {
                if (entries[i].id === 'nachfq.murmur') {
                    loadSettings(entries[i]);
                    return;
                }
            }
        }
    }

    function saveNow() {
        saveTimer.stop();
        var prefs = Model.snapshot(master, channels, randomize);
        var encoded = JSON.stringify(prefs);
        if (encoded === savedState || !shell) return;
        var entry = Object.assign({}, sourceSettings, prefs);
        savedState = encoded;
        shell.updateEntryInline('nachfq.murmur', entry);
    }

    function setMaster(value) {
        master = Model.volume(value, master);
        saveTimer.restart();
    }

    function setLevel(index, value) {
        if (index < 0 || index >= channels.length) return;
        Model.setLevel(channels[index], value);
        channels = channels.slice();
        saveTimer.restart();
    }

    function hold(index, held) {
        if (index < 0 || index >= channels.length) return;
        channels[index].held = held;
        channels = channels.slice();
        if (!held) saveNow();
    }

    function togglePlayback() {
        if (playing) playing = false;
        else if (canPlay) playing = true;
    }

    function toggleRandomize() {
        randomize = !randomize;
        channels.forEach(function(c) {
            if (!root.randomize) Model.returnToBase(c, root.playing);
            else c.duration = 0;
        });
        channels = channels.slice();
        saveNow();
    }

    function reportError(id, message) {
        var next = Object.assign({}, errors);
        if (message) next[id] = message;
        else delete next[id];
        errors = next;
    }

    onCanPlayChanged: if (!canPlay) playing = false
    onShellChanged: readSettings()

    Connections {
        target: root.shell
        function onBarConfigChanged() { root.readSettings(); }
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.saveNow()
    }

    Timer {
        id: drift
        interval: 100
        repeat: true
        running: root.playing && root.canPlay && (root.randomize || root.settling)
        onTriggered: {
            root.channels.forEach(function(c) {
                if (!root.errors[c.id]) Model.advance(c, interval / 1000, root.randomize, Math.random);
            });
            root.channels = root.channels.slice();
        }
    }

    Repeater {
        model: Model.ids.length
        AudioChannel {
            required property int index
            readonly property var channel: root.channels[index]
            soundId: channel.id
            level: root.master * channel.current
            requested: root.playing && channel.base > 0
            onFailed: function(message) { root.reportError(soundId, message); }
        }
    }
}
