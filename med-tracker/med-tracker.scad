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
pad_angle = 97.5;
am_midpoint_angle = 7.5;
pm_midpoint_angle = 187.5;
label_radius = 33.5;
label_size = 7.3;
label_width = 12.5;
label_height = 6.2;

function distance_to_segment(x, y, half_length) = sqrt(pow(max(abs(x) - half_length, 0), 2) + pow(y, 2));
function socket_x(index) = ring_radius * cos(index * 15);
function socket_y(index) = ring_radius * sin(index * 15);
function rotated_x(x, y, angle) = x * cos(angle) - y * sin(angle);
function rotated_y(x, y, angle) = x * sin(angle) + y * cos(angle);
function pad_local_x(x, y) = x * cos(pad_angle) + y * sin(pad_angle);
function pad_local_y(x, y) = -x * sin(pad_angle) + y * cos(pad_angle);
function pad_clearance(index) = distance_to_segment(pad_local_x(socket_x(index), socket_y(index)), pad_local_y(socket_x(index), socket_y(index)), (pad_width - pad_depth) / 2) - pad_radius - syringe_barrel_diameter / 2;
function bottle_x(position) = rotated_x(position, 0, pad_angle);
function bottle_y(position) = rotated_y(position, 0, pad_angle);
function bottle_clearance(index, position) = sqrt(pow(socket_x(index) - bottle_x(position), 2) + pow(socket_y(index) - bottle_y(position), 2)) - bottle_body_diameter / 2 - syringe_barrel_diameter / 2;
function numeral_clearance(index) = number_radius - number_height / 2 - number_outline - ring_radius - syringe_barrel_diameter / 2;
function numeral_angle(index) = 90 - index * 15;
function socket_index_for_numeral(index) = (6 - index + 24) % 24;
function socket_angle_for_numeral(index) = socket_index_for_numeral(index) * 15;
function angle_error(a, b) = min(abs(a - b), abs(a - b + 360), abs(a - b - 360));
function label_x(angle) = label_radius * cos(angle);
function label_y(angle) = label_radius * sin(angle);
function label_local_x(x, y, angle) = (x - label_x(angle)) * cos(angle) + (y - label_y(angle)) * sin(angle);
function label_local_y(x, y, angle) = -(x - label_x(angle)) * sin(angle) + (y - label_y(angle)) * cos(angle);
function point_box_distance(x, y, angle) = sqrt(pow(max(abs(label_local_x(x, y, angle)) - label_width / 2, 0), 2) + pow(max(abs(label_local_y(x, y, angle)) - label_height / 2, 0), 2));
function label_socket_clearance(index, angle) = point_box_distance(socket_x(index), socket_y(index), angle) - socket_top_diameter / 2;
function label_bottle_clearance(position, angle) = point_box_distance(bottle_x(position), bottle_y(position), angle) - bottle_body_diameter / 2;
function label_pad_clearance() = label_radius - label_width / 2 - pad_depth / 2;

for (i = [0 : 23]) {
    assert(pad_clearance(i) >= required_clearance, str("socket ", i + 1, " pad clearance ", pad_clearance(i)));
    assert(bottle_clearance(i, -bottle_spacing / 2) >= required_clearance, str("socket ", i + 1, " left bottle clearance ", bottle_clearance(i, -bottle_spacing / 2)));
    assert(bottle_clearance(i, bottle_spacing / 2) >= required_clearance, str("socket ", i + 1, " right bottle clearance ", bottle_clearance(i, bottle_spacing / 2)));
    assert(numeral_clearance(i) >= required_clearance, str("socket ", i + 1, " numeral clearance ", numeral_clearance(i)));
    assert(angle_error(numeral_angle(i), socket_angle_for_numeral(i)) <= 0.01, str("numeral ", i + 1, " angular error ", angle_error(numeral_angle(i), socket_angle_for_numeral(i))));
    assert(label_socket_clearance(i, am_midpoint_angle) >= required_clearance, str("AM label socket ", i + 1, " clearance ", label_socket_clearance(i, am_midpoint_angle)));
    assert(label_socket_clearance(i, pm_midpoint_angle) >= required_clearance, str("PM label socket ", i + 1, " clearance ", label_socket_clearance(i, pm_midpoint_angle)));
}
for (label_angle = [am_midpoint_angle, pm_midpoint_angle])
    for (position = [-bottle_spacing / 2, bottle_spacing / 2])
        assert(label_bottle_clearance(position, label_angle) >= required_clearance, str("label bottle clearance ", label_bottle_clearance(position, label_angle)));
assert(abs(angle_error(am_midpoint_angle, pm_midpoint_angle) - 180) <= 0.01, str("label angular separation ", angle_error(am_midpoint_angle, pm_midpoint_angle)));
assert(label_pad_clearance() >= required_clearance, str("label pad clearance ", label_pad_clearance()));
assert(base_diameter <= 140);
assert(base_thickness - socket_depth >= 2);
assert(pad_height - bottle_well_depth >= 2);

module stadium(width, depth, height) {
    hull()
        for (x = [-(width - depth) / 2, (width - depth) / 2])
            translate([x, 0, 0]) cylinder(d = depth, h = height);
}

module disc() {
    difference() {
        cylinder(d = base_diameter, h = base_thickness);
        for (a = [0 : 15 : 345])
            translate([ring_radius * cos(a), ring_radius * sin(a), base_thickness - socket_depth])
                cylinder(d1 = socket_tip_diameter, d2 = socket_top_diameter, h = socket_depth + 0.01);
    }
}

module bottle_pad() {
    rotate([0, 0, pad_angle])
        difference() {
            translate([0, 0, base_thickness]) stadium(pad_width, pad_depth, pad_height);
            for (x = [-bottle_spacing / 2, bottle_spacing / 2])
                translate([x, 0, base_thickness + pad_height - bottle_well_depth])
                    cylinder(d = bottle_well_diameter, h = bottle_well_depth + 0.02);
        }
}

module body() union() {
    disc();
    bottle_pad();
}

module number_glyph(value, index) {
    a = numeral_angle(index);
    translate([number_radius * cos(a), number_radius * sin(a), base_thickness])
        rotate([0, 0, a - 90])
            linear_extrude(number_relief)
                offset(r = number_outline)
                    text(str(value), size = number_height, font = "Liberation Sans:style=Bold", halign = "center", valign = "center", spacing = 0.76);
}

module number_set(offset) {
    for (i = [0 : 11]) number_glyph(i + 1, i + offset);
}

module period_label(value, angle) {
    translate([label_x(angle), label_y(angle), base_thickness])
        rotate([0, 0, angle < 180 ? angle : angle - 180])
            linear_extrude(number_relief)
                offset(r = number_outline)
                    text(value, size = label_size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
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
    rotate([0, 0, pad_angle]) {
        bottle(-bottle_spacing / 2, "TYLENOL", [0.75, 0.08, 0.06]);
        bottle(bottle_spacing / 2, "MOTRIN", [0.85, 0.24, 0.08]);
    }
    for (a = [75, 90, 105]) syringe(a, [0.95, 0.25, 0.08]);
    for (a = [255, 270, 285]) syringe(a, [1, 0.72, 0.02]);
}

module assembly() {
    color("#D3B7A7") render() disc();
    color("#D3B7A7") render() bottle_pad();
    color("#0085D5") {
        number_set(0);
        period_label("AM", am_midpoint_angle);
    }
    color("#057748") {
        number_set(12);
        period_label("PM", pm_midpoint_angle);
    }
    if (show_context) context_objects();
}

if (part == "body") body();
if (part == "am_numbers") {
    number_set(0);
    period_label("AM", am_midpoint_angle);
}
if (part == "pm_numbers") {
    number_set(12);
    period_label("PM", pm_midpoint_angle);
}
if (part == "assembly") assembly();
