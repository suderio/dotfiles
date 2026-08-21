import time
import numpy as np
import cv2
import os
import steganography

def create_worst_case_image(filename, width, height):
    img = np.random.randint(0, 128, (height, width, 3), dtype=np.uint8) * 2
    img[height-1, width-1, 2] = 1
    cv2.imwrite(filename, img)

def main():
    dummy_img_path = "worst_case_image.png"

    print("Generating worst-case dummy image...")
    # 200 rows, 10000 columns = 2 million pixels
    create_worst_case_image(dummy_img_path, 10000, 200)

    print("Running benchmark (decoding)...")
    iterations = 5
    times = []

    for _ in range(iterations):
        start_time = time.time()
        try:
            decoded_msg = steganography.decode(dummy_img_path)
        except Exception:
            pass
        end_time = time.time()
        times.append(end_time - start_time)

    avg_time = sum(times) / len(times)
    print(f"Benchmark finished. Average decode time over {iterations} runs: {avg_time:.4f} seconds")

    os.remove(dummy_img_path)

if __name__ == "__main__":
    main()
