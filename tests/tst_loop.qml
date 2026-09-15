import QtQuick
import QtTest
import QtMultimedia
import '..' as Murmur

TestCase {
    id: tests
    name: 'MurmurLoop'
    when: windowShown
    MediaDevices { id: devices }
    Component { id: channel; Murmur.AudioChannel { soundId: 'noise'; level: 1 } }

    function test_twoRealLoopBoundaries() {
        var audio = createTemporaryObject(channel, tests);
        var player = findChild(audio, 'noise');
        verify(player !== null);
        tryVerify(function() { return devices.audioOutputs.some(function(d) { return d.description === 'MurmurTest'; }); });
        player.audioDevice = devices.audioOutputs.filter(function(d) { return d.description === 'MurmurTest'; })[0];
        audio.requested = true;
        tryCompare(player, 'playing', true, 5000);
        wait(64000);
        compare(player.playing, true);
        // The monitor capture verifies continuity across the two 29.75s boundaries.
        compare(player.loops, SoundEffect.Infinite);
        audio.requested = false;
    }
}
