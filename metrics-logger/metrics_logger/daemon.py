from metrics_logger.http_server import MetricsLoggerHTTPServer
from metrics_logger.metrics_manager import MetricsManager


def start():
    MetricsLoggerHTTPServer(MetricsManager()).serve_forever()
