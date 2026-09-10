part = "assembly";
t = 0;
u = 0;
$fn = 40;

wall     = 3.2;
sidew    = 3.5;
cav_hw   = 44;
zslot    = 72;
cav_h    = 105;
slot_y   = 80;
y_in     = 5.6;
back_ang = 62;

bar_hw   = 1.5;
open_hw  = 55;
open_top = 110;
rail_t   = 4;
bar_gap  = 12;

skirt_i  = 52.5;
skirt_o  = 56;
stile_i  = 53.6;
stile_o  = 71;
plate_hw = 68;

tray_fz0 = 44;
tray_fz1 = 48;
tray_wi  = 44;
tray_wo  = 47.5;
tray_fx  = 52;
tray_y0  = -45;
tray_y1  = 96;
tray_top = 70;
wall_z   = 65;
lip_r    = 5;

perch_r  = 8;
perch_y  = -62;
perch_z  = 36;
perch_hw = 39;

clr      = 0.5;

y_fo     = y_in - wall;
y_b0     = y_in + slot_y;
back_dy  = cav_h/tan(back_ang);
y_b1     = y_b0 + back_dy;
z_top    = zslot + cav_h;
z_o      = z_top + wall;
back_off = wall/sin(back_ang);
y_b0o    = y_b0 + back_off;
y_b1o    = y_b0o + (z_o-zslot)/tan(back_ang);
skirt_y1 = 104;

module yz(w, pts) multmatrix([[0,0,1,-w/2],[1,0,0,0],[0,1,0,0],[0,0,0,1]]) linear_extrude(w) polygon(pts);
module bx(x0,x1,y0,y1,z0,z1) translate([x0,y0,z0]) cube([x1-x0,y1-y0,z1-z0]);
module mx() { children(); mirror([1,0,0]) children(); }
module yzat(x0,x1,pts) translate([(x0+x1)/2,0,0]) yz(x1-x0, pts);
module rnd(r) offset(r=r) offset(delta=-r) children();

outer_p = [[y_fo,zslot],[y_fo,z_o],[y_b1o,z_o],[y_b0o,zslot]];
inner_p = [[y_in,zslot-2],[y_in,z_o+2],[y_b1+(z_o+2-z_top)/tan(back_ang),z_o+2],[y_b0-2/tan(back_ang),zslot-2]];
cav_p   = [[y_in,zslot],[y_in,z_top],[y_b1,z_top],[y_b0,zslot]];

module shell() difference(){ multmatrix([[0,0,1,-(cav_hw+sidew)],[1,0,0,0],[0,1,0,0],[0,0,0,1]]) linear_extrude(2*(cav_hw+sidew)) rnd(1.2) polygon(outer_p); yz(2*cav_hw, inner_p); }

module front_plate(){
  difference(){
    union(){
      bx(-plate_hw,plate_hw, y_fo,y_in, zslot, z_o);
      mx() bx(skirt_i,plate_hw, y_fo,y_in, 16, zslot);
    }
  }
}

module shroud(){
  difference(){
    bx(-plate_hw,plate_hw, y_fo,y_in, 6, zslot);
    translate([0,y_in+1,0]) rotate([90,0,0]) linear_extrude(wall+2) rnd(2)
      polygon([[-53.5,26],[53.5,26],[53.5,zslot-1],[-53.5,zslot-1]]);
  }
}

module skirt(){
  mx() bx(skirt_i,skirt_o, y_fo,skirt_y1, 30, zslot);
  mx() bx(cav_hw+sidew,cav_hw+sidew+0.8, y_b1-40,y_b1-8, z_o-16, z_o-13.5);
  mx() xz(y_fo,skirt_y1,[[skirt_o,zslot],[cav_hw+sidew,zslot],[cav_hw+sidew,zslot+8],[skirt_o,zslot]]);
}

module xz(y0,y1,pts) translate([0,y1,0]) rotate([90,0,0]) linear_extrude(y1-y0) polygon(pts);

module rails(){
  mx() xz(2,tray_y1,[[skirt_i,tray_fz0-9.4],[48,tray_fz0-4.9],[48,tray_fz0-0.4],[skirt_i,tray_fz0-0.4]]);
  mx() xz(2,tray_y1,[[skirt_i,tray_fz1+0.4],[48.5,tray_fz1+0.4],[48.5,tray_fz1+5.1],[skirt_i,tray_fz1+9.6]]);
}

hook_x = 2.5*bar_gap;
hook_w = bar_gap - 4;
hook_p = [[-7.5,92],[-3.5,92],[-3.5,open_top+rail_t],[y_in,open_top+rail_t],[y_in,open_top+rail_t+10],[-7.5,open_top+rail_t+10]];
module hooks() mx() translate([hook_x,0,0]) multmatrix([[0,0,1,-hook_w/2],[1,0,0,0],[0,1,0,0],[0,0,0,1]])
  linear_extrude(hook_w) rnd(1.4) polygon(hook_p);

module body() union(){ shell(); front_plate(); shroud(); skirt(); rails(); hooks(); }

module rim_roll(){
  translate([0,tray_y0+1.75,wall_z]) rotate([0,90,0]) cylinder(r=lip_r,h=2*(tray_wi+1.75+lip_r),center=true);
  translate([0,tray_y1-1.75,wall_z]) rotate([0,90,0]) cylinder(r=lip_r,h=2*(tray_wi+1.75+lip_r),center=true);
  mx() translate([tray_wi+1.75,tray_y0,wall_z]) rotate([-90,0,0]) cylinder(r=lip_r,h=tray_y1-tray_y0);
}

module tray(){
  difference(){
    union(){
      bx(-tray_fx,tray_fx, tray_y0,tray_y1, tray_fz0,tray_fz1);
      mx() bx(tray_wi,tray_wo, tray_y0,tray_y1, tray_fz1,wall_z);
      bx(-tray_wo,tray_wo, tray_y0,tray_y0+3.5, tray_fz1,wall_z);
      bx(-tray_wo,tray_wo, tray_y1-3.5,tray_y1, tray_fz1,wall_z);
      rim_roll();
      translate([-perch_hw,perch_y,perch_z]) rotate([0,90,0]) cylinder(r=perch_r,h=2*perch_hw);
      mx() translate([perch_hw,perch_y,perch_z]) sphere(r=perch_r);
      mx() for(x=[20,36]) hull(){
        translate([x+2.5,tray_y0+2,tray_fz0-1]) sphere(r=3.5);
        translate([x,perch_y,perch_z]) rotate([0,90,0]) cylinder(r=perch_r-0.5,h=5);
      }
      bx(-skirt_i+0.1,skirt_i-0.1, tray_y1,tray_y1+4, tray_fz0-6,wall_z);
    }
    bx(-tray_wi,tray_wi, tray_y0+3.5,tray_y1-3.5, tray_fz1,tray_top+40);
    bx(-200,200,-200,200,tray_top,300);
  }
}

module lid(){
  fy0 = y_in + 0.4;
  by1 = y_b1o + 0.4;
  difference(){
    union(){
      bx(-cav_hw-sidew-4.0, cav_hw+sidew+4.0, y_fo+0.4, by1+3.6, z_o, z_o+3.2);
      mx() bx(cav_hw+sidew+0.8, cav_hw+sidew+4.0, fy0, by1+3.6, z_o-20, z_o+0.01);
      bx(-cav_hw-sidew-4.0, cav_hw+sidew+4.0, by1, by1+3.6, z_o-20, z_o+0.01);
      bx(-cav_hw+0.6, cav_hw-0.6, y_in+0.5, y_in+3.7, z_o-12, z_o+0.01);
      mx() bx(cav_hw+sidew, cav_hw+sidew+0.8, y_b1-40, y_b1-8, z_o-19, z_o-17);
    }
    bx(-200,200,-200,200,-200,z_o-20);
  }
}

module cage(){
  color("gray",0.3) difference(){
    union(){
      for(x=[-11:1:11]) translate([x*bar_gap,0,-40]) cylinder(r=bar_hw,h=250);
      translate([0,0,open_top+rail_t/2]) rotate([0,90,0]) cylinder(r=rail_t/2,h=300,center=true);
      translate([0,0,-rail_t/2]) rotate([0,90,0]) cylinder(r=rail_t/2,h=300,center=true);
    }
    bx(-open_hw,open_hw,-8,8,0,open_top);
  }
}

if      (part=="body")   body();
else if (part=="tray")   tray();
else if (part=="lid")    lid();
else if (part=="cavity") yz(2*cav_hw, cav_p);
else if (part=="chk_bt") intersection(){ body(); tray(); }
else if (part=="chk_bd") intersection(){ body(); lid(); }
else if (part=="chk_wb") intersection(){ body(); wall_solid(); }
else if (part=="chk_wt") intersection(){ tray(); wall_solid(); }
else if (part=="chk_wd") intersection(){ lid(); wall_solid(); }
else if (part=="sw_tb") intersection(){ translate([0,t,0]) tray(); body(); }
else if (part=="sw_tw") intersection(){ translate([0,t,0]) tray(); wall_solid(); }
else if (part=="sw_bw") intersection(){ translate([0,0,t]) body(); wall_solid(); }
else if (part=="sw_bo") intersection(){ translate([0,u,t]) body(); wall_solid(); }
else { body(); color("orange") tray(); color("green") lid(); cage(); }

module wall_solid(){
  difference(){
    union(){
      for(x=[-11:1:11]) translate([x*bar_gap,0,-40]) cylinder(r=bar_hw,h=250);
      translate([0,0,open_top+rail_t/2]) rotate([0,90,0]) cylinder(r=rail_t/2,h=300,center=true);
      translate([0,0,-rail_t/2]) rotate([0,90,0]) cylinder(r=rail_t/2,h=300,center=true);
    }
    bx(-open_hw,open_hw,-8,8,0,open_top);
  }
}
