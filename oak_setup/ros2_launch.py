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

# ros2 launch depthai_examples rgb_stereo_node.launch.py

# ros2 launch depthai_examples stereo_inertial_node.launch.py

# ros2 launch depthai_ros_driver camera.launch.py