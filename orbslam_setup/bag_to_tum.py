#!/usr/bin/env python3
import sys
import argparse
import os
import tempfile
import shutil
import subprocess
import atexit
from rclpy.serialization import deserialize_message
from rosbag2_py import SequentialReader, StorageOptions, ConverterOptions, StorageFilter
from geometry_msgs.msg import PoseStamped

def _cleanup_path(path_to_remove):
    try:
        if os.path.isdir(path_to_remove):
            shutil.rmtree(path_to_remove, ignore_errors=True)
        elif os.path.exists(path_to_remove):
            os.remove(path_to_remove)
    except Exception:
        pass

def _decompress_zstd(src_path):
    base, ext = os.path.splitext(src_path)
    if ext not in {".zst", ".zstd"}:
        return src_path

    tmp_dir = tempfile.mkdtemp(prefix="bag_decompress_")
    out_path = os.path.join(tmp_dir, os.path.basename(base))

    try:
        try:
            import zstandard as zstd

            with open(src_path, "rb") as fin, open(out_path, "wb") as fout:
                dctx = zstd.ZstdDecompressor()
                dctx.copy_stream(fin, fout)
        except ImportError:
            subprocess.run(["zstd", "-d", "-f", src_path, "-o", out_path], check=True)
    except Exception as exc:
        _cleanup_path(tmp_dir)
        raise RuntimeError(
            "Failed to decompress Zstd file. Install the 'zstandard' Python package or the 'zstd' CLI."
        ) from exc

    atexit.register(_cleanup_path, tmp_dir)
    return out_path

def _find_bag_file(path):
    """Find the actual bag file in a directory or return the file path."""
    if os.path.isdir(path):
        files = os.listdir(path)
        # Look for bag files, prioritizing uncompressed then compressed
        for ext in ['.db3', '.db3.zstd', '.mcap', '.mcap.zstd']:
            for f in files:
                if f.endswith(ext):
                    return os.path.join(path, f)
        raise FileNotFoundError(f"No bag file found in {path}")
    return path

def _infer_storage_id(path):
    if os.path.isdir(path):
        return "sqlite3"  # Will be determined after finding the file
    _, ext = os.path.splitext(path)
    # Handle compressed extensions
    if ext in {".zst", ".zstd"}:
        base, inner_ext = os.path.splitext(path[:-len(ext)])
        if inner_ext == ".db3":
            return "sqlite3"
        if inner_ext == ".mcap":
            return "mcap"
    if ext == ".db3":
        return "sqlite3"
    if ext == ".mcap":
        return "mcap"
    return "sqlite3"

def extract_tum_trajectory(bag_path, output_path, topic_name):
    """
    Reads a ROS 2 bag and extracts PoseStamped messages to a TUM format text file.
    """
    
    # 1. Setup Reader
    # First, find the actual bag file if a directory was passed
    bag_path = _find_bag_file(bag_path)
    # Then decompress if needed
    bag_path = _decompress_zstd(bag_path)
    reader = SequentialReader()
    storage_options = StorageOptions(uri=bag_path, storage_id=_infer_storage_id(bag_path))
    converter_options = ConverterOptions(
        input_serialization_format='cdr',
        output_serialization_format='cdr'
    )
    
    try:
        reader.open(storage_options, converter_options)
    except Exception as e:
        print(f"Error opening bag: {e}")
        print("Note: Ensure the bag path is a directory containing .mcap or .db3 files, or the direct path to the file.")
        sys.exit(1)

    # 2. Filter for specific topic
    filter_options = StorageFilter(topics=[topic_name])
    reader.set_filter(filter_options)

    print(f"Reading from: {bag_path}")
    print(f"Extracting topic: {topic_name}")
    print(f"Writing to: {output_path}")

    count = 0
    with open(output_path, 'w') as f:
        # Optional: Add header if your analysis tool needs it, 
        # but standard TUM format (and EVO) usually expects raw data or #-comments.
        # f.write("# timestamp x y z q_x q_y q_z q_w\n") 
        
        while reader.has_next():
            (topic, data, t_recorded) = reader.read_next()
            
            # Deserialize data to PoseStamped
            msg = deserialize_message(data, PoseStamped)
            
            # 3. Format Data
            # TUM Format: timestamp x y z qx qy qz qw
            
            # Get timestamp from the message header (sim time), NOT the bag record time
            # This ensures alignment with the SLAM which used use_sim_time
            t_sec = msg.header.stamp.sec + msg.header.stamp.nanosec * 1e-9
            
            tx = msg.pose.position.x
            ty = msg.pose.position.y
            tz = msg.pose.position.z
            
            qx = msg.pose.orientation.x
            qy = msg.pose.orientation.y
            qz = msg.pose.orientation.z
            qw = msg.pose.orientation.w
            
            # Write line with high precision
            f.write(f"{t_sec:.6f} {tx:.9f} {ty:.9f} {tz:.9f} {qx:.9f} {qy:.9f} {qz:.9f} {qw:.9f}\n")
            count += 1

    print(f"Done. Extracted {count} poses to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert ROS 2 Bag Ground Truth to TUM Format")
    parser.add_argument("bag_path", help="Path to the ROS 2 bag (folder or .mcap file)")
    parser.add_argument("output_path", help="Path for the output .txt file")
    parser.add_argument("topic_name", help="Ground truth topic name")
    
    args = parser.parse_args()
    
    extract_tum_trajectory(args.bag_path, args.output_path, args.topic_name)