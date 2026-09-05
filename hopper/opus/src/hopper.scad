$fn = 40;

door_w        = 140;
door_h        = 170;
bar_pitch     = 12;
bar_d         = 3.2;

wall          = 3.0;
clr           = 0.30;

plate_t       = 4.0;
plate_hw      = 78;
plate_z0      = 2;

cav_hw        = 59;
shell_hw      = cav_hw + wall;

cav_y0        = plate_t + wall;
slot_gap      = 70;
slot_y1       = cav_y0 + slot_gap;
conv_run      = 33;
cav_y1        = slot_y1 + conv_run;

z_slot        = 58;
z_throat      = 70;
wall_ang      = 65;
z_conv        = z_throat + conv_run * tan(wall_ang);
straight_h    = 20;
z_cav_top     = z_conv + straight_h;
z_shell_top   = z_cav_top + wall;

ap_hw         = 68;
ap_z0         = 24;
ap_z1         = 66;

shelf_z0      = 22;
shelf_z1      = 26;
shelf_y1      = 46;

frame_hw      = 72;
frame_y1      = 10;
frame_z0      = 68;
frame_z1      = 156;

tongue_z0     = 141;
tongue_z1     = 152;
key_z0        = 140.7;

perch_slot_z0 = 10;
perch_slot_z1 = 16;
perch_slot_hw = 59;

hook_w        = 7;
hook_x        = 36;
hook_z_top    = 176;
bar_z         = door_h;

tray_hw       = 66;
tray_y0       = -38;
tray_y1       = 80;
tray_z0       = 26;
tray_z1       = 57.4;
tray_wall     = 3.0;
lip_reach     = 7;

lid_t         = 3;

latch_z       = [88, 112, 134];
latch_h       = 10;
latch_len     = 15;
latch_t       = 3.2;

module ext_yz(w) rotate([90,0,90]) linear_extrude(height=w, center=true) children();
module ext_yz_at(x0,w) translate([x0,0,0]) rotate([90,0,90]) linear_extrude(height=w) children();
module rbox(x,y,z,r) hull() for(i=[-1,1],j=[-1,1],k=[-1,1])
  translate([i*(x/2-r), j*(y/2-r), k*(z/2-r)]) sphere(r=r);
module rrect(x0,x1,y0,y1,r) translate([(x0+x1)/2,(y0+y1)/2]) offset(r=r)
  square([x1-x0-2*r, y1-y0-2*r], center=true);

module cav2d()
  polygon([[cav_y0,z_slot],[slot_y1,z_slot],[slot_y1,z_throat],
           [cav_y1,z_conv],[cav_y1,z_cav_top],[cav_y0,z_cav_top]]);

module cav2d_open()
  polygon([[cav_y0,z_slot-10],[slot_y1,z_slot-10],[slot_y1,z_throat],
           [cav_y1,z_conv],[cav_y1,z_cav_top],[cav_y1,z_shell_top+10],[cav_y0,z_shell_top+10]]);

module outer2d()
  intersection(){
    offset(delta=wall) cav2d();
    rrect(cav_y0-wall-1, cav_y1+wall+1, z_slot, z_shell_top, 0);
  }

module walls2d() difference(){ outer2d(); cav2d(); }

module hook2d()
  polygon([[cav_y0-wall, z_shell_top-26],[cav_y0, z_shell_top-26],[cav_y0, hook_z_top],
           [-6, hook_z_top],[-6, bar_z-4],[-2.4, bar_z-4],[-2.4, bar_z+bar_d],
           [cav_y0-wall, bar_z+bar_d]]);

module keyway()
  for(m=[-1,1]) translate([m>0 ? cav_hw : -shell_hw-1, cav_y0-wall-0.5, key_z0])
    cube([wall+1, wall+1.5, z_shell_top-key_z0+2]);

function ywall(z) = min(cav_y1+wall,
  slot_y1 + wall*sin(wall_ang) + (z - (z_throat - wall*cos(wall_ang)))/tan(wall_ang));

module latch_arm()
  for(z=latch_z) union(){
    translate([-latch_len, ywall(z)-1.2, z-latch_h/2]) cube([latch_len+6, latch_t+1.2, latch_h]);
    translate([-latch_len, ywall(z)+latch_t, z-latch_h/2])
      hull(){ cube([0.01, 1.8, latch_h]); translate([3.6,0,0]) cube([0.01, 0.01, latch_h]); }
  }

module latch_pocket()
  for(z=latch_z)
    translate([-latch_len-clr, ywall(z)-clr-1.6, z-latch_h/2-clr])
      cube([latch_len+clr+0.01, latch_t+2.2+clr+1.6, latch_h+2*clr]);

module latch_catch()
  for(z=latch_z) difference(){
    translate([-latch_len-3, ywall(z)-1.6, z-latch_h/2-3.5]) cube([3, latch_t+4.0, latch_h+7]);
    translate([-latch_len-3.5, ywall(z)-0.01, z-latch_h/2-clr]) cube([4, latch_t+2.4+0.02, latch_h+2*clr]);
  }

module shell_body()
  union(){
    difference(){
      ext_yz(2*shell_hw) outer2d();
      ext_yz(2*cav_hw) cav2d_open();
    }
    for(m=[-1,1]) ext_yz_at(m*hook_x - (m>0 ? 0 : hook_w), hook_w) hook2d();
  }

module shell(side){
  union(){
    difference(){
      union(){
        intersection(){
          shell_body();
          translate([side>0 ? 0 : -240, -300, -300]) cube([240,600,600]);
        }
        if(side>0) latch_arm();
      }
      keyway();
      if(side<0) latch_pocket();
    }
    if(side<0) latch_catch();
  }
}

module plate2d()
  difference(){
    rrect(-plate_hw, plate_hw, plate_z0, z_shell_top, 4);
    rrect(-ap_hw, ap_hw, ap_z0, ap_z1, 4);
    rrect(-perch_slot_hw, perch_slot_hw, perch_slot_z0, perch_slot_z1, 2);
  }

module mount()
  union(){
    rotate([90,0,0]) translate([0,0,-plate_t]) linear_extrude(height=plate_t) plate2d();
    translate([-ap_hw, plate_t-1, shelf_z0]) cube([2*ap_hw, shelf_y1-plate_t+1, shelf_z1-shelf_z0]);
    for(m=[-1,1]) translate([m>0 ? tray_hw+0.5 : -tray_hw-4.5, plate_t-1, shelf_z1-1])
      cube([4, shelf_y1-plate_t+1, 11]);
    for(m=[-1,1]) translate([m>0 ? shell_hw : -frame_hw, plate_t-1, frame_z0])
      cube([frame_hw-shell_hw, frame_y1-plate_t+1, frame_z1-frame_z0]);
      for(m=[-1,1]) translate([m>0 ? cav_hw+0.3 : -shell_hw-0.5, cav_y0-wall-1, tongue_z0])
      cube([wall+0.2, wall+0.7, tongue_z1-tongue_z0]);
  }

module lid()
  difference(){
    union(){
      translate([0,(cav_y0+cav_y1+wall+12)/2, z_shell_top+lid_t/2])
        rbox(2*shell_hw, cav_y1-cav_y0+wall+12, lid_t, 1.4);
      translate([0,(cav_y0+cav_y1)/2, z_shell_top-4])
        rbox(2*cav_hw-2*clr, cav_y1-cav_y0-2*clr, 8+lid_t, 1.0);
    }
    translate([0,(cav_y0+cav_y1)/2, z_shell_top-7])
      rbox(2*cav_hw-2*clr-6.0, cav_y1-cav_y0-2*clr-6.0, 12, 1.0);
  }

module tray(){
  ix = 2*(tray_hw-tray_wall);
  iy = tray_y1-tray_y0-2*tray_wall;
  cy = (tray_y0+tray_y1)/2;
  zlip = tray_z1-lip_reach;
  difference(){
    union(){
      translate([0,cy,(tray_z0+zlip+3)/2]) rbox(2*tray_hw, tray_y1-tray_y0, zlip+3-tray_z0, 3);
      translate([0,cy,(zlip-3+tray_z1)/2]) rbox(2*tray_hw, tray_y1-tray_y0, tray_z1-zlip+3, 2.6);
      hull(){ translate([0, tray_y1+8, tray_z1-11]) rbox(64, 16, 9, 3);
              translate([0, tray_y1-1, tray_z1-22]) rbox(64, 6, 8, 2.5); }
    }
    translate([0,cy,(tray_z0+tray_wall+zlip)/2])
      rbox(ix, iy, zlip-tray_z0-tray_wall, 2.6);
    translate([0,cy,zlip-0.01])
      linear_extrude(height=lip_reach+0.02, scale=[(ix-2*lip_reach)/ix, (iy-2*lip_reach)/iy])
        offset(r=2.6) square([ix-5.2, iy-5.2], center=true);
  }
}

module perch2d()
  offset(r=-1.2) offset(r=2.4) offset(r=-1.2)
  union(){
    translate([-30,12]) circle(r=11);
    polygon([[-32,8],[-5,8],[-5,16],[-32,16]]);
    polygon([[-5,1],[0,1],[0,22],[-5,22]]);
    polygon([[-5,perch_slot_z0+1.2],[plate_t+3.5,perch_slot_z0+1.2],[plate_t+3.5,perch_slot_z1-1.2],[-5,perch_slot_z1-1.2]]);
    polygon([[plate_t+1.6,perch_slot_z1-1.2],[plate_t+3.5,perch_slot_z1-1.2],[plate_t+3.5,21],[plate_t+1.6,21]]);
  }

module perch() ext_yz(2*perch_slot_hw - 2) perch2d();

module seed_volume() ext_yz(2*cav_hw) cav2d();

module cage(){
  bx = -1.6;
  color([0.42,0.42,0.46]) union(){
    for(x=[-96 : bar_pitch : 96]) if(abs(x) > door_w/2 - 1)
      translate([x,bx,-46]) cylinder(h=290, d=bar_d, $fn=10);
    for(z=[-46 : bar_pitch : door_h+46]) if(z < 1 || z > door_h - 1)
      translate([-100,bx,z]) rotate([0,90,0]) cylinder(h=200, d=bar_d, $fn=10);
  }
}

part = "assembly";
if(part=="shell_left")        shell(-1);
else if(part=="shell_right")  shell(1);
else if(part=="mount")        mount();
else if(part=="lid")          lid();
else if(part=="tray")         tray();
else if(part=="perch")        perch();
else if(part=="seedvol")      seed_volume();
else if(part=="assembly_cage"){ color("#8fb8de") shell(1); color("#a3c9e4") shell(-1);
  color("#dcdcd4") mount(); color("#e8b04a") lid(); color("#7fc98a") tray(); color("#c98a5a") perch(); cage(); }
else { color("#8fb8de") shell(1); color("#a3c9e4") shell(-1);
  color("#dcdcd4") mount(); color("#e8b04a") lid(); color("#7fc98a") tray(); color("#c98a5a") perch(); }
