from launch import LaunchDescription
from launch_ros.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import DeclareLaunchArgument, OpaqueFunction, ExecuteProcess, RegisterEventHandler, TimerAction
from launch.event_handlers import OnProcessStart
from ament_index_python.packages import get_package_share_directory
import os


def _launch_setup(context, *args, **kwargs):
    mode = context.launch_configurations.get('mode', 'rgbd')

    # RealSense launch files
    rs_camera_node = os.path.join(
        get_package_share_directory('realsense2_camera'),
        'launch',
        'rs_camera.launch.py'  # basic camera launch
    )

    rs_launch_node = os.path.join(
        get_package_share_directory('realsense2_camera'),
        'launch',
        'rs_launch.py'  # more configurable launch
    )

    if mode == 'basic':
        return [IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_camera_node)
        )]

    if mode == 'rgbd':
        return [IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node),
            launch_arguments={
                'camera_namespace': 'rgbd',
                'camera_name': 'D435',
                'enable_rgbd': 'true',
                'enable_sync': 'true',
                'align_depth.enable': 'true',
                'enable_color': 'true',
                'enable_depth': 'true'
            }.items()
        )]

    if mode == 'stereo':
        return [IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node),
            launch_arguments={
                'camera_namespace': 'stereo',
                'camera_name': 'D435',
                'enable_infra1': 'true',
                'enable_infra2': 'true',
                'enable_sync': 'true'
            }.items()
        )]

    if mode == 'calibration':
        camera_launch = IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_camera_node)
        )
        
        # Call calibration service after camera starts (5 second delay)
        calib_service_call = TimerAction(
            period=5.0,
            actions=[ExecuteProcess(
                cmd=['ros2', 'service', 'call', '/camera/camera/calib_config_read', 'std_srvs/srv/Empty'],
                output='screen'
            )]
        )
        
        return [camera_launch, calib_service_call]

    raise RuntimeError(f"Unknown mode '{mode}'. Expected one of: 'basic', 'rgbd', 'stereo', 'calibration'.")


def generate_launch_description():
    mode_arg = DeclareLaunchArgument(
        'mode', default_value='rgbd',
        description="Mode to launch: 'basic', 'rgbd', 'stereo', or 'calibration' (only one at a time)"
    )

    return LaunchDescription([
        mode_arg,
        OpaqueFunction(function=_launch_setup)
    ])


# Usage examples:
# ros2 launch realsense_setup ros2_launch.py                # defaults to rgbd
# ros2 launch realsense_setup ros2_launch.py mode:=basic
# ros2 launch realsense_setup ros2_launch.py mode:=stereo
# ros2 launch realsense_setup ros2_launch.py mode:=calibration
# ros2 service call /camera/camera/calib_config_read 