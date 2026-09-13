part = "candidate_a";

$fa = 5;
$fs = 0.8;

door_width = 110;
door_height = 110;
bar_spacing = 12;
bar_diameter = 3.5;
wall = 3.2;
door_tolerance = 3;
tray_base = bar_diameter/2 + 0.3;

inner_width = door_width - 12;
plate_width = door_width + 20;
plate_bottom = tray_base;
plate_top = door_height + 12;
plate_thickness = max(wall, 4);
tray_back = -62;
tray_front = 58;
tray_floor = 4;
tray_wall_height = 34;
tray_lip_height = 19;
hood_front = 34;
hook_center = bar_spacing * 2.5;
hook_width = min(5, bar_spacing - bar_diameter - 1.5);
hook_depth = bar_diameter + 2.5;
hook_throat = bar_diameter - 0.3;

cavity = [[-57,24],[-5,24],[-5,165],[-99,165]];

function side_x(s) = s > 0 ? inner_width/2 : -inner_width/2-wall;

module yz_extrude(width) {
    translate([-width/2,0,0]) rotate([90,0,90]) linear_extrude(width) children();
}

module rounded_xz(width,height,r) {
    offset(r=r) square([width-2*r,height-2*r],center=true);
}

module reservoir_shell() {
    difference() {
        yz_extrude(inner_width + 2*wall) offset(r=wall) polygon(cavity);
        yz_extrude(inner_width) polygon(cavity);
        translate([-inner_width/2-2*wall,-110,164.8]) cube([inner_width+4*wall,120,20]);
        translate([-inner_width/2-0.1,-61,18]) cube([inner_width+0.2,61,42]);
    }
}

module faceplate() {
    difference() {
        translate([0,-bar_diameter/2-0.3-plate_thickness/2,(plate_bottom+plate_top)/2])
            rotate([90,0,0]) linear_extrude(plate_thickness,center=true)
                rounded_xz(plate_width,plate_top-plate_bottom,4);
        translate([0,-bar_diameter/2-0.3-plate_thickness/2,30]) cube([inner_width+7,plate_thickness+2,62],center=true);
    }
}

module trough() {
    translate([-inner_width/2-wall,tray_back,0]) cube([inner_width+2*wall,tray_front-tray_back,tray_floor]);
    for (s=[-1,1]) translate([side_x(s),tray_back,tray_floor])
        cube([wall,tray_front-tray_back,tray_wall_height]);
    translate([-inner_width/2-wall,tray_back,tray_floor])
        cube([inner_width+2*wall,wall,tray_wall_height]);
    translate([-inner_width/2-wall,tray_front-wall,tray_floor])
        cube([inner_width+2*wall,wall,tray_lip_height-wall/2]);
    translate([-inner_width/2-wall,tray_front-wall/2,tray_floor+tray_lip_height-wall/2])
        rotate([0,90,0]) cylinder(d=wall,h=inner_width+2*wall);
    for (s=[-1,1]) translate([s*(inner_width/2+wall/2),tray_front-13,tray_floor+tray_lip_height])
        rotate([90,0,0]) cylinder(d=wall,h=tray_front-tray_back-13);
}

module hood() {
    hood_low = tray_floor + tray_wall_height;
    hood_high = hood_low + hood_front + 10;
    hull() {
        translate([-inner_width/2-wall,-7,hood_low]) cube([inner_width+2*wall,wall,wall]);
        translate([-inner_width/2-wall,hood_front-wall,hood_high-wall]) cube([inner_width+2*wall,wall,wall]);
    }
    for (s=[-1,1]) hull() {
        translate([side_x(s),-7,hood_low]) cube([wall,wall,wall]);
        translate([side_x(s),hood_front-wall,hood_high-wall]) cube([wall,wall,wall]);
    }
    translate([-inner_width/2-wall,hood_front-wall/2,hood_high-wall/2])
        rotate([0,90,0]) cylinder(d=wall,h=inner_width+2*wall);
}

module top_hooks() {
    for (s=[-1,1]) translate([s*hook_center-hook_width/2,0,0]) union() {
        translate([0,-2,door_height+4]) cube([hook_width,hook_depth+8,wall+3]);
        translate([0,hook_depth+2,door_height-6]) cube([hook_width,wall,13]);
        translate([0,-1.8+hook_throat,door_height-5.2])
            cube([hook_width,hook_depth+wall+2.4-hook_throat,wall]);
        hull() {
            translate([0,hook_depth+2,door_height-6]) cube([hook_width,wall,3]);
            translate([0,hook_depth-1,door_height-5]) cube([hook_width,wall,3]);
        }
    }
}

module reinforcements() {
    for (s=[-1,1]) hull() {
        translate([side_x(s),-56,0]) cube([wall,18,wall]);
        translate([side_x(s),-56,0]) cube([wall,wall,24]);
    }
}

module candidate_a() {
    union() {
        reservoir_shell();
        faceplate();
        translate([0,0,tray_base]) trough();
        translate([0,0,tray_base]) hood();
        top_hooks();
        translate([0,0,tray_base]) reinforcements();
    }
}

module capacity() {
    intersection() {
        yz_extrude(inner_width) polygon(cavity);
        translate([-inner_width/2,-110,-20]) cube([inner_width,120,184.8]);
    }
}

module outlet_probe() {
    intersection() {
        capacity();
        translate([-inner_width/2,-110,24]) cube([inner_width,120,0.5]);
    }
}

module inlet_probe() {
    intersection() {
        capacity();
        translate([-inner_width/2,-110,164.3]) cube([inner_width,120,0.5]);
    }
}

module outlet_clear_probe() {
    intersection() {
        capacity();
        translate([-inner_width/2+1,-56,24.1]) cube([inner_width-2,50,0.3]);
    }
}

module inlet_clear_probe() {
    intersection() {
        capacity();
        translate([-inner_width/2+1,-97,164.4]) cube([inner_width-2,90,0.3]);
    }
}

module cage() {
    for (x=[-120:bar_spacing:120]) difference() {
        translate([x,0,-20]) cylinder(d=bar_diameter,h=160);
        translate([-door_width/2,-10,0]) cube([door_width,20,door_height]);
    }
    for (z=[0,door_height]) translate([-120,0,z]) rotate([0,90,0]) cylinder(d=bar_diameter,h=240);
}

module hook_install_sweep() {
    hull() {
        translate([-door_width/2,16,door_height-8.5]) rotate([0,90,0])
            cylinder(d=bar_diameter,h=door_width);
        translate([-door_width/2,0,door_height-8.5]) rotate([0,90,0])
            cylinder(d=bar_diameter,h=door_width);
    }
    hull() {
        translate([-door_width/2,0,door_height-8.5]) rotate([0,90,0])
            cylinder(d=bar_diameter,h=door_width);
        translate([-door_width/2,0,door_height]) rotate([0,90,0])
            cylinder(d=bar_diameter,h=door_width);
    }
}

module section() {
    intersection() {
        candidate_a();
        translate([-0.8,-130,-20]) cube([1.6,240,220]);
    }
}

if (part == "capacity") capacity();
else if (part == "outlet_probe") outlet_probe();
else if (part == "inlet_probe") inlet_probe();
else if (part == "outlet_blockage") intersection() { candidate_a(); outlet_clear_probe(); }
else if (part == "inlet_blockage") intersection() { candidate_a(); inlet_clear_probe(); }
else if (part == "cage") cage();
else if (part == "static_interference") intersection() { candidate_a(); cage(); }
else if (part == "hook_snap_interference") intersection() { candidate_a(); hook_install_sweep(); }
else if (part == "pull_interference") intersection() { translate([0,-7,0]) candidate_a(); cage(); }
else if (part == "lift_interference") intersection() { translate([0,0,5]) candidate_a(); cage(); }
else if (part == "door_section") intersection() { candidate_a(); translate([-100,-1.7,0.1]) cube([200,3.4,door_height-0.2]); }
else if (part == "section") section();
else candidate_a();
