part = "candidate_b";

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
passage_depth = 74;
passage_length = 138;
passage_angle = 70;
plate_width = door_width + 20;
plate_bottom = tray_base;
plate_top = door_height + 10;
plate_thickness = max(wall,4);
tray_back = -74;
tray_front = 50;
tray_floor = 4;
tray_wall_height = 32;
tray_lip_height = 18;
hood_front = 30;
hood_height = 53;
snap_reach = door_tolerance + 2;
snap_beam = wall;

axis_y = -cos(passage_angle);
axis_z = sin(passage_angle);
normal_y = sin(passage_angle);
normal_z = cos(passage_angle);
lower_y = -35;
lower_z = 22;

function p(d,l) = [lower_y + normal_y*d + axis_y*l, lower_z + normal_z*d + axis_z*l];

passage = [p(-passage_depth/2,0),p(passage_depth/2,0),p(passage_depth/2,passage_length),p(-passage_depth/2,passage_length)];

function side_x(s) = s > 0 ? inner_width/2 : -inner_width/2-wall;

module yz_extrude(width) {
    translate([-width/2,0,0]) rotate([90,0,90]) linear_extrude(width) children();
}

module rounded_xz(width,height,r) {
    offset(r=r) square([width-2*r,height-2*r],center=true);
}

module magazine_shell() {
    difference() {
        yz_extrude(inner_width+2*wall) offset(r=wall) polygon(passage);
        yz_extrude(inner_width) polygon(passage);
        yz_extrude(inner_width+0.2) polygon([
            p(-passage_depth/2,passage_length-0.1),
            p(passage_depth/2,passage_length-0.1),
            p(passage_depth/2,passage_length+20),
            p(-passage_depth/2,passage_length+20)
        ]);
        yz_extrude(inner_width+0.2) polygon([
            p(-passage_depth/2,-20),
            p(passage_depth/2,-20),
            p(passage_depth/2,0.1),
            p(-passage_depth/2,0.1)
        ]);
    }
}

module faceplate() {
    difference() {
        translate([0,-bar_diameter/2-0.3-plate_thickness/2,(plate_bottom+plate_top)/2])
            rotate([90,0,0]) linear_extrude(plate_thickness,center=true)
                rounded_xz(plate_width,plate_top-plate_bottom,4);
        translate([0,-bar_diameter/2-0.3-plate_thickness/2,28]) cube([inner_width+7,plate_thickness+2,58],center=true);
    }
}

module tray() {
    translate([-inner_width/2-wall,tray_back,0]) cube([inner_width+2*wall,tray_front-tray_back,tray_floor]);
    for (s=[-1,1]) translate([side_x(s),tray_back,tray_floor])
        cube([wall,tray_front-tray_back,tray_wall_height]);
    translate([-inner_width/2-wall,tray_back,tray_floor]) cube([inner_width+2*wall,wall,tray_wall_height]);
    translate([-inner_width/2-wall,tray_front-wall,tray_floor])
        cube([inner_width+2*wall,wall,tray_lip_height-wall/2]);
    translate([-inner_width/2-wall,tray_front-wall/2,tray_floor+tray_lip_height-wall/2])
        rotate([0,90,0]) cylinder(d=wall,h=inner_width+2*wall);
    for (s=[-1,1]) translate([s*(inner_width/2+wall/2),tray_front-12,tray_floor+tray_lip_height])
        rotate([90,0,0]) cylinder(d=wall,h=tray_front-tray_back-12);
}

module hood() {
    hood_low = tray_floor + tray_wall_height;
    hood_high = hood_low + hood_front + 7;
    hull() {
        translate([-inner_width/2-wall,-4,hood_low]) cube([inner_width+2*wall,wall,wall]);
        translate([-inner_width/2-wall,hood_front-wall,hood_high-wall]) cube([inner_width+2*wall,wall,wall]);
    }
    for (s=[-1,1]) hull() {
        translate([side_x(s),-4,hood_low]) cube([wall,wall,wall]);
        translate([side_x(s),hood_front-wall,hood_high-wall]) cube([wall,wall,wall]);
    }
    translate([-inner_width/2-wall,hood_front-wall/2,hood_high-wall/2]) rotate([0,90,0]) cylinder(d=wall,h=inner_width+2*wall);
}

module snap_arm(side) {
    x0 = side*(door_width/2-snap_reach-wall);
    beam_x = side > 0 ? x0-snap_beam : x0;
    translate([beam_x,0,58]) cube([snap_beam,8,47]);
    translate([side > 0 ? x0-snap_beam : x0,-3,58]) cube([snap_beam,11,7]);
    hull() {
        translate([beam_x,2.5,96]) cube([snap_beam,4.5,8]);
        translate([side > 0 ? door_width/2 : -door_width/2-snap_reach,2.5,98]) cube([snap_reach,4.5,4]);
    }
}

module snap_flange() {
    for (s=[-1,1]) snap_arm(s);
    translate([-inner_width/2,-1,2.2]) cube([inner_width,11,6]);
}

module reinforcements() {
    for (s=[-1,1]) hull() {
        translate([side_x(s),-66,0]) cube([wall,20,wall]);
        translate([side_x(s),-66,0]) cube([wall,wall,23]);
    }
}

module candidate_b() {
    union() {
        magazine_shell();
        faceplate();
        translate([0,0,tray_base]) tray();
        translate([0,0,tray_base]) hood();
        snap_flange();
        translate([0,0,tray_base]) reinforcements();
    }
}

module capacity() {
    intersection() {
        yz_extrude(inner_width) polygon(passage);
        translate([-inner_width/2,-135,-20]) cube([inner_width,140,184.8]);
    }
}

module outlet_probe() {
    yz_extrude(inner_width) polygon([
        p(-passage_depth/2,0),
        p(passage_depth/2,0),
        p(passage_depth/2,0.5),
        p(-passage_depth/2,0.5)
    ]);
}

module inlet_probe() {
    yz_extrude(inner_width) polygon([
        p(-passage_depth/2,passage_length-0.5),
        p(passage_depth/2,passage_length-0.5),
        p(passage_depth/2,passage_length),
        p(-passage_depth/2,passage_length)
    ]);
}

module outlet_clear_probe() {
    yz_extrude(inner_width-2) polygon([
        p(-passage_depth/2+1,0.1),
        p(passage_depth/2-1,0.1),
        p(passage_depth/2-1,0.4),
        p(-passage_depth/2+1,0.4)
    ]);
}

module inlet_clear_probe() {
    yz_extrude(inner_width-2) polygon([
        p(-passage_depth/2+1,passage_length-0.4),
        p(passage_depth/2-1,passage_length-0.4),
        p(passage_depth/2-1,passage_length-0.1),
        p(-passage_depth/2+1,passage_length-0.1)
    ]);
}

module cage() {
    for (x=[-120:bar_spacing:120]) difference() {
        translate([x,0,-20]) cylinder(d=bar_diameter,h=160);
        translate([-door_width/2,-10,0]) cube([door_width,20,door_height]);
    }
    for (z=[0,door_height]) translate([-120,0,z]) rotate([0,90,0]) cylinder(d=bar_diameter,h=240);
}

module section() {
    intersection() {
        candidate_b();
        translate([-0.8,-145,-20]) cube([1.6,230,220]);
    }
}

if (part == "capacity") capacity();
else if (part == "outlet_probe") outlet_probe();
else if (part == "inlet_probe") inlet_probe();
else if (part == "outlet_blockage") intersection() { candidate_b(); outlet_clear_probe(); }
else if (part == "inlet_blockage") intersection() { candidate_b(); inlet_clear_probe(); }
else if (part == "cage") cage();
else if (part == "static_interference") intersection() { candidate_b(); cage(); }
else if (part == "pull_interference") intersection() { translate([0,-3,0]) candidate_b(); cage(); }
else if (part == "door_section") intersection() { candidate_b(); translate([-100,-1.7,0.1]) cube([200,3.4,door_height-0.2]); }
else if (part == "section") section();
else candidate_b();
