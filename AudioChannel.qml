import QtQuick
import QtMultimedia

Item {
    id: root
    objectName: 'channel-' + soundId
    required property string soundId
    property real level: 0
    property bool requested: false
    property bool loaded: false
    signal failed(string message)

    function syncPlayback() {
        if (requested) {
            loaded = true;
            sound.play();
        } else {
            // SoundEffect stops its voice; Play starts the recording again.
            sound.stop();
        }
    }

    onRequestedChanged: syncPlayback()
    Component.onDestruction: sound.stop()

    MediaDevices { id: devices }

    // Qt 6.11's PipeWire backend shares one mixer for SoundEffects with the
    // same device and PCM format. Individual voices retain their own gain.
    SoundEffect {
        id: sound
        objectName: root.soundId
        source: root.loaded ? Qt.resolvedUrl('assets/' + root.soundId + '.wav') : ''
        audioDevice: devices.defaultAudioOutput
        loops: SoundEffect.Infinite
        volume: root.level
        Behavior on volume { NumberAnimation { duration: 100 } }
        onStatusChanged: {
            if (status === SoundEffect.Error) root.failed('Could not load recording');
            else if (status === SoundEffect.Ready) root.failed('');
        }
    }
}
