// Pure mixer state. Used by QML and the deterministic Node test harness.
var ids = ['rain', 'thunder', 'waves', 'wind', 'fire', 'birds', 'crickets', 'coffee', 'bowl', 'noise'];
var names = ['Rain', 'Thunder', 'Waves', 'Wind', 'Fire', 'Birds', 'Crickets', 'Coffee shop', 'Singing bowl', 'White noise'];
// Nerd Fonts Material Design; bird, bowl-outline and waveform identify the last sounds.
var icons = ['󰖗', '󰖓', '󰖚', '󰖝', '󰈸', '󱗆', '󰃤', '󰅶', '󰊩', '󱑽'];

function volume(value, fallback) {
    return typeof value === 'number' && isFinite(value) ? Math.max(0, Math.min(1, value)) : fallback;
}

function preferences(settings) {
    settings = settings || {};
    var levels = {};
    for (var i = 0; i < ids.length; i++)
        levels[ids[i]] = volume(settings.volumes && settings.volumes[ids[i]], i === 0 ? 0.4 : 0);
    return { master: volume(settings.master, 0.5), volumes: levels, randomize: settings.randomize === true };
}

function channels(prefs) {
    return ids.map(function(id, i) {
        var base = prefs.volumes[id];
        return { id: id, name: names[i], icon: icons[i], base: base, current: base,
            from: base, target: base, elapsed: 0, duration: 0, held: false };
    });
}

function setLevel(channel, value) {
    channel.base = volume(value, channel.base);
    channel.current = channel.base;
    channel.from = channel.base;
    channel.target = channel.base;
    channel.elapsed = 0;
    channel.duration = 0;
}

function returnToBase(channel, playing) {
    channel.from = channel.current;
    channel.target = channel.base;
    channel.elapsed = 0;
    channel.duration = playing && channel.current !== channel.base ? 0.6 : 0;
    if (!channel.duration) channel.current = channel.base;
}

function advance(channel, dt, randomize, random) {
    if (channel.held || channel.base === 0) return;
    if (channel.duration === 0) {
        if (!randomize) return;
        channel.from = channel.current;
        channel.target = volume(channel.base * (0.75 + random() * 0.5), channel.base);
        channel.duration = 15 + random() * 15;
        channel.elapsed = 0;
    }
    channel.elapsed = Math.min(channel.duration, channel.elapsed + dt);
    var t = channel.elapsed / channel.duration;
    var smooth = t * t * (3 - 2 * t);
    channel.current = channel.from + (channel.target - channel.from) * smooth;
    if (channel.elapsed >= channel.duration) {
        channel.current = channel.target;
        channel.duration = 0;
    }
}

function snapshot(master, items, randomize) {
    var levels = {};
    items.forEach(function(c) { levels[c.id] = c.base; });
    return { master: master, volumes: levels, randomize: randomize };
}
