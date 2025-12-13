# Robot Vision 2025

**Quantitative Trajectory Analysis of a Handheld Grasping Tool Using Diverse 6 DoF Motion Tracking Modalities**

A comprehensive ROS 2 system for vision-based SLAM and motion tracking using multiple sensor modalities (RealSense and OAK-D cameras) integrated with ORB-SLAM3.

## Overview

This workspace combines:
- **ORB-SLAM3**: State-of-the-art visual SLAM system supporting monocular, stereo, and RGB-D modes with IMU integration
- **ROS 2 Integration**: Full ROS 2 Humble wrapper for ORB-SLAM3
- **Multi-Camera Support**: Configuration for both RealSense (D435) and OAK-D cameras
- **Data Recording**: Automated bag recording and processing pipeline
- **Docker Containerization**: Isolated environments for reproducible deployments


## Quick Start

### 1. Build Base Docker Image

```bash
docker build -f Dockerfile -t rv_base:v1 .
```

### 2. Build Camera-Specific Images

**For OAK-D:**

```bash
cd oak_setup/
docker build -f OAK.Dockerfile -t rv_oak:v1 .
```

**For RealSense:**

```bash
cd realsense_setup/
docker build -f RealSense.Dockerfile -t rv_realsense:v1 .
```

**For ORB-SLAM3:**

```bash
cd orbslam_setup/
docker build -f ORBSLAM.Dockerfile -t rv_orbslam:v1 .
```

### 3. Run with Docker Compose

**OAK-D:**

Terminal 1:

```bash
cd oak_setup/
docker-compose -f oak_docker-compose.yaml up
```

Terminal 2:

```bash
cd oak_setup/
docker-compose -f oak_docker-compose.yaml up
```

**RealSense:**

Terminal 1:

```bash
cd realsense_setup/
docker-compose -f realsense_docker-compose.yaml up
```

Terminal 2:

```bash
cd realsense_setup/
docker-compose -f realsense_docker-compose.yaml up
```

**ORB-SLAM3**

```bash
cd orbslam_setup/
docker-compose -f orbslam_docker-compose.yaml up
```

## Configuration

Configuration files are located in `config/` directory:

- **`oak_rgbd.yaml`**: OAK-D RGB-D camera parameters
- **`oak_stereo.yaml`**: OAK-D stereo camera parameters
- **`oak_stereo_inertial.yaml`**: OAK-D stereo-inertial camera parameters
- **`realsense_rgbd.yaml`**: RealSense RGB-D camera parameters
- **`realsense_stereo.yaml`**: RealSense stereo camera parameters

Edit these files to match your camera calibration and desired SLAM modes.

## Running ORB-SLAM3

### Stereo
```bash
ros2 run orbslam3 stereo ./ORB_SLAM3_ROS2/Vocabulary/ORBvoc.txt ./config/{oak, realsense}_stereo.yaml true
```

### Stereo-Inertial
```bash
ros2 run orbslam3 stereo-inertial ./ORB_SLAM3_ROS2/Vocabulary/ORBvoc.txt ./config/oak_stereo_inertial.yaml true
```

### RGB-D
```bash
ros2 run orbslam3 rgbd ./ORB_SLAM3_ROS2/Vocabulary/ORBvoc.txt ./config/{oak, realsense}_rgbd.yaml
```

## Data Recording and Processing

Bags are automatically recorded to `memory_register/` folders:
- **OAK-D bags**: `memory_register/oak/`
- **RealSense bags**: `memory_register/realsense/`
- **ORB-SLAM3 outputs**: `memory_register/orbslam_data/`

## Trajectory Evaluation

ORB-SLAM3 includes evaluation tools in `evaluation/`:

```bash
# Generate trajectory file from ORB-SLAM3 output
python3 evaluation/evaluate_ate_scale.py ground_truth.txt estimated_trajectory.txt
```

## License

This project integrates:
- **ORB-SLAM3**: GPLv3 License
- **ROS 2**: Apache 2.0 License
- Other components follow their respective licenses

## References

- [ORB-SLAM3 GitHub](https://github.com/inesboujnah/ORB-SLAM3-STEREO-FIXED)
- [ORB-SLAM3 ROS2 Wrapper Github](https://github.com/inesboujnah/ORB_SLAM3_ROS2)
- [ROS 2 Documentation](https://docs.ros.org/en/humble/)
- [RealSense SDK](https://github.com/realsenseai/realsense-ros)
- [OAK-D Documentation](https://docs.luxonis.com/software/ros/depthai-ros/) 
