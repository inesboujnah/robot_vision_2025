# Image taken from https://github.com/turlucode/ros-docker-gui
FROM osrf/ros:humble-desktop-full-jammy
ARG USE_CI

# Set frontend to noninteractive
ARG DEBIAN_FRONTEND=noninteractive

# Install base dependencies in a single layer
RUN apt-get update && apt-get install -y \
    # Base tools
    gnupg2 \
    curl \
    lsb-core \
    vim \
    wget \
    python3-pip \
    libpng16-16 \
    libjpeg-turbo8 \
    libtiff5 \
    cmake \
    build-essential \
    git \
    unzip \
    pkg-config \
    python3-dev \
    # OpenCV dependencies
    python3-numpy \
    # Pangolin dependencies
    libgl1-mesa-dev \
    libglew-dev \
    libpython3-dev \
    libeigen3-dev \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Build OpenCV dependencies
RUN apt-get update && apt-get install -y \
    python2-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# Build OpenCV in a single layer (clone, build, install, clean)
RUN cd /tmp && git clone https://github.com/opencv/opencv.git && \
    cd opencv && \
    git checkout 4.4.0 && mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D BUILD_EXAMPLES=OFF  -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/opencv

# Build Pangolin in a single layer (clone, build, install, clean)
RUN cd /tmp && git clone https://github.com/stevenlovegrove/Pangolin && \
    cd Pangolin && git checkout v0.9.1 && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-std=c++14 -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/Pangolin

# Add RealSense SDK repository
RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | tee /etc/apt/keyrings/librealsense.pgp > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | \
    tee /etc/apt/sources.list.d/librealsense.list

# RUN apt-get install 5.15.167.4-microsoft-standard-WSL2
# RUN apt-get install linux-headers-6.8.0-52-generic -y
# RUN apt-get install linux-headers-$(uname -r)
# Install SDKs and ROS packages in a single layer
RUN apt-get update && apt-get install -y \
    # RealSense SDK
    # librealsense2-dkms \
    # librealsense2-dev \
    # librealsense2-utils \
    # librealsense2-dbg \
    # ROS Packages
    ros-humble-pcl-ros \
    tmux \
    ros-humble-nav2-common \
    x11-apps \
    nano \
    gdb \
    gdbserver \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-cv-bridge \
    ros-humble-image-transport \
    ros-humble-image-common \
    ros-humble-vision-opencv \
    ros-humble-depthai-ros \
    ros-humble-librealsense2* \
    ros-humble-realsense2-*

# --- FIX: Create correct directories and clone source code ---
WORKDIR /
RUN mkdir -p /root/colcon_ws/src && \
    cd /root/colcon_ws/src && \
    git clone https://github.com/UZ-SLAMLab/ORB_SLAM3.git /ORB_SLAM3 && \
    git clone https://github.com/zang09/ORB_SLAM3_ROS2.git /root/colcon_ws/src/orbslam3_ros2

# Build ORB-SLAM3 with its dependencies, using corrected paths
# RUN if [ "$USE_CI" = "true" ]; then \
    # . /opt/ros/humble/setup.sh && cd /ORB_SLAM3 && mkdir -p build && ./build.sh && \
    # . /opt/ros/humble/setup.sh && . /ORB_SLAM3/build/devel/setup.sh && \
    # cd /root/colcon_ws/ && colcon build --symlink-install; \
    # fi

# --- Build ORB-SLAM3 and ROS Wrapper ---
RUN if [ "$USE_CI" = "true" ]; then \
    # 1. Build the main ORB_SLAM3 library
    . /opt/ros/humble/setup.sh && \
    cd /ORB_SLAM3 && mkdir -p build && ./build.sh && \
    \
    sed -i 's|/opt/ros/foxy/lib/python3.8/site-packages/|/opt/ros/humble/lib/python3.10/site-packages/|g' /root/colcon_ws/src/orbslam3_ros2/CMakeLists.txt && \
    sed -i 's|~/Install/ORB_SLAM/ORB_SLAM3|/root/colcon_ws/src/ORB_SLAM3|g' /root/colcon_ws/src/orbslam3_ros2/CMakeLists.txt && \
    # 2. Configure the ROS Wrapper's setup.py
    # This replaces the hard-coded path with the correct path inside the container
    # Commented because purpose not clear sed -i 's|/home/zang/ORB_SLAM3|/ORB_SLAM3|g' /root/colcon_ws/src/orbslam3_ros2/setup.py && \
    \
    # 3. Build the ROS Wrapper
    . /opt/ros/humble/setup.sh && \
    . /ORB_SLAM3/build/devel/setup.sh && \
    cd /root/colcon_ws/ && \
    colcon build --symlink-install --packages-select orbslam3; \
    fi

COPY config/ /root/colcon_ws/src/config/