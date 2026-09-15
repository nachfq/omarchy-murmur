import QtQuick
import Quickshell

ShellRoot {
    id: root
    property int phase: -1
    readonly property var phases: ['empty', 'idle', 'rain', 'ten', 'randomize', 'paused']
    Loader { id: service; active: false; source: 'Service.qml' }
    function advance() {
        phase++;
        if (phase === phases.length) { Qt.quit(); return; }
        if (phase === 1) service.active = true;
        if (phase === 2) service.item.playing = true;
        if (phase === 3) for (var i = 0; i < 10; i++) service.item.setLevel(i, .5);
        if (phase === 4) service.item.toggleRandomize();
        if (phase === 5) service.item.playing = false;
        warmup.restart();
    }
    Timer {
        id: warmup
        interval: 3000
        onTriggered: {
            if (root.phase >= 2 && root.phase <= 4) {
                var voices = service.item.children.filter(function(c) { return c.soundId !== undefined && c.requested; });
                if (voices.length !== (root.phase === 2 ? 1 : 10)
                    || voices.some(function(c) { return !c.loaded || (c.gain !== undefined && c.gain < .99); })) {
                    console.error('Benchmark playback did not settle');
                    Qt.quit();
                    return;
                }
            }
            console.log('YURAGI_BENCH_BEGIN ' + root.phases[root.phase]);
            sample.restart();
        }
    }
    Timer {
        id: sample
        interval: Number(Quickshell.env('YURAGI_BENCH_SECONDS') || 15) * 1000
        onTriggered: { console.log('YURAGI_BENCH_END ' + root.phases[root.phase]); next.restart(); }
    }
    Timer { id: next; interval: 100; onTriggered: root.advance() }
    Component.onCompleted: advance()
}
