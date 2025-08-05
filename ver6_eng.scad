/*[ Base ]*/

// Fan size along X and Y, mm
fanSize = 92;              // The dimensions of the fan along the X and Y axes in millimeters.

// Distance between holes, mm
holesDistance = 82.5;      // The distance between mounting holes in millimeters.

// Holes diameter, mm
holesDiameter = 4.5;       // The diameter of the mounting holes in millimeters.

// Chamfer type
chamfer = "cone";          // Type of chamfer for screw heads: "cylinder" or "cone".

// Base thickness, mm
thickness = 4.5;           // The thickness of the base in millimeters.

// Base inner thickness, mm
thicknessInside = 2.7;     // The inner thickness of the base where the grill is located, in millimeters.

// Round corners, mm
roundRadius = 4;           // The radius for rounding the corners of the base, in millimeters.

// Frame width, mm
frameWidth = 2.8;          // The width of the frame surrounding the fan opening, in millimeters.

// Latch width, mm
latchWidth = 13.6;         // The width of the latches for securing the cover, in millimeters.

// Inner grill diameter, mm
innerGrillDiameter = 10;   // The diameter of the innermost part of the grill, in millimeters.

// Grill number (used for hexagonal grid rows/columns approximation)
grillNumber = 4;           // Number of grill sections (used as a reference for hexagonal grid density).

// Grill thickness, mm
grillThickness = 1.2;      // The thickness of the grill elements, in millimeters.

/*[ Cover ]*/

// Filter thickness, mm
filterThickness = 2.5;     // The thickness of the filter material, in millimeters.

// Gap between base and cover, mm
gap = 0.2;                 // The gap between the base and cover for assembly, in millimeters.
// ---------------------------------------------------------

sizeXY = fanSize + frameWidth;    // Total size of the base along X and Y, including frame width.
sizeZ = thickness;                // Total height of the base.
sizeZinside = thicknessInside;    // Height of the inner section of the base.
echo(sizeXY);                     // Output the calculated sizeXY for debugging.

// Hexagonal grid parameters
hex_diameter = 10;                // External point-to-point distance of a single hexagon in millimeters.
hex_thickness = 1;                // Thickness of each hexagon's walls in millimeters.
hex_rows = 15;                    // Number of rows of hexagons in the grid.
hex_columns = 15;                 // Number of columns of hexagons in the grid.
disk_diameter = sizeXY - frameWidth;  // Diameter of the circular area for the hexagonal grid, matching the inner area.

// --------------------------- Base ---------------------------------------

module rounder() {                  // Module to create the base with rounded corners
    union() {
        difference() {               // Subtract cubes to create rounded corners
            cube([sizeXY, sizeXY, sizeZ], true);  // Base cube, centered
            for(i=[1:4]) {            // Loop to create cubes at each corner
                rotate([0, 0, i*90])
                translate([sizeXY/2, sizeXY/2, 0])
                cube([roundRadius, roundRadius, sizeZ+1], true);
            };
        };
        
        for(i=[1:4]) {               // Add cylinders to round the corners
            rotate([0, 0, i*90])
            translate([sizeXY/2-roundRadius/2, sizeXY/2-roundRadius/2, 0])
            cylinder(h=sizeZ, d=roundRadius, center=true, $fn=100);
        };
    };
}

module hex(diameter, thickness) {   // Module to create a single hexagonal ring
    linear_extrude(height=sizeZ, center=true) {
        difference() {
            circle(d=diameter, $fn=6);  // Outer hexagon
            circle(d=diameter - thickness * 2, $fn=6);  // Inner hexagon to create a ring
        }
    }
}

function compute_x_delta(outer_radius, inner_radius) = (outer_radius + inner_radius) * 0.5 * (1 + cos(60));
function compute_y_delta(outer_radius, inner_radius) = (outer_radius + inner_radius) * 0.5 * sin(60);

module hex_grid(diameter, thickness, rows, columns) {  // Module to create a hexagonal grid
    outer_radius = diameter / 2;
    inner_radius = outer_radius - thickness;

    x_delta = compute_x_delta(outer_radius, inner_radius);  // Horizontal spacing between hexagons
    y_delta = compute_y_delta(outer_radius, inner_radius);  // Vertical spacing between hexagons

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

module grill() {                  // Module to create the grill with hexagonal pattern
    union() {
        difference() {              // Cut out the inner area for the grill
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

module grill_depth() {           // Module to create the inner depth of the grill
    difference() {
        grill();
        translate([0, 0, sizeZinside/2+0.1/2])
        cube([sizeXY-frameWidth*2, sizeXY-frameWidth*2, sizeZ-sizeZinside+0.1], true);
    };
}

module holes() {                 // Module to create mounting holes
    difference() {
        union() {
            grill_depth();
            for(i=[1:4]) {          // Add platforms around mounting holes
                rotate([0, 0, i*90])
                translate([holesDistance/2, holesDistance/2, 0])
                cylinder(h=sizeZ, d=2.5*holesDiameter, center=true, $fn=100);
            };
        };
        
        for(i=[1:4]) {              // Cut holes for screws
            rotate([0, 0, i*90])
            translate([holesDistance/2, holesDistance/2, 0])
            cylinder(h=sizeZ+0.1, d=holesDiameter, center=true, $fn=100);
        };
        
        for(i=[1:4]) {              // Add chamfers for screw heads
            rotate([0, 0, i*90])
            translate([holesDistance/2, holesDistance/2, -0.6])
            if (chamfer == "cone") cylinder(h=sizeZ-1, d1=2*holesDiameter, d2=0, center=true, $fn=100);
            else cylinder(h=sizeZ-1, d=2*holesDiameter, center=true, $fn=100); // Cutout for DIN912 screw heads
        };
    };
}

module latch() {                 // Module to create latches for securing the cover
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

// --------------------------- Cover ---------------------------------------

sizeXY2 = sizeXY + frameWidth*2 + gap*2;  // Total size of the cover, including frame and gap.
sizeZ2 = sizeZ + filterThickness;         // Total height of the cover.
echo(sizeXY2);                            // Output the calculated sizeXY2 for debugging.

module rounder2() {                       // Module to create the cover with rounded corners
    union() {
        difference() {                      // Subtract cubes to create rounded corners
            cube([sizeXY2, sizeXY2, sizeZ2], true);  // Cover cube, centered
            
            for(i=[1:4]) {                  // Cubes at each corner
                rotate([0, 0, i*90])
                translate([sizeXY2/2, sizeXY2/2, 0])
                cube([roundRadius, roundRadius, sizeZ2+1], true);
            };
        };
        
        for(i=[1:4]) {                      // Add cylinders to round the corners
            rotate([0, 0, i*90])
            translate([sizeXY2/2-roundRadius/2, sizeXY2/2-roundRadius/2, 0])
            cylinder(h=sizeZ2, d=roundRadius, center=true, $fn=100);
        };
    };
}

module grill2() {                       // Module to create the cover grill with hexagonal pattern
    union() {
        difference() {                      // Cut out the inner area for the grill
            rounder2();
            intersection() {
                // Use the same size as the base grill for the intersection
                cube([sizeXY-frameWidth*2, sizeXY-frameWidth*2, sizeZ2+0.1], true);
                cylinder(h=sizeZ2+0.1, d=disk_diameter, center=true, $fn=100);
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
            // Use the same disk cut as the base grill
            cylinder(h=sizeZ2, d=disk_diameter, center=true, $fn=100);
        }
    };
}

module grill_depth2() {                 // Module to create the inner depth of the cover grill
    difference() {
        grill2();
        translate([0, 0, sizeZinside/2+0.1/2])
        cube([sizeXY2-frameWidth*2, sizeXY2-frameWidth*2, sizeZ2-sizeZinside+0.1], true);
    };
}

translate([0, 0, -50])                  // Translate the cover downward for visualization
union() {
    grill_depth2();
    
    for(i=[1:4]) {                      // Add latches to secure the cover
        rotate([0, 0, i*90])
        translate([-sizeXY2/2+frameWidth, 0, sizeZ2/2])
        rotate([-90, 0, 0])
        linear_extrude(height=latchWidth-2.5, center=true, slices=100)
        polygon([[0, 0], [0, 2], [1, 0]]);
    };
}