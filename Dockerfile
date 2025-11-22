FROM osrf/ros:humble-desktop-full-jammy

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
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
    python3-numpy \
    libgl1-mesa-dev \
    libglew-dev \
    libpython3-dev \
    libeigen3-dev \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    python2-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && git clone https://github.com/opencv/opencv.git && \
    cd opencv && \
    git checkout 4.4.0 && mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D BUILD_EXAMPLES=OFF  -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/opencv

RUN cd /tmp && git clone https://github.com/stevenlovegrove/Pangolin && \
    cd Pangolin && git checkout v0.9.1 && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-std=c++14 -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/Pangolin

RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | tee /etc/apt/keyrings/librealsense.pgp > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo lsb_release -cs main" | \
    tee /etc/apt/sources.list.d/librealsense.list

RUN apt-get update && apt-get install -y \
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

COPY ORB_SLAM3 /root/colcon_ws/src/ORB_SLAM3
COPY ORB_SLAM3_ROS2 /root/colcon_ws/src/orbslam3_ros2

RUN cd /root/colcon_ws/src/ORB_SLAM3 && \
    chmod +x build.sh && \
    ./build.sh && \
    echo "Build OK"

RUN . /opt/ros/humble/setup.sh && \
    cd /root/colcon_ws && \
    colcon build --symlink-install --packages-select orbslam3

WORKDIR /root
CMD ["bash"]