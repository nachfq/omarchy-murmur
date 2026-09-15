import QtQuick
import QtTest
import QtMultimedia
import '..' as Yuragi

TestCase {
    id: tests
    name: 'YuragiService'
    when: windowShown
    property var mixer: null
    MediaDevices { id: devices }
    // Same binding chain as a slider/audio delegate: mutating a JS object
    // without replacing it leaves this value stale even if the array changes.
    QtObject {
        id: view
        readonly property var channel: tests.mixer ? tests.mixer.channels[0] : null
        readonly property real value: channel ? channel.current : 0
    }

    QtObject {
        id: fakeShell
        property var barConfig: ({layout: {center: [{id: 'nachfq.yuragi'}]}})
        property int writes: 0
        function updateEntryInline(id, settings) {
            compare(id, 'nachfq.yuragi');
            writes++;
            barConfig = {layout: {center: [Object.assign({id: id}, settings)]}};
            return true;
        }
    }

    Component { id: service; Yuragi.Service {} }
    Component { id: badAudio; Yuragi.AudioChannel { soundId: 'missing-test-file' } }

    function playerFor(id) {
        return findChild(findChild(mixer, 'channel-' + id), id);
    }

    function init() {
        fakeShell.barConfig = {layout: {center: [{id: 'nachfq.yuragi'}]}};
        fakeShell.writes = 0;
        mixer = createTemporaryObject(service, tests, {shell: fakeShell});
        verify(mixer !== null);
        tryVerify(function() { return devices.audioOutputs.some(function(d) { return d.description === 'YuragiTest'; }); });
        var output = devices.audioOutputs.filter(function(d) { return d.description === 'YuragiTest'; })[0];
        for (var i = 0; i < 10; i++) playerFor(mixer.channels[i].id).audioDevice = output;
    }

    function cleanup() {
        mixer.playing = false;
        mixer.saveNow();
    }

    function test_initialAndPersistence() {
        compare(mixer.playing, false);
        compare(mixer.master, 0.5);
        compare(mixer.channels[0].base, 0.4);
        mixer.setMaster(0.3);
        mixer.setLevel(1, 0.2);
        mixer.saveNow();
        compare(fakeShell.writes, 1);
        var other = createTemporaryObject(service, tests, {shell: fakeShell});
        compare(other.master, 0.3);
        compare(other.channels[1].base, 0.2);
        compare(other.playing, false);
        compare(other.animating, false);
    }

    function test_editWhilePlayingUpdatesBindingsAndAudio() {
        mixer.togglePlayback();
        tryCompare(playerFor('rain'), 'playing', true);
        mixer.setLevel(0, 0.8);
        compare(view.value, 0.8);
        tryCompare(playerFor('rain'), 'volume', mixer.master * 0.8);
        mixer.setLevel(1, 0.6);
        tryCompare(playerFor('thunder'), 'playing', true);
        mixer.setLevel(1, 0);
        tryCompare(playerFor('thunder'), 'playing', false);
        verify(mixer.playing);
    }

    function test_mutingDoesNotRestartOtherChannels() {
        mixer.setLevel(1, 0.6);
        mixer.togglePlayback();
        var rain = playerFor('rain');
        var voice = findChild(mixer, 'channel-rain');
        tryCompare(voice, 'gain', 1);
        tryCompare(playerFor('thunder'), 'playing', true);
        var events = [];
        var changed = function() { events.push(rain.playing); };
        rain.playingChanged.connect(changed);
        mixer.setLevel(1, 0);
        wait(1200);
        verify(rain.playing);
        compare(voice.gain, 1);
        compare(events.length, 0, JSON.stringify(events));
        mixer.setLevel(1, 0.6);
        wait(1200);
        compare(events.length, 0, JSON.stringify(events));
        rain.playingChanged.disconnect(changed);
    }

    function test_randomUpdatesBindingsAndAudio() {
        mixer.togglePlayback();
        mixer.toggleRandomize();
        var initial = view.value;
        // Fix this transition's target so the regression does not depend on
        // Math.random happening to choose a noticeable change.
        var next = mixer.channels.slice();
        next[0] = Object.assign({}, next[0], {from: initial, target: 0.2, elapsed: 0, duration: 2});
        mixer.channels = next;
        tryVerify(function() { return Math.abs(view.value - initial) > 0.000001; }, 5000);
        compare(view.value, mixer.channels[0].current);
        compare(findChild(mixer, 'channel-rain').level, mixer.master * view.value);
        mixer.hold(0, true);
        var held = view.value;
        wait(300);
        compare(view.value, held);
        tryVerify(function() { return Math.abs(playerFor('rain').volume - mixer.master * held) < 0.0001; });
        mixer.setLevel(0, 0.7);
        compare(view.value, 0.7);
        mixer.hold(0, false);
        wait(300);
        mixer.toggleRandomize();
        tryCompare(view, 'value', 0.7);
    }

    function test_allChannelsAndPause() {
        for (var i = 0; i < 10; i++) mixer.setLevel(i, 0.5);
        mixer.togglePlayback();
        for (var j = 0; j < 10; j++) {
            var player = playerFor(mixer.channels[j].id);
            verify(player !== null);
            tryCompare(player, 'playing', true, 15000);
            compare(player.loops, SoundEffect.Infinite);
        }
        compare(Object.keys(mixer.errors).length, 0);
        mixer.toggleRandomize();
        verify(mixer.animating);
        wait(500);
        mixer.togglePlayback();
        verify(!mixer.animating);
        var held = mixer.channels[0].current;
        wait(250);
        compare(mixer.channels[0].current, held);
        for (var k = 0; k < 10; k++)
            tryCompare(playerFor(mixer.channels[k].id), 'playing', false);
        mixer.togglePlayback();
        // SoundEffect deliberately restarts each recording on resume.
        for (var n = 0; n < 10; n++)
            tryCompare(playerFor(mixer.channels[n].id), 'playing', true);
    }

    function test_randomDoesNotWriteAndMutedStaysOff() {
        mixer.toggleRandomize();
        mixer.togglePlayback();
        var writes = fakeShell.writes;
        wait(1200);
        compare(fakeShell.writes, writes);
        compare(mixer.channels[1].current, 0);
        verify(!playerFor('thunder').source.toString());
        mixer.setLevel(0, 0);
        verify(!mixer.playing);
        verify(!mixer.animating);
        tryVerify(function() { return !playerFor('rain').source.toString(); });
        mixer.setLevel(1, 0.4); // First positive level after an empty mix starts it.
        tryCompare(playerFor('thunder'), 'playing', true);
        verify(mixer.playing);
        mixer.togglePlayback(); // Manual pause of a nonempty mix is respected.
        mixer.setLevel(0, 0.4);
        wait(800);
        verify(!mixer.playing);
        verify(!playerFor('rain').playing);
        verify(!playerFor('thunder').playing);
    }

    function test_restoringSettingsDoesNotAutoplay() {
        var zero = {};
        for (var i = 0; i < mixer.channels.length; i++) zero[mixer.channels[i].id] = 0;
        mixer.loadSettings({volumes: zero});
        verify(!mixer.playing);
        verify(!mixer.canPlay);
        zero.rain = 0.5;
        mixer.loadSettings({volumes: zero});
        wait(200);
        verify(mixer.canPlay);
        verify(!mixer.playing);
    }

    function test_errorIsolation() {
        mixer.setLevel(1, 0.3);
        mixer.reportError('rain', 'test failure');
        verify(mixer.canPlay);
        compare(mixer.errors.rain, 'test failure');
        mixer.setLevel(1, 0);
        verify(!mixer.canPlay);
        mixer.reportError('rain', '');
        verify(mixer.canPlay);
        var bad = createTemporaryObject(badAudio, tests);
        var message = '';
        bad.failed.connect(function(error) { message = error; });
        bad.requested = true;
        tryVerify(function() { return message.length > 0; }, 5000);
        bad.requested = false;
    }

    function test_fadesReverseAndReleaseSamples() {
        var voice = findChild(mixer, 'channel-rain');
        var player = playerFor('rain');
        mixer.togglePlayback();
        tryCompare(player, 'status', SoundEffect.Ready);
        tryVerify(function() { return voice.gain > 0 && voice.gain < 1; });
        tryCompare(voice, 'gain', 1);
        var base = mixer.channels[0].base;
        mixer.togglePlayback();
        verify(player.playing); // Audio stays alive while the button says Play.
        wait(200);
        verify(voice.gain > 0 && voice.gain < 1);
        var partial = voice.gain;
        mixer.togglePlayback();
        compare(voice.gain, partial); // Reversal must not jump or restart at zero.
        tryCompare(voice, 'gain', 1);
        verify(player.playing);
        mixer.togglePlayback();
        tryCompare(player, 'playing', false);
        compare(voice.gain, 0);
        compare(voice.loaded, false);
        compare(player.source.toString(), '');
        compare(mixer.channels[0].base, base);
        mixer.togglePlayback();
        mixer.togglePlayback(); // Cancel even while a recording is loading.
        wait(800);
        verify(!player.playing);
        compare(voice.gain, 0);
        verify(!voice.loaded);
    }
}
