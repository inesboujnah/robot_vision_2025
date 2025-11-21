#!/bin/bash

set -e

# Source ROS 2 setup so ros2 commands are available
source /opt/ros/humble/setup.bash

# If RECORD_BAG is set to 1 or true, start ros2 bag recording in background
if [ "${RECORD_BAG}" = "1" ] || [ "${RECORD_BAG,,}" = "true" ]; then
    BAG_DIR="${BAG_DIR:-/root/memory_register/realsense}"
    mkdir -p "$BAG_DIR"
    # record into a timestamped subfolder
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    BAG_OUTPUT="${BAG_DIR}/bag_${TIMESTAMP}"
    echo "Starting ros2 bag record -a -> ${BAG_OUTPUT}"
    # Allow passing extra ros2 bag options via BAG_OPTS env var
    ros2 bag record ${BAG_OPTS:-} -a -o "$BAG_OUTPUT" &
    BAGRUN_PID=$!
    echo "ros2 bag started (PID ${BAGRUN_PID})"

    # If HOST_UID is provided, change ownership of the created folder so host user can access it
    if [ -n "${HOST_UID}" ]; then
        HOST_GID="${HOST_GID:-${HOST_UID}}"
        # best-effort chown; ignore errors
        chown -R "${HOST_UID}:${HOST_GID}" "$BAG_OUTPUT" || true
    fi
fi

# Exec the original entrypoint script so it becomes PID 1
exec /root/realsense_entrypoint.sh
