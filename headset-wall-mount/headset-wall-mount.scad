part = "mount";

$fn = 160;

plate = 4;
hole_d = 5.5;
csk_d = 9;
holes = [[0, 35], [0, 4.5]];

arc_c = [0, -45.5];
arc_r = 68.5;
wall = 5;
arc_half = 68;
height = 106;

lip_out = 3;
lip_h = 6;

root = 6;

lobe_xy = [52, -22];
lobe_r = 14;
top_r = 8;
peg_pad = 10.5;

peg_xy = [[-44.5, -31], [44.5, -31]];
peg_d = 10;
peg_h = 45;
cap_d = 14;
cap_h = 3;

module plate2d() {
  hull() {
    translate(arc_c) intersection() {
      difference() { circle(arc_r); circle(arc_r - wall); }
      polygon([[0, 0], for (a = [-arc_half : 2 : arc_half]) 2 * arc_r * [sin(a), cos(a)]]);
    }
    translate(holes[0]) circle(top_r);
    for (s = [-1, 1]) {
      translate([s * lobe_xy[0], lobe_xy[1]]) circle(lobe_r);
      translate([s * peg_xy[1][0], peg_xy[1][1]]) circle(peg_pad);
    }
  }
}

module shell() {
  r_in = arc_r - wall;
  // one profile: root chamfers both sides, straight wall, 45 deg outward lip; every slope prints unsupported
  translate(arc_c) rotate(90 - arc_half) rotate_extrude(angle = 2 * arc_half)
    polygon([
      [r_in - root, 0], [arc_r + root, 0], [arc_r, root],
      [arc_r, height - lip_h], [arc_r + lip_out, height - lip_h + lip_out],
      [arc_r + lip_out, height], [r_in, height], [r_in, root]
    ]);
}

module peg() {
  cylinder(d1 = peg_d + 8, d2 = peg_d, h = 4);
  cylinder(d = peg_d, h = peg_h - cap_h);
  // cap underside at 45 deg: a strap stays on and nothing needs support
  translate([0, 0, peg_h - cap_h]) cylinder(d1 = peg_d, d2 = cap_d, h = (cap_d - peg_d) / 2);
  translate([0, 0, peg_h - cap_h + (cap_d - peg_d) / 2]) cylinder(d = cap_d, h = cap_h - (cap_d - peg_d) / 2);
}

module countersunk_hole() {
  translate([0, 0, -1]) cylinder(d = hole_d, h = plate + 2);
  translate([0, 0, plate - (csk_d - hole_d) / 2]) cylinder(d1 = hole_d, d2 = csk_d, h = (csk_d - hole_d) / 2 + 0.01);
  translate([0, 0, plate]) cylinder(d = csk_d, h = height);
}

difference() {
  union() {
    linear_extrude(plate) plate2d();
    translate([0, 0, plate]) {
      intersection() { shell(); union() { linear_extrude(root + 0.01) plate2d(); translate([-200, -200, root]) cube([400, 400, height]); } }
      for (p = peg_xy) translate(p) peg();
    }
  }
  for (h = holes) translate(h) countersunk_hole();
}
