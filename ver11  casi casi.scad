// ==================== VARIABLES PRINCIPALES ====================
fanSize = 92;
holesDistance = 82.5;
holesDiameter = 4.5;
chamfer = "cone";
thickness = 4.5;
thicknessInside = 2.7;
roundRadius = 4;
frameWidth = 2.8;
latchWidth = 13.6;
innerGrillDiameter = 10;
grillNumber = 4;
grillThickness = 1.2;

sizeXY = fanSize + frameWidth;
sizeZ = thickness;
sizeZinside = thicknessInside;

hex_diameter = 10;
hex_thickness = 1;
hex_rows = 15;
hex_columns = 15;
disk_diameter = sizeXY - frameWidth;


module rounder() {
    union() {
        difference() {
            cube([sizeXY, sizeXY, sizeZ], true);
            for(i=[1:4]) {
                rotate([0, 0, i*90])
                translate([sizeXY/2, sizeXY/2, 0])
                cube([roundRadius, roundRadius, sizeZ+1], true);
            };
        };
        for(i=[1:4]) {
            rotate([0, 0, i*90])
            translate([sizeXY/2-roundRadius/2, sizeXY/2-roundRadius/2, 0])
            cylinder(h=sizeZ, d=roundRadius, center=true, $fn=100);
        };
    };
}

module hex(diameter, thickness) {
    linear_extrude(height=sizeZ, center=true) {
        difference() {
            circle(d=diameter, $fn=6);
            circle(d=diameter - thickness * 2, $fn=6);
        }
    }
}

function compute_x_delta(outer_radius, inner_radius) = (outer_radius + inner_radius) * 0.5 * (1 + cos(60));
function compute_y_delta(outer_radius, inner_radius) = (outer_radius + inner_radius) * 0.5 * sin(60);

module hex_grid(diameter, thickness, rows, columns) {
    outer_radius = diameter / 2;
    inner_radius = outer_radius - thickness;

    x_delta = compute_x_delta(outer_radius, inner_radius);
    y_delta = compute_y_delta(outer_radius, inner_radius);

    union() {
        for (r=[0:1:rows - 1]) {
            translate([0, 2 * y_delta * r, 0]) {
                for (c=[0:2:columns - 1]) {
                    translate([x_delta * c, 0, 0]) hex(diameter, thickness);
                }
                for (c=[1:2:columns - 1]) {
                    translate([x_delta * c, y_delta, 0]) hex(diameter, thickness);
                }
            }
        }
    }
}

module grill() {
    union() {
        difference() {
            rounder();
            intersection() {
                cube([sizeXY-frameWidth*2, sizeXY-frameWidth*2, sizeZ+0.1], true);
                cylinder(h=sizeZ+0.1, d=sizeXY-frameWidth, center=true, $fn=100);
            };
        };
        intersection() {
            outer_radius = hex_diameter / 2;
            inner_radius = outer_radius - hex_thickness;
            x_delta = compute_x_delta(outer_radius, inner_radius);
            y_delta = compute_y_delta(outer_radius, inner_radius);
            grid_width = x_delta * (hex_columns - 1) + hex_diameter;
            grid_height = 2 * y_delta * (hex_rows - 1) + hex_diameter;
            translate([-grid_width / 2, -grid_height / 2, 0]) {
                hex_grid(
                    diameter=hex_diameter,
                    thickness=hex_thickness,
                    rows=hex_rows,
                    columns=hex_columns
                );
            }
            cylinder(h=sizeZ, d=disk_diameter, center=true, $fn=100);
        }
    };
}

module grill_depth() {
    difference() {
        grill();
        translate([0, 0, sizeZinside/2+0.1/2])
        cube([sizeXY-frameWidth*2, sizeXY-frameWidth*2, sizeZ-sizeZinside+0.1], true);
    };
}

module holes() {
    difference() {
        union() {
            grill_depth();
            for(i=[1:4]) {
                rotate([0, 0, i*90])
                translate([holesDistance/2, holesDistance/2, 0])
                cylinder(h=sizeZ, d=2.5*holesDiameter, center=true, $fn=100);
            };
        };
        for(i=[1:4]) {
            rotate([0, 0, i*90])
            translate([holesDistance/2, holesDistance/2, 0])
            cylinder(h=sizeZ+0.1, d=holesDiameter, center=true, $fn=100);
        };
        for(i=[1:4]) {
            rotate([0, 0, i*90])
            translate([holesDistance/2, holesDistance/2, -0.6])
            if (chamfer == "cone")
                cylinder(h=sizeZ-1, d1=2*holesDiameter, d2=0, center=true, $fn=100);
            else
                cylinder(h=sizeZ-1, d=2*holesDiameter, center=true, $fn=100);
        };
    };
}

module latch() {
    difference() {
        holes();
        for(i=[1:4]) {
            rotate([0, 0, i*90])
            translate([-latchWidth/2, -sizeXY/2-0.1, sizeZ/2-1.8+0.1])
            cube([latchWidth, 1.2+0.1, 1.8]);
        };
    };
}


// ==================== Clonar 3 veces ====================
// ==================== Clonar 3 veces y voltear ====================


// ==================== grills() CENTRADO ====================
module grills() {
    ancho_total = sizeXY * 3; // 3 piezas en fila
    for (i = [0:2])
        translate([i * sizeXY - (ancho_total - sizeXY)/2, 0, 0]) // centrado en X
            rotate([180, 0, 0])
                latch();
}

// ==================== MAIN ====================
extraDepth = 20;

// Dimensiones reales
sizeX = sizeXY * 3;
sizeY = sizeXY;

// Mostramos la fila de grills centrada
grills();

// Cubos laterales largos (eje X → arriba y abajo)
translate([ 0, (sizeY/2) + (extraDepth/2), 0 ])
    cube([ sizeX, extraDepth, sizeZ ], center = true);

translate([ 0, -(sizeY/2) - (extraDepth/2), 0 ])
    cube([ sizeX, extraDepth, sizeZ ], center = true);

// Cubos laterales cortos (eje Y → izquierda y derecha)
translate([ (sizeX/2) + (extraDepth/2), 0, 0 ])
    cube([ extraDepth, sizeY, sizeZ ], center = true);

translate([ -(sizeX/2) - (extraDepth/2), 0, 0 ])
    cube([ extraDepth, sizeY, sizeZ ], center = true);