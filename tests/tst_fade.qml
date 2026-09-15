import QtQuick
import QtTest
import QtMultimedia
import '..' as Yuragi

TestCase {
    name: 'YuragiFade'
    when: windowShown
    MediaDevices { id: devices }
    Yuragi.AudioChannel { id: voice; soundId: 'noise'; level: 1 }
    function test_recordedFade() {
        tryVerify(function() { return devices.audioOutputs.some(function(d) { return d.description === 'YuragiFade'; }); });
        findChild(voice, 'noise').audioDevice = devices.audioOutputs.filter(function(d) { return d.description === 'YuragiFade'; })[0];
        wait(1000); // Allow the independent monitor recorder to connect.
        voice.requested = true;
        tryCompare(findChild(voice, 'noise'), 'status', SoundEffect.Ready);
        wait(2000);
        voice.requested = false;
        wait(1500);
        verify(!findChild(voice, 'noise').playing);
    }
}
