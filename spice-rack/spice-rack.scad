width = 381;
depth = 276.9;
top_height = 152.4;
jar_diameter = 48;
jar_height = 100;
rows = 4;

wall = 0.84;
tread = 1.2;
hook = 4;
curb = 5;
clearance = 0.25;
bed = 180;
nest = [6, 8];
gap = 3;
explode = 0;
part = "assembly";

tiers = rows - 1;
pitch = depth / rows;
rise = top_height / tiers;
segments = ceil(width / (bed - 10));
segment = width / segments;
bracket = 2 * wall + 2 * clearance;

function y(k) = k * pitch;
function z(k) = k * rise;
function back(k) = k == tiers ? y(k + 1) : y(k + 1) - wall - clearance;
function usable(k) = back(k) - wall - y(k);

assert(usable(1) >= jar_diameter + 2 * clearance, "tread too shallow for the jar");
assert(rise > hook + tread + 2 * wall + 2 * clearance + bracket, "rise too small for the hook");
assert(segment <= bed - 10, "segment longer than the print height");

module rect(y0, y1, z0, z1) translate([y0, z0]) square([y1 - y0, z1 - z0]);

module catch(k) {
    face = y(k) - wall;
    floor_top = z(k - 1) - tread - hook;
    rect(face - bracket, face, floor_top - wall, floor_top);
    rect(face - bracket, face - bracket + wall, floor_top - wall, z(k - 1) - tread - clearance);
    polygon([[face, floor_top - wall], [face - bracket, floor_top - wall], [face, floor_top - wall - bracket]]);
}

module profile(k) {
    rect(y(k) - wall, y(k), 0, z(k));
    rect(y(k) - wall, back(k), z(k) - tread, z(k));
    if (k > 1) catch(k);
    if (k < tiers) {
        rect(back(k) - wall, back(k), z(k) - tread - hook, z(k));
    } else {
        rect(back(k) - wall, back(k), 0, z(k) + curb);
        rect(y(k) - wall, back(k), 0, wall);
    }
}

function left(k) = y(k) - wall - (k > 1 ? bracket : 0);
function extent(k) = [back(k) - left(k), z(k) + (k == tiers ? curb : 0)];

module piece(k, length) linear_extrude(length) translate([-left(k), 0]) profile(k);

function seams(k) = k % 2 == 0
    ? concat([0], [for (i = [0 : segments - 1]) (i + 0.5) * segment], [width])
    : [for (i = [0 : segments]) i * segment];

module tier(k) {
    s = seams(k);
    for (i = [0 : len(s) - 2])
        translate([s[i] + i * explode, left(k), 0]) rotate([90, 0, 90])
            piece(k, s[i + 1] - s[i] - (i < len(s) - 2 ? clearance : 0));
}

module rack() for (k = [1 : tiers]) tier(k);

module jar() {
    color([0.85, 0.9, 0.95]) cylinder(d = jar_diameter, h = jar_height * 0.82, $fn = 48);
    color("dimgray") translate([0, 0, jar_height * 0.82]) cylinder(d = jar_diameter * 0.9, h = jar_height * 0.18, $fn = 48);
    color("firebrick") translate([0, 0, jar_height * 0.3]) cylinder(d = jar_diameter + 0.6, h = jar_height * 0.4, $fn = 48);
}

module jars() {
    n = floor(width / (jar_diameter + 4));
    step = width / n;
    for (r = [0 : tiers], i = [0 : n - 1]) {
        y0 = r == 0 ? 0 : y(r);
        y1 = r == 0 ? y(1) - wall : back(r) - wall;
        translate([(i + 0.5) * step, (y0 + y1) / 2, z(r)]) jar();
    }
}

full = segment - clearance;
half = segment / 2 - clearance;

module stack(k, lengths) {
    n = len(lengths);
    for (i = [0 : n - 1]) translate([(n - 1 - i) * nest[0], i * nest[1], 0]) piece(k, lengths[i]);
}

module standing(length) {
    e = extent(1);
    translate([e[1], 0, 0]) rotate([0, 0, 90]) piece(1, length);
}

module tube_with(count) {
    piece(tiers, full);
    e = extent(1);
    inner = [y(tiers + 1) - wall - y(tiers), z(tiers) - tread - wall];
    spacing = (inner[1] - count * e[0]) / (count + 1);
    assert(e[1] + 2 * gap <= inner[0] && spacing >= gap, "tier 1 does not fit inside the top tier");
    if (count > 0) for (j = [0 : count - 1])
        translate([y(tiers) - left(tiers) + (inner[0] - e[1]) / 2, wall + spacing + j * (e[0] + spacing), 0]) standing(full);
}

module plate(n) {
    t = extent(tiers);
    s = extent(2) + 3 * nest;
    w = n == 1 ? 2 * t[0] + gap : t[0] + gap + s[0];
    h = max(t[1], s[1]);
    assert(w <= bed && h <= bed, "plate overflows the bed");
    translate([-w / 2, -h / 2, 0]) {
        tube_with(n == 1 ? 2 : 1);
        translate([t[0] + gap, 0, 0])
            if (n == 1) tube_with(0); else stack(2, [full, full, half, half]);
    }
}

if (part == "assembly") rack();
if (part == "scene") { color("burlywood") rack(); jars(); }
if (part == "split") for (k = [1 : tiers]) color(k % 2 == 0 ? "peru" : "burlywood") tier(k);
if (part == "tier1") piece(1, full);
if (part == "tier2") piece(2, full);
if (part == "tier2_end") piece(2, half);
if (part == "tier3") piece(3, full);
if (part == "plate_1") plate(1);
if (part == "plate_2") plate(2);
