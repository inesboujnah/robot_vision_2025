#!/bin/bash
set -e

# Source ROS 2 setup
source /opt/ros/humble/setup.bash
source /root/colcon_ws/install/setup.bash

# --- NEW: Define Remapping Arguments based on Camera and Mode ---
REMAP_ARGS=""

if [ "${CAMERA}" = "oak" ]; then
    # OAK-D Remappings
    if [ "${MODE}" = "stereo-inertial" ]; then
        REMAP_ARGS="--remap /camera/left:=/oak/left/image_raw \
                    --remap /camera/right:=/oak/right/image_raw \
                    --remap /imu:=/oak/imu/data"
    elif [ "${MODE}" = "stereo" ]; then
        REMAP_ARGS="--remap /camera/left:=/oak/left/image_raw \
                    --remap /camera/right:=/oak/right/image_raw"
    elif [ "${MODE}" = "rgbd" ]; then
        REMAP_ARGS="--remap /camera/rgb:=/oak/rgb/image_raw \
                    --remap /camera/depth:=/oak/stereo/image_raw"
    fi

elif [[ "${CAMERA}" == *"realsense"* ]] || [[ "${CAMERA}" == *"d435"* ]]; then
    # RealSense Remappings
    if [ "${MODE}" = "stereo" ]; then
        REMAP_ARGS="--remap /camera/left:=/stereo/D435/infra1/image_rect_raw \
                    --remap /camera/right:=/stereo/D435/infra2/image_rect_raw"
    elif [ "${MODE}" = "rgbd" ]; then
        REMAP_ARGS="--remap /camera/rgb:=/rgbd/D435/color/image_raw \
                    --remap /camera/depth:=/rgbd/D435/aligned_depth_to_color/image_raw"
    fi
fi
# ----------------------------------------------------------------

echo "Starting with Mode: ${MODE}, Camera: ${CAMERA}"
echo "Remapping Args: ${REMAP_ARGS}"

# Start the bag play in the background
# Added --loop so it doesn't stop after one run (optional, remove if unwanted)
ros2 bag play /root/memory_register/${CAMERA}/${BAG} &

# Give the bag a moment to start
sleep 20

# Execute the node with the remapping arguments
if [ "${MODE}" = "stereo" ] || [ "${MODE}" = "stereo-inertial" ]; then
    exec ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/config/${CAMERA}_${MODE}.yaml \
        ${DO_RECTIFY} \
        --ros-args ${REMAP_ARGS}
else
    exec ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/config/${CAMERA}_${MODE}.yaml \
        --ros-args ${REMAP_ARGS}
fi