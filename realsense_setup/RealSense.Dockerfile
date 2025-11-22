FROM rv_base:v1

# Work inside the workspace source
WORKDIR /root/colcon_ws/src

# Create launch_manager package
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    ros2 pkg create launch_manager --build-type ament_python"

# Add launch directory and file
RUN mkdir -p /root/colcon_ws/src/launch_manager/launch
COPY ros2_launch.py /root/colcon_ws/src/launch_manager/launch/ros2_launch.launch.py

# Modify setup.py to install launch files
RUN sed -i "/# <<< ADD THIS >>>/a \        ('share', 'launch_manager', glob('launch/*.py'))," \
    /root/colcon_ws/src/launch_manager/setup.py || true

# Build ONLY the launch_manager package
WORKDIR /root/colcon_ws
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    colcon build --packages-select launch_manager --symlink-install"

WORKDIR /root/
COPY realsense_entrypoint.sh realsense_entrypoint.sh
RUN chmod +x realsense_entrypoint.sh

# Add optional wrapper that can start ros2 bag recording
COPY entrypoint_with_bag.sh entrypoint_with_bag.sh
RUN mkdir -p /root/memory_register/oak/orbslam_data &&\  
    chmod +x entrypoint_with_bag.sh

# Use the wrapper as the container ENTRYPOINT. Set `RECORD_BAG=1` at runtime to enable recording.
ENTRYPOINT ["/root/entrypoint_with_bag.sh"]