import os
import yaml
import tempfile
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument, OpaqueFunction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory

def _launch_setup(context, *args, **kwargs):
    # Get the mode from launch configuration
    mode = context.launch_configurations.get('mode', 'rgbd')

    # 1. Define base parameters (common to all modes)
    params = {
        'camera': {
            'i_tf_camera_model': 'OAK-D-PRO',
            'i_enable_sync': True,
        },
        'pipeline_gen': {
            'i_enable_sync': True,
        }
    }

    # 2. Update parameters based on mode
    if mode == 'rgbd':
        params['camera'].update({
            'i_tf_camera_name': 'rgbd',
            'i_pipeline_type': 'RGBD'
        })
        
        params['pipeline_gen']['i_enable_imu'] = False
        
        params['rgb'] = {
            'i_synced': True,
            'i_publish_topic': True,
            'i_output_isp': False,
            'i_width': 640,
            'i_height': 400
        }
        
        params['stereo'] = {
            'i_align_depth': True,
            'i_synced': True
        }

    elif mode == 'stereo':
        params['camera'].update({
            'i_tf_camera_name': 'stereo',
            'i_pipeline_type': 'Depth'
        })
        
        params['pipeline_gen']['i_enable_imu'] = False
        
        params['stereo'] = {
            'i_left_rect_publish_topic': True,
            'i_right_rect_publish_topic': True,
            'i_left_rect_synced': True,
            'i_right_rect_synced': True,
            'i_align_depth': True,
            'i_subpixel': True,
            'i_synced': True,
            'i_publish_topic': False
        }
        
        params['rgb'] = {
            'i_publish_topic': False
        }
        
        params['left'] = {
            'i_synced': True,
            'i_publish_topic': True,
            'i_resolution': '400P',
            'i_width': 640,
            'i_height': 400
        }
        
        params['right'] = {
            'i_synced': True,
            'i_publish_topic': True,
            'i_resolution': '400P',
            'i_width': 640,
            'i_height': 400
        }

    elif mode == 'stereo-inertial':
        params['camera'].update({
            'i_tf_camera_name': 'stereo-inertial',
            'i_pipeline_type': 'Depth'
        })
        
        params['pipeline_gen']['i_enable_imu'] = True
        
        params['stereo'] = {
            'i_left_rect_publish_topic': True,
            'i_right_rect_publish_topic': True,
            'i_left_rect_synced': True,
            'i_right_rect_synced': True,
            'i_align_depth': True,
            'i_subpixel': True,
            'i_synced': True,
            'i_publish_topic': False
        }
        
        params['left'] = {
            'i_synced': True,
            'i_publish_topic': True,
            'i_resolution': '400P',
            'i_width': 640,
            'i_height': 400
        }
        
        params['right'] = {
            'i_synced': True,
            'i_publish_topic': True,
            'i_resolution': '400P',
            'i_width': 640,
            'i_height': 400
        }
        params['rgb'] = {
            'i_publish_topic': False
        }
        
        params['imu'] = {
            'i_synced': False,
            'i_acc_freq': 100,
            'i_gyro_freq': 100,
            'i_acc_cov': 0.0,
            'i_gyro_cov': 0.0
        }

    else:
        raise RuntimeError(f"Unknown mode '{mode}'. Expected one of: 'rgbd', 'stereo', 'stereo-inertial'.")

    # 3. Wrap parameters in the ROS 2 YAML structure
    node_name = 'oak' 
    ros_params_dict = {node_name: {'ros__parameters': params}}

    # 4. Create a temporary YAML file
    config_fd, config_path = tempfile.mkstemp(suffix='.yaml', prefix=f'oak_{mode}_')
    with os.fdopen(config_fd, 'w') as f:
        yaml.dump(ros_params_dict, f, default_flow_style=False)
    
    print(f"[INFO] Generated temporary params file: {config_path}")

    # 5. Include the standard OAK launch file passing the params_file
    oak_launch_path = os.path.join(
        get_package_share_directory('depthai_ros_driver'),
        'launch',
        'camera.launch.py'
    )

    return [
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(oak_launch_path),
            launch_arguments={'params_file': config_path}.items()
        )
    ]

def generate_launch_description():
    mode_arg = DeclareLaunchArgument(
        'mode', default_value='rgbd',
        description="Mode to launch: 'rgbd', 'stereo', 'stereo-inertial' (only one at a time)"
    )

    return LaunchDescription([
        mode_arg,
        OpaqueFunction(function=_launch_setup)
    ])
