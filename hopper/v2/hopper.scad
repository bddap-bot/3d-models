part = "assembly";

t        = 2.4;
W_in     = 130;
H        = 120;
y_back0  = 5;
y_backT  = -48;
y_front  = 55;
bar_d    = 2.5;
door_w   = 140;
door_h   = 170;
overlap  = 15;
clr      = 0.3;
seam_clr = 0.2;
seam_lap = 6;
lid_t    = 2.4;
plate_t  = 3;
groove_d = 2.5;
tray_w   = 144;
tray_d   = 100;
tray_h   = 30;
lip      = 8;
perch_d  = 16;
r_edge   = 4;
ch       = 1.2;

hw       = W_in/2;
x_out    = hw + t;
z_roof   = H + t;
run      = y_back0 - y_backT;
ang      = atan2(H, run);
th_y     = t/sin(ang);
z_door0  = -(door_h - z_roof)/2;
z_door1  = z_door0 + door_h;
z_fl0    = z_door0 - overlap;
y_fl0    = -bar_d - plate_t;
y_fl1    = -bar_d;
y_lip0   = y_fl1 - t;
z_lidbot = H - 3;
z_ledge  = z_lidbot - clr - t;
p_back0  = [y_back0-th_y, 0];
p_backT  = [y_backT-th_y-run*t/H, z_roof];
y_lid0   = p_backT[0] - 3;
z_fl1    = 60;
y_ledge0 = y_backT - th_y;
y_plate0 = clr;
y_plate1 = clr + plate_t;
x_win    = x_out - groove_d + clr;
x_plate  = door_w/2 + overlap - 2.3;
z_plate0 = -38;
z_plate1 = 3.5 + (door_w/2 + overlap - 2.3) - (W_in/2 + t - groove_d + clr) + 4;
z_shelf1 = -10;
y_tray0  = y_plate1 + 0.5;
y_shelf1 = y_tray0 + tray_d + 3.5;
perch_y  = y_shelf1 - 1.25;
perch_z  = -25;

echo(wall_angle_deg=ang, slot_width=y_front-y_back0, through_w=2*x_out, through_h=z_roof, door_z0=z_door0);

module prof_interior() polygon([[y_back0,0],[y_front,0],[y_front,H],[y_backT,H]]);
module prof_outer()    polygon([p_back0,[y_front+t,0],[y_front+t,z_roof],p_backT]);
module yz(x0,x1) translate([x0,0,0]) rotate([90,0,90]) linear_extrude(height=x1-x0) children();

module outside_back_wall() polygon([p_back0+3*(p_back0-p_backT), p_backT-3*(p_back0-p_backT), [-300,4*z_roof], [-300,-3*z_roof]]);

module body() {
  difference() {
    union() {
      difference() {
        yz(-x_out,x_out) prof_outer();
        yz(-hw,hw) prof_interior();
        translate([-hw, y_lid0-5, z_lidbot-clr]) cube([W_in, y_lip0-y_lid0+5, 50]);
      }
      intersection() {
        translate([-x_out,y_fl0,z_fl0]) cube([2*x_out, plate_t, z_fl1-z_fl0]);
        yz(-200,200) outside_back_wall();
      }
      translate([-x_out,y_lip0,z_ledge]) cube([2*x_out, t, z_roof-z_ledge]);
      for (s=[-1,1]) mirror([s<0?1:0,0,0]) intersection() {
        union() {
          translate([hw-4,y_ledge0-3,z_ledge]) cube([4+t, y_lip0-y_ledge0+3, t]);
          translate([hw-4,y_ledge0-3,H]) cube([4+t, y_lip0-y_ledge0+3, t]);
          translate([hw-3,y_plate0-clr-t,0]) cube([3+t, plate_t+2*clr+2*t, z_roof]);
        }
        yz(0,x_out) prof_outer();
      }
    }
    for (s=[-1,1]) mirror([s<0?1:0,0,0]) translate([x_out-groove_d, y_plate0-clr, -1]) cube([groove_d+1, plate_t+2*clr, z_roof+2]);
  }
}

module lap(g) {
  difference() { offset(delta=1) prof_outer(); offset(delta=t/2+g) prof_interior(); }
  translate([y_lip0-1, z_ledge-1]) square([1+t/2-g, z_roof-z_ledge+2]);
  intersection() { translate([y_fl0-1, z_fl0-1]) square([plate_t+1, z_fl1-z_fl0+2]); outside_back_wall(); }
}

module body_half(tongue) intersection() {
  body();
  difference() {
    union() {
      yz(seam_clr/2, x_out+1) square(1000, center=true);
      if (tongue) yz(-seam_lap, seam_clr/2) lap(seam_clr);
    }
    if (!tongue) yz(seam_clr/2-1, seam_lap+seam_clr) lap(0);
  }
}

module body_R() body_half(true);
module body_L() mirror([1,0,0]) body_half(false);

module lid() {
  z_hb1 = z_door1 + overlap;
  lid_len = y_lip0 - clr - y_lid0;
  translate([-hw+clr, y_lid0, z_lidbot]) cube([W_in-2*clr, lid_len, lid_t]);
  translate([-hw+clr, y_lid0, z_lidbot]) cube([W_in-2*clr, t, lid_t+6]);
  translate([-x_plate, y_lip0-4, z_roof+clr]) cube([2*x_plate, 4+t, z_hb1-z_roof-clr]);
  translate([-hw+4+clr, y_lip0-4, z_lidbot]) cube([W_in-8-2*clr, 4-clr, z_roof+clr-z_lidbot]);
  for (s=[-1,1]) translate([s>0 ? x_out+clr : -x_plate, y_lip0-4, z_lidbot]) cube([x_plate-x_out-clr, 4+t, z_roof+clr-z_lidbot]);
}

module rounded_plate(w, h, r) offset(r=r) offset(delta=-r) square([w,h]);

module bracket() {
  difference() {
    translate([-x_plate, y_plate1, z_plate0]) rotate([90,0,0]) linear_extrude(height=plate_t) rounded_plate(2*x_plate, z_plate1-z_plate0, r_edge);
    translate([0, y_plate1+1, 0]) rotate([90,0,0]) linear_extrude(height=plate_t+2)
      polygon([[-x_win,-0.5],[x_win,-0.5],[x_win,3.5],[x_win+100,103.5],[-x_win-100,103.5],[-x_win,3.5]]);
  }
  translate([-x_plate, y_plate0, z_shelf1-plate_t]) cube([2*x_plate, y_shelf1-y_plate0, plate_t]);
  for (s=[-1,1]) translate([s*(tray_w/2-ch+clr), y_plate0, z_shelf1]) rotate([-90,0,0]) linear_extrude(height=y_shelf1-y_plate0)
    polygon([[0,0],[s*ch,0],[s*ch,-ch]]);
  translate([-x_plate, y_shelf1-plate_t, z_shelf1]) cube([2*x_plate, plate_t, 7]);
  translate([-x_plate, y_shelf1-plate_t, perch_z]) cube([2*x_plate, plate_t, z_shelf1-perch_z]);
  translate([-x_plate, perch_y, perch_z]) rotate([0,90,0]) cylinder(d=perch_d, h=2*x_plate, $fn=48);
}

module tray() {
  fl = 2.4; z0 = z_shelf1;
  yl = y_tray0 + 60;
  difference() {
    translate([-tray_w/2, y_tray0, z0]) linear_extrude(height=tray_h) rounded_plate(tray_w, tray_d, 6);
    translate([-tray_w/2+t, y_tray0+t, z0+fl]) linear_extrude(height=tray_h) rounded_plate(tray_w-2*t, tray_d-2*t, 6-t);
    translate([-tray_w/2-1, y_tray0-1, z0+8]) cube([tray_w+2, t+1, tray_h]);
    for (s=[-1,1]) translate([s>0 ? 64.5 : -tray_w/2-1, y_tray0-1, -0.5]) cube([tray_w/2+1-64.5, 8, tray_h]);
    for (s=[-1,1]) translate([s*tray_w/2, y_tray0-1, 0]) rotate([-90,0,0]) linear_extrude(height=tray_d+2)
      polygon([[0,-z0+1],[-s*(ch+1),-z0+1],[0,-z0-ch]]);
  }
  intersection() {
    translate([-tray_w/2, y_tray0, z0]) linear_extrude(height=tray_h) rounded_plate(tray_w, tray_d, 6);
    union() {
      translate([0, y_tray0+tray_d, z0+tray_h-lip-t*sqrt(2)]) yz(-tray_w/2, tray_w/2) polygon([[0,0],[-lip,lip],[-lip,lip+t*sqrt(2)],[0,lip+t*sqrt(2)]]);
      for (s=[-1,1]) translate([s*tray_w/2, yl, z0+tray_h-lip-t*sqrt(2)]) rotate([90,0,0]) mirror([0,0,1]) linear_extrude(height=tray_d-60)
        polygon([[0,0],[-s*lip,lip],[-s*lip,lip+t*sqrt(2)],[0,lip+t*sqrt(2)]]);
    }
  }
}

module assembly() {
  color("SteelBlue") body_R();
  color("SteelBlue") body_L();
  color("Orange") lid();
  color("SeaGreen") bracket();
  color("Gold") tray();
}

if (part=="body_R") body_R();
if (part=="body_L") body_L();
if (part=="lid") lid();
if (part=="bracket") bracket();
if (part=="tray") tray();
if (part=="assembly") assembly();
if (part=="seam") intersection() { union() { translate([5,0,0]) body_R(); translate([-5,0,0]) body_L(); } translate([-25,-200,50]) cube([50,400,10]); }
if (part=="section") intersection() { assembly(); translate([-400,-200,-200]) cube([400,400,400]); }
