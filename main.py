"""This module contains the business logic of the function.

use the automation_context module to wrap your function in an Automate context helper
"""
import os
import subprocess

from archaea.geometry.vector3d import Vector3d
from archaea.geometry.mesh import Mesh
from archaea_simulation.simulation_objects.domain import Domain
from archaea_simulation.speckle.vtk_to_speckle import vtk_to_speckle, Text
from archaea_simulation.cfd.utils.path import get_cfd_export_path
from pydantic import Field
from speckle_automate import (
    AutomateBase,
    AutomationContext,
    execute_automate_function,
)
from specklepy.objects.base import Base
from specklepy.objects.other import DisplayStyle
from specklepy.objects.geometry import Brep, Line, Polyline, Point, Plane

from flatten import flatten_base

# # TODO: Use speckle text object when specklepy has new release


class FunctionInputs(AutomateBase):
    """These are function author defined values.

    Automate will make sure to supply them matching the types specified here.
    Please use the pydantic model schema to define your inputs:
    https://docs.pydantic.dev/latest/usage/models/
    """

    wind_direction: float = Field(
        title="Wind Direction",
        description=(
            "Wind direction represents as azimuth angle is like a compass direction"
            "with North = 0°, East = 90°, South = 180°, West = 270°."
        ),
    )
    wind_speed: float = Field(
        title="Wind Speed",
        description="Wind speed (m/s) in XY plane."
    )
    reference_height: float = Field(
        title="Reference Wind Speed Height",
        description="Altitude (m) of the wind speed is measured.",
        default=15,
    )
    number_of_cpus: int = Field(
        title="Number of CPUs",
        description="Number of CPUs to run simulation in parallel.",
        default=4,
    )
    tunnel_width_scale: float = Field(
        title="Tunnel width scale",
        description=("Scale value of the tunnel width according to context objects bounding box. "
                     "It scales the inlet surface which we send wind into tunnel."),
        default=5,
    )
    tunnel_depth_scale: float = Field(
        title="Tunnel depth scale",
        description="Scale value of the tunnel depth according to context objects bounding box.",
        default=5,
    )
    tunnel_height_scale: float = Field(
        title="Tunnel height scale",
        description=("Scale value of the tunnel height according to context objects bounding box. "
                     "It scales from zGround."),
        default=3,
    )


def automate_function(
        automate_context: AutomationContext,
        function_inputs: FunctionInputs,
) -> None:
    """This is an example Speckle Automate function.

    Args:
        automate_context: A context helper object, that carries relevant information
            about the runtime context of this function.
            It gives access to the Speckle project data, that triggered this run.
            It also has convenience methods attach result data to the Speckle model.
        function_inputs: An instance object matching the defined schema.
    """

    print("number of cpus", os.cpu_count())
    subprocess.run("/bin/bash -c 'source /opt/openfoam9/etc/bashrc'", shell=True)

    # the context provides a convenient way, to receive the triggering version
    version_root_object = automate_context.receive_version()
    accepted_types = [Brep.speckle_type]
    objects_to_create_stl = []
    flatten_base_objects = flatten_base(version_root_object)

    count = 0
    for b in flatten_base_objects:
        if b.speckle_type in accepted_types:
            if not b.id:
                raise ValueError("Cannot operate on objects without their id's.")
            objects_to_create_stl.append(b)
            count += 1

    speckle_meshes = []
    for speckle_mesh in objects_to_create_stl:
        speckle_meshes += speckle_mesh.displayValue

    archaea_meshes = []
    for speckle_mesh in speckle_meshes:
        archaea_mesh = Mesh.from_ngon_mesh(speckle_mesh.vertices, speckle_mesh.faces)
        archaea_meshes.append(archaea_mesh)

    x_scale = function_inputs.tunnel_width_scale
    y_scale = function_inputs.tunnel_depth_scale
    z_scale = function_inputs.tunnel_height_scale
    # Init domain
    domain = Domain.from_meshes(archaea_meshes, x_scale=x_scale, y_scale=y_scale, z_scale=z_scale, wind_direction=function_inputs.wind_direction, wind_speed=function_inputs.wind_speed)

    # Get folder to copy cases
    archaea_folder = get_cfd_export_path('archaea')
    if not os.path.exists(archaea_folder):
        os.makedirs(archaea_folder)

    # Get case folder
    case_folder = os.path.join(archaea_folder, version_root_object.id)
    domain.create_cfd_case(case_folder, function_inputs.number_of_cpus)
    cmd_path = os.path.join(case_folder, './All-runs')
    cmd = "/bin/bash -c '{cmd_path}'".format(cmd_path=cmd_path)

    completed_process = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    print(completed_process.stdout)

    block_mesh_log = os.path.join(case_folder, 'log.blockMesh')
    add_to_store_if_exist(automate_context, block_mesh_log)

    decompose_par_log = os.path.join(case_folder, 'log.decomposePar')
    add_to_store_if_exist(automate_context, decompose_par_log)

    patch_summary_log = os.path.join(case_folder, 'log.patchSummary')
    add_to_store_if_exist(automate_context, patch_summary_log)

    reconstruct_par_log = os.path.join(case_folder, 'log.reconstructPar')
    add_to_store_if_exist(automate_context, reconstruct_par_log)

    reconstruct_par_mesh_log = os.path.join(case_folder, 'log.reconstructParMesh')
    add_to_store_if_exist(automate_context, reconstruct_par_mesh_log)

    simple_foam_log = os.path.join(case_folder, 'log.simpleFoam')
    add_to_store_if_exist(automate_context, simple_foam_log)

    snappy_hex_mesh_log = os.path.join(case_folder, 'log.snappyHexMesh')
    add_to_store_if_exist(automate_context, snappy_hex_mesh_log)

    surface_features_log = os.path.join(case_folder, 'log.surfaceFeatures')
    add_to_store_if_exist(automate_context, surface_features_log)

    vtk_file = os.path.join(case_folder, 'postProcessing',
                            'cutPlaneSurface', '400', 'U_cutPlane.vtk')

    result_mesh = vtk_to_speckle(vtk_file, domain.center.move(Vector3d(domain.x / 2 + 2, -domain.y / 2 - 2, 0)))

    domain_corner_lines = domain_lines(domain.corners)
    subdomain_corner_lines = domain_lines(domain.subdomain_corners)

    arrow_line, arrow, text = wind_direction_arrow(domain)

    result = Base()
    result.data = [result_mesh, domain_corner_lines, subdomain_corner_lines, [arrow_line, arrow, text]]

    automate_context.create_new_version_in_project(
        result,
        "automate_result"
    )

    if count == 0:
        # this is how a run is marked with a failure cause
        automate_context.mark_run_failed(
            "Automation failed: "
            "Not found appropriate object to run CFD simulation."
        )
    else:
        automate_context.mark_run_success("Object found to run simulation!")

def wind_direction_arrow(domain: Domain):
    wind_vector = Vector3d.from_azimuth_angle(domain.wind_direction)
    vector = wind_vector.reverse()
    mid = domain.center.move(vector.scale(domain.y / 2))

    mid = mid.move(vector.scale(5))

    point_left = mid.move(vector.scale(2)).rotate(Vector3d(0, 0, 1), 45, mid)
    point_right = mid.move(vector.scale(2)).rotate(Vector3d(0, 0, 1), -45, mid)
    offset_mid_2 = mid.move(vector.scale(2 ** 0.5))
    offset_mid_10 = mid.move(vector.scale(10))

    arrow_line = Polyline.from_points([Point.from_coords(p.x, p.y, p.z) for p in [offset_mid_2, offset_mid_10]])
    arrow = Polyline.from_points([Point.from_coords(p.x, p.y, p.z) for p in [mid, point_left, point_right, mid]])

    x_dir = vector.reverse()
    y_dir = x_dir.cross_product(Vector3d(0,0,1)).reverse()
    text_v = point_left.move(vector.scale(20))
    plane = Plane.from_list([text_v.x, text_v.y, text_v.z,
                             0, 0, 1,
                             x_dir.x, x_dir.y, 0,
                             y_dir.x, y_dir.y, 0,
                             3])

    text = Text()
    text.height = 2.5
    text.value = f"{domain.wind_speed} m/s"
    text.plane = plane
    text.units = "m"

    display_style = DisplayStyle()
    display_style.color = -16777216
    display_style.line_type = "Continuous"
    display_style.units = "m"
    display_style.line_weight = 0

    text.displayStyle = display_style

    return arrow_line, arrow, text

def domain_lines(corners):
    speckle_domain_points = [Point.from_coords(corner.x, corner.y, corner.z) for corner in corners]
    floor_polyline = Polyline.from_points(speckle_domain_points[0:4])
    floor_polyline.closed = True
    ceiling_polyline = Polyline.from_points(speckle_domain_points[-4:])
    ceiling_polyline.closed = True

    line_1 = Line()
    line_1.units = 'm'
    line_1.start = speckle_domain_points[0]
    line_1.end = speckle_domain_points[4]

    line_2 = Line()
    line_2.units = 'm'
    line_2.start = speckle_domain_points[1]
    line_2.end = speckle_domain_points[5]

    line_3 = Line()
    line_3.units = 'm'
    line_3.start = speckle_domain_points[2]
    line_3.end = speckle_domain_points[6]

    line_4 = Line()
    line_4.units = 'm'
    line_4.start = speckle_domain_points[3]
    line_4.end = speckle_domain_points[7]

    return [floor_polyline,ceiling_polyline,line_1,line_2,line_3,line_4]


def add_to_store_if_exist(automate_context: AutomationContext, path):
    if os.path.exists(path):
        automate_context.store_file_result(path)

# make sure to call the function with the executor
if __name__ == "__main__":
    # NOTE: always pass in the automate function by its reference, do not invoke it!

    # pass in the function reference with the inputs schema to the executor
    execute_automate_function(automate_function, FunctionInputs)

    # if the function has no arguments, the executor can handle it like so
    # execute_automate_function(automate_function_without_inputs)
