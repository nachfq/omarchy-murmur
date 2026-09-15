#!/usr/bin/env python3
"""Record the real service: muting a voice must not silence/restart another."""
import argparse,array,json,math,os,shutil,subprocess,sys,tempfile,time,wave
from pathlib import Path
assert os.getenv('YURAGI_PRIVATE_AUDIO')=='1'
root=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=root)
args=parser.parse_args()
out=root/'artifacts/mute';out.mkdir(parents=True,exist_ok=True)
module=subprocess.check_output(['pactl','load-module','module-null-sink','sink_name=yuragi-continuity'],text=True).strip()
subprocess.run(['pactl','set-default-sink','yuragi-continuity'],check=True)
q=rec=None
try:
 with tempfile.TemporaryDirectory(prefix='yuragi-mute-') as tmp:
    tmp=Path(tmp);(tmp/'assets').mkdir()
    for name in ['Service.qml','AudioChannel.qml','Model.js']:shutil.copy2(args.source/name,tmp/name)
    for name,amp in [('rain',.05),('thunder',.005)]:
        pcm=array.array('h',(int(32767*amp*math.sin(2*math.pi*((300*t+20*t*t) if name=='rain' else 100*t))) for i in range(48000*15) for t in [i/48000]))
        if sys.byteorder != 'little': pcm.byteswap()
        with wave.open(str(tmp/'assets'/f'{name}.wav'),'wb') as w:w.setparams((1,2,48000,0,'NONE','not compressed'));w.writeframes(pcm.tobytes())
    (tmp/'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot {
 Service { id: m }
 property int phase: 0
 Timer { interval: 3000; running: true; repeat: true; onTriggered: {
   if (phase === 0) { m.setMaster(1); m.setLevel(0,1); m.setLevel(1,1); m.togglePlayback(); }
   else if (phase === 1 || phase === 3) m.setLevel(1,0);
   else if (phase === 2) m.setLevel(1,1);
   else Qt.quit();
   console.log("PHASE", phase++);
 } }
}''')
    rec=subprocess.Popen(['ffmpeg','-y','-v','error','-f','pulse','-i','yuragi-continuity.monitor','-ac','1','-ar','48000','-t','16',str(out/'capture.wav')])
    time.sleep(.3)
    with (out/'probe.log').open('w') as log:q=subprocess.Popen(['quickshell','-p',str(tmp),'--no-color'],stdout=log,stderr=subprocess.STDOUT);assert q.wait(timeout=25)==0
    assert rec.wait(timeout=10)==0
    data=subprocess.check_output(['ffmpeg','-v','error','-i',str(out/'capture.wav'),'-af','highpass=f=250','-f','f32le','-'])
    samples=array.array('f',data)
    if sys.byteorder != 'little': samples.byteswap()
    active=next(i for i,x in enumerate(samples) if abs(x)>.001)
    result=[]
    for k in range(2,23):
        start=active+int(k*.5*48000);chunk=samples[start:start+12000]
        crossings=sum(a<=0<b for a,b in zip(chunk,chunk[1:]));frequency=crossings/.25
        result.append({'seconds':k*.5,'hz':frequency,'peak':max(map(abs,chunk))})
    start=active+48000; end=active+int(11.5*48000)
    assert end <= len(samples), 'Capture ended before continuity checks'
    longest=run=0
    for value in samples[start:end]:
        run=run+1 if abs(value)<.0001 else 0
        longest=max(longest,run)
    report={'longest_gap_ms':longest/48, 'windows':result}
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    assert report['longest_gap_ms'] < 20, report
    for row in result:
        # The reference chirp rises by 40 Hz/s. A restarted voice would return
        # to 300 Hz; a silenced voice has no zero crossings. Allow timing jitter.
        expected=300+40*(row['seconds']+.125)
        assert abs(row['hz']-expected)<20, (row,expected)
    print(f"Mute/re-enable twice: continuous reference, no restart; longest near-silent run {longest/48:.2f} ms")
finally:
    for p in [q,rec]:
        if p and p.poll() is None:p.terminate();p.wait()
    subprocess.run(['pactl','unload-module',module],check=True)
