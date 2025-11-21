from launch import LaunchDescription
from launch_ros.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():

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

    return LaunchDescription([
        # Include basic camera launch
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_camera_node)
        ),

        # Include configurable launch with arguments
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node),
            launch_arguments={
                'camera_namespace': 'camera1',
                'camera_name': 'D435',
                'enable_rgbd': 'true',
                'enable_sync': 'true',
                'align_depth.enable': 'true',
                'enable_color': 'true',
                'enable_depth': 'true'
            }.items()
        ),
    ])
from launch import LaunchDescription
from launch_ros.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():

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

    return LaunchDescription([
        # Include basic camera launch
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_camera_node)
        ),

        # Include configurable launch with arguments
        IncludeLaunchDescription(
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
        ),

        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rs_launch_node),
            launch_arguments={
                'camera_namespace': 'stereo',
                'camera_name': 'D435'
            }.items()
        ),
    ])



# ros2 launch realsense2_camera rs_camera.launch.py
# ros2 launch realsense2_camera rs_launch.py camera_namespace:=robot1 camera_name:=D455_1

# ros2 launch realsense2_camera rs_launch.py camera_namespace:=rgbd camera_name:=D435 enable_rgbd:=true enable_sync:=true align_depth.enable:=true enable_color:=true enable_depth:=true 
# ros2 launch realsense2_camera rs_launch.py camera_namespace:=stereo camera_name:=D435 enable_infra1:=true enable_infra2:=true