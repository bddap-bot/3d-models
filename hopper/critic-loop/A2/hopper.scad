part = "assembly";

$fn = 28;

wall_min  = 2.4;
w3        = 3.0;
clr       = 0.4;

bar_x1    = 3.5;
bar_pitch = 12;
open_hw   = 55;
open_hh   = 55;
wire_d    = 3.5;

fl_x0     = bar_x1;
fl_x1     = fl_x0 + 5;
fl_hw     = 70;
fl_z0     = -95;
fl_z1     = 14;

ap_hw     = 53;
ap_z0     = -40;

post_y0   = 42;
post_y1   = 66;
post_z1   = 70;
prong_x0  = -3.0;
prong_x1  = -0.5;
prong_z0  = 55;
wrap_z0   = 58.5;
hook_z1   = 63;

lat_t     = wall_min;
lat_x0    = fl_x1 - lat_t;
lat_hw    = 9;
lat_y     = 52;
fin_y     = [46,58];
fin_hw    = 2;
lat_root  = -87;
lat_top   = -50;
lat_z_bot = -66;
lat_slot  = 2.5;

perch_d   = 16;
perch_x   = -24;
perch_z   = -42;
perch_hl  = 45;
pweb_y    = 40;
pweb_z0   = -52;

slot_z    = 14;
cav_x0    = 12;
cav_x1    = 62;
cav_hw    = 45;
wall_ang  = 70;
cav_top   = 165;
fill_top  = 160;
cot       = 1/tan(wall_ang);
off_h     = w3/sin(wall_ang);
hop_hw    = cav_hw + w3;
rib_y1    = 55.6;
rib_x1    = 70;
rib_z1    = 30;

ledge_y   = 51;
ledge_z0  = 11;
web_y0    = rib_y1 + clr;
web_y1    = web_y0 + w3;
web_x1    = 74;
web_z0    = -33;
web_z1    = rib_z1;
stop_x0   = rib_x1 + clr;

rail_y    = 47;
rail_z1   = -30;
rail2_y   = 49;
rail2_z0  = -23.2;
rail_x1   = 70;
det_x0    = 20;
det_x1    = 27;

tray_x0   = -2;
tray_x1   = 66;
tray_z0   = -30;
tray_z1   = 13.0;
tray_hw   = 48.5;
tray_fl_hw= 52;
tray_fl_x0= 9;

lid_deep  = 12;
lid_t     = 3.5;

module bx(a,b) { translate(a) cube([b[0]-a[0], b[1]-a[1], b[2]-a[2]]); }

module rb(a,b,r=1.5) {
  rr = min(r, (b[0]-a[0])/2, (b[1]-a[1])/2, (b[2]-a[2])/2);
  hull() for (x=[a[0]+rr,b[0]-rr]) for (y=[a[1]+rr,b[1]-rr]) for (z=[a[2]+rr,b[2]-rr])
    translate([x,y,z]) sphere(rr);
}

function back_in(z)  = cav_x1 + cot*(z-slot_z);
function back_out(z) = back_in(z) + off_h;

module wedge_prism(prof, y0, y1)
  translate([0,y1,0]) rotate([90,0,0]) linear_extrude(height=y1-y0) polygon(prof);

module ap_prof(g=0) {
  hull() {
    for (t=[-1,1]) translate([0, t*(ap_hw-4), ap_z0+4]) rotate([0,90,0]) cylinder(r=4+g, h=0.01);
    translate([0, -ap_hw-g, fl_z1-0.01]) cube([0.01, 2*(ap_hw+g), 0.01]);
  }
}

module ap_cut() {
  hull() { translate([fl_x0-3,0,0]) ap_prof(1.5); translate([fl_x1+3,0,0]) ap_prof(0); }
}

module hook() {
  for (fy = fin_y) {
    a = fy-fin_hw; b = fy+fin_hw;
    rb([prong_x0, a, wrap_z0], [fl_x1, b, hook_z1], 1.0);
    rb([prong_x0, a, prong_z0], [prong_x1, b, hook_z1], 1.0);
  }
}

module latch_arm(yc) {
  y0 = yc - lat_hw; y1 = yc + lat_hw;
  union() {
    bx([lat_x0, y0, lat_root], [fl_x1, y1, lat_top]);
    for (fy = fin_y) {
      a = fy-fin_hw; b = fy+fin_hw;
      rb([-1, a, lat_z_bot], [fl_x1, b, lat_z_bot+4], 1.0);
      hull() {
        rb([-1, a, lat_z_bot+2], [2.5, b, -58], 0.9);
        rb([-1, a, lat_z_bot+2], [1.2, b, -55.5], 0.9);
      }
    }
    rb([fl_x1-1, y0+3, lat_top-8], [fl_x1+9, y1-3, lat_top], 1.5);
  }
}

module side_frame() {
  union() {
    bx([fl_x1-1, web_y0, web_z0], [web_x1, web_y1, web_z1]);
    hull() {
      bx([fl_x1-1, ledge_y, ledge_z0], [rib_x1, web_y1, slot_z]);
      bx([fl_x1-1, web_y0, ledge_z0-(web_y0-ledge_y)], [rib_x1, web_y1, ledge_z0]);
    }
    bx([stop_x0, ledge_y, slot_z], [stop_x0+3, web_y1, rib_z1]);
    bx([fl_x1-1, rail_y, web_z0], [rail_x1, web_y1, rail_z1]);
    bx([fl_x1-1, rail2_y, rail2_z0], [rail_x1, web_y1, rail2_z0+3]);
    hull() {
      bx([det_x0+1, rail_y, rail_z1], [det_x1-1, web_y1, rail_z1+0.6]);
      bx([det_x0, rail_y, rail_z1-0.5], [det_x1, web_y1, rail_z1]);
    }
  }
}

module perch() {
  union() {
    hull() {
      translate([perch_x,-perch_hl,perch_z]) rotate([-90,0,0]) cylinder(d=perch_d, h=2*perch_hl);
      translate([perch_x,-perch_hl,perch_z-perch_d*0.45]) rotate([-90,0,0]) cylinder(d=5, h=2*perch_hl);
    }
    for (s=[0,1]) mirror([0,s,0])
      rb([perch_x-perch_d/2, pweb_y-w3, pweb_z0], [fl_x1, pweb_y, ap_z0], 1.2);
  }
}

module base() {
  difference() {
    union() {
      rb([fl_x0,-fl_hw,fl_z0],[fl_x1,fl_hw,fl_z1], 2);
      for (s=[0,1]) mirror([0,s,0]) rb([fl_x0,post_y0,fl_z1],[fl_x1,post_y1,post_z1], 2);
      for (s=[0,1]) mirror([0,s,0]) hook();
      for (s=[0,1]) mirror([0,s,0]) side_frame();
      for (s=[0,1]) mirror([0,s,0]) latch_arm(lat_y);
      perch();
    }
    ap_cut();
    for (s=[0,1]) mirror([0,s,0]) for (d=[-1,1])
      bx([lat_x0-6, lat_y+d*lat_hw-lat_slot/2, lat_root], [fl_x1+2, lat_y+d*lat_hw+lat_slot/2, lat_top]);
    for (s=[0,1]) mirror([0,s,0])
      bx([fl_x0-0.01, lat_y-lat_hw, lat_root], [lat_x0, lat_y+lat_hw, lat_z_bot]);
  }
}

module hopper_outer() {
  union() {
    wedge_prism([[fl_x1,slot_z],[back_out(slot_z),slot_z],[back_out(cav_top),cav_top],[fl_x1,cav_top]],
                -hop_hw, hop_hw);
    for (s=[0,1]) mirror([0,s,0]) rb([fl_x1, hop_hw-1, slot_z], [rib_x1, rib_y1, rib_z1], 1.2);
  }
}

module hopper_cav(zlo=slot_z-2, zhi=cav_top+2) {
  wedge_prism([[cav_x0,zlo],[back_in(zlo),zlo],[back_in(zhi),zhi],[cav_x0,zhi]], -cav_hw, cav_hw);
}

module hopper() {
  difference() {
    hopper_outer();
    hopper_cav();
  }
}

module lid() {
  lz = cav_top - lid_deep;
  union() {
    rb([fl_x1-lid_t,-hop_hw-lid_t,cav_top],[back_out(cav_top)+lid_t,hop_hw+lid_t,cav_top+lid_t], 1.6);
    difference() {
      wedge_prism([[cav_x0+clr,lz],[back_in(lz)-clr,lz],
                   [back_in(cav_top+lid_t)-clr,cav_top+lid_t],[cav_x0+clr,cav_top+lid_t]],
                  -cav_hw+clr, cav_hw-clr);
      wedge_prism([[cav_x0+clr+w3,lz-1],[back_in(lz)-clr-w3,lz-1],
                   [back_in(cav_top+lid_t+1)-clr-w3,cav_top+lid_t+1],[cav_x0+clr+w3,cav_top+lid_t+1]],
                  -cav_hw+clr+w3, cav_hw-clr-w3);
    }
  }
}

module tray() {
  difference() {
    union() {
      hull() {
        rb([tray_x0,-tray_hw,tray_z0],[tray_x1,tray_hw,tray_z1-6], 2);
        rb([tray_x0-1.5,-tray_hw-1.5,tray_z1-2],[tray_x1+1.5,tray_hw+1.5,tray_z1], 2);
      }
      for (s=[0,1]) mirror([0,s,0])
        bx([tray_fl_x0,tray_hw-2,tray_z0],[tray_x1,tray_fl_hw,tray_z0+5.3]);
      rb([tray_x1-3,-22,tray_z1-16],[tray_x1+9,22,tray_z1-2], 2);
    }
    rb([tray_x0+w3,-tray_hw+w3,tray_z0+w3],[tray_x1-w3,tray_hw-w3,tray_z1+25], 3);
    for (s=[0,1]) mirror([0,s,0]) hull() {
      bx([det_x0-0.5, tray_hw-3, tray_z0-1], [det_x1+0.5, tray_fl_hw+1, tray_z0+1.0]);
      bx([det_x0-2.5, tray_hw-3, tray_z0-1], [det_x1+2.5, tray_fl_hw+1, tray_z0-0.6]);
    }
  }
}

module fillsolid() {
  wedge_prism([[cav_x0,slot_z],[back_in(slot_z),slot_z],[back_in(fill_top),fill_top],[cav_x0,fill_top]],
              -cav_hw, cav_hw);
}

module window(x0=-200, x1=bar_x1) { bx([x0,-open_hw,-open_hh],[x1,open_hw,open_hh]); }

module assembly() { union() { base(); hopper(); tray(); lid(); } }

module crossing() { intersection() { assembly(); bx([-200,-200,-200],[bar_x1,200,200]); } }

if (part == "assembly") assembly();
else if (part == "base") base();
else if (part == "hopper") hopper();
else if (part == "tray") tray();
else if (part == "lid") lid();
else if (part == "cavity") fillsolid();
else if (part == "gauge_slot") intersection() { assembly(); bx([cav_x0,-cav_hw,slot_z],[cav_x1,cav_hw,slot_z+4]); }
else if (part == "gauge_fall") intersection() { assembly(); bx([cav_x0,-cav_hw,tray_z1],[cav_x1,cav_hw,slot_z]); }
else if (part == "gauge_cross") difference() { crossing(); window(); }
else if (part == "gauge_cross_y") difference() {
  intersection() { crossing(); bx([-200,-200,-open_hh],[bar_x1,200,open_hh]); } window(); }
else if (part == "gauge_trayout") intersection() { base(); translate([70,0,0]) tray(); }
else if (part == "gauge_hopfit") intersection() { base(); hopper(); }
else if (part == "gauge_lidfit") intersection() { hopper(); lid(); }
else if (part == "gauge_liftpath") intersection() { base(); translate([0,0,60]) hopper(); }
else if (part == "gauge_traytilt") intersection() { base(); translate([0,0,2]) tray(); }
else if (part == "section") {
  difference() {
    union() {
      color("silver") base(); color("skyblue") hopper();
      color("orange") tray(); color("lightgreen") lid();
      color("wheat") fillsolid();
    }
    translate([-200,0,-200]) cube([400,200,500]);
  }
}
else if (part == "assembly_colored") {
  color("silver") base(); color("skyblue") hopper(); color("orange") tray(); color("lightgreen") lid();
}

if (part == "gauge_trayfit") intersection() { base(); tray(); }
else if (part == "gauge_trayslide") intersection() { base(); for (d=[10,20,30,40,50,60,70]) translate([d,0,0]) tray(); }
