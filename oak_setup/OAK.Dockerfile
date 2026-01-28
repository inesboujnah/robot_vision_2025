FROM rv_base:humble

# Work inside the workspace source
WORKDIR /root/colcon_ws/src

# --- PACKAGE 1: launch_manager ---
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    ros2 pkg create launch_manager --build-type ament_python"

RUN mkdir -p /root/colcon_ws/src/launch_manager/launch
COPY ros2_launch.py /root/colcon_ws/src/launch_manager/launch/ros2_launch.launch.py
COPY ros2_launch_w.py /root/colcon_ws/src/launch_manager/launch/ros2_launch_w.launch.py

# Add glob and install rule for launch files
RUN sed -i "1 a from glob import glob" /root/colcon_ws/src/launch_manager/setup.py && \
    sed -i "/data_files *= *\[/a \        ('share/launch_manager/launch', glob('launch/*.py'))," \
    /root/colcon_ws/src/launch_manager/setup.py


# --- PACKAGE 2: gt_bridge ---
# 1. Create the package
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    ros2 pkg create gt_bridge --build-type ament_python"

# 2. Copy the python script into the package
COPY udp_pose_bridge.py /root/colcon_ws/src/gt_bridge/gt_bridge/udp_pose_bridge.py

# 3. Register the node in setup.py so 'ros2 run' can find it
# We inject the entry point into the console_scripts list
RUN sed -i "/'console_scripts': \[/a \            'udp_bridge = gt_bridge.udp_pose_bridge:main'," \
    /root/colcon_ws/src/gt_bridge/setup.py


# --- BUILD ---
WORKDIR /root/colcon_ws
# Build both packages
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    colcon build --packages-select launch_manager gt_bridge --symlink-install"

WORKDIR /root/

# Add optional wrapper that can start ros2 bag recording
COPY oak_entrypoint_with_bag.sh /root/oak_entrypoint_with_bag.sh
RUN mkdir -p /root/memory_register/oak &&\
    chmod +x /root/oak_entrypoint_with_bag.sh

# Use the wrapper as the container ENTRYPOINT. Set `RECORD_BAG=1` at runtime to enable recording.
ENTRYPOINT ["/root/oak_entrypoint_with_bag.sh"]