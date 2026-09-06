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
groove_d = 2.7;
tray_w   = 144;
tray_d   = 100;
tray_h   = 30;
lip      = 8;
perch_d  = 16;
r_edge   = 4;
ch       = 1.2;
slit     = 1.5;
catch_d  = 1.2;
catch_clr = clr;
z_catch  = 18;
stop_h   = 2.5;
perch_fwd = 40;
perch_drop = 35;

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
finger_w = groove_d - clr;
x_slit   = x_out + slit;
z_finger = z_catch + catch_d;
z_groove = z_finger + catch_clr + 1;
z_rib    = z_finger + 9;
z_plate1 = z_finger + 6;
z_shelf1 = -10;
y_tray0  = y_plate1 + 0.5;
y_tray1  = y_tray0 + tray_d;
y_shelf1 = y_tray1 + 3.5;
perch_y  = y_tray1 + perch_fwd;
perch_z  = z_shelf1 + tray_h - perch_drop;
z_arm0   = perch_z - plate_t/2;

echo(wall_angle_deg=ang, slot_width=y_front-y_back0, through_w=2*x_out, through_h=z_roof, door_z0=z_door0);

module prof_interior() polygon([[y_back0,0],[y_front,0],[y_front,H],[y_backT,H]]);
module prof_outer()    polygon([p_back0,[y_front+t,0],[y_front+t,z_roof],p_backT]);
module yz(x0,x1) translate([x0,0,0]) rotate([90,0,90]) linear_extrude(height=x1-x0) children();
module xz(y0,y1) translate([0,y1,0]) rotate([90,0,0]) linear_extrude(height=y1-y0) children();
module catch(g) offset(r=g) polygon([[x_win,z_catch],[x_win-catch_d,z_catch],[x_win,z_finger]]);

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
          xz(y_plate0-clr-t, y_plate1+clr+t) polygon([[hw-4,0],[x_out,0],[x_out,z_rib],[hw,z_rib],[hw-4,z_rib-4*tan(ang)]]);
        }
        yz(0,x_out) prof_outer();
      }
    }
    for (s=[-1,1]) mirror([s<0?1:0,0,0]) {
      translate([x_out-groove_d, y_plate0-clr, -1]) cube([groove_d+1, plate_t+2*clr, z_groove+1]);
      xz(y_plate0-clr, y_plate1+clr) catch(catch_clr);
    }
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
    xz(y_plate0-1, y_plate1+1)
      polygon([[-x_slit,-0.5],[x_slit,-0.5],[x_slit,z_finger],[x_slit+100,z_finger+100],[-x_slit-100,z_finger+100],[-x_slit,z_finger]]);
  }
  for (s=[-1,1]) mirror([s<0?1:0,0,0]) xz(y_plate0, y_plate1) {
    translate([x_win,-1]) square([finger_w, z_finger+1]);
    catch(0);
  }
  yz(-x_plate, x_plate) {
    translate([y_plate0, z_shelf1-plate_t]) square([y_shelf1-y_plate0, plate_t]);
    polygon([[y_shelf1-plate_t-(z_shelf1-plate_t-z_arm0), z_shelf1-plate_t],[y_shelf1, z_shelf1-plate_t],[y_shelf1, z_arm0],[y_shelf1-plate_t, z_arm0]]);
    polygon([[y_shelf1-plate_t-stop_h, z_shelf1],[y_shelf1, z_shelf1],[y_shelf1, z_shelf1+stop_h],[y_shelf1-plate_t, z_shelf1+stop_h]]);
    translate([y_shelf1-plate_t, z_arm0]) square([perch_y-y_shelf1+plate_t, plate_t]);
    hull() { translate([perch_y, perch_z]) circle(d=perch_d, $fn=48); translate([perch_y-perch_d/sqrt(2), perch_z]) square(0.4, center=true); }
  }
  for (s=[-1,1]) translate([s*(tray_w/2-ch+clr), y_plate0, z_shelf1]) rotate([-90,0,0]) linear_extrude(height=y_shelf1-y_plate0)
    polygon([[0,0],[s*ch,0],[s*ch,-ch]]);
}

module tray() {
  fl = t; z0 = z_shelf1;
  yl = y_tray0 + 60;
  difference() {
    translate([-tray_w/2, y_tray0, z0]) linear_extrude(height=tray_h) rounded_plate(tray_w, tray_d, 6);
    hull() {
      translate([-tray_w/2+t, y_tray0+t, z0+fl+2]) linear_extrude(height=tray_h) rounded_plate(tray_w-2*t, tray_d-2*t, 6-t);
      translate([-tray_w/2+t, y_tray0+t, z0+fl]) linear_extrude(height=0.01) offset(delta=-2) rounded_plate(tray_w-2*t, tray_d-2*t, 6-t);
    }
    translate([-tray_w/2-1, y_tray0-1, z0+8]) cube([tray_w+2, t+1, tray_h]);
    for (s=[-1,1]) translate([s>0 ? 64.5 : -tray_w/2-1, y_tray0-1, -0.5]) cube([tray_w/2+1-64.5, 8, tray_h]);
    for (s=[-1,1]) translate([s*tray_w/2, y_tray0-1, 0]) rotate([-90,0,0]) linear_extrude(height=tray_d+2)
      polygon([[0,-z0+1],[-s*(ch+1),-z0+1],[0,-z0-ch]]);
    yz(-tray_w/2-1, tray_w/2+1) polygon([[y_tray1-stop_h-1, z0-1],[y_tray1+1, z0-1],[y_tray1+1, z0+stop_h+1]]);
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

module clip(box) if (is_undef(box)) children(); else render() intersection() { children(); translate(box[0]) cube(box[1]); }

module assembly(box=undef) {
  color("SteelBlue") clip(box) body_R();
  color("SteelBlue") clip(box) body_L();
  color("Orange") clip(box) lid();
  color("SeaGreen") clip(box) bracket();
  color("Gold") clip(box) tray();
}

module conure() color("Gray", 0.5) yz(-3,3) {
  translate([perch_y-10, perch_z+perch_d/2+40]) scale([22,30]) circle(1, $fn=64);
  translate([perch_y-28, perch_z+perch_d/2+84]) circle(16, $fn=48);
  polygon([[perch_y+4,perch_z+35],[perch_y+14,perch_z+38],[perch_y+48,perch_z-40],[perch_y+38,perch_z-43]]);
}

if (part=="body_R") body_R();
if (part=="body_L") body_L();
if (part=="lid") lid();
if (part=="bracket") bracket();
if (part=="tray") tray();
if (part=="assembly") assembly();
if (part=="seam") intersection() { union() { translate([5,0,0]) body_R(); translate([-5,0,0]) body_L(); } translate([-25,-200,50]) cube([50,400,10]); }
half = [[-400,-200,-200],[400,400,400]];
if (part=="section") assembly(half);
if (part=="perch") { assembly(half); conure(); }
if (part=="catch") assembly([[x_win-15, y_plate0+plate_t/2-0.3, -8],[30, 0.6, 35]]);
