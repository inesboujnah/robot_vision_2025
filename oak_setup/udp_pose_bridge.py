#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import PoseStamped
import socket
import json

# Configuration
LISTEN_IP = "127.0.0.1"
LISTEN_PORT = 55555
ROS_TOPIC = "/robot/ground_truth"
FRAME_ID = "world"

class UdpPoseBridge(Node):
    def __init__(self):
        super().__init__('udp_pose_bridge')
        
        # Create Publisher
        self.publisher_ = self.create_publisher(PoseStamped, ROS_TOPIC, 10)
        
        # Create UDP Socket
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Set timeout to allow ROS spin loop to continue
        self.sock.settimeout(0.01) 
        
        try:
            self.sock.bind((LISTEN_IP, LISTEN_PORT))
            self.get_logger().info(f"Bridge started. Listening on {LISTEN_IP}:{LISTEN_PORT}")
        except OSError as e:
            self.get_logger().error(f"Failed to bind port: {e}")
            return

        # Check for data frequently
        self.timer = self.create_timer(0.01, self.check_udp)

    def check_udp(self):
        try:
            # Receive Data
            data, addr = self.sock.recvfrom(1024)
            packet = json.loads(data.decode())
            
            # Extract data
            t_raw = packet["t"]          
            p = packet["pose"]           # [x, y, z, qx, qy, qz, qw]

            msg = PoseStamped()

            # --- TIMESTAMP HANDLING ---
            # Assumption: t_raw is Unix Epoch Seconds.
            seconds = int(t_raw)
            nanoseconds = int((t_raw - seconds) * 1e9)
            
            msg.header.stamp.sec = seconds
            msg.header.stamp.nanosec = nanoseconds
            msg.header.frame_id = FRAME_ID
            
            # Position
            msg.pose.position.x = float(p[0])
            msg.pose.position.y = float(p[1])
            msg.pose.position.z = float(p[2])
            
            # Orientation
            msg.pose.orientation.x = float(p[3])
            msg.pose.orientation.y = float(p[4])
            msg.pose.orientation.z = float(p[5])
            msg.pose.orientation.w = float(p[6])
            
            self.publisher_.publish(msg)

        except socket.timeout:
            pass # No data this cycle
        except Exception as e:
            self.get_logger().error(f"Error processing packet: {e}")

    def destroy_node(self):
        self.sock.close()
        super().destroy_node()

def main(args=None):
    rclpy.init(args=args)
    node = UdpPoseBridge()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()