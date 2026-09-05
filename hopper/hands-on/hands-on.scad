view = "seam";
drop = 0;

cuts = view == "seam" || view == "seam_corner" ? [[[-200, -200, 121], [200, 200, 300], [0, 0, 1]], [[-200, -200, -200], [200, 200, 118], [0, 0, -1]]]
     : view == "window_corner" ? [[[-200, -200, 3], [200, 200, 300], [0, 0, 1]], [[-200, -200, -200], [200, 200, 0], [0, 0, -1]]]
     : view == "groove" ? [[[66, -200, -200], [200, 200, 200], [1, 0, 0]]]
     : view == "perch_section" ? [[[30, -200, -200], [200, 200, 200], [1, 0, 0]]]
     : view == "opus_perch" ? [[[0, -300, -300], [300, 600, 600], [1, 0, 0]]]
     : [];

module part(name, c, i, dz = 0, lane = "fable") difference() {
  color(c) translate([0, 0, dz]) import(str("../", lane, "/out/", name, ".stl"));
  for (b = cuts) color(c) translate(b[0] + b[2] * 0.05 * i) cube(b[1] - b[0]);
}
module assembly() {
  part("body_R", "SteelBlue", 0);
  part("body_L", "LightSteelBlue", 1);
  part("lid", "Orange", 2);
  part("bracket", "SeaGreen", 3, -drop);
  part("tray", "Gold", 4, -drop);
}
module mark(lo, hi, c) color(c) translate(lo) cube(hi - lo);
module perch_axis(x0, len) color("Red") translate([x0, 106.05, -25]) rotate([0, 90, 0]) cylinder(d = 2, h = len, $fn = 24);

if (view == "seam_corner") {
  assembly();
  mark([67.4, -8.9, 118], [67.7, -2.5, 121.2], "Red");
} else if (view == "window_corner") {
  assembly();
  mark([64.9, 0.3, 0], [65.2, 3.3, 3.2], "Red");
} else if (view == "perch_section") {
  assembly();
  mark([-0.25, 95.55, -34], [0.25, 96.05, 20], "Red");
  mark([-0.25, 103.55, -34], [0.25, 104.05, 20], "Black");
  mark([-0.25, 80, 19.75], [0.25, 120, 20.25], "Red");
  mark([-0.25, 80, -17.25], [0.25, 120, -16.75], "Black");
  perch_axis(30.5, 1);
} else if (view == "opus_perch") {
  part("shell_left", "LightSteelBlue", 0, 0, "opus");
  part("mount", "Gray", 1, 0, "opus");
  part("tray", "Gold", 2, 0, "opus");
  part("perch", "SeaGreen", 3, 0, "opus");
  mark([-0.25, -38.25, -5], [0.25, -37.75, 60], "Red");
  mark([-0.25, -60, 25.75], [0.25, 0, 26.25], "Black");
  mark([-0.25, -60, 22.75], [0.25, 0, 23.25], "Black");
} else if (view == "perch_axis") {
  assembly();
  perch_axis(-130, 260);
} else if (view == "bracket_print") {
  rotate([0, -90, 0]) translate([-82.7, 0, 0]) part("bracket", "SeaGreen", 0);
} else {
  assembly();
}
