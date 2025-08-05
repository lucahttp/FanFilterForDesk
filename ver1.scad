module hex(diameter, thickness) {
    difference() {
        circle(d=diameter,$fn=6);
        circle(d=diameter - thickness * 2,$fn=6);
    }
}


function compute_x_delta(outer_radius,inner_radius) = (outer_radius + inner_radius) * 0.5 * (1 + cos(60));
function compute_y_delta(outer_radius,inner_radius) = (outer_radius + inner_radius) * 0.5 * sin(60);


module hex_grid(diameter, thickness, rows, columns) {
    outer_radius = diameter / 2;
    inner_radius = outer_radius - thickness;

    x_delta = compute_x_delta(outer_radius,inner_radius);

    y_delta = compute_y_delta(outer_radius,inner_radius);

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


intersection() {
    // Hexagonal grid
    hex_grid(
        diameter=20, // External point-to-point distance of a single hexagon
        thickness=2, // Thickness parameter (used for spacing calculations)
        rows=5,      // Reduced rows for better visibility within circle
        columns=5    // Reduced columns for better visibility within circle
    );
    
    // Calculate the bounding circle diameter to encompass the entire grid
    outer_radius = 20 / 2;
    inner_radius = outer_radius - 2;
    x_delta = compute_x_delta(outer_radius, inner_radius);
    y_delta = compute_y_delta(outer_radius, inner_radius);
    grid_width = x_delta * (5 - 1) + 20;
    grid_height = 2 * y_delta * (5 - 1) + 20;
    bounding_diameter = sqrt(pow(grid_width, 2) + pow(grid_height, 2)) + 10; // Adjusted for better fit
    
    // Circular disk to keep only overlapping parts
    circle(d=bounding_diameter, $fn=360);
}