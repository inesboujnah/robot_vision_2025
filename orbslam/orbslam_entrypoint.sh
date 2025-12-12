#!/bin/bash

set -e

# Source ROS 2 setup so ros2 commands are available
source /opt/ros/humble/setup.bash

source /root/colcon_ws/install/setup.bash

if [ "${MODE}" = "stereo" ] || [ "${MODE}" = "stereo-inertial" ]; then
    exec ros2 bag play /root/memory_register/${CAMERA}/${BAG} && exec ros2 run ${MODE} ./ORB_SLAM3_ROS2/Vocabulary/ORBvoc.txt ./config/${CAMERA}_${MODE}.yaml ${DO_RECTIFY}
else
    exec ros2 bag play /root/memory_register/${CAMERA}/${BAG} && exec ros2 run ${MODE} ./ORB_SLAM3_ROS2/Vocabulary/ORBvoc.txt ./config/${CAMERA}_${MODE}.yaml
fi    