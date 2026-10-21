part = "spool";

sizes = [
    [65, 21, 15, 30, 3, 2.6, [2, 3, 4.5, 6, 8, 10]],
    [41, 13.5, 9.5, 19, 2.4, 2, [2, 2.5, 3, 4, 5, 6]],
    [20.5, 6.75, 4.5, 9.5, 1.6, 1.6, [2, 2.5, 3, 4]],
];
size = sizes[part == "spool_tiny" ? 2 : part == "spool_small" ? 1 : 0];

R      = size[0];
core_r = size[1];
bore_r = size[2];
gap    = size[3];
base_t = size[4];
cone_t = size[5];
slots  = size[6];
lip    = 4;
clear  = 0.25;
$fn    = 160;

cone_z0 = base_t + gap;
cone_dz = R - core_r;
cone_v  = cone_t * sqrt(2);
top_z   = cone_z0 + cone_dz + cone_v;

module keyhole(d) {
    p = d + clear;
    w = d - min(1.2, max(0.4, 0.15 * d));
    r = R - lip - p / 2;
    hull() {
        translate([R + 1, -(w / 2 + 2)]) square([0.01, w + 4]);
        translate([R - 3, -w / 2]) square([0.01, w]);
    }
    translate([r, -w / 2]) square([R - r, w]);
    translate([r, 0]) circle(d = p, $fn = 48);
}

module slot_ring(phase) {
    for (i = [0 : len(slots) - 1])
        rotate(phase + i * 360 / len(slots)) keyhole(slots[i]);
}

module body() {
    difference() {
        union() {
            cylinder(r = R, h = base_t);
            cylinder(r = core_r, h = cone_z0 + cone_v);
            rotate_extrude() polygon([
                [core_r, cone_z0],
                [R, cone_z0 + cone_dz],
                [R, top_z],
                [core_r, cone_z0 + cone_v],
            ]);
        }
        translate([0, 0, -1]) cylinder(r = bore_r, h = top_z + 2);
        translate([0, 0, -1]) linear_extrude(base_t + 2) slot_ring(0);
        translate([0, 0, cone_z0 + 1]) linear_extrude(cone_dz + cone_v + 1) slot_ring(180 / len(slots));
    }
}

if (part != "section") body();
if (part == "section") difference() {
    body();
    translate([-R - 5, -2 * R, -1]) cube([2 * R + 10, 2 * R, top_z + 2]);
}
