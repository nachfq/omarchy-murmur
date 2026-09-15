import QtQuick
import QtTest
import QtMultimedia
import '..' as Yuragi

TestCase {
    id: tests
    name: 'YuragiOutput'
    when: windowShown
    MediaDevices { id: devices }
    Yuragi.Service { id: mixer }

    function phase(name) {
        // Give the native stream time to connect before the runner counts it.
        wait(300);
        console.log('YURAGI_OUTPUT_' + name);
        wait(3000);
    }

    function test_oneStreamAndDeviceChange() {
        tryCompare(devices.defaultAudioOutput, 'description', 'YuragiOutputA');
        for (var i = 0; i < 10; i++) mixer.setLevel(i, 0.5);
        mixer.togglePlayback();
        phase('TEN');
        mixer.toggleRandomize();
        phase('DRIFT');
        for (var j = 0; j < 9; j++) mixer.setLevel(j, 0);
        phase('ONE');
        mixer.togglePlayback();
        phase('PAUSED');
        mixer.togglePlayback();
        phase('RESUMED');
        // The runner changes its private server's default and removes A.
        console.log('YURAGI_OUTPUT_SWITCH');
        tryVerify(function() { return devices.defaultAudioOutput.description === 'YuragiOutputB'; });
        phase('SWITCHED');
        mixer.playing = false;
    }
}
