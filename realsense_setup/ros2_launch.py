from launch import LaunchDescription
from launch_ros.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():

    rgb_stereo_node = os.path.join(
        get_package_share_directory('depthai_examples'),
        'launch',
        'rgb_stereo_node.launch.py'
    )

    stereo_inertial_node = os.path.join(
        get_package_share_directory('depthai_examples'),
        'launch',
        'stereo_inertial_node.launch.py'
    )

    return LaunchDescription([
        IncludeLaunchDescription(PythonLaunchDescriptionSource(rgb_stereo_node)),
        IncludeLaunchDescription(PythonLaunchDescriptionSource(stereo_inertial_node)),
    ])

# ros2 launch realsense2_camera rs_camera.launch.py
# ros2 launch realsense2_camera rs_launch.py camera_namespace:=robot1 camera_name:=D455_1
# ros2 launch realsense2_camera rs_launch.py camera_namespace:=camera1 camera_name:=D435 enable_rgbd:=true enable_sync:=true align_depth.enable:=true enable_color:=true enable_depth:=true 
# ros2 launch realsense2_camera rs_launch.py camera_namespace:=camera2 camera_name:=D435 enable_infra1:=true enable_infra2:=true