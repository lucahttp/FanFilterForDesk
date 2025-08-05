module hex(diameter, thickness) {
    difference() {
        circle(d=diameter, $fn=6);
        circle(d=diameter - thickness * 2, $fn=6);
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

disk_diameter = 50;  // Diameter of the circular disk
hex_diameter = 10;   // External point-to-point distance of a single hexagon
hex_thickness = 1;   // Thickness of each hexagon's walls
hex_rows = 15;       // Number of rows of hexagons
hex_columns = 15;    // Number of columns of hexagons

intersection() {
    // Calculate the grid's offset to center it
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
    
    // Circular disk centered at origin with adjustable diameter
    circle(d=disk_diameter, $fn=360);
}