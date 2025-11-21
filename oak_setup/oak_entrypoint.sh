#!/bin/bash

source /opt/ros/humble/setup.bash
# Use exec so the ros2 launch process takes PID 1 and receives signals correctly
exec ros2 launch launch_manager ros2_launch.launch.py
