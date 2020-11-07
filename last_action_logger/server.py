import os
import time
import json
import datetime
import traceback
from http.server import HTTPServer, BaseHTTPRequestHandler

import redis


REDIS_HOST = os.environ.get("REDIS_HOST") or "localhost"
REDIS_PORT = int(os.environ.get("REDIS_PORT") or "6379")
REDIS_POOL_MAX_CONNECTIONS = int(os.environ.get("REDIS_POOL_MAX_CONNECTIONS") or "50")
REDIS_POOL_TIMEOUT = int(os.environ.get("REDIS_POOL_TIMEOUT") or "5")
REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION = os.environ.get("REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION") or "deploymentid:last_action"
UPDATE_GRACE_PERIOD_SECONDS = int(os.environ.get("UPDATE_GRACE_PERIOD_SECONDS") or "300")


print("REDIS_HOST={} REDIS_PORT={}".format(REDIS_HOST, REDIS_PORT))
redis_pool = redis.BlockingConnectionPool(
    max_connections=REDIS_POOL_MAX_CONNECTIONS, timeout=REDIS_POOL_TIMEOUT,
    host=REDIS_HOST, port=REDIS_PORT
)
ready = False
while not ready:
    time.sleep(1)
    r = redis.Redis(connection_pool=redis_pool)
    if r.ping():
        ready = True
    r.close()


def redis_set_deployment_last_action(deploymentid):
    try:
        key = "{}:{}".format(REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION, deploymentid)
        curdt = datetime.datetime.now()
        r = redis.Redis(connection_pool=redis_pool)
        try:
            lastval = r.get(key)
            lastdt = datetime.datetime.strptime(lastval.decode(), "%Y%m%dT%H%M%S.%f") if lastval else None
            if not lastdt or (curdt - lastdt).total_seconds() >= UPDATE_GRACE_PERIOD_SECONDS:
                r.set(key, curdt.strftime("%Y%m%dT%H%M%S.%f"))
        finally:
            r.close()
    except:
        traceback.print_exc()


class HTTPRequestHandler(BaseHTTPRequestHandler):

    def _parse_request_data(self):
        try:
            content_length = self.headers.get('content-length') or 0
            if content_length:
                return json.loads(self.rfile.read(int(content_length)).decode())
        except:
            traceback.print_exc()
        return {}

    def do_POST(self):
        data = self._parse_request_data()
        deploymentid = data.get('deploymentid')
        if deploymentid:
            redis_set_deployment_last_action(deploymentid)
        self.send_response(200)
        self.end_headers()


HTTPServer(('0.0.0.0', 8500), HTTPRequestHandler).serve_forever()
