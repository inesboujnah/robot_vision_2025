# Comprehensive List of depthai-ros Topics

## RGB/COLOR IMAGE TOPICS

### Camera Sensor (RGB/Color)
- *Camera Node -> ~/{camera_name}* (sensor_msgs/Image)
  - Published by: Camera node
  - Default topic: ~/camera_isp, ~/camera_preview
  - Message Type: sensor_msgs/Image
  - Camera Info: ~/{camera_name}/camera_info (sensor_msgs/CameraInfo)
  - Compressed: ~/{camera_name}/image/compressed (sensor_msgs/CompressedImage)

---

## DEPTH/STEREO TOPICS

### Stereo Depth
- *Stereo Node -> ~/stereo/image_raw* (sensor_msgs/Image - Depth)
  - Published by: Stereo node
  - Message Type: sensor_msgs/Image (16-bit depth)
  - Camera Info: ~/stereo/camera_info
  - Supports disparity output via i_output_disparity parameter

### Left Rectified Stereo
- *Stereo Node -> ~/left_camera/image_rect* (sensor_msgs/Image - Rectified Grayscale)
  - Published by: Stereo node (when i_left_rect_publish_topic enabled)
  - Alternative (RS Mode): ~/left_camera/image_rect_raw
  - Camera Info: ~/left_camera/camera_info

### Right Rectified Stereo
- *Stereo Node -> ~/right_camera/image_rect* (sensor_msgs/Image - Rectified Grayscale)
  - Published by: Stereo node (when i_right_rect_publish_topic enabled)
  - Alternative (RS Mode): ~/right_camera/image_rect_raw
  - Camera Info: ~/right_camera/camera_info

### Disparity
- *Example Topic: disparity/image* (stereo_msgs/DisparityImage)
  - Published by: Example nodes
  - Message Type: stereo_msgs/DisparityImage

---

## IMU TOPICS

### IMU Data (Standard ROS)
- *Imu Node -> ~/{imu_name}/data* (sensor_msgs/Imu)
  - Published by: Imu node
  - Message Type: sensor_msgs/Imu
  - Contains: Accelerometer, Gyroscope data
  - RS Mode: ~/{imu_name} (without /data suffix)

### IMU with Magnetic Field (Custom)
- *Imu Node -> ~/{imu_name}/data* (depthai_ros_msgs/ImuWithMagneticField)
  - Published by: Imu node (when i_enable_mag_imu enabled)
  - Message Type: depthai_ros_msgs/ImuWithMagneticField
  - Contains: IMU + Magnetic field data

### Magnetic Field (Separate)
- *Imu Node -> ~/{imu_name}/mag* (sensor_msgs/MagneticField)
  - Published by: Imu node (when split mode enabled)
  - Message Type: sensor_msgs/MagneticField

---

## DETECTION/NEURAL NETWORK TOPICS

### 2D Detection
- *Detection Node -> ~/{nn_name}/detections* (vision_msgs/Detection2DArray)
  - Published by: Detection node (2D detection network)
  - Message Type: vision_msgs/Detection2DArray
  - Contains: Bounding boxes and class information

### Passthrough (Detection)
- *Detection Node -> ~/{nn_name}/preview* (sensor_msgs/Image)
  - Published by: Detection node (when passthrough enabled)
  - Message Type: sensor_msgs/Image

### 3D Spatial Detection
- *SpatialDetection Node -> ~/{nn_name}/spatial_detections* (vision_msgs/Detection3DArray)
  - Published by: SpatialDetection node
  - Message Type: vision_msgs/Detection3DArray
  - Contains: 3D bounding boxes with spatial coordinates

### Spatial Detection Depth
- *SpatialDetection Node -> ~/{nn_name}/spatial_detections/depth* (sensor_msgs/Image)
  - Published by: SpatialDetection node (when depth passthrough enabled)
  - Message Type: sensor_msgs/Image

### Segmentation Output
- *Segmentation Node -> ~/{seg_name}/image_raw* (sensor_msgs/Image)
  - Published by: Segmentation node
  - Message Type: sensor_msgs/Image
  - Camera Info: ~/{seg_name}/camera_info

### Segmentation Passthrough
- *Segmentation Node -> ~/{seg_name}/passthrough/image_raw* (sensor_msgs/Image)
  - Published by: Segmentation node (when passthrough enabled)
  - Message Type: sensor_msgs/Image
  - Camera Info: ~/{seg_name}/passthrough/camera_info

---

## FEATURE TRACKING TOPICS

### Feature Tracker Output
- *FeatureTracker Node -> ~/{tracker_name}/tracked_features* (depthai_ros_msgs/TrackedFeatures)
  - Published by: FeatureTracker node
  - Message Type: depthai_ros_msgs/TrackedFeatures
  - Contains: Tracked feature points with IDs

### Feature Tracker (Left - Rectified)
- *FeatureTracker Node -> ~/left_camera_rect_feature_tracker/tracked_features* (depthai_ros_msgs/TrackedFeatures)
  - Published by: FeatureTracker node (left rectified)
  - Message Type: depthai_ros_msgs/TrackedFeatures

### Feature Tracker (Right - Rectified)
- *FeatureTracker Node -> ~/right_camera_rect_feature_tracker/tracked_features* (depthai_ros_msgs/TrackedFeatures)
  - Published by: FeatureTracker node (right rectified)
  - Message Type: depthai_ros_msgs/TrackedFeatures

---

## POINT CLOUD TOPICS

### RGBD Point Cloud
- *RGBD Node -> ~/{rgbd_name}/points* (sensor_msgs/PointCloud2)
  - Published by: RGBD node
  - Message Type: sensor_msgs/PointCloud2
  - Generated from: RGB + Depth/Stereo alignment

### Point Cloud (Example)
- *Example Topic: stereo/points* (sensor_msgs/PointCloud2)
  - Published by: Example nodes
  - Message Type: sensor_msgs/PointCloud2

### Point Cloud (RGBD Example)
- *Example Topic: points/color* (sensor_msgs/PointCloud2)
  - Published by: Example nodes
  - Message Type: sensor_msgs/PointCloud2

---

## THERMAL TOPICS

### Thermal Image (Color)
- *Thermal Node -> ~/thermal/image* (sensor_msgs/Image)
  - Published by: Thermal node
  - Message Type: sensor_msgs/Image (RGB or thermal colormap)
  - Camera Info: ~/thermal/camera_info

### Thermal Raw Data
- *Thermal Node -> ~/thermal/raw_data* (sensor_msgs/Image)
  - Published by: Thermal node (when i_publish_raw enabled)
  - Message Type: sensor_msgs/Image
  - Camera Info: ~/thermal/raw_data/camera_info

### Example Thermal Topic
- *Example Topic: thermal/image* (sensor_msgs/Image)
  - Published by: Example nodes
  - Message Type: sensor_msgs/Image

---

## TIME-OF-FLIGHT (TOF) TOPICS

### ToF Depth Image
- *ToF Node -> ~/{tof_name}* (sensor_msgs/Image)
  - Published by: ToF node
  - Message Type: sensor_msgs/Image (16-bit depth)
  - Camera Info: ~/{tof_name}/camera_info

### Example ToF Topic
- *Example Topic: tof/image* (sensor_msgs/Image)
  - Published by: Example nodes
  - Message Type: sensor_msgs/Image

### RGBD with ToF
- *RGBD Node (ToF) -> pcl/data* (sensor_msgs/PointCloud2)
  - Published by: RGBD node with ToF
  - Message Type: sensor_msgs/PointCloud2

---

## ODOMETRY & VISUAL ODOMETRY TOPICS

### VIO (Visual Inertial Odometry)
- *Vio Node -> ~/{vio_name}/odometry* (nav_msgs/Odometry)
  - Published by: Vio node
  - Message Type: nav_msgs/Odometry
  - Contains: Position, orientation, velocity
  - TF Publish: Optional (controlled by i_publish_tf parameter)

### Odometry (Example)
- *Example Topic: odom* (nav_msgs/Odometry)
  - Published by: Example nodes
  - Message Type: nav_msgs/Odometry

---

## SLAM TOPICS

### Absolute Pose (SLAM)
- *Slam Node -> ~/{slam_name}/absolute_pose* (geometry_msgs/PoseWithCovarianceStamped)
  - Published by: Slam node (when i_publish_absolute_pose enabled)
  - Message Type: geometry_msgs/PoseWithCovarianceStamped
  - Frame: Map frame to base frame

### Occupancy Grid Map
- *Slam Node -> ~/{slam_name}/map* (nav_msgs/OccupancyGrid)
  - Published by: Slam node (when i_publish_map enabled)
  - Message Type: nav_msgs/OccupancyGrid
  - Frame: Map frame

### Ground Point Cloud (SLAM)
- *Slam Node -> ~/{slam_name}/ground_pcl* (sensor_msgs/PointCloud2)
  - Published by: Slam node (when i_publish_ground_pcl enabled)
  - Message Type: sensor_msgs/PointCloud2
  - Contains: Ground-classified points

### Obstacle Point Cloud (SLAM)
- *Slam Node -> ~/{slam_name}/obstacle_pcl* (sensor_msgs/PointCloud2)
  - Published by: Slam node (when i_publish_obstacle_pcl enabled)
  - Message Type: sensor_msgs/PointCloud2
  - Contains: Obstacle-classified points

### Map to Odom Transform (SLAM)
- *Slam Node -> TF2 Transform: map -> odom*
  - Published by: Slam node (when i_publish_tf enabled)
  - Transform: From map frame to odometry frame

---

## TRANSFORM FRAME TOPICS

### Transform Broadcaster (TF2)
- *All Sensor Nodes -> /tf* (tf2_msgs/TFMessage)
  - Published by: Various nodes (when TF publishing enabled)
  - Standard frame hierarchy:
    - map -> odom -> base_link -> Camera/IMU/ToF frames

### Example Transform Frames
- oak_rgb_camera_optical_frame (RGB camera)
- oak_stereo_optical_frame (Stereo depth)
- oak_left_camera_optical_frame (Left mono)
- oak_right_camera_optical_frame (Right mono)
- oak_imu_frame (IMU)
- oak_thermal_camera_optical_frame (Thermal)
- oak_tof_camera_optical_frame (ToF)

---

## TOPIC NAMING CONVENTIONS

### Node Name Format
- Default: ~/{node_name} (private namespace)
- RS Compatibility Mode: Different suffixes
- Example: ~/rgb, ~/stereo, ~/left_camera, ~/right_camera, ~/imu, ~/vio, ~/slam

### Topic Suffix Patterns
1. *Image Topics*: /image, /image_raw, /image_rect, /image_rect_raw, /image/compressed
2. *Camera Info*: /camera_info
3. *Detection*: /detections, /spatial_detections
4. *Features*: /tracked_features
5. *Point Clouds*: /points, /ground_pcl, /obstacle_pcl
6. *Pose/Odometry*: /odometry, /absolute_pose
7. *Maps*: /map

### Parameter Control
- i_publish_topic: Enable/disable topic publishing
- i_enable_lazy_publisher: Lazy subscriber mode
- i_publish_compressed: Enable compressed image transport
- i_publish_raw: Publish raw sensor data
- i_publish_tf: Publish transforms

---

## SUMMARY BY SOURCE NODE

| Node Type | Primary Topic | Message Type |
|-----------|---------------|--------------|
| Camera | ~/{name} | sensor_msgs/Image |
| Stereo | ~/stereo/image_raw | sensor_msgs/Image |
| Stereo (Rect) | ~/{cam}/image_rect | sensor_msgs/Image |
| IMU | ~/{name}/data | sensor_msgs/Imu |
| Thermal | ~/{name}/image | sensor_msgs/Image |
| ToF | ~/{name} | sensor_msgs/Image |
| Detection (2D) | ~/{name}/detections | vision_msgs/Detection2DArray |
| Detection (3D) | ~/{name}/spatial_detections | vision_msgs/Detection3DArray |
| Segmentation | ~/{name}/image_raw | sensor_msgs/Image |
| Feature Tracker | ~/{name}/tracked_features | depthai_ros_msgs/TrackedFeatures |
| RGBD | ~/{name}/points | sensor_msgs/PointCloud2 |
| VIO | ~/{name}/odometry | nav_msgs/Odometry |
| SLAM | ~/{name}/map | nav_msgs/OccupancyGrid |
| SLAM (Pose) | ~/{name}/absolute_pose | geometry_msgs/PoseWithCovarianceStamped |
| SLAM (PCL) | ~/{name}/ground_pcl, obstacle_pcl | sensor_msgs/PointCloud2 |

---

## EXAMPLE LAUNCH CONFIGURATIONS

### depthai_examples Topics
- *rgb_publisher.cpp*: rgb/image (sensor_msgs/Image)
- *disparity_publisher.cpp*: disparity/image (stereo_msgs/DisparityImage)
- *thermal_publisher.cpp*: thermal/image (sensor_msgs/Image)
- *tof_publisher.cpp*: tof/image (sensor_msgs/Image)
- *feature_tracker_publisher.cpp*: features_left, features_right (depthai_ros_msgs/TrackedFeatures)
- *imu_publisher.cpp*: imu/data (sensor_msgs/Imu)
- *odom_publisher.cpp*: odom (nav_msgs/Odometry)
- *rgbd_publisher.cpp*: points/color (sensor_msgs/PointCloud2)
- *rgbd_spatial_detections.cpp*: Multiple topics including rgb/spatial_detections, stereo/depth, stereo/points

---

## NOTES

1. All topics use private namespace (~/) which translates to /{node_namespace}/{topic_name}
2. Message types are from standard ROS 2 packages: sensor_msgs, geometry_msgs, nav_msgs, vision_msgs, and custom depthai_ros_msgs
3. Most image topics have associated camera_info topics for camera calibration
4. Many topics can be enabled/disabled via parameters
5. Compressed image transport is supported for bandwidth reduction
6. Synchronized publishing is available for multi-sensor setups