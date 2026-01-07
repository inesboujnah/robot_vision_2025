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
: > $SLAM_LOG
: > $BAG_LOG

# --- 2. Define Remapping ---
REMAP_ARGS=""

if [ "${CAMERA}" = "oak_pro" ] || [ "${CAMERA}" = "oak_pro_wide" ]; then
    if [ "${MODE}" = "stereo-inertial" ]; then
        REMAP_ARGS="--remap camera/left:=/oak/left/image_rect --remap camera/right:=/oak/right/image_rect --remap imu:=/oak/imu/data"

    elif [ "${MODE}" = "stereo" ]; then
        REMAP_ARGS="--remap camera/right:=/oak/right/image_rect --remap camera/left:=/oak/left/image_rect"

    elif [ "${MODE}" = "rgbd" ]; then
        REMAP_ARGS="--remap camera/rgb:=/oak/rgb/image_rect --remap camera/depth:=/oak/stereo/image_raw"
    fi

elif [ "${CAMERA}" == "realsense" ]; then
    if [ "${MODE}" = "stereo" ]; then
        REMAP_ARGS="--remap camera/left:=/stereo/D435/infra1/image_rect_raw --remap camera/right:=/stereo/D435/infra2/image_rect_raw"

    elif [ "${MODE}" = "rgbd" ]; then
        REMAP_ARGS="--remap camera/rgb:=/rgbd/D435/color/image_raw --remap camera/depth:=/rgbd/D435/aligned_depth_to_color/image_raw"
    fi
fi

if [ "${FROM_BAG}" = "1" ] || [ "${FROM_BAG,,}" = "true" ]; then

    echo "----------------------------------------------------"
    echo "Phase 1: Bag Decompression"
    echo "----------------------------------------------------"

    # 1. Start Bag in Background
    ros2 bag play /root/memory_register/${CAMERA}/${BAG} --loop --clock > $BAG_LOG 2>&1 &
    BAG_PID=$!

    # 2. WAIT FOR BAG TO ACTUALLY START PUBLISHING
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

        if [ $COUNT -ge 240 ]; then 
            echo "Timeout waiting for bag to start."
            kill $BAG_PID
            exit 1
        fi
    done


    echo "----------------------------------------------------"
    echo "Phase 2: Starting SLAM"
    echo "----------------------------------------------------"

    # Show available topics and bag info
    echo "Available ROS2 topics with types:"
    ros2 topic list -t 2>/dev/null || true
    echo "---"
    echo "Checking bag information:"
    ros2 bag info /root/memory_register/${CAMERA}/${BAG} 2>&1 | grep -E "Duration|Message count|Topic information" | head -10 || true
    echo "---"
    

    sleep 3

    # Check topics based on MODE and CAMERA
    echo "Verifying topic publishing rates:"
    if [ "${CAMERA}" = "oak_pro" ] || [ "${CAMERA}" = "oak_pro_wide" ]; then
        if [ "${MODE}" = "stereo-inertial" ]; then
            echo "Left: publishing"
            ros2 topic hz /oak/left/image_rect 2>&1 | head -5
            echo "Right: publishing"
            ros2 topic hz /oak/right/image_rect 2>&1 | head -5
            echo "IMU: publishing"
            ros2 topic hz /oak/imu/data 2>&1 | head -5
            echo "stereo-inertial mode verified"
        elif [ "${MODE}" = "stereo" ]; then
            echo "Left: publishing"
            ros2 topic hz /oak/left/image_rect 2>&1 | head -5
            echo "Right: publishing"
            ros2 topic hz /oak/right/image_rect 2>&1 | head -5
            echo "stereo mode verified"
        elif [ "${MODE}" = "rgbd" ]; then
            echo "RGB: publishing"
            ros2 topic hz /oak/rgb/image_rect 2>&1 | head -5
            echo "Depth: publishing"
            ros2 topic hz /oak/stereo/image_raw 2>&1 | head -5
            echo "rgbd mode verified"
        fi
    elif [ "${CAMERA}" == "realsense" ]; then
        if [ "${MODE}" = "stereo" ]; then
            echo "Infra1: publishing"
            ros2 topic hz /stereo/D435/infra1/image_rect_raw 2>&1 | head -5
            echo "Infra2: publishing"
            ros2 topic hz /stereo/D435/infra2/image_rect_raw 2>&1 | head -5
            echo "stereo mode verified"
        elif [ "${MODE}" = "rgbd" ]; then
            echo "RGB: publishing"
            ros2 topic hz /rgbd/D435/color/image_raw 2>&1 | head -5
            echo "Depth: publishing"
            ros2 topic hz /rgbd/D435/aligned_depth_to_color/image_raw 2>&1 | head -5
            echo "rgbd mode verified"
        fi
    fi
fi

echo "Starting SLAM."

# 4. Start SLAM Node
if [ "${MODE}" = "stereo" ] || [ "${MODE}" = "stereo-inertial" ]; then
    ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/orbslam_setup/config/${CAMERA}_${MODE}.yaml \
        ${DO_RECTIFY} \
        --ros-args ${REMAP_ARGS} -p use_sim_time:=true > $SLAM_LOG 2>&1 &
elif [ "${MODE}" = "rgbd" ]; then
    ros2 run orbslam3 ${MODE} \
        /root/colcon_ws/src/ORB_SLAM3/Vocabulary/ORBvoc.txt \
        /root/orbslam_setup/config/${CAMERA}_${MODE}.yaml \
        --ros-args ${REMAP_ARGS} -p use_sim_time:=true > $SLAM_LOG 2>&1 &
fi
SLAM_PID=$!

# Monitor SLAM logs
tail -f $SLAM_LOG &
TAIL_PID=$!

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