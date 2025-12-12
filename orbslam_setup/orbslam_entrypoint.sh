#!/bin/bash

set -e

# Source ROS 2 setup so ros2 commands are available
source /opt/ros/humble/setup.bash

source /root/colcon_ws/install/setup.bash

if [ "${MODE}" = "stereo" ] || [ "${MODE}" = "stereo-inertial" ]; then
    ros2 bag play /root/memory_register/${CAMERA}/${BAG} &
    exec ros2 run orbslam3 ${MODE} /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt /root/colcon_ws/src/config/${CAMERA}_${MODE}.yaml ${DO_RECTIFY}
else
    ros2 bag play /root/memory_register/${CAMERA}/${BAG} &
    exec ros2 run orbslam3 ${MODE} /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt /root/colcon_ws/src/config/${CAMERA}_${MODE}.yaml
fi    