$fn = 72;
part = "assembly";
show_context = false;

base_diameter = 108;
base_thickness = 10;
platform_height = 14;
platform_width = 76;
platform_depth = 50;
platform_radius = 9;
bottle_body_diameter = 34.5;
bottle_well_diameter = 35;
bottle_well_depth = 5;
socket_top_diameter = 8.6;
socket_tip_diameter = 4.5;
socket_depth = 8;
inner_ring_radius = 34;
outer_ring_radius = 43;
number_radius = 50.5;
number_height = 6;
number_outline = 0.3;
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
            translate([0, 6, base_thickness]) rounded_box([platform_width, platform_depth, platform_height], platform_radius);
        }
        for (r = [inner_ring_radius, outer_ring_radius])
            for (a = [0 : 15 : 345])
                translate([r * cos(a), r * sin(a), base_thickness - socket_depth])
                    cylinder(d1 = socket_tip_diameter, d2 = socket_top_diameter, h = socket_depth + 0.01);
        for (x = [-18, 18])
            translate([x, 9, base_thickness + platform_height - bottle_well_depth])
                cylinder(d = bottle_well_diameter, h = bottle_well_depth + 0.02);
    }
}

module number_glyph(value, index) {
    a = 97.5 - index * 15;
    translate([number_radius * cos(a), number_radius * sin(a), base_thickness])
        rotate([0, 0, a - 90])
            linear_extrude(number_relief)
                offset(r = number_outline)
                    text(str(value), size = number_height, font = "Liberation Sans:style=Bold", halign = "center", valign = "center", spacing = 0.76);
}

module number_set(offset) {
    for (i = [0 : 11]) number_glyph(i + 1, i + offset);
}

module bottle(x, label, label_color) {
    color([0.95, 0.95, 0.92, 0.82])
        translate([x, 9, base_thickness + platform_height - bottle_well_depth]) cylinder(d = bottle_body_diameter, h = 74);
    color([0.98, 0.98, 0.98])
        translate([x, 9, base_thickness + platform_height + 61]) cylinder(d = 36, h = 18);
    color(label_color)
        translate([x, -bottle_body_diameter / 2 + 8.5, base_thickness + platform_height + 25])
            rotate([90, 0, 0]) linear_extrude(0.4)
                text(label, size = 5, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}

module syringe(r, a, c) {
    x = r * cos(a);
    y = r * sin(a);
    color(c) translate([x, y, base_thickness - 6]) cylinder(d = 4.2, h = 10);
    color(c) translate([x, y, base_thickness + 2]) cylinder(d = 12.5, h = 68);
    color(c) translate([x, y, base_thickness + 70]) cylinder(d = 18, h = 2.5);
}

module context_objects() {
    bottle(-18, "TYLENOL", [0.75, 0.08, 0.06]);
    bottle(18, "MOTRIN", [0.85, 0.24, 0.08]);
    syringe(inner_ring_radius, 230, [1, 0.72, 0.02]);
    syringe(outer_ring_radius, 310, [0.95, 0.25, 0.08]);
}

module assembly() {
    color("#D3B7A7") body();
    color("#0085D5") number_set(0);
    color("#057748") number_set(12);
    if (show_context) context_objects();
}

if (part == "body") body();
if (part == "am_numbers") number_set(0);
if (part == "pm_numbers") number_set(12);
if (part == "assembly") assembly();
