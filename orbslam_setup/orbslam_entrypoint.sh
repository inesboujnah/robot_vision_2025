#!/bin/bash
set -e

# Source ROS 2 setup
source /opt/ros/humble/setup.bash
source /root/colcon_ws/install/setup.bash

# --- 1. CONFIGURATION ---
SLAM_LOG="/tmp/slam_output.log"
rm -f $SLAM_LOG
touch $SLAM_LOG

# --- 2. DEFINE REMAPPING ---
REMAP_ARGS=""
if [ "${CAMERA}" = "oak" ]; then
    if [ "${MODE}" = "stereo-inertial" ]; then
        REMAP_ARGS="--remap /camera/left:=/oak/left/image_raw --remap /camera/right:=/oak/right/image_raw --remap /imu:=/oak/imu/data"
    elif [ "${MODE}" = "stereo" ]; then
        REMAP_ARGS="--remap /camera/left:=/oak/left/image_raw --remap /camera/right:=/oak/right/image_raw"
    elif [ "${MODE}" = "rgbd" ]; then
        REMAP_ARGS="--remap /camera/rgb:=/oak/rgb/image_raw --remap /camera/depth:=/oak/stereo/image_raw"
    fi
elif [[ "${CAMERA}" == *"realsense"* ]] || [[ "${CAMERA}" == *"d435"* ]]; then
    if [ "${MODE}" = "stereo" ]; then
        REMAP_ARGS="--remap /camera/left:=/stereo/D435/infra1/image_rect_raw --remap /camera/right:=/stereo/D435/infra2/image_rect_raw"
    elif [ "${MODE}" = "rgbd" ]; then
        REMAP_ARGS="--remap /camera/rgb:=/rgbd/D435/color/image_raw --remap /camera/depth:=/rgbd/D435/aligned_depth_to_color/image_raw"
    fi
fi

echo "----------------------------------------------------"
echo "Phase 1: Pre-loading Bag (Decompression)"
echo "----------------------------------------------------"

# 1. Start Bag in Background (Paused)
ros2 bag play /root/memory_register/${CAMERA}/${BAG} --start-paused &
BAG_PID=$!

echo "Bag player started (PID: $BAG_PID). Waiting for decompression..."

# 2. WAIT FOR DECOMPRESSION
SERVICE_NAME="/rosbag2_player/toggle_paused"
MAX_WAIT_DECOMPRESS=60
COUNT=0

until ros2 service list | grep -q "$SERVICE_NAME"; do
    sleep 1
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_WAIT_DECOMPRESS ]; then
        echo "ERROR: Timeout waiting for bag decompression."
        kill $BAG_PID
        exit 1
    fi
    echo -ne "Decompressing... ($COUNT s)\r"
done
echo -e "\nDecompression DONE! Bag is ready and paused."

echo "----------------------------------------------------"
echo "Phase 2: Starting SLAM"
echo "----------------------------------------------------"

# 3. BACKGROUND UNPAUSE LOGIC (The "Mid-Load" Trigger)
(
    # Wait for the SLAM node to say "Loading ORB Vocabulary"
    echo "Trigger: Waiting for loading to start..."
    while ! grep -q "Loading ORB Vocabulary" $SLAM_LOG; do
        sleep 0.1
    done
    
    # FOUND IT! Now we wait exactly 1.5 seconds.
    # This allows the loading to proceed, but ensures we unpause BEFORE it finishes.
    echo "Trigger: Loading started. Waiting 1.5s to unpause..."
    sleep 1.5
    
    # Execute Unpause
    echo "Trigger: UNPAUSING BAG NOW!"
    ros2 service call $SERVICE_NAME rosbag2_interfaces/srv/TogglePaused {} > /dev/null
)&

# 4. Start SLAM Node (Foreground)
if [ "${MODE}" = "stereo" ] || [ "${MODE}" = "stereo-inertial" ]; then
    ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/config/${CAMERA}_${MODE}.yaml \
        ${DO_RECTIFY} \
        --ros-args ${REMAP_ARGS} > $SLAM_LOG 2>&1 &
else
    ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/config/${CAMERA}_${MODE}.yaml \
        --ros-args ${REMAP_ARGS} > $SLAM_LOG 2>&1 &
fi
SLAM_PID=$!

# Monitor logs
tail -f $SLAM_LOG &
TAIL_PID=$!

wait $SLAM_PID
kill $BAG_PID $TAIL_PID 2>/dev/null
exit 0