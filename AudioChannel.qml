import QtQuick
import QtMultimedia

Item {
    id: root
    objectName: 'channel-' + soundId
    required property string soundId
    property real level: 0
    property bool requested: false
    property bool loaded: false
    property int resumePosition: 0
    property bool seekPending: false
    signal failed(string message)

    function syncPlayback() {
        if (requested) {
            loaded = true;
            seekPending = !player.seekable;
            if (!seekPending) player.position = resumePosition;
            player.play();
        } else if (player.playbackState !== MediaPlayer.StoppedState) {
            // Qt's paused FFmpeg players retain active decoder threads.
            // Stop releases them; keep the position for the next Play.
            resumePosition = player.position;
            player.stop();
        }
    }

    onRequestedChanged: syncPlayback()
    Component.onDestruction: player.stop()

    MediaDevices { id: devices }

    MediaPlayer {
        id: player
        objectName: root.soundId
        source: root.loaded ? Qt.resolvedUrl('assets/' + root.soundId + '.ogg') : ''
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            device: devices.defaultAudioOutput
            volume: root.level
            // Small ramps avoid abrupt user-volume changes and interpolate
            // the 10 Hz random targets without a busy JS animation loop.
            Behavior on volume { NumberAnimation { duration: 100 } }
        }
        onErrorOccurred: function(error, errorString) { root.failed(errorString); }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                root.failed('');
                if (root.requested && root.seekPending) {
                    player.position = root.resumePosition;
                    root.seekPending = false;
                }
            }
        }
    }
}
