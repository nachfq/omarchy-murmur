const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { test } = require('node:test');
const model = vm.createContext({});
vm.runInContext(fs.readFileSync(require('node:path').join(__dirname, '../Model.js'), 'utf8'), model);
const plain = value => JSON.parse(JSON.stringify(value));
const channel = level => model.channels(model.preferences({volumes: {rain: level}}))[0];

test('fresh mix has ten channels, only rain selected, master 50%, drift off', () => {
    const p = model.preferences({});
    assert.equal(p.master, 0.5);
    assert.equal(p.randomize, false);
    assert.equal(Object.keys(p.volumes).length, 10);
    assert.equal(p.volumes.rain, 0.4);
    assert.equal(Object.values(p.volumes).filter(v => v > 0).length, 1);
});

test('restore validates untrusted settings and ignores unknown channels', () => {
    const p = model.preferences({master: Infinity, randomize: 'true', volumes: {rain: -2, thunder: 8, waves: '0.5', aliens: 1}});
    assert.equal(p.master, 0.5);
    assert.equal(p.randomize, false);
    assert.equal(p.volumes.rain, 0);
    assert.equal(p.volumes.thunder, 1);
    assert.equal(p.volumes.waves, 0);
    assert.equal(p.volumes.aliens, undefined);
});

test('random targets are within ±25% of base, capped at full volume', () => {
    for (const level of [0.001, 0.4, 0.9, 1]) {
        for (const randomValue of [0, 0.25, 0.5, 0.999999]) {
            const c = channel(level);
            model.advance(c, 0, true, () => randomValue);
            assert.ok(c.target >= level * 0.75 && c.target <= Math.min(1, level * 1.25));
            assert.ok(c.duration >= 15 && c.duration <= 30);
            assert.equal(c.current, level);
        }
    }
});

test('random drift remains bounded and smooth over one simulated hour', () => {
    const c = channel(0.4);
    let seed = 7;
    const rng = () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;
    for (let n = 0; n < 36000; n++) {
        const before = c.current;
        model.advance(c, 0.1, true, rng);
        assert.ok(c.current >= 0.3 - 1e-9 && c.current <= 0.5);
        assert.ok(Math.abs(c.current - before) < 0.003);
    }
});

test('zero and held channels never consume random numbers or move', () => {
    for (const c of [channel(0), Object.assign(channel(0.5), {held: true})]) {
        const before = plain(c);
        model.advance(c, 20, true, () => { throw new Error('must not sample'); });
        assert.deepEqual(plain(c), before);
    }
});

test('manual adjustment replaces base and transition; zero stays excluded', () => {
    const c = channel(0.5);
    model.advance(c, 10, true, () => 1);
    model.setLevel(c, 0.2);
    assert.equal(c.base, 0.2);
    assert.equal(c.current, 0.2);
    assert.equal(c.duration, 0);
    model.setLevel(c, 0);
    model.advance(c, 30, true, () => 1);
    assert.equal(c.current, 0);
});

test('switching randomize off returns gently to base and settles', () => {
    const c = channel(0.5);
    model.advance(c, 30, true, () => 1);
    assert.equal(c.current, 0.625);
    model.returnToBase(c, true);
    model.advance(c, 0.3, false, () => { throw new Error('randomize is off'); });
    assert.ok(c.current > 0.5 && c.current < 0.625);
    model.advance(c, 0.3, false, () => 0);
    assert.equal(c.current, 0.5);
    assert.equal(c.duration, 0);
});

test('turning drift off while paused settles without needing a timer', () => {
    const c = channel(0.5);
    model.advance(c, 20, true, () => 0);
    model.returnToBase(c, false);
    assert.equal(c.current, c.base);
    assert.equal(c.duration, 0);
});

test('persistence stores base preferences, never automatic gains or playing state', () => {
    const items = model.channels(model.preferences({}));
    model.advance(items[0], 20, true, () => 0);
    const snapshot = plain(model.snapshot(0.25, items, true));
    assert.equal(snapshot.volumes.rain, 0.4);
    assert.equal(snapshot.master, 0.25);
    assert.equal(snapshot.randomize, true);
    assert.deepEqual(Object.keys(snapshot).sort(), ['master', 'randomize', 'volumes']);
    assert.deepEqual(plain(model.preferences(snapshot)), snapshot);
});
