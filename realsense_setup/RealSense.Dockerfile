FROM rv_base:humble

# Work inside the workspace source
WORKDIR /root/colcon_ws/src

# Create launch_manager package
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    ros2 pkg create launch_manager --build-type ament_python"

# Add launch directory and file
RUN mkdir -p /root/colcon_ws/src/launch_manager/launch
COPY ros2_launch.py /root/colcon_ws/src/launch_manager/launch/ros2_launch.launch.py

# Add `glob` import
RUN sed -i "1 a from glob import glob" /root/colcon_ws/src/launch_manager/setup.py

# Add installation rule for launch/*.py
RUN sed -i "/data_files *= *\[/a \        ('share/launch_manager/launch', glob('launch/*.py'))," \
    /root/colcon_ws/src/launch_manager/setup.py


# Build ONLY the launch_manager package
WORKDIR /root/colcon_ws
RUN /bin/bash -lc "source /opt/ros/humble/setup.bash && \
    colcon build --packages-select launch_manager --symlink-install"

WORKDIR /root/

# Add optional wrapper that can start ros2 bag recording
COPY realsense_entrypoint_with_bag.sh /root/realsense_entrypoint_with_bag.sh
RUN mkdir -p /root/memory_register/realsense &&\
    chmod +x /root/realsense_entrypoint_with_bag.sh

# Use the wrapper as the container ENTRYPOINT. Set `RECORD_BAG=1` at runtime to enable recording.
ENTRYPOINT ["/root/realsense_entrypoint_with_bag.sh"]