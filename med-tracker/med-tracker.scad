$fn = 96;
part = "assembly";
show_context = false;

base_diameter = 126;
base_thickness = 14;
pad_width = 77;
pad_depth = 41;
pad_height = 7;
pad_radius = pad_depth / 2;
bottle_body_diameter = 34.5;
bottle_well_diameter = 35;
bottle_well_depth = 5;
bottle_spacing = 36;
socket_top_diameter = 8.6;
socket_tip_diameter = 4.5;
socket_depth = 12;
ring_radius = 47;
number_radius = 59.1;
number_height = 6;
number_outline = 0.3;
number_relief = 1;
syringe_barrel_diameter = 14;
syringe_flange_diameter = 20;
required_clearance = 1.5;

function distance_to_segment(x, y, half_length) = sqrt(pow(max(abs(x) - half_length, 0), 2) + pow(y, 2));
function socket_x(index) = ring_radius * cos(index * 15);
function socket_y(index) = ring_radius * sin(index * 15);
function pad_clearance(index) = distance_to_segment(socket_x(index), socket_y(index), (pad_width - pad_depth) / 2) - pad_radius - syringe_barrel_diameter / 2;
function bottle_clearance(index, bottle_x) = sqrt(pow(socket_x(index) - bottle_x, 2) + pow(socket_y(index), 2)) - bottle_body_diameter / 2 - syringe_barrel_diameter / 2;
function numeral_clearance(index) = number_radius - number_height / 2 - number_outline - ring_radius - syringe_barrel_diameter / 2;

for (i = [0 : 23]) {
    assert(pad_clearance(i) >= required_clearance, str("socket ", i + 1, " pad clearance ", pad_clearance(i)));
    assert(bottle_clearance(i, -bottle_spacing / 2) >= required_clearance, str("socket ", i + 1, " left bottle clearance ", bottle_clearance(i, -bottle_spacing / 2)));
    assert(bottle_clearance(i, bottle_spacing / 2) >= required_clearance, str("socket ", i + 1, " right bottle clearance ", bottle_clearance(i, bottle_spacing / 2)));
    assert(numeral_clearance(i) >= required_clearance, str("socket ", i + 1, " numeral clearance ", numeral_clearance(i)));
}
assert(base_diameter <= 140);
assert(base_thickness - socket_depth >= 2);
assert(pad_height - bottle_well_depth >= 2);

module stadium(width, depth, height) {
    hull()
        for (x = [-(width - depth) / 2, (width - depth) / 2])
            translate([x, 0, 0]) cylinder(d = depth, h = height);
}

module body() {
    difference() {
        union() {
            cylinder(d = base_diameter, h = base_thickness);
            translate([0, 0, base_thickness]) stadium(pad_width, pad_depth, pad_height);
        }
        for (a = [0 : 15 : 345])
            translate([ring_radius * cos(a), ring_radius * sin(a), base_thickness - socket_depth])
                cylinder(d1 = socket_tip_diameter, d2 = socket_top_diameter, h = socket_depth + 0.01);
        for (x = [-bottle_spacing / 2, bottle_spacing / 2])
            translate([x, 0, base_thickness + pad_height - bottle_well_depth])
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
        translate([x, 0, base_thickness + pad_height - bottle_well_depth]) cylinder(d = bottle_body_diameter, h = 74);
    color([0.98, 0.98, 0.98])
        translate([x, 0, base_thickness + pad_height + 58]) cylinder(d = 36, h = 18);
    color(label_color)
        translate([x, -bottle_body_diameter / 2 - 0.2, base_thickness + pad_height + 23])
            rotate([90, 0, 0]) linear_extrude(0.4)
                text(label, size = 5, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}

module syringe(a, c) {
    x = ring_radius * cos(a);
    y = ring_radius * sin(a);
    color(c) translate([x, y, base_thickness - socket_depth]) cylinder(d = 6, h = socket_depth + 2);
    color(c) translate([x, y, base_thickness]) cylinder(d = syringe_barrel_diameter, h = 90);
    color(c) translate([x, y, base_thickness + 90]) cylinder(d = syringe_flange_diameter, h = 3);
}

module context_objects() {
    bottle(-bottle_spacing / 2, "TYLENOL", [0.75, 0.08, 0.06]);
    bottle(bottle_spacing / 2, "MOTRIN", [0.85, 0.24, 0.08]);
    for (a = [-15, 0, 15]) syringe(a, [0.95, 0.25, 0.08]);
    for (a = [165, 180, 195]) syringe(a, [1, 0.72, 0.02]);
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
