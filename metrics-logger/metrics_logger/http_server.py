from http.server import HTTPServer

from metrics_logger.http_request_handler import MetricsLoggerHTTPRequestHandler


class MetricsLoggerHTTPServer(HTTPServer):

    def __init__(self, metrics_manager):
        self.metrics_manager = metrics_manager
        super(MetricsLoggerHTTPServer, self).__init__(('0.0.0.0', 8500), MetricsLoggerHTTPRequestHandler)

    def service_actions(self):
        self.metrics_manager.flush_deployment_api_metrics()
