import time
import redis
import datetime

from metrics_logger import config


class MetricsManager():

    def __init__(self):
        print("initializing metrics_logger REDIS_HOST={} REDIS_PORT={}".format(config.REDIS_HOST, config.REDIS_PORT))
        self.redis_pool = redis.BlockingConnectionPool(
            max_connections=config.REDIS_POOL_MAX_CONNECTIONS, timeout=config.REDIS_POOL_TIMEOUT,
            host=config.REDIS_HOST, port=config.REDIS_PORT
        )
        ready = False
        while not ready:
            r = redis.Redis(connection_pool=self.redis_pool)
            if r.ping():
                ready = True
            r.close()
            time.sleep(.01)
        self.deployment_api_metrics = {}
        self.deployment_api_metrics_last_flush = datetime.datetime.now()
        print("metrics_logger initialized successfully")

    def set_deployment_last_action(self, deploymentid):
        key = "{}:{}".format(config.REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION, deploymentid)
        curdt = datetime.datetime.now()
        r = redis.Redis(connection_pool=self.redis_pool)
        try:
            lastval = r.get(key)
            lastdt = datetime.datetime.strptime(lastval.decode(), "%Y%m%dT%H%M%S.%f") if lastval else None
            if not lastdt or (curdt - lastdt).total_seconds() >= config.UPDATE_GRACE_PERIOD_SECONDS:
                if config.DEBUG:
                    print("Setting last action")
                r.set(key, curdt.strftime("%Y%m%dT%H%M%S.%f"))
        finally:
            r.close()

    def set_deployment_api_metrics(self, log_message, deploymentid, api_name, request_content_length, response_content_length, response_is_cached):
        if api_name in ['WebUpload', 'PutObject', 'DeleteObject']:
            request_type = 'in'
        elif api_name in ['WebDownload', 'GetObject']:
            request_type = 'out'
        else:
            request_type = 'misc'
        if config.DEBUG:
            log_message('%s.%s: (type=%s, req_size=%s, res_size=%s, res_cache=%s)', deploymentid, api_name, request_type, request_content_length, response_content_length, response_is_cached)
        metrics = self.deployment_api_metrics.setdefault(deploymentid, {
            'bytes_in': 0, 'bytes_out': 0,
            'num_requests_in': 0, 'num_requests_out': 0, 'num_requests_misc': 0
        })
        metrics['bytes_in'] += request_content_length
        metrics['bytes_out'] += response_content_length
        metrics['num_requests_{}'.format(request_type)] += 1

    def flush_deployment_api_metrics(self):
        if len(self.deployment_api_metrics) == 0:
            return
        if (datetime.datetime.now() - self.deployment_api_metrics_last_flush).total_seconds() < config.DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS:
            return
        if config.DEBUG:
            print("Flushing deployment api metrics")
        r = redis.Redis(connection_pool=self.redis_pool)
        try:
            pipe = r.pipeline()
            for deploymentid, metrics in self.deployment_api_metrics.items():
                for metric, value in metrics.items():
                    if value > 0:
                        pipe.incrby('{}:{}:{}'.format(config.REDIS_KEY_PREFIX_DEPLOYMENT_API_METRIC, deploymentid, metric), value)
            pipe.execute()
            self.deployment_api_metrics = {}
            self.deployment_api_metrics_last_flush = datetime.datetime.now()
        finally:
            r.close()

    def set_deployment_metrics(self, data, log_message):
        deploymentid = data.get('deploymentid')
        if not deploymentid:
            if config.DEBUG:
                log_message('missing deploymentid: %s', data)
            return
        self.set_deployment_last_action(deploymentid)
        api_data = data.get('api')
        if not api_data:
            if config.DEBUG:
                log_message('missing api: %s', data)
            return
        api_name = api_data.get('name')
        response_header_data = data.get('responseHeader')
        if not response_header_data:
            if config.DEBUG:
                log_message('missing responseHeader: %s', data)
            return
        try:
            response_content_length = int(response_header_data.get('Content-Length'))
        except:
            response_content_length = 0
        response_content_length += len(str(response_header_data))
        response_is_cached = response_header_data.get('X-Cache') == 'HIT'
        request_header_data = data.get('requestHeader')
        if not request_header_data:
            if config.DEBUG:
                log_message('missing requestHeader: %s', data)
            return
        try:
            request_content_length = int(request_header_data.get('Content-Length'))
        except:
            request_content_length = 0
        request_content_length += len(str(request_header_data))
        self.set_deployment_api_metrics(log_message, deploymentid, api_name, request_content_length, response_content_length, response_is_cached)
