part = "spool";

R      = 65;
core_r = 21;
bore_r = 15;
gap    = 30;
base_t = 3;
cone_t = 2.6;
slots  = [2, 3, 4.5, 6, 8, 10];
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
            intersection() {
                translate([0, 0, cone_z0])
                    cylinder(r1 = core_r, r2 = R + cone_v, h = cone_dz + cone_v);
                cylinder(r = R, h = top_z);
            }
        }
        translate([0, 0, cone_z0 + cone_v])
            cylinder(r1 = core_r, r2 = R + cone_v + 1, h = cone_dz + cone_v + 1);
        translate([0, 0, -1]) cylinder(r = bore_r, h = top_z + 2);
        translate([0, 0, -1]) linear_extrude(base_t + 2) slot_ring(0);
        translate([0, 0, cone_z0 + 1]) linear_extrude(cone_dz + cone_v + 1) slot_ring(30);
    }
}

if (part == "spool") body();
if (part == "section") difference() {
    body();
    translate([-R - 5, -2 * R, -1]) cube([2 * R + 10, 2 * R, top_z + 2]);
}
