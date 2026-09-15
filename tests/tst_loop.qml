import QtQuick
import QtTest
import QtMultimedia
import '..' as Yuragi

TestCase {
    id: tests
    name: 'YuragiLoop'
    when: windowShown
    MediaDevices { id: devices }
    Component { id: channel; Yuragi.AudioChannel { soundId: 'noise'; level: 1 } }

    function test_twoRealLoopBoundaries() {
        var audio = createTemporaryObject(channel, tests);
        var player = findChild(audio, 'noise');
        verify(player !== null);
        tryVerify(function() { return devices.audioOutputs.some(function(d) { return d.description === 'YuragiTest'; }); });
        player.audioDevice = devices.audioOutputs.filter(function(d) { return d.description === 'YuragiTest'; })[0];
        audio.requested = true;
        tryCompare(player, 'playing', true, 5000);
        wait(64000);
        compare(player.playing, true);
        // The monitor capture verifies continuity across the two 29.75s boundaries.
        compare(player.loops, SoundEffect.Infinite);
        audio.requested = false;
    }
}
