#!/bin/bash

set -e

# Source ROS 2 setup so ros2 commands are available
source /opt/ros/humble/setup.bash

source /root/colcon_ws/install/setup.bash

cd /root/memory_register/oak

if [ "${RECORD_BAG}" = "1" ] || [ "${RECORD_BAG,,}" = "true" ]; then
    
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    BAG_OUTPUT="${CAMERA}_${MODE}_${TIMESTAMP}"
    echo "Starting ros2 bag record -a -> ${BAG_OUTPUT}"
    ros2 bag record -a -o "$BAG_OUTPUT" -x "(.*)/compressed(.*)|(.*)/theora(.*)" --compression-mode file --compression-format zstd &
fi

if [ "${CAMERA}" = "oak_pro" ]; then
    exec ros2 launch launch_manager ros2_launch.launch.py mode:=${MODE}
elif [ "${CAMERA}" = "oak_pro_wide" ]; then
    exec ros2 launch launch_manager ros2_launch_w.launch.py mode:=${MODE}
fi

