import logging
import sys
import time

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)

logging.info("Python logger started.")

i = 0
while True:
    logging.info(f"Heartbeat {i}")
    i += 1
    time.sleep(5)  # every 5 seconds
