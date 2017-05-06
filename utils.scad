use <MCAD/array/along_curve.scad>
use <MCAD/fasteners/nuts_and_bolts.scad>

include <MCAD/units/metric.scad>


cap_screw_head_diameters = [
    [3, 5.5],
    [4, 7],
    [5, 8.5],
    [6, 10],
    [8, 13],
    [10, 16],
    [12, 18],
    [16, 24],
    [20, 30],
    [24, 36],
];

/**
 * screwhole - renders a cap screw hole
 *
 * @param size Diameter of screw
 * @param length Fastened length (distance between screw and nut)
 * @param nut_projection Direction to project nut in (axial, radial)
 * @param align_with Alignment of whole set (above_head, below_head, center,
 *                                           below_nut, above_nut)
 */
module screwhole (size, length, nut_projection = "axial",
                  align_with = "above_head",
                  screw_extra_length = 9999, head_extra_length = 9999,
                  nut_projection_length = 100)
{
    cap_head_d = lookup (size, cap_screw_head_diameters);
    cap_head_h = size;

    nut_thickness = mcad_metric_nut_thickness (size);

    elevation = (
        (align_with == "above_head") ? 0 :
        (align_with == "below_head") ? cap_head_h :
        (align_with == "center") ? cap_head_h + length / 2 :
        (align_with == "below_nut") ? cap_head_h + length :
        (align_with == "above_nut") ? cap_head_h + length + nut_thickness : 0
    );

    /* screw head */
    translate ([0, 0, -elevation]) {
        translate ([0, 0, cap_head_h])
        mirror (Z)
        cylinder (d = cap_head_d, h = cap_head_h + head_extra_length);

        /* screw body */
        translate ([0, 0, cap_head_h - epsilon])
        cylinder (d = size + 0.3, h = length + screw_extra_length + epsilon);

        /* nut */
        translate ([0, 0, cap_head_h + length - epsilon])
        hull () {
            axis = (nut_projection == "axial") ? +Z : +X;

            mcad_linear_multiply (no = 2, separation = nut_projection_length,
                                  axis = axis)
            mcad_nut_hole (size = size);
        }
    }
}

screwhole (3, 20, align_with = "below_nut");
