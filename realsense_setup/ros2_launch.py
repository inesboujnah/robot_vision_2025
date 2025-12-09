from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import DeclareLaunchArgument, OpaqueFunction, ExecuteProcess, RegisterEventHandler, TimerAction
from launch.event_handlers import OnProcessStart
from ament_index_python.packages import get_package_share_directory
import os


def _launch_setup(context, *args, **kwargs):
    mode = context.launch_configurations.get('mode', 'rgbd')
    delay = float(context.launch_configurations.get('delay', '5.0'))

    # RealSense launch files

    rs_launch_node = os.path.join(
        get_package_share_directory('realsense2_camera'),
        'launch',
        'rs_launch.py'
    )

    if mode == 'rgbd':
        camera_launch = IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node),
            launch_arguments={
                'camera_namespace': 'rgbd',
                'camera_name': 'D435',
                'enable_rgbd': 'true',
                'enable_sync': 'true',
                'align_depth.enable': 'true',
                'enable_color': 'true',
                'enable_depth': 'true',
                'initial_reset': 'true'
            }.items()
        )
        
        return [TimerAction(period=delay, actions=[camera_launch])]

    if mode == 'stereo':
        camera_launch = IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node),
            launch_arguments={
                'camera_namespace': 'stereo',
                'camera_name': 'D435',
                'enable_infra1': 'true',
                'enable_infra2': 'true',
                'enable_sync': 'true',
                'initial_reset': 'true'
            }.items()
        )
        
        return [TimerAction(period=delay, actions=[camera_launch])]

    raise RuntimeError(f"Unknown mode '{mode}'. Expected one of: 'rgbd', 'stereo'.")


def generate_launch_description():
    mode_arg = DeclareLaunchArgument(
        'mode', default_value='rgbd',
        description="Mode to launch: 'rgbd' or 'stereo' (only one at a time)"
    )
    
    delay_arg = DeclareLaunchArgument(
        'delay', default_value='0.0',
        description="Delay in seconds before launching the node (default: 0.0)"
    )

    return LaunchDescription([
        mode_arg,
        delay_arg,
        OpaqueFunction(function=_launch_setup)
    ])
