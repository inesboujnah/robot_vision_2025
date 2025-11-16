# DepthAI ROS Launch Files and Topics Guide

This document maps all 20 launch files to the topics they publish, including both driver and filter-based launches.

## Complete Launch Files Overview (20 total)

*depthai_ros_driver:* 13 launch files
*depthai_filters:* 8 launch files

## Launch Files Overview

### 1. driver.launch.py (Base Driver)
*Description:* Base launch file that starts the core DepthAI driver with default RGBD pipeline.

*Config File:* config/driver.yaml

*Topics Published:*
- oak/rgb/image_raw - RGB camera stream (sensor_msgs/Image)
- oak/rgb/camera_info - RGB camera calibration info (sensor_msgs/CameraInfo)
- oak/stereo/image_raw - Depth/Stereo image (sensor_msgs/Image)
- oak/stereo/camera_info - Stereo camera calibration info (sensor_msgs/CameraInfo)
- tf - Transform frames
- tf_static - Static transforms

*Typical Usage:*
bash
ros2 launch depthai_ros_driver driver.launch.py


---

### 2. rgbd_pcl.launch.py (RGB-D with Point Cloud)
*Description:* Launches RGB-D pipeline with point cloud generation enabled.

*Config File:* config/rgbd.yaml

*Base Topics (from driver) +:*
- oak/rgbd/points - PointCloud2 representation of the scene (sensor_msgs/PointCloud2)
- oak/rgb/image_raw - RGB camera stream
- oak/stereo/image_raw - Depth image
- oak/stereo/camera_info - Depth camera info

*Parameters:*
- i_enable_rgbd: true - Enables RGBD node
- i_pipeline_type: rgbd - Sets pipeline to RGBD mode

*Typical Usage:*
bash
ros2 launch depthai_ros_driver rgbd_pcl.launch.py
ros2 launch depthai_ros_driver rgbd_pcl.launch.py name:=my_camera


---

### 3. vio.launch.py (Visual Inertial Odometry)
*Description:* Launches VIO (Visual-Inertial Odometry) for motion tracking using camera and IMU.

*Config File:* config/vio.yaml

*Topics Published (from base driver) +:*
- oak/vio/odometry - Odometry estimation (nav_msgs/Odometry)
- oak/vio/camera_pose - Camera pose estimation (geometry_msgs/PoseStamped)
- oak/imu/data - IMU data (sensor_msgs/Imu)
- oak/imu/accel - Accelerometer data (sensor_msgs/Imu)
- oak/imu/gyro - Gyroscope data (sensor_msgs/Imu)
- oak/stereo/image_raw - Depth image for tracking
- oak/rgb/image_raw - RGB image for tracking

*Parameters:*
- i_enable_vio: true - Enables VIO
- i_pipeline_type: rgbd - RGBD pipeline for depth
- i_fps: 60.0 - VIO and stereo at 60 FPS
- i_batch_report_threshold: 1 - IMU batch size
- i_enable_rotation: false - Gyroscope rotation control

*Transforms Published:*
- oak → oak_parent_frame
- oak_imu → oak

*Typical Usage:*
bash
ros2 launch depthai_ros_driver vio.launch.py


---

### 4. pointcloud.launch.py (Point Cloud Only - Depth)
*Description:* Launches depth-only pipeline with point cloud conversion.

*Config File:* config/pcl.yaml

*Topics Published:*
- oak/stereo/image_raw - Depth image (sensor_msgs/Image)
- oak/stereo/camera_info - Depth camera info
- oak/points - Point cloud output from depth_image_proc (sensor_msgs/PointCloud2)

*Key Features:*
- Uses depth_image_proc::PointCloudXyzNode composable node
- Converts depth image to 3D point cloud
- No RGB camera topics

*Typical Usage:*
bash
ros2 launch depthai_ros_driver pointcloud.launch.py


---

### 5. oak_t.launch.py (Thermal Camera)
*Description:* Launches thermal imaging mode for OAK-T camera.

*Config File:* config/oak_t.yaml

*Topics Published:*
- oak/thermal/image_raw - Thermal image stream (sensor_msgs/Image)
- oak/thermal/camera_info - Thermal camera calibration info (sensor_msgs/CameraInfo)

*Parameters:*
- i_pipeline_type: Thermal - Thermal imaging pipeline
- i_enable_ir: false - Disable IR (since thermal provides heat data)

*Typical Usage:*
bash
ros2 launch depthai_ros_driver oak_t.launch.py


---

### 6. rtabmap.launch.py (SLAM with RTABMap)
*Description:* Launches real-time appearance-based mapping (RTAB-Map) for SLAM capabilities.

*Config File:* config/rtabmap.yaml

*Base Topics (from VIO-enabled driver) +:*
- rtabmap/map - Occupancy grid map (nav_msgs/OccupancyGrid)
- rtabmap/mapGraph - Map topology graph
- rtabmap/grid_prob_map - Probability-based grid
- oak/vio/odometry - Visual odometry input
- oak/rgb/image_raw - RGB for visual features
- oak/stereo/image_raw - Depth for mapping

*RTABMap Nodes Launched:*
1. rtabmap - Main SLAM engine
2. rtabmap_viz - Visualization node

*Remappings:*
- rgb/image → oak/rgb/image_raw
- rgb/camera_info → oak/rgb/camera_info
- depth/image → oak/stereo/image_raw
- odom → oak/vio/odometry

*Parameters:*
- subscribe_depth: true - Subscribe to depth
- subscribe_rgb: true - Subscribe to RGB
- approx_sync: true - Approximate time synchronization
- subscribe_odom_info: false - No odometry info needed

*Typical Usage:*
bash
ros2 launch depthai_ros_driver rtabmap.launch.py


---

### 7. example_segmentation.launch.py (Semantic Segmentation)
*Description:* Launches semantic segmentation using DeepLab-v3+ model.

*Config File:* config/segmentation.yaml

*Topics Published:*
- oak/rgb/image_raw - Input RGB image
- oak/rgb/camera_info - RGB camera info
- oak/rgb/passthrough/image_raw - RGB passthrough frame
- oak/nn/image_raw - Segmentation output (class map)

*Parameters:*
- i_pipeline_type: rgb - RGB camera pipeline
- i_nn_type: rgb - Neural network on RGB
- i_nn_family: segmentation - Segmentation task
- i_nn_model: luxonis/deeplab-v3-plus:256x256 - DeepLab model
- i_enable_passthrough: true - Publish original RGB alongside

*Typical Usage:*
bash
ros2 launch depthai_ros_driver example_segmentation.launch.py
ros2 launch depthai_ros_driver example_segmentation.launch.py use_rviz:=true


---

### 8. calibration.launch.py (Camera Calibration)
*Description:* Launches driver in calibration mode for camera parameter tuning.

*Config File:* config/calibration.yaml

*Topics Published:*
- oak/left/image_raw - Left stereo rectified image
- oak/left/camera_info - Left camera calibration
- oak/right/image_raw - Right stereo rectified image
- oak/right/camera_info - Right camera calibration
- oak/rgb/image_raw - RGB camera image (optional)

*Purpose:*
- Test and validate camera calibration parameters
- Adjust stereo rectification settings
- Verify calibration quality

---

### 9. example_multicam.launch.py (Multiple Cameras)
*Description:* Launches multiple OAK cameras simultaneously with different pipelines.

*Config File:* config/multicam_example.yaml

*Cameras Launched:*
1. *oak_d_w* (Standard RGBD):
   - Topics: oak_d_w/rgb/image_raw, oak_d_w/stereo/image_raw
   - Device ID: 19443010D1BFF51200

2. *oak_d_lite* (With YOLO Detection):
   - Topics: 
     - oak_d_lite/rgb/image_raw
     - oak_d_lite/nn/detections - YOLO detection results
     - oak_d_lite/nn/detection_markers - Visualization markers
   - Device ID: 18443010C1038C1200
   - Model: YOLO

3. *oak_d_pro* (Spatial RGBD):
   - Topics:
     - oak_d_pro/rgb/image_raw
     - oak_d_pro/stereo/image_raw
     - oak_d_pro/rgbd/points - Point cloud
   - Device ID: 1944301051FB4D1300

*Special Nodes:*
- obj_pub.py - Detection publisher with remappings

*Remappings:*

/oak/nn/detections → /oak_d_pro/nn/detections
/oak/nn/detection_markers → /oak_d_pro/nn/detection_markers


*Typical Usage:*
bash
ros2 launch depthai_ros_driver example_multicam.launch.py


---

### 10. driver_as_part_of_a_robot.launch.py
*Description:* Integration template for embedding DepthAI driver in a larger robot system.

*Purpose:*
- Shows how to namespace and integrate with other robot components
- Demonstrates parameter passing for multi-system setup

---

### 11. sr_poe_rgbd_pcl.launch.py & sr_rgbd_pcl.launch.py
*Description:* Special runtime (SR) configurations for OAK-D SR camera with POE support.

*Topics Published:*
- Similar to rgbd_pcl.launch.py but optimized for SR cameras
- oak/rgb/image_raw - RGB 
- oak/stereo/image_raw - Depth
- oak/rgbd/points - Point cloud

---

### 12. stereo_from_rosbag.launch.py
*Description:* Simulates camera from recorded ROS bag file instead of real hardware.

*Topics Published (from rosbag):*
- oak/left/image_raw - Left stereo image from bag
- oak/right/image_raw - Right stereo image from bag
- oak/stereo/image_raw - Processed stereo depth
- oak/rgb/image_raw - RGB from bag (if available)

*Parameters:*
- i_simulate_from_topic: true - Simulation mode
- i_simulated_topic_name - Topic to read from rosbag

*Typical Usage:*
bash
ros2 launch depthai_ros_driver stereo_from_rosbag.launch.py


---

## depthai_filters Launch Files

Filter-based post-processing launch files that extend driver capabilities with composable nodes.

### 13. example_det2d_overlay.launch.py (Detection 2D Overlay)
*Description:* Overlays 2D detection bounding boxes on camera frame for visualization.

*Base:* Includes driver.launch.py with default RGBD config

*Topics Subscribed:*
- oak/nn/passthrough/image_raw - Original RGB frame
- oak/nn/detections - 2D detection results

*Topics Published (via Detection2DOverlay filter):*
- oak/nn/overlay - Frame with detection overlays drawn
- All base driver topics

*Filter Node:* depthai_filters::Detection2DOverlay (composable)

*Config File:* depthai_filters/config/detection.yaml

*Typical Usage:*
bash
ros2 launch depthai_filters example_det2d_overlay.launch.py
ros2 launch depthai_filters example_det2d_overlay.launch.py name:=camera1


---

### 14. example_seg_overlay.launch.py (Segmentation Overlay)
*Description:* Overlays semantic segmentation output on original RGB image for visualization.

*Base:* Includes driver.launch.py with example_segmentation.launch.py

*Topics Subscribed:*
- oak/nn/passthrough/image_raw - Original RGB passthrough
- oak/nn/image_raw - Segmentation class map

*Topics Published (via SegmentationOverlay filter):*
- oak/nn/overlay - RGB with segmentation overlay
- All segmentation driver topics

*Filter Node:* depthai_filters::SegmentationOverlay (composable)

*Config File:* depthai_filters/config/segmentation.yaml (from driver)

*Typical Usage:*
bash
ros2 launch depthai_filters example_seg_overlay.launch.py


---

### 15. example_feature_tracker.launch.py (Feature Tracker Overlay)
*Description:* Visualizes tracked feature points on RGB image stream.

*Base:* Includes driver.launch.py with feature tracking enabled

*Topics Subscribed:*
- oak/rgb/image_raw - RGB preview frame
- oak/rgb_feature_tracker/tracked_features - Tracked feature points

*Topics Published (via FeatureTrackerOverlay filter):*
- oak/overlay_rgb - RGB with feature points drawn
- All base driver topics

*Filter Node:* depthai_filters::FeatureTrackerOverlay (composable)

*Config File:* depthai_filters/config/feature_tracker.yaml

*Typical Usage:*
bash
ros2 launch depthai_filters example_feature_tracker.launch.py


---

### 16. example_feature_3d.launch.py (3D Feature Visualization)
*Description:* Projects tracked 2D features into 3D space using depth information.

*Base:* Includes driver.launch.py

*Topics Subscribed:*
- oak/stereo/image_raw - Depth image
- oak/stereo/camera_info - Depth camera calibration
- oak/rgb_feature_tracker/tracked_features - 2D feature tracks

*Topics Published (via Features3D filter):*
- oak/features_3d - 3D feature point cloud (PointCloud2)
- All base driver topics

*Filter Node:* depthai_filters::Features3D (composable)

*Config File:* depthai_filters/config/feature_tracker.yaml

*Purpose:*
- Convert 2D tracked features to 3D points
- Use depth information for feature localization
- Useful for structure-from-motion and reconstruction

*Typical Usage:*
bash
ros2 launch depthai_filters example_feature_3d.launch.py


---

### 17. example_wls_filter.launch.py (Weighted Least Squares Depth Filter)
*Description:* Applies WLS (Weighted Least Squares) filter for depth map enhancement.

⚠ *Status:* UNDER DEVELOPMENT - Not fully functional

*Base:* Includes driver.launch.py

*Topics Subscribed:*
- oak/stereo/image_raw - Original depth image
- oak/stereo/camera_info - Depth camera info
- oak/left/image_rect - Rectified left stereo image

*Filters Applied:*
1. image_proc::RectifyNode - Rectifies left image
2. depthai_filters::WLSFilter - Applies weighted least squares smoothing

*Topics Published:*
- oak/left/image_rect - Rectified left image
- oak/stereo/filtered - Smoothed depth map (when complete)

*Config File:* depthai_filters/config/wls.yaml

*Note:* Returns empty LaunchDescription - feature incomplete

---

### 18. spatial_bb.launch.py (Spatial Bounding Box)
*Description:* Visualizes 3D spatial bounding boxes from spatial detection results.

*Base:* Includes driver.launch.py

*Topics Subscribed:*
- oak/nn/passthrough_depth/camera_info - Depth camera calibration
- oak/nn/spatial_detections - 3D spatial detection results
- oak/nn/passthrough/image_raw - Original frame for context

*Topics Published (via SpatialBB filter):*
- oak/nn/spatial_markers - 3D bounding box markers (visualization_msgs/MarkerArray)
- All base driver topics

*Filter Node:* depthai_filters::SpatialBB (composable)

*Config File:* depthai_filters/config/spatial_bb.yaml

*RViz Config:* depthai_filters/config/spatial_bb.rviz

*Features:*
- Converts spatial detections to 3D markers
- Displays 3D bounding boxes in RViz
- Shows object positions in 3D space

*Typical Usage:*
bash
ros2 launch depthai_filters spatial_bb.launch.py


---

### 19. thermal_temp.launch.py (Thermal Temperature Conversion)
*Description:* Converts raw thermal sensor data to temperature values for OAK-T camera.

*Base:* Includes oak_t.launch.py (Thermal Camera)

*Topics Subscribed:*
- oak/thermal/raw_data/image_raw - Raw thermal sensor data

*Topics Published (via ThermalTemp filter):*
- oak/thermal/temperature - Converted temperature map (in Celsius or Kelvin)
- All thermal driver topics

*Filter Node:* depthai_filters::ThermalTemp (composable)

*Use Cases:*
- Temperature measurement and mapping
- Thermal anomaly detection
- Building diagnostics
- Industrial monitoring

*Typical Usage:*
bash
ros2 launch depthai_filters thermal_temp.launch.py
ros2 launch depthai_filters thermal_temp.launch.py name:=thermal_camera


---

### 20. det2d_usb_cam_overlay.launch.py (Multi-Source Detection Overlay)
*Description:* Combines 2D detections from DepthAI with USB camera feed overlay.

⚠ *Status:* UNDER DEVELOPMENT - Not fully functional

*Base:* Includes example_det2d_overlay.launch.py

*Additional Component:*
- USB Camera node (usb_cam::usb_cam_node_exe)

*Topics from DepthAI:*
- oak/nn/detections - DepthAI detections
- oak/nn/overlay - DepthAI overlay

*Topics from USB Camera:*
- /image_raw - USB camera feed
- Parameters: 320x240 resolution, YUYV to RGB conversion

*Filter Chain:*
1. DepthAI detection overlay
2. USB camera integration
3. Bounding box overlay

*Config Files:*
- depthai_filters/config/detection.yaml (from example_det2d_overlay)
- depthai_filters/config/usb_cam_overlay.yaml

*Note:* Returns empty LaunchDescription - feature incomplete

---

## Quick Reference Table

### DepthAI ROS Driver Launch Files

| Launch File | Pipeline Type | Key Topics | Use Case |
|---|---|---|---|
| *driver.launch.py* | RGBD (default) | rgb/image_raw, stereo/image_raw | Basic RGB-D capture |
| *rgbd_pcl.launch.py* | RGBD | + rgbd/points | RGB-D + 3D visualization |
| *vio.launch.py* | RGBD + VIO | + vio/odometry, imu/data | Motion tracking & odometry |
| *pointcloud.launch.py* | Depth only | stereo/image_raw, points | Depth-only point clouds |
| *oak_t.launch.py* | Thermal | thermal/image_raw | Thermal imaging |
| *rtabmap.launch.py* | RGBD + VIO + SLAM | + rtabmap/map | Full SLAM system |
| *example_segmentation.launch.py* | RGB + NN | rgb/image_raw, nn/image_raw | Semantic segmentation |
| *calibration.launch.py* | RGBStereo | left/image_raw, right/image_raw | Calibration validation |
| *example_multicam.launch.py* | Mixed | Multiple namespaced topics | Multi-camera systems |
| *stereo_from_rosbag.launch.py* | Simulated | rosbag topics | Offline testing |
| *sr_poe_rgbd_pcl.launch.py* | RGBD (POE) | + rgbd/points | SR camera POE mode |
| *sr_rgbd_pcl.launch.py* | RGBD (SR) | + rgbd/points | Special Runtime cameras |
| *driver_as_part_of_a_robot.launch.py* | Any | Depends on config | Robot integration template |

### DepthAI Filters Launch Files

| Launch File | Filter Type | Input Topics | Output Topics | Status |
|---|---|---|---|---|
| *example_det2d_overlay.launch.py* | 2D Detection Overlay | nn/passthrough, nn/detections | nn/overlay | ✅ Stable |
| *example_seg_overlay.launch.py* | Segmentation Overlay | nn/passthrough, nn/image_raw | nn/overlay | ✅ Stable |
| *example_feature_tracker.launch.py* | Feature Overlay | rgb/image_raw, tracked_features | overlay_rgb | ✅ Stable |
| *example_feature_3d.launch.py* | 3D Feature Visualization | stereo/image_raw, tracked_features | features_3d | ✅ Stable |
| *spatial_bb.launch.py* | Spatial Bounding Box | nn/spatial_detections | nn/spatial_markers | ✅ Stable |
| *thermal_temp.launch.py* | Thermal Temperature | thermal/raw_data | thermal/temperature | ✅ Stable |
| *example_wls_filter.launch.py* | WLS Depth Filter | stereo/image_raw | stereo/filtered | ⚠ In Development |
| *det2d_usb_cam_overlay.launch.py* | Multi-Source Overlay | /image_raw, nn/detections | nn/overlay | ⚠ In Development |

---

## Common Topic Naming Conventions

### Namespacing
- Default namespace: oak
- Custom namespace: Pass name:=custom_name to use custom_name instead
- Multi-camera: Each camera has its own namespace (e.g., oak_d_w, oak_d_lite, etc.)

### Topic Structure

/{namespace}/rgb/image_raw              # RGB camera
/{namespace}/rgb/camera_info            # RGB calibration
/{namespace}/stereo/image_raw           # Depth image
/{namespace}/stereo/camera_info         # Depth calibration
/{namespace}/rgbd/points                # Point cloud (if RGBD enabled)
/{namespace}/vio/odometry               # Odometry (if VIO enabled)
/{namespace}/imu/data                   # IMU data (if available)
/{namespace}/nn/detections              # NN detections (if enabled)


---

## Launching with Custom Parameters

### Change node name:
bash
ros2 launch depthai_ros_driver driver.launch.py name:=camera1


### Enable point cloud:
bash
ros2 launch depthai_ros_driver rgbd_pcl.launch.py pointcloud.enable:=true


### Use RealSense compatibility mode:
bash
ros2 launch depthai_ros_driver driver.launch.py rs_compat:=true


### Set camera position:
bash
ros2 launch depthai_ros_driver driver.launch.py \
  cam_pos_x:=0.1 \
  cam_pos_y:=0.0 \
  cam_pos_z:=0.5


### Enable visualization with RViz:
bash
ros2 launch depthai_ros_driver vio.launch.py use_rviz:=true


---

## Configuration Files Location

All configuration YAML files are located in:

depthai_ros_driver/config/
├── driver.yaml
├── rgbd.yaml
├── vio.yaml
├── pcl.yaml
├── oak_t.yaml
├── rtabmap.yaml
├── segmentation.yaml
├── calibration.yaml
├── multicam_example.yaml
├── low_bandwidth.yaml
├── yolo.yaml
├── yolo_spatial.yaml
├── isaac_vslam.yaml
└── rviz/
    ├── rgbd.rviz
    ├── vio.rviz
    ├── segmentation.rviz


---

## Monitoring Topics

To see all published topics:
bash
ros2 topic list


To view a specific topic:
bash
ros2 topic echo /oak/rgb/image_raw


To check topic information:
bash
ros2 topic info /oak/rgb/image_raw


To view camera info:
bash
ros2 topic echo /oak/rgb/camera_info


---

## Transform Frames

Each launch establishes transform hierarchy:

oak_parent_frame
└── oak (camera base)
    ├── oak_rgb_camera_optical_frame (RGB camera)
    ├── oak_stereo_left_camera_optical_frame (Left stereo)
    ├── oak_stereo_right_camera_optical_frame (Right stereo)
    ├── oak_imu (IMU sensor, if available)
    └── oak_thermal_camera_optical_frame (Thermal, if available)


Check available transforms:
bash
ros2 run tf2_tools view_frames


---

## Launch Files by Category

### Camera Type Launch Files
- *oak_t.launch.py* - Thermal camera (OAK-T)
- *driver.launch.py* - Standard RGB-D cameras
- *calibration.launch.py* - Stereo rectified images
- *pointcloud.launch.py* - Depth-only cameras

### AI/Vision Launch Files
- *example_segmentation.launch.py* - Semantic segmentation
- *example_multicam.launch.py* - Multiple cameras with YOLOv3
- *example_feature_tracker.launch.py* - Feature tracking
- *example_feature_3d.launch.py* - 3D feature tracking

### Odometry & SLAM Launch Files
- *vio.launch.py* - Visual-inertial odometry
- *rtabmap.launch.py* - Real-time SLAM mapping

### Point Cloud & Visualization
- *rgbd_pcl.launch.py* - RGB-D with point clouds
- *sr_rgbd_pcl.launch.py* - Special Runtime with point clouds
- *sr_poe_rgbd_pcl.launch.py* - POE camera with point clouds

### Filter/Post-Processing Launch Files
- *example_det2d_overlay.launch.py* - 2D detection overlay
- *example_seg_overlay.launch.py* - Segmentation overlay
- *spatial_bb.launch.py* - 3D bounding box visualization
- *thermal_temp.launch.py* - Thermal temperature conversion

### Testing & Development
- *stereo_from_rosbag.launch.py* - Rosbag replay simulation
- *example_wls_filter.launch.py* - Depth filtering (experimental)
- *det2d_usb_cam_overlay.launch.py* - Multi-source overlay (experimental)
- *driver_as_part_of_a_robot.launch.py* - Robot integration template

---

## Topic Naming Patterns

### Standard Topics per Camera

{namespace}/rgb/image_raw                    # RGB stream
{namespace}/rgb/camera_info                  # RGB calibration
{namespace}/rgb/image_rect                   # Rectified RGB (if enabled)
{namespace}/stereo/image_raw                 # Depth image
{namespace}/stereo/camera_info               # Depth calibration
{namespace}/left/image_raw                   # Left stereo
{namespace}/left/camera_info
{namespace}/right/image_raw                  # Right stereo
{namespace}/right/camera_info


### Optional Topics (based on pipeline)

{namespace}/rgbd/points                      # Point cloud (RGBD mode)
{namespace}/vio/odometry                     # Odometry (VIO enabled)
{namespace}/imu/data                         # IMU data
{namespace}/thermal/image_raw                # Thermal images
{namespace}/thermal/raw_data/image_raw       # Raw thermal data
{namespace}/nn/detections                    # Detection results
{namespace}/nn/spatial_detections            # 3D detections
{namespace}/nn/image_raw                     # Segmentation output
{namespace}/nn/passthrough/image_raw         # NN passthrough frame


### Filter Output Topics

{namespace}/nn/overlay                       # Detection/Segmentation overlay
{namespace}/overlay_rgb                      # Feature tracker overlay
{namespace}/nn/spatial_markers               # 3D bounding box markers
{namespace}/features_3d                      # 3D feature point cloud
{namespace}/thermal/temperature              # Temperature conversion


---

## Recommended Launch Sequences

### Basic Setup
bash
# Start basic RGB-D driver
ros2 launch depthai_ros_driver driver.launch.py

# In another terminal, view topics
ros2 topic list
ros2 topic echo /oak/rgb/image_raw


### Point Cloud Visualization
bash
# Launch with point cloud
ros2 launch depthai_ros_driver rgbd_pcl.launch.py

# View in RViz
ros2 run rviz2 rviz2
# Add PointCloud2 visualization for oak/rgbd/points


### SLAM Mapping
bash
# Full SLAM setup
ros2 launch depthai_ros_driver rtabmap.launch.py

# View map in RViz
ros2 run rviz2 rviz2
# Add OccupancyGrid for rtabmap/map


### Object Detection with Visualization
bash
# Detection with overlay
ros2 launch depthai_filters example_det2d_overlay.launch.py

# View result
ros2 topic echo /oak/nn/overlay


### Multi-Camera System
bash
# Launch multiple cameras
ros2 launch depthai_ros_driver example_multicam.launch.py

# Each camera has its namespace
ros2 topic list | grep oak_d_


### Thermal Imaging with Temperature
bash
# Thermal + temperature conversion
ros2 launch depthai_filters thermal_temp.launch.py

# View temperature data
ros2 topic echo /oak/thermal/temperature


---

## Performance Considerations

### High Bandwidth Topics (Consider compression)
- rgb/image_raw - Full resolution RGB
- stereo/image_raw - Full resolution depth
- rgbd/points - Point cloud (can be large)

### Lower Bandwidth Alternatives
- Use rgb/compressed instead of rgb/image_raw
- Reduce frame resolution with parameters
- Publish detected regions instead of full frames

### Synchronization
- Most filters expect synchronized input
- Use approx_sync: true for time-based sync
- Message filters library handles multi-topic sync

---

## Debugging & Troubleshooting

### Check active nodes:
bash
ros2 node list


### Check running topics:
bash
ros2 topic list -t


### Monitor topic bandwidth:
bash
ros2 run rqt_graph rqt_graph


### View transform tree:
bash
ros2 run tf2_tools view_frames


### Record to rosbag for offline analysis:
bash
ros2 bag record /oak/rgb/image_raw /oak/stereo/image_raw


### Replay from rosbag:
bash
ros2 launch depthai_ros_driver stereo_from_rosbag.launch.py


---

## Notes

- Topic names are case-sensitive
- Default namespace is oak (override with name:=custom_name)
- Camera info always published alongside image topics
- Filters are composable nodes for efficiency
- Some filters are in development phase (marked with ⚠)
- VIO and SLAM require sufficient visual features in environment
- Point clouds require both RGB and depth data for proper generation