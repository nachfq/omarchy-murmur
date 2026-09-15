import QtQuick
import QtMultimedia

Item {
    id: root
    objectName: 'channel-' + soundId
    required property string soundId
    property real level: 0
    property bool requested: false
    property bool loaded: false
    property real gain: 0
    signal failed(string message)

    function fadeTo(value) {
        fade.stop();
        fade.to = value;
        fade.duration = Math.round(600 * Math.abs(value - gain));
        fade.start();
    }

    function stopVoice() {
        fade.stop();
        gain = 0;
        sound.stop();
        // Paused/muted recordings need no decoded sample buffers in memory.
        loaded = false;
    }

    function syncPlayback() {
        if (requested) {
            loaded = true;
            if (!sound.playing) sound.play();
            if (sound.status === SoundEffect.Ready) fadeTo(1);
        } else if (sound.status !== SoundEffect.Ready || gain === 0) {
            stopVoice();
        } else {
            fadeTo(0);
        }
    }

    onRequestedChanged: syncPlayback()
    Component.onDestruction: sound.stop()

    MediaDevices { id: devices }

    NumberAnimation {
        id: fade
        target: root
        property: 'gain'
        easing.type: Easing.InOutSine
        onFinished: if (!root.requested) root.stopVoice()
    }

    // Qt 6.11's PipeWire backend shares one mixer for SoundEffects with the
    // same device and PCM format. Individual voices retain their own gain.
    SoundEffect {
        id: sound
        objectName: root.soundId
        source: root.loaded ? Qt.resolvedUrl('assets/' + root.soundId + '.wav') : ''
        audioDevice: devices.defaultAudioOutput
        loops: SoundEffect.Infinite
        volume: root.level * root.gain
        // Keep steady-state drift interpolation inside Qt. The short playback
        // envelope already interpolates gain, so it needs no second animation.
        Behavior on volume {
            enabled: !fade.running
            NumberAnimation { duration: 100 }
        }
        onPlayingChanged: {
            if (playing && root.requested && status === SoundEffect.Ready) root.fadeTo(1);
        }
        onStatusChanged: {
            if (status === SoundEffect.Error) root.failed('Could not load recording');
            else if (status === SoundEffect.Ready) {
                root.failed('');
                if (root.requested) root.fadeTo(1);
                else root.stopVoice();
            }
        }
    }
}
