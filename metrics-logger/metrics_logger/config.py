import os


DEBUG = os.environ.get("DEBUG") == "yes"
REDIS_HOST = os.environ.get("REDIS_HOST") or "localhost"
REDIS_PORT = int(os.environ.get("REDIS_PORT") or "6379")
REDIS_POOL_MAX_CONNECTIONS = int(os.environ.get("REDIS_POOL_MAX_CONNECTIONS") or "50")
REDIS_POOL_TIMEOUT = int(os.environ.get("REDIS_POOL_TIMEOUT") or "5")
REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION = os.environ.get("REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION") or "deploymentid:last_action"
UPDATE_GRACE_PERIOD_SECONDS = int(os.environ.get("UPDATE_GRACE_PERIOD_SECONDS") or "300")
DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS = int(os.environ.get("DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS") or "300")
REDIS_KEY_PREFIX_DEPLOYMENT_API_METRIC = os.environ.get("REDIS_KEY_PREFIX_DEPLOYMENT_API_METRIC") or 'deploymentid:minio-metrics'
