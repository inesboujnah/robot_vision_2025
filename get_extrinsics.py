import depthai as dai
import numpy as np

with dai.Device() as device:
    calibData = device.readCalibration()
    # Get extrinsics: IMU -> Left Camera
    matrix = calibData.getImuToCameraExtrinsics(dai.CameraBoardSocket.LEFT)
    
    print("IMU.T_b_c1: !!opencv-matrix")
    print("   rows: 4")
    print("   cols: 4")
    print("   dt: f")
    print("   data: [", end="")
    flat = np.array(matrix).flatten()
    for i, val in enumerate(flat):
        if i % 4 == 0 and i != 0: print("\n          ", end="")
        print(f"{val:.8f}", end=", " if i != len(flat)-1 else "")
    print("]")
