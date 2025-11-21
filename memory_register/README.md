**Overview**

This README explains how to build and run the Realsense and OAK ROS2 images so that their nodes launch and recorded `ros2 bag` data is saved into the repository `memory_register` folders.

**Prerequisites**

- `docker` installed and working
- `docker-compose` (optional, for compose example)
- Sufficient disk space for recorded bags

**Prepare host folders**

Create the target folders in the repo to persist bag recordings:

```bash
# from repository root
mkdir -p ./memory_register/realsense
mkdir -p ./memory_register/oak
```

**Build the images**

From the repository root run:

```bash
# Build Realsense image
docker build -t realsense:local -f realsense_setup/RealSense.Dockerfile .

# Build OAK image
docker build -t oak_realsense:local -f oak_setup/OAK.Dockerfile .
```

**Run (single container) — save to `memory_register`**

Run the Realsense service and persist bags to `memory_register/realsense`:

```bash
# from repository root
docker run --rm \
  --name realsense_node \
  -e RECORD_BAG=1 \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -e BAG_OPTS="--compression lz4" \
  -v $(pwd)/memory_register/realsense:/root/memory_register/realsense \
  realsense:local
```

Run the OAK service and persist bags to `memory_register/oak`:

```bash
docker run --rm \
  --name oak_node \
  -e RECORD_BAG=1 \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -v $(pwd)/memory_register/oak:/root/memory_register/oak \
  oak_realsense:local
```

Notes:
- `RECORD_BAG=1` enables the wrapper which starts `ros2 bag record` in the background.
- `BAG_OPTS` can include any additional `ros2 bag record` options (topic filters, compression, etc.).
- `HOST_UID`/`HOST_GID` (optional) cause the wrapper to chown created bag folders to the host UID/GID so files are accessible without `sudo`.
- If you don't mount a host folder the bags remain inside the container and will be lost when the container is removed (unless you omit `--rm`).

**Docker Compose example**

Add the following services to your `docker-compose.yaml` (or use as a reference):

```yaml
services:
  realsense:
    image: realsense:local
    environment:
      - RECORD_BAG=1
      - HOST_UID=${HOST_UID:-1000}
      - HOST_GID=${HOST_GID:-1000}
    volumes:
      - ./memory_register/realsense:/root/memory_register/realsense

  oak:
    image: oak_realsense:local
    environment:
      - RECORD_BAG=1
      - HOST_UID=${HOST_UID:-1000}
      - HOST_GID=${HOST_GID:-1000}
    volumes:
      - ./memory_register/oak:/root/memory_register/oak
```

Start with:

```bash
# set your UID/GID and bring up services
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

docker compose up --build
```

Stop with `Ctrl+C` (or `docker compose down`). The bag folders will be in `./memory_register/realsense` and `./memory_register/oak`.

**Inspecting and copying bags**

List recorded bag folders on host:

```bash
ls -l memory_register/realsense
ls -l memory_register/oak
```

If a container produced bags but you did not mount the host folder, copy them out from a stopped container:

```bash
docker cp <container_id>:/root/memory_register/realsense ./local_copy_of_rosbags
```

**Permissions**

Containers typically run as `root`, so created files may be owned by `root` on the host. Use either:

- the `HOST_UID`/`HOST_GID` env vars (recommended) when running the container so the wrapper chowns the created bag folder to your host user, or
- run `sudo chown -R $(id -u):$(id -g) memory_register/realsense` after recording to fix ownership.

**Disable recording**

To launch nodes without recording, simply omit the `RECORD_BAG` environment variable (or set it to `0`).

```bash
docker run --rm -v $(pwd)/memory_register/realsense:/root/memory_register/realsense realsense:local
```

**Troubleshooting**

- If `ros2` or `ros2 bag` is not found in the container, verify the image builds successfully and ROS 2 Humble is present.
- If bags are empty or recording doesn't start, ensure topics are active and that `ros2 bag record` sees published topics (run `ros2 topic list` inside the container to confirm).

If you want, I can add these examples to the repo `docker-compose.yaml` directly or create a top-level `README.md` combining this with other project instructions.
