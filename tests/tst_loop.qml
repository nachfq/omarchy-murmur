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
        player.audioOutput.device = devices.audioOutputs.filter(function(d) { return d.description === 'MurmurTest'; })[0];
        var wraps = 0;
        var previous = 0;
        player.positionChanged.connect(function() {
            if (player.position < previous - 1000) wraps++;
            previous = player.position;
        });
        audio.requested = true;
        tryCompare(player, 'playbackState', MediaPlayer.PlayingState, 5000);
        wait(64000);
        compare(player.playbackState, MediaPlayer.PlayingState);
        verify(wraps >= 2, 'The real Qt player must cross two loop boundaries');
        audio.requested = false;
    }
}
