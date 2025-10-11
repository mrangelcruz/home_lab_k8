import logging
import sys
import time
import threading

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)

logging.info("Python logger started.")

# Memory stress: grow a list over time
memory_hog = []

def memory_stress():
    while True:
        memory_hog.append("x" * 10**6)  # 1 MB per loop
        time.sleep(0.5)

# CPU stress: spin in a tight loop
def cpu_stress():
    while True:
        _ = sum(i*i for i in range(10000))

# Start stress threads
threading.Thread(target=memory_stress, daemon=True).start()
threading.Thread(target=cpu_stress, daemon=True).start()

# Logging heartbeat
i = 0
while True:
    logging.info(f"Heartbeat {i}")
    i += 1
    time.sleep(5)
