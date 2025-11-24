from launch import LaunchDescription
from launch_ros.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():

    oak_launch_node = os.path.join(
        get_package_share_directory('depthai_ros_driver'),
        'launch',
        'camera.launch.py'
    )
 
    return LaunchDescription([
        IncludeLaunchDescription(PythonLaunchDescriptionSource(oak_launch_node),
            launch_arguments={
                'camera.i_tf_camera_name': 'rgbd',
                'camera.i_tf_camera_model': 'OAK-D-PRO-W',
                'camera.i_pipeline_type': 'RGBD',
                'camera.i_enable_sync': 'true',
                'pipeline_gen.i_enable_sync': 'true'
            }.items()
        ),
        IncludeLaunchDescription(PythonLaunchDescriptionSource(oak_launch_node),
            launch_arguments={
                'camera.i_tf_camera_name': 'stereo',
                'camera.i_tf_camera_model': 'OAK-D-PRO-W',
                'camera.i_pipeline_type': 'Stereo',
                'camera.i_enable_sync': 'true',
                'pipeline_gen.i_enable_sync': 'true',
                'stereo.i_align_depth': 'true'
            }.items()
        ),
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
        ),
    ])

# ros2 launch depthai_ros_driver camera.launch.py