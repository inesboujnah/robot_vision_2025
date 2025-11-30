from launch import LaunchDescription
from launch_ros.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import DeclareLaunchArgument, OpaqueFunction
from ament_index_python.packages import get_package_share_directory
import os


def _launch_setup(context, *args, **kwargs):
    mode = context.launch_configurations.get('mode', 'rgbd')

    oak_launch_node = os.path.join(
        get_package_share_directory('depthai_ros_driver'),
        'launch',
        'camera.launch.py'
    )

    oak_calibration_node = os.path.join(
        get_package_share_directory('depthai_ros_driver'),
        'launch',
        'calibration.launch.py'
    )

    if mode == 'rgbd':
        return [
            IncludeLaunchDescription(PythonLaunchDescriptionSource(oak_launch_node),
                launch_arguments={
                    'camera.i_tf_camera_name': 'rgbd',
                    'camera.i_tf_camera_model': 'OAK-D-PRO-W',
                    'camera.i_pipeline_type': 'RGBD',
                    'camera.i_enable_sync': 'true',
                    'pipeline_gen.i_enable_sync': 'true'
                }.items()
            )
        ]

    if mode == 'stereo':
        return [
            IncludeLaunchDescription(PythonLaunchDescriptionSource(oak_launch_node),
                launch_arguments={
                    'camera.i_tf_camera_name': 'stereo',
                    'camera.i_tf_camera_model': 'OAK-D-PRO-W',
                    'camera.i_pipeline_type': 'Stereo',
                    'camera.i_enable_sync': 'true',
                    'pipeline_gen.i_enable_sync': 'true',
                    'stereo.i_align_depth': 'true'
                }.items()
            )
        ]

    if mode == 'stereo-inertial':
        return [
            IncludeLaunchDescription(PythonLaunchDescriptionSource(oak_launch_node),
                launch_arguments={
                    'camera.i_tf_camera_name': 'stereo-inertial',
                    'camera.i_tf_camera_model': 'OAK-D-PRO-W',
                    'camera.i_pipeline_type': 'Stereo',
                    'camera.i_enable_sync': 'true',
                    'pipeline_gen.i_enable_sync': 'true',
                    'stereo.i_align_depth': 'true',
                    'pipeline_gen.i_enable_imu': 'true'
                }.items()
            )
        ]

    if mode == 'calibration':
        return [
            IncludeLaunchDescription(PythonLaunchDescriptionSource(oak_calibration_node))
        ]

    raise RuntimeError(f"Unknown mode '{mode}'. Expected one of: 'rgbd', 'stereo', 'stereo-inertial', 'calibration'.")


def generate_launch_description():
    mode_arg = DeclareLaunchArgument(
        'mode', default_value='rgbd',
        description="Mode to launch: 'rgbd', 'stereo', 'stereo-inertial', or 'calibration' (only one at a time)"
    )

    return LaunchDescription([
        mode_arg,
        OpaqueFunction(function=_launch_setup)
    ])

# ros2 launch depthai_ros_driver camera.launch.py
# ros2 launch depthai_ros_driver calibration.launch.py