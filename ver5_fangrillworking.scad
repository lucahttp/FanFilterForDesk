/*[ Base ]*/

// Fan size along X and Y, mm
fanSize = 92;

// Distance between holes, mm
holesDistance = 82.5;

// Holes diameter, mm
holesDiameter = 4.5;

// Chamfer type
chamfer = "cone"; //["cylinder", "cone"]

// Base thickness, mm
thickness = 4.5;

// Base inner thickness, mm
thicknessInside = 2.7;

// Round corners, mm
roundRadius = 4;			

// Frame width, mm
frameWidth = 2.8;

// Latch width, mm
latchWidth = 13.6;

// Inner grill diameter, mm
innerGrillDiameter = 10;

// Grill number (used for hexagonal grid rows/columns approximation)
grillNumber = 4;

// Grill thickness, mm
grillThickness = 1.2;

/*[ Cover ]*/

// Filter thickness, mm
filterThickness = 2.5;

// Gap between base and cover, mm
gap = 0.2;
// ---------------------------------------------------------

sizeXY = fanSize + frameWidth;
sizeZ = thickness;
sizeZinside = thicknessInside;
echo(sizeXY);

// Hexagonal grid parameters
hex_diameter = 10;    // External point-to-point distance of a single hexagon
hex_thickness = 1;    // Thickness of each hexagon's walls
hex_rows = 15;        // Number of rows of hexagons (adjusted for fit)
hex_columns = 15;     // Number of columns of hexagons (adjusted for fit)
disk_diameter = sizeXY - frameWidth;  // Diameter of the circular disk, matching inner area

// --------------------------- База ---------------------------------------

module rounder() {									// Основа со скруглёнными углами
    union() {
        difference() {								// Обрезка углов по закругления
            cube([sizeXY, sizeXY, sizeZ], true);	// Основа
            
            for(i=[1:4]) {							// Кубики по углам
                rotate([0, 0, i*90])
                translate([sizeXY/2, sizeXY/2, 0])
                cube([roundRadius, roundRadius, sizeZ+1], true);
            };
        };
        
        for(i=[1:4]) {								// Цилиндры по углам для закругления
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
        difference() {									// Вырез под решётку
            rounder();
            intersection() {
                cube([sizeXY-frameWidth*2, sizeXY-frameWidth*2, sizeZ+0.1], true);
                cylinder(h=sizeZ+0.1, d=sizeXY-frameWidth, center=true, $fn=100);
            };
        };
        
        // Add hexagonal grid with circular boundary
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
            for(i=[1:4]) {						// Площадки по периметру
                rotate([0, 0, i*90])
                translate([holesDistance/2, holesDistance/2, 0])
                cylinder(h=sizeZ, d=2.5*holesDiameter, center=true, $fn=100);
            };
        };
        
        for(i=[1:4]) {							// Отверстия под винты
            rotate([0, 0, i*90])
            translate([holesDistance/2, holesDistance/2, 0])
            cylinder(h=sizeZ+0.1, d=holesDiameter, center=true, $fn=100);
        };
        
        for(i=[1:4]) {							// Фаски под потай
            rotate([0, 0, i*90])
            translate([holesDistance/2, holesDistance/2, -0.6])
            if (chamfer == "cone") cylinder(h=sizeZ-1, d1=2*holesDiameter, d2=0, center=true, $fn=100);
            else cylinder(h=sizeZ-1, d=2*holesDiameter, center=true, $fn=100); // Вырез под шляпку DIN912
        };
    };
}

module latch() {				// Защёлки
    difference() {
        holes();
        
        for(i=[1:4]) {
            rotate([0, 0, i*90])
            translate([-latchWidth/2, -sizeXY/2-0.1, sizeZ/2-1.8+0.1])
            cube([latchWidth, 1.2+0.1, 1.8]);
        };
    };
}
latch();

// --------------------------- Крышка ---------------------------------------

sizeXY2 = sizeXY + frameWidth*2 + gap*2;
sizeZ2 = sizeZ + filterThickness;
echo(sizeXY2);

module rounder2() {									// Основа со скругlёнными углами
    union() {
        difference() {								// Обрезка углов по закругления
            cube([sizeXY2, sizeXY2, sizeZ2], true);	// Основа
            
            for(i=[1:4]) {							// Кубики по углам
                rotate([0, 0, i*90])
                translate([sizeXY2/2, sizeXY2/2, 0])
                cube([roundRadius, roundRadius, sizeZ2+1], true);
            };
        };
        
        for(i=[1:4]) {								// Цилиндры по углам для закругления
            rotate([0, 0, i*90])
            translate([sizeXY2/2-roundRadius/2, sizeXY2/2-roundRadius/2, 0])
            cylinder(h=sizeZ2, d=roundRadius, center=true, $fn=100);
        };
    };
}

module grill2() {
    union() {
        difference() {									// Вырез под решётку
            rounder2();
            intersection() {
                cube([sizeXY2-frameWidth*2, sizeXY2-frameWidth*2, sizeZ2+0.1], true);
                cylinder(h=sizeZ2+0.1, d=sizeXY2-frameWidth, center=true, $fn=100);
            };
        };
        
        // Add hexagonal grid with circular boundary
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
            cylinder(h=sizeZ2, d=disk_diameter, center=true, $fn=100);
        }
    };
}

module grill_depth2() {
    difference() {
        grill2();
        translate([0, 0, sizeZinside/2+0.1/2])
        cube([sizeXY2-frameWidth*2, sizeXY2-frameWidth*2, sizeZ2-sizeZinside+0.1], true);
    };
}

translate([0, 0, -50])
union() {
    grill_depth2();
    
    for(i=[1:4]) {								// Защёлки
        rotate([0, 0, i*90])
        translate([-sizeXY2/2+frameWidth, 0, sizeZ2/2])
        rotate([-90, 0, 0])
        linear_extrude(height=latchWidth-2.5, center=true, slices=100)
        polygon([[0, 0], [0, 2], [1, 0]]);
    };
}