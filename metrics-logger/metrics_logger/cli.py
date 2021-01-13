import sys

from metrics_logger import daemon


def main():
    if sys.argv[1] == "start_daemon":
        print('Starting metrics_logger daemon')
        daemon.start()
    else:
        raise Exception("Invalid args")
