height = 120;
nozzle = 0.4;
pane_z = 0.4;
tracery_z = 1.6;
rim_z = 0.8;
came_z = 0.6;
came_width = 2 * nozzle;
min_cell = height / 40;
bed = 180;
gap = 3;
plates = [[0, 1, 2, 3], [4, 5, 6, 7]];
part = "leading_a";

$fa = 4;
$fs = 0.8;

unit = height / 120;
width = 0.44 * height;
rim_width = 3 * unit;
bar = 1.8 * unit;
min_solid = 1.2 * nozzle;
inner_w = width - 2 * rim_width;
outer_k = (inner_w + rim_width) / width;
function rise(w, k = 1) = w * sqrt(k - 0.25);
spring = height - rim_width - rise(width, outer_k);
inner_h = spring + rise(inner_w);
function oculus(w) = sqrt(5) / 4 * w;
stilt = 0.42 * inner_w;
quarry = 9 * unit;
far = 4 * height;

assert(bar >= 2 * nozzle, "tracery bars thinner than two nozzle lines");
assert(len([for (p = plates) if (len(p) != len(plates[0])) p]) == 0, "plates hold different numbers of windows");
assert(len([for (p = plates, w = p) if (!is_num(w) || w != floor(w) || w < 0 || w > 7) w]) == 0, "windows are numbered 0 to 7");

module lancet(w, h, k = 1) {
    r = k * w;
    intersection() {
        translate([-w / 2, 0]) square([w, h]);
        union() {
            translate([-w / 2, 0]) square([w, h - rise(w, k)]);
            translate([0, h - rise(w, k)]) intersection_for (s = [-1, 1]) translate([s * (r - w / 2), 0]) circle(r);
        }
    }
}

module stroke(w) difference() {
    offset(delta = w / 2) children();
    offset(delta = -w / 2) children();
}

module foil_light(n, r) {
    d = r / (1 + 1.15 * sin(180 / n));
    circle(d * cos(180 / n));
    for (i = [0 : n - 1]) rotate(90 + i * 360 / n) translate([d, 0]) circle(r - d);
}

module roundel(n, r) {
    if (n == 0) stroke(bar) circle(r);
    else difference() {
        circle(r + bar / 2);
        foil_light(n, r - bar / 2);
    }
}

module trefoil_light(w, y) {
    r = 0.34 * w;
    translate([-w / 2, -far]) square([w, far + y]);
    for (s = [-1, 1]) translate([s * (w / 2 - r), y]) circle(r);
    translate([0, y + 0.5 * w]) circle(0.42 * w);
}

module cinquefoil_light(w, y) {
    r = 0.2 * w;
    translate([-w / 2, -far]) square([w, far + y]);
    translate([0, y - far]) offset(delta = -0.12 * w) lancet(w, far + rise(w));
    for (s = [-1, 1], a = [2, 24]) translate([s * (w / 2 - (w - r) * cos(a)), y + (w - r) * sin(a)]) circle(r);
    translate([0, y + 0.585 * w]) circle(0.29 * w);
}

module cusped(w, h, k = 1, foils = 3) {
    assert(foils == 3 || foils == 5, "a light's head has three or five foils");
    difference() {
        offset(delta = bar / 2) lancet(w, h, k);
        intersection() {
            offset(delta = -bar / 2) lancet(w, h, k);
            if (foils == 3) trefoil_light(w - bar, h - rise(w, k));
            else cinquefoil_light(w - bar, h - rise(w, k));
        }
    }
}

module geometric(w, y, foils) {
    for (s = [-1, 1]) translate([s * w / 4, 0]) {
        if (len(foils) > 1) {
            stroke(bar) lancet(w / 2, y + rise(w / 2));
            geometric(w / 2, y, [for (i = [1 : len(foils) - 1]) foils[i]]);
        } else cusped(w / 2, y + rise(w / 2));
    }
    translate([0, y + oculus(w)]) roundel(foils[0], w / 4);
}

module triplet() {
    w = inner_w / 3;
    for (s = [-1, 1]) translate([s * w, 0]) cusped(w, spring + rise(w));
    cusped(w, spring + stilt + rise(w));
    for (s = [-1, 1]) translate([s * 0.275 * inner_w, spring + 0.45 * inner_w]) roundel(0, 0.1 * inner_w);
}

module intersecting(n) for (j = [1 : n - 1]) {
    x = (j / n - 0.5) * inner_w;
    translate([x - bar / 2, 0]) square([bar, spring]);
    intersection() {
        translate([-inner_w, spring]) square([2 * inner_w, inner_h]);
        for (s = [-1, 1]) translate([x + s * inner_w, spring]) stroke(bar) circle(inner_w);
    }
}

rose_y = spring + 0.25 * inner_w;
rose_r = inner_w - sqrt(inner_w * inner_w / 4 + pow(rose_y - spring, 2));
rose_sill = rose_y - sqrt(rose_r * rose_r - inner_w * inner_w / 16) - bar / 2;

module rose(n) {
    hub = 0.28 * rose_r;
    a = 180 / n;
    translate([0, rose_y]) difference() {
        circle(rose_r + bar / 2);
        circle(hub - bar / 2);
        for (i = [0 : n - 1]) rotate(90 + i * 2 * a) hull() {
            translate([hub / (1 - sin(a)), 0]) circle(hub * sin(a) / (1 - sin(a)) - bar / 2);
            translate([rose_r / (1 + sin(a)), 0]) circle(rose_r * sin(a) / (1 + sin(a)) - bar / 2);
        }
    }
    for (s = [-1, 1]) translate([s * inner_w / 4, 0]) cusped(inner_w / 2, rose_sill);
}

tiers = [0, 0.48 * spring, spring];

module perpendicular() {
    w = inner_w / 3;
    for (j = [-1 : 1], t = [0, 1]) translate([j * w, tiers[t]]) cusped(w, tiers[t + 1] - tiers[t], 0.75);
    for (x = [-1.5 : 0.5 : 1.5]) translate([x * w - bar / 2, spring]) square([bar, inner_h]);
    for (y = [spring, spring + 0.45 * inner_w]) translate([-inner_w / 2, y - bar / 2]) square([inner_w, bar]);
}

net_y = spring - 0.12 * inner_w;

module reticulated() {
    w = inner_w / 3;
    for (j = [-1 : 1]) translate([j * w, 0]) cusped(w, net_y + rise(w));
    for (s = [-1, 1]) translate([s * w / 2, net_y + sqrt(1.25) * w]) roundel(4, w / 2);
    translate([0, net_y + sqrt(1.25) * w + rise(w)]) roundel(4, w / 2);
}

module stone(window) {
    if (window == 0) geometric(inner_w, spring, [4]);
    if (window == 1) triplet();
    if (window == 2) intersecting(3);
    if (window == 3) rose(8);
    if (window == 4) perpendicular();
    if (window == 5) reticulated();
    if (window == 6) geometric(inner_w, spring, [6, 0]);
    if (window == 7) cusped(inner_w, inner_h, 1, 5);
}

module inner() lancet(inner_w, inner_h);
module outline() translate([0, -rim_width]) lancet(width, height, outer_k);
module cleaned() offset(r = -min_solid / 2) offset(r = min_solid / 2) intersection() {
    children();
    offset(r = min_cell / 2 + nozzle) offset(r = -min_cell / 2) children();
}
module glass(window) cleaned() difference() {
    inner();
    stone(window);
}

module band(y0, y1) translate([-inner_w, y0]) square([2 * inner_w, y1 - y0]);
module side(s) translate([s > 0 ? 0 : -far, -far]) square([far, 2 * far]);
module hbars(ys) for (y = ys) translate([-inner_w, y - came_width / 2]) square([2 * inner_w, came_width]);
module vbar(x, y0, y1) translate([x - came_width / 2, y0]) square([came_width, y1 - y0]);
module lattice(px, py, x, y) for (s = [-1, 1], m = [-ceil(far / py) : ceil(far / py)])
    translate([x, y + m * py]) rotate(s * atan(py / px)) square([2 * far, came_width], center = true);
module scales(px, rows) for (m = [0 : rows - 1], j = [-ceil(inner_w / px) : ceil(inner_w / px)])
    translate([(j + (m % 2) / 2) * px, m * px / 2]) intersection() {
        stroke(came_width) circle(px / 2);
        translate([-px, 0]) square([2 * px, px]);
    }
module chevrons(x, py, angle) for (m = [-ceil(inner_h / py) : ceil(inner_h / py)], s = [0, 1])
    translate([x, m * py]) mirror([s, 0]) rotate(angle) translate([0, -came_width / 2]) square([far, came_width]);
module rays(n, turn, from, to) for (i = [0 : n - 1])
    rotate(turn + i * 360 / n) translate([from, -came_width / 2]) square([to - from, came_width]);
module sectors(n, turn) translate([0, spring + oculus(inner_w)]) {
    stroke(came_width) circle(0.07 * inner_w);
    rays(n, turn, 0.07 * inner_w, inner_w / 4);
}
module bordered(inset) {
    stroke(came_width) offset(delta = -inset) children(0);
    intersection() {
        offset(delta = -inset) children(0);
        children(1);
    }
}

module leading(window) {
    edge = 4.2 * unit;
    if (window == 0) {
        w = inner_w / 2 - bar - 2 * edge;
        y = bar / 2 + edge;
        row = (spring - y) / round((spring - y) / (1.2 * w));
        intersection() {
            for (s = [-1, 1]) translate([s * inner_w / 4, 0]) lancet(inner_w / 2, spring + rise(inner_w / 2));
            bordered(edge) {
                glass(window);
                union() {
                    hbars([spring]);
                    for (s = [-1, 1]) intersection() {
                        side(s);
                        band(0, spring);
                        lattice(w, row, s * inner_w / 4, y + row / 2);
                    }
                }
            }
        }
        sectors(4, 45);
    }
    if (window == 1) for (light = [[-1, spring], [0, spring + stilt], [1, spring]]) {
        w = inner_w / 3;
        row = (light[1] - bar / 2) / round((light[1] - bar / 2) / w);
        intersection() {
            translate([(light[0] - 0.5) * w, 0]) square([w, light[1] + came_width / 2]);
            union() {
                hbars([light[1]]);
                lattice(w, row, 0, bar / 2 + row / 2);
            }
        }
    }
    if (window == 2) {
        rows = round(spring / quarry);
        hbars([for (m = [1 : rows]) m * spring / rows]);
        for (m = [0 : rows - 1], j = [-1 : 1]) if ((m + j) % 2 != 0) vbar(j * inner_w / 3, m * spring / rows, (m + 1) * spring / rows);
    }
    if (window == 3) for (s = [-1, 1]) intersection() {
        translate([s * inner_w / 4, 0]) lancet(inner_w / 2, rose_sill);
        union() {
            chevrons(s * inner_w / 4, quarry, 35);
            vbar(s * inner_w / 4, 0, inner_h);
        }
    }
    if (window == 4) {
        r = 0.1 * inner_w;
        ys = [for (t = [0, 1]) (tiers[t] + tiers[t + 1]) / 2 - r];
        difference() {
            union() {
                hbars(ys);
                for (j = [-1 : 1]) vbar(j * inner_w / 3, 0, spring);
            }
            for (j = [-1 : 1], y = ys) translate([j * inner_w / 3, y]) circle(r);
        }
        for (j = [-1 : 1], y = ys) translate([j * inner_w / 3, y]) stroke(came_width) circle(r);
    }
    if (window == 5) scales(inner_w / 3, floor(net_y / (inner_w / 6)));
    if (window == 6) {
        hbars([for (m = [1 : 7]) m * spring / 7]);
        sectors(6, 0);
    }
    if (window == 7) {
        cusps = bar / 2 + 0.075 * (inner_w - bar);
        field = inner_w / 2 - cusps - edge;
        bordered(edge) {
            offset(delta = -cusps) inner();
            translate([0, cusps + edge]) {
                for (r = [0.6, 1.3, 2.2, 3.3, 4.6]) stroke(came_width) circle(r * field);
                rays(10, 0, 0.6 * field, far);
            }
        }
    }
}

module cells(window) cleaned() difference() {
    glass(window);
    leading(window);
}

module place(list) {
    n = min(len(list), floor((bed + gap) / (width + gap)));
    assert(len(list) > 0, "empty plate");
    assert(max(n * width + (n - 1) * gap, len(list) > n ? height : 0) <= bed && height + (len(list) - n) * (width + gap) <= bed, "plate overflows the bed");
    for (j = [0 : len(list) - 1]) {
        $window = list[j];
        if (j < n) translate([(j - (n - 1) / 2) * (width + gap), rim_width]) children();
        else translate([rim_width - height / 2, height + (j - n + 1) * (width + gap) - width / 2]) rotate(-90) children();
    }
}

module slab(z, thickness) translate([0, 0, z]) linear_extrude(thickness) children();

if (part == "pane") slab(0, pane_z) place(plates[0]) outline();
if (part == "rim") slab(pane_z + tracery_z, rim_z) place(plates[0]) difference() {
    outline();
    inner();
}
for (p = [0 : len(plates) - 1]) {
    letter = chr(97 + p);
    if (part == str("tracery_", letter)) slab(pane_z, tracery_z) place(plates[p]) difference() {
        outline();
        glass($window);
    }
    if (part == str("leading_", letter)) slab(pane_z, came_z) place(plates[p]) difference() {
        outline();
        cells($window);
    }
    if (part == str("cells_", letter)) slab(pane_z, came_z) place(plates[p]) cells($window);
}
