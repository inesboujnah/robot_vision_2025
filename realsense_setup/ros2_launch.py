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
                'enable_depth': 'true'
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
                'enable_sync': 'true'
            }.items()
        )
        
        return [TimerAction(period=delay, actions=[camera_launch])]

    '''if mode == 'calibration':
        camera_launch = IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node)
        )
        
        # Call calibration service after camera starts
        calib_service_call = TimerAction(
            period=delay,
            actions=[ExecuteProcess(
                cmd=['ros2', 'service', 'call', '/camera/camera/calib_config_read', 'std_srvs/srv/Empty'],
                output='screen'
            )]
        )
        
        return [TimerAction(period=delay, actions=[camera_launch]), calib_service_call]
    '''
    raise RuntimeError(f"Unknown mode '{mode}'. Expected one of: 'rgbd', 'stereo'.")


def generate_launch_description():
    mode_arg = DeclareLaunchArgument(
        'mode', default_value='rgbd',
        description="Mode to launch: 'rgbd' or 'stereo' (only one at a time)"
    )
    
    delay_arg = DeclareLaunchArgument(
        'delay', default_value='5.0',
        description="Delay in seconds before launching the node (default: 5.0)"
    )

    return LaunchDescription([
        mode_arg,
        delay_arg,
        OpaqueFunction(function=_launch_setup)
    ])


# Usage examples:
# ros2 launch realsense_setup ros2_launch.py                        # defaults to rgbd with 5 second delay
# ros2 launch realsense_setup ros2_launch.py mode:=basic
# ros2 launch realsense_setup ros2_launch.py mode:=stereo delay:=3.0  # custom delay
# ros2 launch realsense_setup ros2_launch.py mode:=calibration delay:=2.0
# ros2 service call /camera/camera/calib_config_read