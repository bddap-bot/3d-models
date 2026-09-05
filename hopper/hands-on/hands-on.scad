view = "seam";
drop = 0;

cuts = view == "seam" || view == "seam_corner" ? [[[-200, -200, 121], [200, 200, 300], [0, 0, 1]], [[-200, -200, -200], [200, 200, 118], [0, 0, -1]]]
     : view == "window_corner" ? [[[-200, -200, 3], [200, 200, 300], [0, 0, 1]], [[-200, -200, -200], [200, 200, 0], [0, 0, -1]]]
     : view == "groove" ? [[[66, -200, -200], [200, 200, 200], [1, 0, 0]]]
     : view == "perch_section" ? [[[30, -200, -200], [200, 200, 200], [1, 0, 0]]]
     : [];

module part(name, c, i, dz = 0) difference() {
  color(c) translate([0, 0, dz]) import(str("../fable/out/", name, ".stl"));
  for (b = cuts) color(c) translate(b[0] + b[2] * 0.05 * i) cube(b[1] - b[0]);
}
module assembly() {
  part("body_R", "SteelBlue", 0);
  part("body_L", "LightSteelBlue", 1);
  part("lid", "Orange", 2);
  part("bracket", "SeaGreen", 3, -drop);
  part("tray", "Gold", 4, -drop);
}
module perch_axis(len) color("Red") translate([-len / 2, 106.05, -25]) rotate([0, 90, 0]) cylinder(d = 2, h = len, $fn = 24);
module mark_y(y, z0, z1, c) color(c) translate([-0.25, y - 0.25, z0]) cube([0.5, 0.5, z1 - z0]);
module mark_z(z, y0, y1, c) color(c) translate([-0.25, y0, z - 0.25]) cube([0.5, y1 - y0, 0.5]);

if (view == "perch_section") {
  assembly();
  mark_y(95.8, -34, 20, "Red");
  mark_y(103.8, -34, 20, "Black");
  mark_z(20, 80, 120, "Red");
  mark_z(-17, 80, 120, "Black");
  color("Red") translate([30.5, 106.05, -25]) rotate([0, 90, 0]) cylinder(d = 2, h = 1, $fn = 24);
} else if (view == "perch_axis") {
  assembly();
  perch_axis(260);
} else if (view == "bracket_print") {
  rotate([0, -90, 0]) translate([-82.7, 0, 0]) part("bracket", "SeaGreen", 0);
} else {
  assembly();
}
