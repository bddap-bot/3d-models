part = "assembly";

$fa = 4; $fs = 0.9;

wall        = 3;
door_w      = 110;
door_h      = 110;
bar_pitch   = 12;
bar_d       = 5;

front_y0    = 2.5;
front_y1    = front_y0 + wall;
chute_iw    = 98;
chute_id    = 70;
rear_y0     = front_y1 + chute_id;
rear_y1     = rear_y0 + wall;
side_t      = 3;
chute_hw    = chute_iw/2 + side_t;

plate_w     = 150;
plate_top   = 132;
chute_top   = 168;

tray_z      = 25;
tray_t      = 3;
slot_h      = 50;
slot_top    = tray_z + slot_h;

ledge_z     = tray_z - tray_t;
ledge_in    = 5;
lip_z       = tray_z + 1.5;
lip_in      = 3;
detent_y    = 14;
detent_h    = 1.2;

win_hw      = chute_iw/2 + 1.5;
win_z0      = ledge_z - 2;
win_z1      = slot_top;

tray_hw     = chute_iw/2;
tray_wt     = 3;
tray_out_y  = rear_y0 - 0.4;
tray_in_y   = -67;
tray_rear_y = 2.4;
rim_hi      = 73.5;
lip_lean    = 6;

fin_hx      = 35;
fin_t       = 4;
fin_in_y    = -88;
fin_top     = 16;
perch_y     = -80;
perch_z     = 12;
perch_r     = 7;
perch_stem  = 4;

rail_t      = 12;
rail_h      = 16;
hook_hx     = 30;
hook_t      = 5;
hook_z0     = door_h - 6;
hook_z1     = door_h + rail_h + 6;

lid_gap     = 0.4;
lid_skirt   = 15;
lid_t       = 3;

module rrect(w, d, r) { offset(r = r) square([w - 2*r, d - 2*r], center = true); }

module yzx(h) { rotate([0,0,90]) rotate([90,0,0]) linear_extrude(h) children(); }

module chute_outer2d() { translate([0, (front_y0 + rear_y1)/2]) rrect(2*chute_hw, rear_y1 - front_y0, 4); }
module chute_inner2d() { translate([0, (front_y1 + rear_y0)/2]) rrect(chute_iw, chute_id, 3); }

module plate2d() { translate([0, plate_top/2]) rrect(plate_w, plate_top, 6); }


rim_lo      = 50;
slope_b     = (rim_hi - rim_lo) / (tray_rear_y - tray_in_y);
slope_c     = rim_hi - slope_b * tray_rear_y;

module window2d() { translate([0, (win_z0 + win_z1)/2]) rrect(2*win_hw, win_z1 - win_z0, 5); }

module hook2d() {
    difference() {
        translate([(-15 + front_y1)/2, (hook_z0 + hook_z1)/2])
            rrect(front_y1 + 15, hook_z1 - hook_z0, 3);
        translate([(-11 + front_y1 + 4)/2, (hook_z0 - 4 + door_h + rail_h + 1)/2])
            square([front_y1 + 4 + 11, door_h + rail_h + 1 - hook_z0 + 4], center = true);
        polygon([[-20, hook_z0 - 6], [-11, hook_z0 - 6], [-11, hook_z0], [-15, hook_z0 + 8], [-20, hook_z0 + 8]]);
    }
}

module fin2d() {
    union() {
        translate([(fin_in_y + front_y1)/2, fin_top/2]) rrect(front_y1 - fin_in_y, fin_top, 3);
        translate([(fin_in_y + front_y1)/2, fin_top/4]) square([front_y1 - fin_in_y, fin_top/2], center = true);
    }
}

module perch2d() {
    hull() {
        translate([perch_y, perch_z]) circle(r = perch_r);
        translate([perch_y, 0.5]) square([perch_stem, 1], center = true);
    }
}

module tray_out2d(d) { translate([0, (tray_in_y + tray_rear_y)/2]) offset(delta = -d) rrect(2*tray_hw, tray_rear_y - tray_in_y, 4); }
module tray_in2d(d)  { translate([0, (tray_in_y + tray_wt + tray_rear_y + 20)/2]) offset(delta = -d) rrect(2*(tray_hw - tray_wt), tray_rear_y + 20 - tray_in_y - tray_wt, 3); }
module band2d(d) { difference() { tray_out2d(d); tray_in2d(d); } }

module below(dz) {
    translate([0, 0, slope_c + dz]) rotate([atan(slope_b), 0, 0]) translate([-300, -300, -1000]) cube([600, 600, 1000]);
}

module ledges() {
    for (s = [-1, 1]) hull() {
        translate([s*(chute_iw/2 - ledge_in/2), (front_y1 + rear_y0)/2, ledge_z - 0.5]) cube([ledge_in, chute_id, 1], center = true);
        translate([s*(chute_iw/2 - 0.75), (front_y1 + rear_y0)/2, 0.5]) cube([1.5, chute_id, 1], center = true);
    }
}

module lips() {
    for (s = [-1, 1]) hull() {
        translate([s*(chute_iw/2 - lip_in/2), (front_y1 + rear_y0)/2, lip_z + 5.5]) cube([lip_in, chute_id, 2], center = true);
        translate([s*(chute_iw/2 - 0.25), (front_y1 + rear_y0)/2, lip_z + 0.2]) cube([0.5, chute_id, 0.4], center = true);
    }
}

module detents() {
    for (s = [-1, 1]) translate([s*(chute_iw/2 - ledge_in/2), detent_y, ledge_z])
        resize([ledge_in - 1, 9, 2*detent_h]) sphere(r = 3);
}

module body() {
    difference() {
        union() {
            linear_extrude(chute_top) difference() { chute_outer2d(); chute_inner2d(); }
            translate([0, front_y1, 0]) rotate([90, 0, 0]) linear_extrude(wall) plate2d();
            ledges();
            lips();
            detents();
            for (s = [-1, 1]) translate([s*hook_hx - hook_t/2, 0, 0]) yzx(hook_t) hook2d();
            for (s = [-1, 1]) translate([s*fin_hx - fin_t/2, 0, 0]) yzx(fin_t) fin2d();
            translate([-chute_iw/2, 0, 0]) yzx(chute_iw) perch2d();
        }
        hull() {
            translate([0, front_y1 + 0.1, 0]) rotate([90, 0, 0]) linear_extrude(0.1) window2d();
            translate([0, front_y0 - 1.9, 0]) rotate([90, 0, 0]) linear_extrude(0.1) offset(r = 2) window2d();
        }
    }
}

module tray() {
    tcy = (tray_in_y + tray_rear_y) / 2;
    union() {
        translate([0, 0, ledge_z]) linear_extrude(tray_t)
            translate([0, (tray_in_y + tray_out_y)/2]) rrect(2*tray_hw, tray_out_y - tray_in_y, 3);
        intersection() {
            translate([0, tcy, ledge_z])
                linear_extrude(height = rim_hi - ledge_z, scale = 1 - lip_lean/tray_hw)
                    translate([0, -tcy]) band2d(0);
            below(0);
        }
    }
}

module lid() {
    union() {
        translate([0, 0, lid_skirt]) linear_extrude(lid_t) offset(r = lid_t) offset(delta = lid_gap) chute_outer2d();
        linear_extrude(lid_skirt) difference() {
            offset(r = lid_t) offset(delta = lid_gap) chute_outer2d();
            offset(delta = lid_gap) chute_outer2d();
        }
        translate([0, 0, lid_skirt]) linear_extrude(lid_t) hull() {
            translate([0, front_y0 - 2]) circle(r = 2);
            translate([0, front_y0 - 14]) circle(r = 13);
        }
    }
}

module seedvolume() {
    difference() {
        translate([0, 0, tray_z]) linear_extrude(chute_top - tray_z) chute_inner2d();
        body();
        tray();
    }
}

module cage() {
    color("silver") difference() {
        union() {
            for (x = [-84 : bar_pitch : 84]) translate([x, 0, -40]) cylinder(d = bar_d, h = 230);
            translate([0, 0, -40 + bar_d/2]) rotate([0, 90, 0]) cylinder(d = bar_d, h = 190, center = true);
            translate([0, 0, door_h + rail_h/2]) cube([190, rail_t, rail_h], center = true);
            translate([0, 0, -rail_h/2]) cube([190, rail_t, rail_h], center = true);
        }
        translate([0, 0, door_h/2]) cube([door_w, 60, door_h], center = true);
    }
}

module fitgauge() { translate([0, 0, door_h/2]) cube([door_w, 400, door_h], center = true); }

module widthgauge() { cube([door_w, 400, 900], center = true); }

module slotgauge() { translate([0, front_y1 - 0.05, 0]) rotate([90, 0, 0]) linear_extrude(front_y1 - front_y0 - 0.1) translate([0, tray_z + slot_h/2]) rrect(chute_iw, slot_h, 5); }

module flowgauge() { translate([0, front_y1 + chute_id/2, (tray_z + chute_top)/2]) cube([91, 64, chute_top - tray_z], center = true); }

module crossing() { intersection() { union() { body(); tray(); } translate([0, -1000 + front_y0 - 0.05, 0]) cube([2000, 2000, 2000], center = true); } }

if      (part == "body")        body();
else if (part == "tray")        tray();
else if (part == "lid")         lid();
else if (part == "seedvolume")  seedvolume();
else if (part == "crossing")    crossing();
else if (part == "check_fit")   difference() { crossing(); fitgauge(); }
else if (part == "check_fit_low") intersection() { difference() { crossing(); fitgauge(); } translate([0, 0, door_h/2 - 400]) cube([900, 900, 800], center = true); }
else if (part == "check_clash_tray") intersection() { body(); tray(); }
else if (part == "check_clash_lid")  intersection() { body(); translate([0, 0, chute_top - lid_skirt]) lid(); }
else if (part == "check_tray_travel") intersection() { body(); union() { for (t = [0 : 6 : 84]) translate([0, -t, 0]) tray(); } }
else if (part == "check_flow")  intersection() { union() { body(); tray(); } flowgauge(); }
else if (part == "check_width") difference() { crossing(); widthgauge(); }
else if (part == "check_slot")  intersection() { union() { body(); tray(); } slotgauge(); }
else if (part == "section") difference() {
    union() { color("dimgray") body(); color("steelblue") tray(); color("darkorange") translate([0, 0, chute_top - lid_skirt]) lid(); cage(); }
    translate([200, 0, 100]) cube([400, 500, 500], center = true);
}
else if (part == "assembly_cage") { color("dimgray") body(); color("steelblue") tray(); color("darkorange") translate([0, 0, chute_top - lid_skirt]) lid(); cage(); }
else { color("dimgray") body(); color("steelblue") tray(); color("darkorange") translate([0, 0, chute_top - lid_skirt]) lid(); }
