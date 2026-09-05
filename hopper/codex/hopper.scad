$fn = 48;
part = "assembly";

door_w = 140;
door_h = 170;
body_w = 136;
body_h = 164;
body_top_d = 80;
body_bottom_d = 55;
wall = 3;
outlet_h = 54;
outlet_w = 130;
tray_clearance = 0.5;

module yz_prism(width, points) {
    multmatrix([[0,0,1,-width/2],[1,0,0,0],[0,1,0,0],[0,0,0,1]])
        linear_extrude(height=width) polygon(points);
}

module soft_bar_x(length, depth, height, radius=2) {
    minkowski() {
        cube([length-2*radius,depth-2*radius,height-2*radius], center=true);
        sphere(radius);
    }
}

module hopper_body() {
    difference() {
        union() {
            yz_prism(body_w, [[0,0],[body_bottom_d,0],[body_top_d,body_h],[0,body_h]]);
            translate([0,-1.4,82]) cube([door_w,3.2,170],center=true);
            translate([-67,-5,30]) cube([6,8,18],center=true);
            translate([ 67,-5,30]) cube([6,8,18],center=true);
            translate([-67,-5,134]) cube([6,8,18],center=true);
            translate([ 67,-5,134]) cube([6,8,18],center=true);
            translate([0,52,7]) cube([body_w,10,14],center=true);
        }
        yz_prism(outlet_w, [[wall,7],[52,7],[52,62],[75,150],[wall,150],[wall,166],[-1,166],[-1,7]]);
        translate([0,77,7+outlet_h/2]) cube([outlet_w,60,outlet_h],center=true);
        translate([0,50,164]) cube([130,110,8],center=true);
        for (x=[-67,67], z=[30,134])
            translate([x,-7,z]) rotate([90,0,0]) cylinder(h=10,d=3.6,center=true);
    }
}

module lid() {
    difference() {
        union() {
            translate([0,39,2]) soft_bar_x(140,84,4,2);
            translate([0,39,-1.4]) cube([130,74,3.2],center=true);
            translate([0,-2,3]) cube([140,8,10],center=true);
            translate([-62,76,4]) cube([10,6,8],center=true);
            translate([ 62,76,4]) cube([10,6,8],center=true);
        }
        translate([0,38,-3]) cube([124,64,4],center=true);
    }
}

module tray_perch() {
    difference() {
        union() {
            translate([0,72,3]) soft_bar_x(136,92,6,2);
            translate([0,72,14]) difference() {
                soft_bar_x(136,92,24,3);
                translate([0,-1,4]) soft_bar_x(128,82,20,4);
            }
            yz_prism(136, [[112,7],[116,3],[124,3],[128,7],[128,15],[124,19],[116,19],[112,15]]);
            translate([-58,105,9]) hull() {
                cube([8,8,12],center=true);
                translate([0,15,2]) cube([8,8,12],center=true);
            }
            translate([58,105,9]) hull() {
                cube([8,8,12],center=true);
                translate([0,15,2]) cube([8,8,12],center=true);
            }
            translate([-65,29,24]) cube([5,12,18],center=true);
            translate([ 65,29,24]) cube([5,12,18],center=true);
        }
        translate([0,72,19]) soft_bar_x(126,80,20,4);
    }
}

module assembly() {
    color("seagreen") hopper_body();
    color("lightgreen") translate([0,0,166]) lid();
    color("darkseagreen") translate([0,-28,-28]) tray_perch();
}

if (part == "hopper_body") rotate([0,90,0]) hopper_body();
else if (part == "lid") rotate([180,0,0]) lid();
else if (part == "tray_perch") tray_perch();
else assembly();
