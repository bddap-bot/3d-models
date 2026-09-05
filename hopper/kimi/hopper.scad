// Parametric seed hopper, green-cheek conure, Bambu A1 mini, PETG.
// Frame: X across door (printed vertical so layers run with seed flow),
// Y depth (+Y = outside cage), Z up. Plate closes the door opening; the bin
// hangs inside; the fill port in the plate latches from outside only.

part = "assembly"; // body | lid | tray | interior | assembly

plate_w = 138; plate_h = 168; plate_t = 3; wall = 3;
cx0 = 3; cx1 = 135; cy0 = -63; cy1 = -3; cz0 = 35; cz1 = 165;
bin_y0 = -66;
roof_z = cz1;

bar_d = 3; bar_lx = -6; bar_rx = 144;  // vertical bars flanking the opening

port_x0 = 9; port_x1 = 129; port_z0 = 122; port_z1 = 162;
lid_x0 = 4; lid_x1 = 134; lid_z0 = 114; lid_z1 = 170; lid_t = 3;

tray_x0 = 4; tray_x1 = 134; tray_y0 = -73; tray_y1 = 3; tray_z0 = 25;
cut_z0 = 24; cut_z1 = 52;

module side_clips(zc) {
  for (bx = [bar_lx, bar_rx]) {
    xe = bx < 0 ? bx - 3 : plate_w - 1;
    len = bx < 0 ? 1 - xe : bx + 3 - xe;
    translate([xe, -5, zc]) cube([len, 3, 8]);
    translate([xe, 2, zc]) cube([len, 3, 8]);
    translate([bx < 0 ? -1 : plate_w - 1, -3, zc]) cube([2, 4, 8]);
  }
}

module body() {
  difference() {
    union() {
      cube([plate_w, plate_t, plate_h]);
      translate([0, bin_y0, 35]) cube([wall, 1 - bin_y0, cz1 - 35]);
      translate([cx1, bin_y0, 35]) cube([wall, 1 - bin_y0, cz1 - 35]);
      translate([0, bin_y0, 35]) cube([plate_w, wall, cz1 - 35]);
      translate([0, bin_y0, roof_z - 1]) cube([plate_w, 1 - bin_y0, plate_h - roof_z + 1]);
      side_clips(36);
      side_clips(84);
      side_clips(132);
      translate([2, 2, lid_z0]) cube([2, 5, plate_h - lid_z0]);
      translate([2, 6, lid_z0]) cube([5, 3, plate_h - lid_z0]);
      translate([134, 2, lid_z0]) cube([2, 5, plate_h - lid_z0]);
      translate([131, 6, lid_z0]) cube([5, 3, plate_h - lid_z0]);
      translate([lid_x0, 2, lid_z0 - 4]) cube([lid_x1 - lid_x0, 5, 5]);
      translate([2, -70, 20]) cube([5, 72, 5]);
      translate([131, -70, 20]) cube([5, 72, 5]);
    }
    translate([port_x0, -1, port_z0])
      cube([port_x1 - port_x0, plate_t + 2, port_z1 - port_z0]);
    translate([2, -1, cut_z0]) cube([134, plate_t + 2, cut_z1 - cut_z0]);
  }
}

module lid() {
  w = lid_x1 - lid_x0;
  h = lid_z1 - lid_z0;
  translate([2, 2, 0]) linear_extrude(lid_t) offset(r = 2)
    square([w - 4, h - 4]);
  translate([w / 2 - 15, h - 2, -2]) cube([30, 2, 2]);
}

module tray() {
  w = tray_x1 - tray_x0;
  d = tray_y1 - tray_y0;
  difference() {
    union() {
      linear_extrude(3) offset(r = 3) square([w - 6, d - 6]);
      cube([w, wall, 18]);
      translate([0, d - wall, 0]) cube([w, wall, 25]);
      cube([wall, d, 18]);
      translate([w - wall, 0, 0]) cube([wall, d, 18]);
      translate([0, d, 0]) cube([w, 6, 12]);
    }
    translate([wall, wall, 3]) cube([w - 2 * wall, d - 2 * wall, 40]);
    translate([w / 2 - 20, d + 2, 4]) cube([40, 6, 6]);
  }
  translate([0, wall, 18]) rotate([0, 90, 0]) cylinder(h = w, r = 1.5, $fn = 24);
  translate([0, d - wall, 25]) rotate([0, 90, 0]) cylinder(h = w, r = 1.5, $fn = 24);
  translate([w / 2, -8.5, 11]) rotate([0, 90, 0])
    cylinder(h = 98, r = 8, center = true, $fn = 48);
  for (x = [34, 88]) translate([x, -8, 0]) cube([8, 9, 13]);
}

if (part == "body") body();
else if (part == "lid") lid();
else if (part == "tray") tray();
else if (part == "interior")
  translate([cx0, cy0, cz0]) cube([cx1 - cx0, cy1 - cy0, cz1 - cz0]);
else {
  color("lightsteelblue") body();
  color("khaki") translate([lid_x0, plate_t + lid_t, lid_z0])
    rotate([90, 0, 0]) lid();
  color("salmon") translate([tray_x0, tray_y0, tray_z0]) tray();
}

echo(str("cavity_mm3=", (cx1-cx0)*(cy1-cy0)*(cz1-cz0)));
echo(str("outlet_mm=", cy1-cy0, " x ", cx1-cx0, " wall_angle_deg=90"));
