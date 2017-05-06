use <MCAD/array/along_curve.scad>
use <MCAD/shapes/2Dshapes.scad>
use <MCAD/shapes/boxes.scad>
include <MCAD/units/metric.scad>

use <utils.scad>

wall_thickness = 3;
clearance = 3;
pcb_size = [55.5, 83.5, 31];
box_size = pcb_size + [2, 2, 2] * (wall_thickness + clearance);

screwhole_positions = [
    [48 / 2, pcb_size[1] / 2 - 3.4],
    [-48 / 2, pcb_size[1] / 2 - 3.4],
    [48 / 2, pcb_size[1] / 2 - 3.4 - 65],
    [-48 / 2, pcb_size[1] / 2 - 3.4 - 65]
];

$fs = 0.4;
$fa = 1;

module place_pcb ()
{
    translate ([0, 0, -pcb_size[2] / 2])
    children ();
}

module pcb ()
{
    ccube (pcb_size, center = X + Y);

    translate (-[5.6, 0, 0] + [pcb_size[0] / 2, -pcb_size[1] / 2, 8])
    rotate (90, X) {
        mcad_linear_multiply (no = 2, separation = -20, axis = X)
        cylinder (d = 7, h = 14.5);

        translate ([-40.6, 0])
        cylinder (d = 7, h = 3);
    }
}

module place_pcb_screws ()
{
    for (pos = screwhole_positions) {
        translate (pos)
        children ();
    }
}

module pcb_screwholes ()
{
    place_pcb_screws ()
    mirror (Z)
    screwhole (3, 10, align_with = "above_nut", head_extra_length = 20);
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

            place_on_box_bottom ()
            translate ([0, 0, wall_thickness])
            place_pcb_screws ()
            cylinder (d = 6, h = 3);
        }

        place_on_box_bottom ()
        pcb_screwholes ();
    }
}

module box_bottom ()
{
}

basic_box ();
%
place_pcb ()
pcb ();
