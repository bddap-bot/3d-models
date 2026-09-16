$fn = 72;
part = "assembly";
show_candle = false;

horn_points = [[55, 0, 55], [58, 0, 38], [64, 0, 21], [75, 0, 5], [90, 0, -8], [108, 0, -17], [126, 0, -20], [138, 0, -17]];
horn_radii = [24.5, 22, 19, 15.5, 11.5, 8, 4.5, 1.4];

plaque_r = 52;
plaque_t = 8;
boss_r = 25;
boss_t = 7;
ring_x = 86;
ring_z = 55;
horn_dx = ring_x - 55;

module horn_curve() {
    for (i = [0 : len(horn_points) - 2])
        hull() {
            translate(horn_points[i]) sphere(r = horn_radii[i]);
            translate(horn_points[i + 1]) sphere(r = horn_radii[i + 1]);
        }
}

module horn() {
    difference() {
        union() {
            horn_curve();
            translate([55, 0, 49]) cylinder(d1 = 49, d2 = 52, h = 35);
            translate([55, 0, 47.5]) cylinder(d = 51, h = 4);
            translate([55, 0, 61]) cylinder(d = 56, h = 4);
        }
        translate([55, 0, 63]) cylinder(d = 40.8, h = 23);
        translate([55, 0, 62.98]) cylinder(d1 = 38.8, d2 = 40.8, h = 1.4);
    }
}

module hexagon(r, h) {
    rotate([0, 90, 0]) linear_extrude(height = h) rotate(30) circle(r = r, $fn = 6);
}

module plaque() {
    difference() {
        union() {
            hexagon(plaque_r, plaque_t);
            translate([plaque_t - 0.5, 0, 0]) hexagon(boss_r, boss_t + 0.5);
        }
        for (z = [-33, 33]) {
            translate([-1, 0, z]) rotate([0, 90, 0]) cylinder(d = 4.8, h = plaque_t + 2);
            translate([plaque_t - 2.4, 0, z]) rotate([0, 90, 0]) cylinder(d1 = 4.8, d2 = 9.6, h = 2.4);
        }
    }
}

module mount() {
    arm_x = plaque_t + boss_t - 0.5;
    union() {
        plaque();
        translate([arm_x, -8, -6]) cube([ring_x - 26.2 - arm_x, 16, 12]);
        translate([ring_x, 0, -6]) difference() {
            cylinder(d = 61, h = 12);
            translate([0, 0, -1]) cylinder(d = 52.2, h = 14);
        }
    }
}

module candle() {
    color("silver") translate([55, 0, 63.2]) cylinder(d = 39, h = 15.5);
    color("ivory") translate([55, 0, 64]) cylinder(d = 37.5, h = 15.2);
    color("#3A2718") translate([55, 0, 79]) cylinder(d = 1.2, h = 3);
}

module assembly() {
    translate([horn_dx, 0, 0]) {
        color("#D7B982") horn();
        if (show_candle) candle();
    }
    color("#25211F") translate([0, 0, ring_z]) mount();
}

if (part == "horn") horn();
if (part == "mount") mount();
if (part == "assembly") assembly();
if (part == "horn_print") rotate([180, 0, 0]) horn();
if (part == "mount_print") rotate([0, -90, 0]) mount();
if (part == "plate_print") {
    translate([-18, 30, 84]) rotate([180, 0, 0]) horn();
    translate([65, 120, 0]) rotate([0, -90, 0]) mount();
}
