$fn = 72;
part = "assembly";
show_context = false;

base_diameter = 158;
base_thickness = 8;
platform_height = 20;
platform_width = 82;
platform_depth = 62;
platform_radius = 12;
bottle_well_diameter = 38;
bottle_well_depth = 5;
syringe_hole_diameter = 13.5;
peg_hole_diameter = 4.2;
peg_hole_depth = 5;
peg_shank_diameter = 4.35;
peg_shank_height = 8;
peg_cap_diameter = 7;
peg_cap_height = 3;
inner_ring_radius = 53;
outer_ring_radius = 63;
number_radius = 73;
number_height = 9;
number_relief = 1;

module rounded_box(size, radius) {
    hull() {
        for (x = [-size[0] / 2 + radius, size[0] / 2 - radius])
            for (y = [-size[1] / 2 + radius, size[1] / 2 - radius])
                translate([x, y, 0]) cylinder(r = radius, h = size[2]);
    }
}

module body() {
    difference() {
        union() {
            cylinder(d = base_diameter, h = base_thickness);
            translate([0, 0, base_thickness]) rounded_box([platform_width, platform_depth, platform_height], platform_radius);
        }
        for (r = [inner_ring_radius, outer_ring_radius])
            for (a = [0 : 15 : 345])
                translate([r * cos(a), r * sin(a), base_thickness - peg_hole_depth]) cylinder(d = peg_hole_diameter, h = peg_hole_depth + 0.02);
        for (x = [-20.5, 20.5])
            translate([x, 8, base_thickness + platform_height - bottle_well_depth]) cylinder(d = bottle_well_diameter, h = bottle_well_depth + 0.02);
        for (x = [-13, 13])
            translate([x, -22, -0.01]) cylinder(d = syringe_hole_diameter, h = base_thickness + platform_height + 0.02);
    }
}

module number_glyph(value, index) {
    a = 97.5 - index * 15;
    translate([number_radius * cos(a), number_radius * sin(a), base_thickness])
        rotate([0, 0, a - 90])
            linear_extrude(number_relief)
                offset(r = 0.35)
                    text(str(value), size = number_height, font = "Liberation Sans:style=Bold", halign = "center", valign = "center", spacing = 0.8);
}

module number_set(offset) {
    for (i = [0 : 11]) number_glyph(i + 1, i + offset);
}

module peg() {
    cylinder(d = peg_shank_diameter, h = peg_shank_height);
    translate([0, 0, peg_shank_height]) cylinder(d = peg_cap_diameter, h = peg_cap_height);
}

module peg_pair(y) {
    for (x = [-72, 72]) translate([x, y, 0]) peg();
}

module assembly() {
    color("#D3B7A7") body();
    color("#0085D5") number_set(0);
    color("#057748") number_set(12);
    color("#0085D5") peg_pair(-72);
    color("#057748") peg_pair(72);
    if (show_context) context_objects();
}

module context_objects() {
    for (x = [-20.5, 20.5]) {
        color([0.92, 0.92, 0.9, 0.75]) translate([x, 8, base_thickness + platform_height - bottle_well_depth]) cylinder(d = 36, h = 67);
        color([0.85, 0.85, 0.83, 0.9]) translate([x, 8, 90]) cylinder(d = 38, h = 18);
    }
    for (x = [-13, 13])
        color(x < 0 ? "#0085D5" : "#057748") translate([x, -22, 4]) cylinder(d = 12.5, h = 75);
    color("#0085D5") translate([inner_ring_radius * cos(240), inner_ring_radius * sin(240), base_thickness - 3]) peg();
    color("#057748") translate([outer_ring_radius * cos(300), outer_ring_radius * sin(300), base_thickness - 3]) peg();
}

if (part == "body") body();
if (part == "am_numbers") number_set(0);
if (part == "pm_numbers") number_set(12);
if (part == "blue_pegs") peg_pair(-72);
if (part == "green_pegs") peg_pair(72);
if (part == "assembly") assembly();
