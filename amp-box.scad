use <MCAD/array/along_curve.scad>
use <MCAD/shapes/2Dshapes.scad>
use <MCAD/shapes/boxes.scad>
include <MCAD/units/metric.scad>

use <utils.scad>

front_panel_thickness = 2;
back_panel_thickness = 4;
wall_thickness = 3;
clearance = 8;
back_extra_clearance = 10;
pcb_size = [55.5, 83.5, 31];
box_size = (
    pcb_size +
    [2, 2, 2] * (wall_thickness + clearance) +
    [0, back_extra_clearance, 0]
);
standoff_height = 3;

panel_xy_size = [
    box_size[0] - 2 * wall_thickness,
    box_size[2] - 2 * wall_thickness
];
front_panel_size = concat (panel_xy_size, front_panel_thickness);
back_panel_size = concat (panel_xy_size, back_panel_thickness);

screwhole_positions = [
    [48 / 2, pcb_size[1] / 2 - 3.4],
    [-48 / 2, pcb_size[1] / 2 - 3.4],
    [48 / 2, pcb_size[1] / 2 - 3.4 - 65],
    [-48 / 2, pcb_size[1] / 2 - 3.4 - 65]
];

wire_clip_size = [64, 17.8, 2.9];
wire_clip_screwhole_distance = 58.2;

function get_panel_thickness (pos) = (
    (pos == "front") ? front_panel_thickness : back_panel_thickness
);

function get_panel_size (pos) = (
    (pos == "front") ? front_panel_size : back_panel_size
);

$fs = 0.4;
$fa = 1;

module place_pcb ()
{
    translate (
        [
            0,
            (pcb_size[1] - box_size[1]) / 2 + front_panel_thickness,
            -box_size[2] / 2 + wall_thickness + standoff_height
        ]
    )
    children ();
}

module pcb ()
{
    ccube (pcb_size, center = X + Y);

    translate (-[5.6, 0, 0] + [pcb_size[0] / 2, -pcb_size[1] / 2, 8])
    rotate (90, X)
    translate ([0, 0, -epsilon]) {
        mcad_linear_multiply (no = 2, separation = -20, axis = X)
        cylinder (d = 7, h = 14.5);

        translate ([-40.6, 0])
        cylinder (d = 7, h = 3);
    }
}

module place_pcb_screws ()
{
    place_pcb ()
    for (pos = screwhole_positions) {
        translate (pos)
        children ();
    }
}

module pcb_screwholes ()
{
    place_pcb_screws ()
    translate ([0, 0, -(standoff_height + wall_thickness)])
    mirror (Z)
    screwhole (3, 10, align_with = "above_nut", head_extra_length = 20);
}

module place_panel_screwholes () {
    screw_offset = 3;

    rotate (90, X)
    for (z = [box_size[1] / 2 - front_panel_thickness,
              -box_size[1] / 2 + back_panel_thickness]) {
        for (x = [1, -1] * (box_size[0] / 2 - wall_thickness - screw_offset)) {
            for (y = [1, -1] *
                 (box_size[2] / 2 - wall_thickness - screw_offset)) {
                translate ([x, y, z])
                mirror_if (z > 0, Z)
                children ();
            }
        }
    }
}

module panel_screwholes ()
{
    place_panel_screwholes ()
    translate ([0, 0, 4])
    screwhole (3, 10, align_with = "above_nut",
               head_extra_length = 20,
               screw_extra_length = 20,
               nut_projection_length = 10);
}

module basic_box ()
{
    outer_size = [box_size[0], box_size[2], box_size[1]];
    inner_size = outer_size - [2, 2, -1] * wall_thickness;

    module place_on_box_bottom () {
        translate ([0, 0, -box_size[2] / 2])
        children ();
    }


    render ()
    difference () {
        union () {
            rotate (90, X)
            difference () {
                mcad_rounded_box (outer_size, 5, sidesonly = true, center = true);
                mcad_rounded_box (inner_size, 5 - 3, sidesonly = true, center = true);
            }

            place_pcb_screws ()
            mirror (Z)
            cylinder (d = 6, h = standoff_height);

            place_panel_screwholes ()
            cylinder (d = 8, h = 4);
        }

        pcb_screwholes ();
        panel_screwholes ();
    }
}

module box_bottom ()
{
    render ()
    difference () {
        basic_box ();
        ccube (1000, center = X + Y);
    }
}

module box_top ()
{
    render ()
    difference () {
        basic_box ();

        mirror (Z)
        ccube (1000, center = X + Y);
    }
}

module place_panel (pos)
{
    dir = (pos == "front") ? -1 : 1;
    thickness = get_panel_thickness (pos);

    translate ([0, dir * (box_size[1] / 2 - thickness), 0])
    rotate (-90, X)
    children ();
}

module basic_panel (pos)
{
    dir = (pos == "front") ? -1 : 1;
    thickness = get_panel_thickness (pos);
    size = get_panel_size (pos);

    translate ([0, 0, dir * thickness / 2])
    mcad_rounded_box (size, 2, center = true, sidesonly = true);
}

module front_panel ()
{
    render ()
    difference () {
        place_panel ("front")
        basic_panel ("front");

        place_pcb ()
        pcb ();

        /* power button */
        translate ([0, -pcb_size[1] / 2, 30])
        place_pcb ()
        rotate (90, X)
        cylinder (d = 16, h = 5, center = true);

        panel_screwholes ();
    }
}

module back_panel ()
{
    backplate_thickness = 4;

    module place_wire_clip ()
    {
        translate ([0, 10])
        children ();
    }

    module wire_clip ()
    {
        translate ([0, 0, back_panel_thickness + epsilon])
        mirror (Z)
        ccube (wire_clip_size + [0, 0, epsilon], center = X + Y);
    }

    module wire_clip_nuttrap_cylinders ()
    {
        place_wire_clip_screwholes ()
        translate ([0, 0, epsilon])
        mirror (Z)
        cylinder (d = 10, h = 3);
    }

    module place_wire_clip_screwholes ()
    {
        translate ([-wire_clip_screwhole_distance / 2, 0])
        mcad_linear_multiply (no = 2, separation = wire_clip_screwhole_distance,
                              axis = X)
        children ();
    }

    module wire_clip_screwholes ()
    {
        place_wire_clip_screwholes ()
        translate ([0, 0, -3])
        mirror (Z)
        screwhole (3, 10, align_with = "above_nut");
    }

    module wire_clip_cutout ()
    {
        mirror (Z)
        translate (-[0, wire_clip_size[1] / 2 - 1, 0])
        ccube ([46, 6, 100], center = X + Z);
    }

    module power_jack ()
    {
        translate ([0, -15]) {
            intersection () {
                cylinder (d = 12, h = 20, center = true);
                cube ([10.8, 20, 20], center = true);
            }

            translate ([0, 0, back_panel_thickness + epsilon])
            mirror (Z)
            cylinder (d = 14.2, h = 1.6);
        }
    }

    rotate (180, Y)
    place_panel ()
    render ()
    difference () {
        union () {
            basic_panel ("back");

            place_wire_clip ()
            wire_clip_nuttrap_cylinders ();
        }

        place_wire_clip () {
            wire_clip ();
            wire_clip_screwholes ();
            wire_clip_cutout ();
        }

        power_jack ();
    }
}

*basic_box ();

%place_pcb ()
pcb ();

*box_bottom ();
box_top ();

front_panel ();
back_panel ();
