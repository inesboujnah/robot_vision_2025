**Overview**

This README explains how to build and run the RealSense and OAK-D ROS 2 images so that their nodes launch and recorded `ros2 bag` data is saved into the repository `memory_register` folders.

**Prerequisites**

- `docker` and `docker-compose` installed and working
- Base image `rv_base:v1` already built (contains ROS 2 Humble and dependencies)
- Sufficient disk space for recorded bags
- Camera hardware connected (RealSense D435/D455 or OAK-D)

**Prepare host folders**

The required folders already exist:
- `./memory_register/realsense` - for RealSense bag recordings
- `./memory_register/oak` - for OAK-D bag recordings
- `./memory_register/orbslam_data` - for ORB-SLAM3 outputs

**Build the images**

From the repository root, build the images with these exact tags:

```bash
# Build RealSense image (requires rv_base:v1)
cd realsense_setup
docker build -t rv_realsense:v1 -f RealSense.Dockerfile .

# Build OAK-D image (requires rv_base:v1)
cd ../oak_setup
docker build -t rv_oak:v1 -f OAK.Dockerfile .
```

Both Dockerfiles:
- Extend `rv_base:v1` (ROS 2 Humble base)
- Create a `launch_manager` ROS 2 package
- Copy `ros2_launch.py` as the main launch file
- Install entrypoint scripts that handle bag recording
- Set `ENTRYPOINT` to auto-launch nodes on container start

**Run with Docker Compose (Recommended)**

Navigate to the appropriate setup folder and use the provided compose file:

**RealSense:**
```bash
cd realsense_setup
docker-compose -f realsense_docker-compose.yaml up
```

**OAK-D:**
```bash
cd oak_setup
docker-compose -f oak_docker-compose.yaml up
```

The compose files:
- Use `network_mode: host` for ROS 2 DDS discovery
- Run `privileged: true` for camera device access
- Mount `memory_register/{realsense,oak}` for bag recordings
- Mount `memory_register/orbslam_data` for ORB-SLAM3 outputs
- Set `RECORD_BAG=1` to enable automatic bag recording
- Enable interactive terminal with `stdin_open` and `tty`

To run in detached mode:
```bash
docker-compose -f realsense_docker-compose.yaml up -d
```

To stop:
```bash
docker-compose -f realsense_docker-compose.yaml down
```

**Bag recording behavior**

When `RECORD_BAG=1` is set (default in compose files):
- The entrypoint script runs `ros2 bag record -a` in the background
- Bags are saved to timestamped folders: `{camera}_YYYY-MM-DD_HH-MM-SS`
- **RealSense** bags go to `/root/memory_register/realsense/realsense_<timestamp>`
- **OAK-D** bags go to `/root/memory_register/oak/oak_<timestamp>`
- All topics are recorded (`-a` flag)

To disable recording, remove the `RECORD_BAG` env var or set it to `0`:
```yaml
environment:
  - RECORD_BAG=0
```

**Accessing the running container**

To exec into a running container and interact with ROS 2:

```bash
# RealSense
docker-compose -f realsense_setup/realsense_docker-compose.yaml exec realsense bash

# OAK-D
docker-compose -f oak_setup/oak_docker-compose.yaml exec oak bash
```

Inside the container:
```bash
# Source ROS 2 (already done by entrypoint)
source /opt/ros/humble/setup.bash

# List active ROS 2 nodes
ros2 node list

# List published topics
ros2 topic list

# Echo a topic
ros2 topic echo /camera/color/image_raw
```

**Viewing logs**

```bash
# Follow logs in real-time
docker-compose -f realsense_setup/realsense_docker-compose.yaml logs -f

# View logs from specific service
docker-compose -f oak_setup/oak_docker-compose.yaml logs oak
```

**Inspecting recorded bags**

List recorded bag folders on host:

```bash
ls -la memory_register/realsense/
ls -la memory_register/oak/
```

Inspect bag metadata:
```bash
ros2 bag info memory_register/realsense/realsense_2025-12-02_14-30-15
```

Play back a bag:
```bash
ros2 bag play memory_register/oak/oak_2025-12-02_15-45-00
```

**Permissions**

Bags are created as `root` inside containers. If you need to access them without `sudo`:

```bash
sudo chown -R $(id -u):$(id -g) memory_register/realsense
sudo chown -R $(id -u):$(id -g) memory_register/oak
```

**Troubleshooting**

- **Camera not detected**: Ensure USB devices are accessible. You may need to add device mappings:
  ```yaml
  devices:
    - /dev/bus/usb:/dev/bus/usb  # for RealSense
  ```

- **No topics published**: Check camera connection and drivers inside container:
  ```bash
  # RealSense
  rs-enumerate-devices
  
  # OAK-D
  python3 -c "import depthai; print(depthai.Device.getAllAvailableDevices())"
  ```

- **ROS 2 nodes not visible**: Verify `network_mode: host` is set in compose file for DDS discovery.

- **Bags empty or not recording**: Confirm `RECORD_BAG=1` is set and check entrypoint logs. Verify topics exist with `ros2 topic list`.

- **Permission denied**: Run container with `--privileged` or add specific device access.

**Manual run (without compose)**

If you prefer running containers directly:

```bash
# RealSense
docker run --rm -it \
  --name realsense_node \
  --network host \
  --privileged \
  -e RECORD_BAG=1 \
  -v $(pwd)/memory_register/realsense:/root/memory_register/realsense \
  -v $(pwd)/memory_register/orbslam_data:/root/memory_register/orb_slam_data \
  rv_realsense:v1

# OAK-D
docker run --rm -it \
  --name oak_node \
  --network host \
  --privileged \
  -e RECORD_BAG=1 \
  -v $(pwd)/memory_register/oak:/root/memory_register/oak \
  -v $(pwd)/memory_register/orbslam_data:/root/memory_register/orb_slam_data \
  rv_oak:v1
```
