part = "assembly";
$fn = 40;

wall        = 3;
bar_pitch   = 12;
bar_dia     = 3;
door_w      = 110;
door_h      = 110;
cage_y0     = -3;

tank_in_x   = 52;
tank_out_x  = 55;
up_out_x    = 60;

front_y     = 16;
slot_w      = 72;
rear_y0     = front_y + slot_w;
floor_z     = 46;
top_z       = 152;
wall_ang    = 70;
rear_y1     = rear_y0 + (top_z - floor_z) / tan(wall_ang);
rear_out_y  = rear_y1 + wall;

face_x      = 68;
face_t      = 4;
face_z0     = -20;
face_z1     = 130;
win_x       = 48;
win_z0      = 0;
win_z1      = 64;

hook_x      = 30;
hook_w      = 6;

bay_in_x    = 52;
bay_out_x   = 55;
lip_out_x   = 58;
lip_z       = 58;
rail_z0     = 10;
rail_z1     = 14;
rail_in_x   = 48;
bay_z0      = -20;

tray_x       = 51.5;
tray_y0      = 4;
tray_y1      = 96;
tray_floor_z = 14;
tray_lip_z   = 36;
tray_side_z  = 41;

perch_r = 5.5;
perch_y = -16;
perch_z = 8.3;
perch_x = 44;

groove_z0  = 154;
groove_z1  = 158.5;
groove_x   = 56;
tank_top_z = 161.5;

lid_x  = 55.6;
lid_t  = 4;
lid_z0 = 154.3;
lid_y0 = 15.7;
lid_y1 = 134;

cav = [[front_y, floor_z], [rear_y0, floor_z], [rear_y1, top_z], [front_y, top_z]];

module yz(pts, x0, x1)
  translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) polygon(pts);

module yz_o(pts, r, x0, x1)
  translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) offset(r = r) polygon(pts);

module tank() {
  difference() {
    union() {
      yz_o(cav, wall, -tank_out_x, tank_out_x);
      intersection() {
        yz_o(cav, wall, -up_out_x, up_out_x);
        translate([-up_out_x, -200, 138]) cube([2*up_out_x, 400, 40]);
      }
      translate([-up_out_x, front_y - wall, top_z + wall])
        cube([2*up_out_x, rear_out_y - front_y + wall, tank_top_z - top_z - wall]);
    }
    yz(cav, -tank_in_x, tank_in_x);
    translate([-up_out_x - 1, front_y - 2*wall, floor_z - 30]) cube([2*up_out_x + 2, 200, 30]);
    translate([-tank_in_x, front_y, top_z]) cube([2*tank_in_x, rear_y1 - front_y, 40]);
    translate([-groove_x, front_y - 0.4, groove_z0])
      cube([2*groove_x, rear_out_y - front_y + wall + 60, groove_z1 - groove_z0]);
  }
}

module faceplate() {
  difference() {
    rotate([90, 0, 0]) translate([0, 0, -face_t]) linear_extrude(face_t) offset(r = 8)
      translate([-face_x + 8, face_z0 + 8]) square([2*face_x - 16, face_z1 - face_z0 - 16]);
    translate([0, -1, 0]) rotate([90, 0, 0]) translate([0, 0, -face_t - 2])
      linear_extrude(face_t + 4) offset(r = 6)
        translate([-win_x + 6, win_z0 + 6]) square([2*win_x - 12, win_z1 - win_z0 - 12]);
  }
}

module hooks() {
  for (sx = [-1, 1]) translate([sx * hook_x - hook_w/2, 0, 0]) {
    translate([0, -8, 113]) cube([hook_w, 12, 5]);
    translate([0, -8, 100]) cube([hook_w, 4, 18]);
  }
}

module retainers() {
  for (sx = [-1, 1]) translate([sx * hook_x - hook_w/2, 0, 0]) {
    translate([0, -9, -19]) cube([hook_w, 13, 6]);
    hull() {
      translate([0, -9, -19]) cube([hook_w, 4, 6]);
      translate([0, -9, -1]) cube([hook_w, 4, 4]);
    }
  }
}

module perch() {
  union() {
    translate([-perch_x, perch_y, perch_z]) rotate([0, 90, 0]) cylinder(r = perch_r, h = 2*perch_x);
    for (sx = [-1, 1]) hull() {
      translate([sx > 0 ? perch_x - 6 : -perch_x, perch_y, perch_z]) rotate([0, 90, 0]) cylinder(r = perch_r, h = 6);
      translate([sx > 0 ? 50 : -56, face_t, perch_z - perch_r]) cube([6, 3, 2*perch_r]);
    }
  }
}

module base() {
  union() {
    faceplate();
    hooks();
    retainers();
    difference() {
      for (sx = [-1, 1]) translate([sx > 0 ? bay_in_x : -lip_out_x, face_t, bay_z0])
        cube([lip_out_x - bay_in_x, rear_out_y - face_t, lip_z - bay_z0]);
      for (sx = [-1, 1]) translate([sx > 0 ? bay_in_x - 1 : -bay_out_x - 0.3, face_t - 1, floor_z])
        cube([bay_out_x - bay_in_x + 1.3, rear_out_y, lip_z - floor_z + 1]);
    }
    perch();
    translate([-bay_out_x, face_t, bay_z0]) cube([2*bay_out_x, rear_out_y - face_t, 4]);
    for (sx = [-1, 1]) translate([sx > 0 ? rail_in_x : -bay_out_x, face_t, rail_z0])
      cube([bay_out_x - rail_in_x, rear_out_y - face_t, rail_z1 - rail_z0]);
    translate([-bay_out_x, rear_y0, 43]) cube([2*bay_out_x, wall / sin(wall_ang), floor_z - 43]);
  }
}

module tray() {
  union() {
    translate([-tray_x, tray_y0, tray_floor_z]) cube([2*tray_x, tray_y1 - tray_y0, wall]);
    for (sx = [-1, 1]) translate([sx > 0 ? tray_x - wall : -tray_x, tray_y0, tray_floor_z])
      cube([wall, tray_y1 - tray_y0, tray_side_z - tray_floor_z]);
    translate([-tray_x, tray_y1 - wall, tray_floor_z]) cube([2*tray_x, wall, tray_side_z - tray_floor_z]);
    translate([-tray_x, tray_y0, tray_floor_z]) cube([2*tray_x, wall, tray_lip_z - tray_floor_z]);
    hull() {
      translate([-tray_x, tray_y0 + wall/2, tray_lip_z - wall/2]) rotate([0, 90, 0]) cylinder(r = wall/2, h = 2*tray_x);
      translate([-tray_x, tray_y0 + wall/2 + 7, tray_lip_z - wall/2]) rotate([0, 90, 0]) cylinder(r = wall/2, h = 2*tray_x);
      translate([-tray_x, tray_y0 + wall/2 + 9, tray_lip_z - wall/2 - 5]) rotate([0, 90, 0]) cylinder(r = wall/2, h = 2*tray_x);
    }
  }
}

module lid() {
  union() {
    translate([-lid_x, lid_y0, lid_z0]) cube([2*lid_x, lid_y1 - lid_y0, lid_t]);
    translate([-lid_x, lid_y1 - 4, lid_z0 + lid_t]) cube([2*lid_x, 4, 6]);
  }
}

module cage() {
  n = 14;
  color([0.55, 0.55, 0.58]) {
    for (i = [-n : n]) {
      bx = i * bar_pitch;
      if (abs(bx) > door_w/2 + 1)
        translate([bx, cage_y0 + bar_dia/2, -70]) cylinder(r = bar_dia/2, h = 300);
      else {
        translate([bx, cage_y0 + bar_dia/2, -70]) cylinder(r = bar_dia/2, h = 70);
        translate([bx, cage_y0 + bar_dia/2, door_h]) cylinder(r = bar_dia/2, h = 130);
      }
    }
    translate([-n*bar_pitch, cage_y0 + bar_dia/2, 0]) rotate([0, 90, 0]) cylinder(r = bar_dia/2, h = 2*n*bar_pitch);
    translate([-n*bar_pitch, cage_y0 + bar_dia/2, door_h + bar_dia/2]) rotate([0, 90, 0]) cylinder(r = bar_dia/2, h = 2*n*bar_pitch);
  }
}

module cavity() {
  difference() {
    yz(cav, -tank_in_x, tank_in_x);
    tank();
    base();
  }
}

if (part == "base") base();
else if (part == "tank") tank();
else if (part == "tray") tray();
else if (part == "lid") lid();
else if (part == "cavity") cavity();
else if (part == "cage") cage();
else if (part == "assembly" || part == "assembly_nocage") {
  color([0.86, 0.86, 0.9]) base();
  color([0.75, 0.78, 0.85]) tank();
  color([0.92, 0.6, 0.25]) tray();
  color([0.35, 0.7, 0.9]) lid();
  if (part == "assembly") cage();
}
