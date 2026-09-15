$fn = 72;
part = "assembly";
show_candle = false;

horn_points = [[55, 0, 55], [58, 0, 38], [64, 0, 21], [75, 0, 5], [90, 0, -8], [108, 0, -17], [126, 0, -20], [138, 0, -17]];
horn_radii = [24.5, 22, 19, 15.5, 11.5, 8, 4.5, 1.4];

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

module plaque() {
    difference() {
        rotate([0, 90, 0]) linear_extrude(height = 7) polygon(points = [[-38, -50], [38, -50], [45, -39], [45, 39], [34, 50], [-34, 50], [-45, 39], [-45, -39]]);
        for (z = [-31, 31]) {
            translate([-1, 0, z]) rotate([0, 90, 0]) cylinder(d = 4.8, h = 9);
            translate([4, 0, z]) rotate([0, 90, 0]) cylinder(d1 = 4.8, d2 = 9.6, h = 3.1);
        }
    }
}

module mount() {
    union() {
        plaque();
        translate([6.5, -8, 39]) cube([21.9, 16, 20]);
        translate([55, 0, 49]) difference() {
            cylinder(d = 61, h = 12);
            translate([0, 0, -1]) cylinder(d = 53, h = 14);
        }
    }
}

module candle() {
    color("silver") translate([55, 0, 63.2]) cylinder(d = 39, h = 15.5);
    color("ivory") translate([55, 0, 64]) cylinder(d = 37.5, h = 15.2);
    color("#3A2718") translate([55, 0, 79]) cylinder(d = 1.2, h = 3);
    color("#FFB52E") translate([55, 0, 82]) hull() {
        sphere(r = 1.8);
        translate([0, 0, 6]) sphere(r = 0.7);
    }
}

module assembly() {
    color("#D7B982") horn();
    color("#25211F") mount();
    if (show_candle) candle();
}

if (part == "horn") horn();
if (part == "mount") mount();
if (part == "assembly") assembly();
if (part == "horn_print") rotate([180, 0, 0]) horn();
if (part == "mount_print") rotate([0, -90, 0]) mount();
if (part == "plate_print") {
    translate([-18, 37, 84]) rotate([180, 0, 0]) horn();
    translate([65, 120, 0]) rotate([0, -90, 0]) mount();
}
