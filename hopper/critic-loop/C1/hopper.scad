part = "assembly";

$fn = 48;

target_L    = 1.036;
wall        = 3.0;
cav_w       = 114;
slot_gap    = 52;
wall_ang    = 65;

open_w      = 110;
open_h      = 110;
bar_d       = 3.5;
bar_pitch   = 12;

front_y     = 3;
thr_y0      = 40;
thr_y1      = thr_y0 + slot_gap;
thr_z0      = 48;
thr_z1      = 70;
conv_run    = thr_y0 - front_y;
conv_rise   = conv_run * tan(wall_ang);
conv_z      = thr_z1 + conv_rise;
back_y      = thr_y1 + conv_run;
cav_d       = back_y - front_y;
cav_ztop    = conv_z + (target_L*1e6/cav_w - slot_gap*(thr_z1-thr_z0)
                        - (slot_gap + cav_d)/2*conv_rise) / cav_d;

sx_in       = cav_w/2;
sx_out      = sx_in + wall;

fl_t        = wall;
fl_w        = 2*sx_out;
fl_z0       = -16;
fl_z1       = cav_ztop + 1;
win_w       = 100;
win_z0      = 44;
win_z1      = 88;
win_rib     = 8;

hous_y1     = thr_y1 + wall;
floor_z0    = 15;
tray_y0     = 9;
tray_y1     = thr_y0;
tray_z0     = 21;
deck_z1     = 24;
lip_z1      = 40;
chan_top    = 45;
tray_top    = 44.0;
clr         = 0.4;
rail_z0     = 30;
rail_z1     = 36;
rail_d      = 3.0;
rail_t      = 2.5;
tray_wall   = 2.6;

perch_r     = 7;
perch_y     = -14;
perch_z     = 15;
perch_hw    = 52;

mnt_hw      = 48;
mnt_yin     = -8;
mnt_fin_y   = -5.2;
hook_z0     = -16;
hook_z1     = 10;
keep_z0     = 84;
keep_z1     = 93;

rim_h       = 30;
rim_t       = 2.5;
grv_d       = 1.2;
grv_h       = 4;
spg_t       = 2.5;
snap_x0     = sx_in - 13;
lid_t       = 3.6;
lid_h       = 14;

module ex(x0,x1)  { translate([x0,0,0]) rotate([90,0,90]) linear_extrude(height=x1-x0) children(); }
module exy(y0,y1) { translate([0,y1,0]) rotate([90,0,0]) linear_extrude(height=y1-y0) children(); }
module clipz(a,b) { intersection() { children(); translate([-400,a]) square([1200,b-a]); } }
module clipy(a,b) { intersection() { children(); translate([-600,a]) square([1200,b-a]); } }
module rnd(r)     { offset(r=r) offset(r=-2*r) offset(r=r) children(); }

cav_pts     = [[thr_y0,thr_z0],[thr_y1,thr_z0],[thr_y1,thr_z1],[back_y,conv_z],
               [back_y,cav_ztop],[front_y,cav_ztop],[front_y,conv_z],[thr_y0,thr_z1]];
cav_pts_ext = [[thr_y0,thr_z0-14],[thr_y1,thr_z0-14],[thr_y1,thr_z1],[back_y,conv_z],
               [back_y,cav_ztop+14],[front_y,cav_ztop+14],[front_y,conv_z],[thr_y0,thr_z1]];

module cav2d()       { polygon(cav_pts); }
module cav2d_ext()   { polygon(cav_pts_ext); }
module sideplate2d() { clipz(thr_z0, cav_ztop) offset(delta=wall) cav2d(); }
module shell2d()     { difference() { sideplate2d(); cav2d_ext(); } }
module spigot2d()    { clipz(thr_z0+3, cav_ztop-rim_h-1)
                         difference() { offset(delta=-clr) cav2d(); offset(delta=-clr-spg_t) cav2d(); } }
module rimring2d()   { clipz(cav_ztop-rim_h, cav_ztop)
                         difference() { cav2d(); offset(delta=-rim_t) cav2d_ext(); } }
module rimplate2d()  { clipz(cav_ztop-rim_h, cav_ztop) cav2d(); }

module hous_base2d() {
  union() {
    translate([0, floor_z0])        square([hous_y1, tray_z0-floor_z0]);
    translate([thr_y0, tray_z0])    square([hous_y1-thr_y0, deck_z1-tray_z0]);
    translate([thr_y0, deck_z1])    square([2*rail_d, lip_z1-deck_z1]);
    translate([0, fl_z0])           square([tray_y0, chan_top-fl_z0]);
    translate([hous_y1-wall, floor_z0]) square([wall, thr_z0-floor_z0]);
  }
}
module chan2d()       { translate([tray_y0, tray_z0]) square([tray_y1-tray_y0, chan_top-tray_z0]); }
module hous_solid2d() { union() { hous_base2d(); chan2d(); } }
module hous2d() {
  difference() {
    hous_base2d();
    translate([tray_y0-rail_d, rail_z0]) square([rail_d+0.01, rail_z1-rail_z0]);
    translate([tray_y1-0.01, rail_z0]) square([rail_d+0.01, rail_z1-rail_z0]);
  }
}
module aper2d() {
  translate([tray_y0-rail_d-0.5, tray_z0-0.6])
    square([tray_y1-tray_y0+2*rail_d+1, chan_top-tray_z0+0.6]);
}

module xy_taper(a,b,zlo,zhi) {
  translate([0,0,zlo]) linear_extrude(height=zhi-zlo)
    polygon([[a,400],[b,400],[b,0],[(a+b)/2,-(b-a)/2],[a,0]]);
}

module perch2d() {
  rnd(1.2) hull() {
    translate([perch_y, perch_z]) circle(r=perch_r);
    translate([0, perch_z-perch_r+1.5]) square([5, 2*perch_r-3]);
  }
}
module perch() {
  intersection() {
    ex(-perch_hw, perch_hw) perch2d();
    xy_taper(-perch_hw, perch_hw, perch_z-perch_r-4, perch_z+perch_r+4);
  }
}

module hook2d() {
  union() {
    rnd(1.2) union() {
      translate([mnt_yin, 0]) square([fl_t-mnt_yin, hook_z1]);
      translate([mnt_yin, hook_z0]) square([mnt_fin_y-mnt_yin, -hook_z0]);
    }
    translate([mnt_fin_y-0.01, -4]) square([1.81, 2.5]);
  }
}
module keep2d() { rnd(1.2) translate([mnt_yin, keep_z0]) square([fl_t-mnt_yin, keep_z1-keep_z0]); }

module mount() {
  intersection() { ex(-mnt_hw, mnt_hw) hook2d(); xy_taper(-mnt_hw, mnt_hw, hook_z0-2, hook_z1+2); }
  intersection() { ex(-mnt_hw, mnt_hw) keep2d(); xy_taper(-mnt_hw, mnt_hw, keep_z0-2, keep_z1+2); }
}

module flange2d() {
  hull() for (sx=[-1,1], sz=[0,1])
    translate([sx*(fl_w/2-5), sz==0 ? fl_z0+5 : fl_z1-5]) circle(r=5);
}
module window2d() {
  hw = win_w/2; zm = (win_z0+win_z1)/2; r = (win_z1-win_z0)/2;
  difference() {
    rnd(4) polygon([[-hw,zm],[-hw+r,win_z1],[hw-r,win_z1],[hw,zm],[hw-r,win_z0],[-hw+r,win_z0]]);
    translate([-win_rib/2, win_z0-1]) square([win_rib, win_z1-win_z0+2]);
  }
}
module flange() { difference() { exy(0, fl_t) flange2d(); exy(-2, fl_t+2) window2d(); } }

snap_pockets = [ [back_y, 1, cav_ztop-24], [front_y, -1, cav_ztop-24],
                 [thr_y1, 1, 59], [thr_y0, -1, 59] ];
function inner_face(p) = p[0] - p[1]*rim_t;
boss_x1 = 52;

module snap_bosses() {
  for (p = snap_pockets) if (p[2] < 100) hull() {
    translate([snap_x0, p[1] > 0 ? p[0]-rim_t : p[0]-0.5, p[2]-8]) cube([boss_x1-snap_x0, rim_t+0.5, 16]);
    translate([snap_x0-3, p[1] > 0 ? p[0] : p[0]-0.5, p[2]-8]) cube([0.01, 0.5, 16]);
  }
}
module cover_pockets() {
  for (p = snap_pockets)
    translate([snap_x0-1, inner_face(p) + (p[1] > 0 ? -0.6 : -1.5), p[2]-5]) cube([4, 2.1, 10]);
}
module cover_snaps() {
  for (p = snap_pockets) {
    translate([snap_x0, inner_face(p) + (p[1] > 0 ? -spg_t : 0), p[2]-6]) cube([13, spg_t, 12]);
    translate([snap_x0, inner_face(p) + (p[1] > 0 ? 0 : -1.4), p[2]-4]) cube([2.5, 1.4, 8]);
  }
}
module detents() {
  translate([-snap_x0, tray_y0-rail_d-0.9, 33]) sphere(r=1.6);
  translate([-snap_x0, tray_y1+rail_d+0.9, 33]) sphere(r=1.6);
}

module lid_outline2d() { translate([-sx_out, front_y]) square([2*sx_out, back_y+wall-front_y]); }
module lid_groove() {
  translate([0,0,cav_ztop-lid_h+4]) linear_extrude(height=grv_h)
    clipy(front_y+9, back_y-2) difference() { offset(delta=4) lid_outline2d(); offset(delta=-grv_d) lid_outline2d(); }
}
module lid_ridge() {
  translate([0,0,cav_ztop-lid_h+4]) linear_extrude(height=grv_h)
    clipy(front_y+9, back_y-2) difference() { offset(delta=clr) lid_outline2d(); offset(delta=clr-grv_d) lid_outline2d(); }
}

module body() {
  difference() {
    union() {
      ex(-sx_out, -sx_in)          difference() { union() { sideplate2d(); hous_solid2d(); } aper2d(); }
      ex(-sx_in, -sx_in+rim_t)     rimplate2d();
      ex(-sx_in, sx_in)            union() { shell2d(); hous2d(); }
      ex(-sx_in+rim_t, sx_in-rim_t-clr) rimring2d();
      ex(sx_in-0.6, sx_out)        difference() { hous_solid2d(); aper2d(); }
      flange();
      mount();
      perch();
      snap_bosses();
      detents();
    }
    cover_pockets();
    lid_groove();
  }
}

module sidecover() {
  difference() {
    union() {
      ex(sx_in, sx_out)       sideplate2d();
      ex(sx_in-rim_t, sx_in)  rimplate2d();
      ex(sx_in-spg_t-2, sx_in) spigot2d();
      cover_snaps();
    }
    lid_groove();
  }
}

lid_z0 = cav_ztop - lid_h;

module lid() {
  intersection() {
    union() {
      difference() {
        translate([0,0,lid_z0]) linear_extrude(height=lid_h+lid_t) offset(r=clr+lid_t) lid_outline2d();
        translate([0,0,lid_z0-1]) linear_extrude(height=lid_h+1) offset(delta=clr) lid_outline2d();
      }
      lid_ridge();
    }
    translate([-400, front_y, 0]) cube([800,800,800]);
  }
}

module rrect(x0,y0,x1,y1,r) { hull() for (a=[[x0+r,y0+r],[x1-r,y0+r],[x1-r,y1-r],[x0+r,y1-r]]) translate(a) circle(r=r); }

tr_y0 = tray_y0 + clr;
tr_y1 = tray_y1 - clr;
tr_z0 = tray_z0 + clr;
tr_hw = sx_in - 0.6;

module rail2d() {
  polygon([[tr_y0, rail_z0+clr], [tr_y0-rail_t, rail_z0+clr+rail_t], [tr_y0-rail_t, rail_z1-clr], [tr_y0, rail_z1-clr]]);
  polygon([[tr_y1, rail_z0+clr], [tr_y1, rail_z1-clr], [tr_y1+rail_t, rail_z1-clr], [tr_y1+rail_t, rail_z0+clr+rail_t]]);
}

module tray() {
  difference() {
    union() {
      translate([0,0,tr_z0]) linear_extrude(height=tray_top-tr_z0) rrect(-tr_hw, tr_y0, tr_hw, tr_y1, 3);
      ex(-(tr_hw-1.5), tr_hw-1.5) rail2d();
      translate([0,0,tr_z0]) linear_extrude(height=tray_top-tr_z0)
        rrect(-(sx_out+6), tr_y0+2, -(tr_hw-2), tr_y1-2, 3);
    }
    hull() {
      translate([0,0,tr_z0+tray_wall]) linear_extrude(height=0.1)
        rrect(-(tr_hw-tray_wall), tr_y0+tray_wall, tr_hw-tray_wall, tr_y1-tray_wall, 3);
      translate([0,0,rail_z1]) linear_extrude(height=0.1)
        rrect(-(tr_hw-tray_wall), tr_y0+tray_wall, tr_hw-tray_wall, tr_y1-tray_wall, 3);
      translate([0,0,tray_top+2]) linear_extrude(height=0.1)
        rrect(-(tr_hw-tray_wall-3.0), tr_y0+tray_wall+3.0, tr_hw-tray_wall-3.0, tr_y1-tray_wall-3.0, 3);
    }
  }
}

module cage() {
  difference() {
    union() {
      for (i=[-9:9]) translate([i*bar_pitch - bar_d/2, -bar_d, -80]) cube([bar_d, bar_d, 320]);
      translate([-120, -bar_d, -bar_d]) cube([240, bar_d, bar_d]);
      translate([-120, -bar_d, open_h])  cube([240, bar_d, bar_d]);
    }
    translate([-open_w/2, -10, 0.001]) cube([open_w, 20, open_h-0.002]);
  }
}

module cavity() {
  difference() {
    ex(-sx_in, sx_in) clipz(thr_z0, cav_ztop) cav2d();
    ex(-sx_in-1, -sx_in+rim_t) rimplate2d();
    ex(sx_in-rim_t, sx_in+1) rimplate2d();
    ex(-sx_in+rim_t, sx_in-rim_t-clr) rimring2d();
    snap_bosses();
  }
}

if      (part == "body")      body();
else if (part == "sidecover") sidecover();
else if (part == "lid")       lid();
else if (part == "tray")      tray();
else if (part == "cavity")    cavity();
else if (part == "assembly")  {
  body();
  translate([0.05,0,0]) sidecover();
  translate([0,0,0.05]) lid();
  translate([0,0,0.05]) tray();
  %cage();
}
