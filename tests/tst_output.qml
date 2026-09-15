import QtQuick
import QtTest
import QtMultimedia
import '..' as Murmur

TestCase {
    id: tests
    name: 'MurmurOutput'
    when: windowShown
    MediaDevices { id: devices }
    Murmur.Service { id: mixer }

    function phase(name) {
        // Give the native stream time to connect before the runner counts it.
        wait(300);
        console.log('MURMUR_OUTPUT_' + name);
        wait(3000);
    }

    function test_oneStreamAndDeviceChange() {
        tryCompare(devices.defaultAudioOutput, 'description', 'MurmurOutputA');
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
        console.log('MURMUR_OUTPUT_SWITCH');
        tryVerify(function() { return devices.defaultAudioOutput.description === 'MurmurOutputB'; });
        phase('SWITCHED');
        mixer.playing = false;
    }
}
