import time
import socket
import sys
from port_scanner import scan_ports


def main():
    target = "127.0.0.1"
    ports = range(1, 1000)

    start = time.time()
    scan_ports(target, ports)
    end = time.time()

    print(f"Optimized Time taken: {end - start:.4f} seconds")


if __name__ == "__main__":
    main()
