import QtQuick
import QtTest
import QtMultimedia
import '..' as Murmur

TestCase {
    id: tests
    name: 'MurmurService'
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
        property var barConfig: ({layout: {center: [{id: 'nachfq.murmur'}]}})
        property int writes: 0
        function updateEntryInline(id, settings) {
            compare(id, 'nachfq.murmur');
            writes++;
            barConfig = {layout: {center: [Object.assign({id: id}, settings)]}};
            return true;
        }
    }

    Component { id: service; Murmur.Service {} }
    Component { id: badAudio; Murmur.AudioChannel { soundId: 'missing-test-file' } }

    function playerFor(id) {
        return findChild(findChild(mixer, 'channel-' + id), id);
    }

    function init() {
        fakeShell.barConfig = {layout: {center: [{id: 'nachfq.murmur'}]}};
        fakeShell.writes = 0;
        mixer = createTemporaryObject(service, tests, {shell: fakeShell});
        verify(mixer !== null);
        tryVerify(function() { return devices.audioOutputs.some(function(d) { return d.description === 'MurmurTest'; }); });
        var output = devices.audioOutputs.filter(function(d) { return d.description === 'MurmurTest'; })[0];
        for (var i = 0; i < 10; i++) playerFor(mixer.channels[i].id).audioOutput.device = output;
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
        tryCompare(playerFor('rain'), 'playbackState', MediaPlayer.PlayingState);
        mixer.setLevel(0, 0.8);
        compare(view.value, 0.8);
        tryCompare(playerFor('rain').audioOutput, 'volume', mixer.master * 0.8);
        mixer.setLevel(1, 0.6);
        tryCompare(playerFor('thunder'), 'playbackState', MediaPlayer.PlayingState);
        mixer.setLevel(1, 0);
        tryCompare(playerFor('thunder'), 'playbackState', MediaPlayer.StoppedState);
        verify(mixer.playing);
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
        tryVerify(function() { return Math.abs(playerFor('rain').audioOutput.volume - mixer.master * held) < 0.0001; });
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
            tryCompare(player, 'playbackState', MediaPlayer.PlayingState, 15000);
            compare(player.loops, MediaPlayer.Infinite);
        }
        compare(Object.keys(mixer.errors).length, 0);
        mixer.toggleRandomize();
        verify(mixer.animating);
        wait(500);
        // Seek well into the recording so restarting from zero cannot pass
        // the resume assertion merely by playing for a few milliseconds.
        playerFor('rain').position = 10000;
        wait(100);
        mixer.togglePlayback();
        verify(!mixer.animating);
        var held = mixer.channels[0].current;
        wait(250);
        compare(mixer.channels[0].current, held);
        for (var k = 0; k < 10; k++)
            tryCompare(playerFor(mixer.channels[k].id), 'playbackState', MediaPlayer.StoppedState);
        var savedPosition = findChild(mixer, 'channel-rain').resumePosition;
        verify(savedPosition >= 10000);
        mixer.togglePlayback();
        tryVerify(function() {
            var rain = playerFor('rain');
            return rain.playbackState === MediaPlayer.PlayingState && rain.position >= savedPosition;
        }, 1000);
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
}
