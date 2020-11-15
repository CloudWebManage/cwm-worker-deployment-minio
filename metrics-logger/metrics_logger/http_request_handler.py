import json
import traceback

from http.server import BaseHTTPRequestHandler

from metrics_logger import config


class MetricsLoggerHTTPRequestHandler(BaseHTTPRequestHandler):

    def _parse_request_data(self):
        try:
            content_length = self.headers.get('content-length') or 0
            if content_length:
                return json.loads(self.rfile.read(int(content_length)).decode())
        except:
            if config.DEBUG:
                traceback.print_exc()
        return {}

    def do_POST(self):
        data = self._parse_request_data()
        self.server.metrics_manager.set_deployment_metrics(data, self.log_message)
        self.send_response(200)
        self.end_headers()

    def log_request(self, code='-', size='-'):
        pass
