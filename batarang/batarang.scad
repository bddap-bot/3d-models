$fn = 48;
function bezier(a,b,c,d,t) = pow(1-t,3)*a + 3*pow(1-t,2)*t*b + 3*(1-t)*t*t*c + t*t*t*d;
function curve(a,b,c,d) = [for (i=[1:16]) bezier(a,b,c,d,i/16)];
right = concat([[0,8],[3,8],[5,15],[8,7]],
    curve([8,7],[19,8],[36,16],[48,19]),
    curve([48,19],[42,12],[38,5],[36,-2]),
    curve([36,-2],[30,3],[25,0],[23,-8]),
    curve([23,-8],[17,-3],[11,-6],[0,-18]));
module outline() {
    offset(r=1.2) offset(delta=-1.2)
    offset(r=-2.2) offset(delta=2.2)
    polygon(concat(right,[for(i=[len(right)-2:-1:1]) [-right[i][0],right[i][1]]]));
}
module bevel() {
    cylinder(h=1,r1=0,r2=1);
    translate([0,0,1]) cylinder(h=1,r1=1,r2=0);
}
color([0.16,0.18,0.22])
minkowski() {
    linear_extrude(height=2) outline();
    bevel();
}
