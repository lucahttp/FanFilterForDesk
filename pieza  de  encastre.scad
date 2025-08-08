// Parameters
outer_size = 60;         // outer width/length of the base square
wall_thickness = 3;      // wall thickness
height = 30;             // height of the 4-sided frame
tab_thickness = 20;      // how much the top lip extends outward
tab_height = 5;          // height of the top lip above the main box

module hollow_square_with_top_lip_connected() {
    difference() {
        // Main hollow box
        cube([outer_size, outer_size, height], center=false);

        // Inner cutout to make it hollow
        translate([wall_thickness, wall_thickness, 0])
            cube([outer_size - 2*wall_thickness, outer_size - 2*wall_thickness, height], center=false);
    }

    // Single continuous tab/lip with 90° corners
    difference() {
        // Outer tab/lip box
        translate([-tab_thickness, -tab_thickness, height - tab_height])
            cube([outer_size + 2 * tab_thickness, outer_size + 2 * tab_thickness, tab_height]);

        // Inner hole to make the lip "ring"-shaped
        translate([0, 0, height - tab_height])
            cube([outer_size, outer_size, tab_height]);
    }
}

// Call the module
hollow_square_with_top_lip_connected();
