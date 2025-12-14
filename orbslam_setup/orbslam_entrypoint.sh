#!/bin/bash
set -e

# Source ROS 2 setup
source /opt/ros/humble/setup.bash
source /root/colcon_ws/install/setup.bash

# --- 1. CONFIGURATION ---
LOG_DIR="/tmp/logs"
mkdir -p "$LOG_DIR"
SLAM_LOG="$LOG_DIR/slam_output.log"
BAG_LOG="$LOG_DIR/bag_output.log"
# Logs are bind-mounted; truncate instead of removing to avoid busy errors
: > $SLAM_LOG
: > $BAG_LOG

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

# 1. Start Bag in Background (continuous playback at normal speed with loop)
#    This logs to a file so we can check for crashes.
ros2 bag play /root/memory_register/${CAMERA}/${BAG} --loop > $BAG_LOG 2>&1 &
BAG_PID=$!

echo "Bag player started (PID: $BAG_PID). Waiting for initial topics..."

# 2. WAIT FOR BAG TO ACTUALLY START PUBLISHING (not just initialize)
#    We look for first stereo topic publication
MAX_WAIT=120
COUNT=0
while ! grep -q "Adding keyboard callbacks" $BAG_LOG; do
    sleep 0.5
    COUNT=$((COUNT+1))
    
    # CRASH CHECK: If bag player dies, show why and exit.
    if ! kill -0 $BAG_PID 2>/dev/null; then
        echo "ERROR: Bag player crashed!"
        echo "--- BAG LOG START ---"
        cat $BAG_LOG
        echo "--- BAG LOG END ---"
        exit 1
    fi

    if [ $COUNT -ge 240 ]; then echo "Timeout waiting for bag to start."; kill $BAG_PID; exit 1; fi
    echo -ne "Waiting for bag to start streaming... ($COUNT)\r"
done

echo -e "\nBag ready to stream."

echo "----------------------------------------------------"
echo "Phase 2: Starting SLAM"
echo "----------------------------------------------------"

echo "Bag is streaming. Starting SLAM now..."

# Debug: Show available topics and verify stereo images are publishing
echo "Available ROS2 topics with types:"
ros2 topic list -t 2>/dev/null || true
echo "---"
echo "Checking bag duration and status..."
ros2 bag info /root/memory_register/${CAMERA}/${BAG} 2>&1 | grep -E "Duration|Message count|Topic information" | head -10 || true
echo "---"
echo "Waiting 3 seconds for bag to start streaming messages..."
sleep 3
echo "Checking if stereo images are being published NOW..."
timeout 3 ros2 topic hz /stereo/D435/infra1/image_rect_raw 2>&1 | head -5 || echo "Still no messages (bag may have finished first loop)"
echo "---"
echo "Remapping will be: /camera/left -> /stereo/D435/infra1/image_rect_raw"
echo "                   /camera/right -> /stereo/D435/infra2/image_rect_raw"
echo "---"

# 4. Start SLAM Node with QoS override for bag playback compatibility
if [ "${MODE}" = "stereo" ] || [ "${MODE}" = "stereo-inertial" ]; then
    ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/config/${CAMERA}_${MODE}.yaml \
        ${DO_RECTIFY} \
        --ros-args ${REMAP_ARGS} \
        --param qos_overrides./camera/left.subscription.reliability:=best_effort \
        --param qos_overrides./camera/right.subscription.reliability:=best_effort > $SLAM_LOG 2>&1 &
else
    ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/config/${CAMERA}_${MODE}.yaml \
        --ros-args ${REMAP_ARGS} > $SLAM_LOG 2>&1 &
fi
SLAM_PID=$!

# Monitor SLAM logs
tail -f $SLAM_LOG &
TAIL_PID=$!

echo "Waiting for Vocabulary to load..."

# 5. Wait for Vocabulary to fully load
while ! grep -q "Vocabulary loaded!" $SLAM_LOG; do
    sleep 0.1
    # CRASH CHECK: If SLAM dies, show the log tail.
    if ! kill -0 $SLAM_PID 2>/dev/null; then 
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "SLAM DIED PREMATURELY! Here is the error log:"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        tail -n 50 $SLAM_LOG
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        kill $BAG_PID $TAIL_PID
        exit 1
    fi
done

echo "Vocabulary loaded! SLAM is now processing data..."

# Give SLAM a moment to subscribe to topics
echo "Giving SLAM 3 seconds to subscribe to image topics..."
sleep 3

echo "Checking SLAM node subscriptions..."
ros2 node info /ORB_SLAM3_ROS2 2>&1 | head -30 || echo "Could not get node info"

# Check if SLAM is still running
if ! kill -0 $SLAM_PID 2>/dev/null; then
    echo "ERROR: SLAM died immediately after vocabulary load!"
    echo "--- FULL SLAM LOG ---"
    cat $SLAM_LOG
    echo "--- END SLAM LOG ---"
    kill $BAG_PID $TAIL_PID 2>/dev/null
    exit 1
fi

echo "SLAM running... (bag playing at normal speed with loop)"
echo "Processing frames... (this will run until you press Ctrl+C)"

# 7. Wait for finish or user interrupt (Ctrl+C)
wait $SLAM_PID
SLAM_EXIT=$?

echo ""
echo "SLAM exited with code: $SLAM_EXIT"
echo "--- SLAM LOG (last 30 lines) ---"
tail -n 30 $SLAM_LOG || true
echo "--- BAG LOG (last 30 lines) ---"
tail -n 30 $BAG_LOG || true
kill $BAG_PID $TAIL_PID 2>/dev/null

exit 0