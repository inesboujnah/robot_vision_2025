#!/bin/bash

set -e

# Source ROS 2 setup so ros2 commands are available
source /opt/ros/humble/setup.bash

source /root/colcon_ws/install/setup.bash

cd /root/memory_register/realsense

# If RECORD_BAG is set to 1 or true, start ros2 bag recording in background
if [ "${RECORD_BAG}" = "1" ] || [ "${RECORD_BAG,,}" = "true" ]; then
    
    # record into a timestamped subfolder
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    BAG_OUTPUT="/realsense_${TIMESTAMP}"
    echo "Starting ros2 bag record -a -> ${BAG_OUTPUT}"
    
    ros2 bag record -a -o "$BAG_OUTPUT"
fi

exec ros2 launch launch_manager ros2_launch.launch.py mode:=basic
exec ros2 launch launch_manager ros2_launch.launch.py mode:=${MODE}
