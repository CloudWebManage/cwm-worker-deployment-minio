import time
import uuid
import datetime
import subprocess


def wait_for_cmd(cmd, expected_returncode, ttl_seconds, error_msg, expected_output=None, extra_error_msg_cmds=None):
    start_time = datetime.datetime.now()
    while True:
        returncode, output = subprocess.getstatusoutput(cmd)
        if returncode == expected_returncode and (expected_output is None or expected_output == output):
            break
        if (datetime.datetime.now() - start_time).total_seconds() > ttl_seconds:
            print(output)
            if extra_error_msg_cmds:
                _, output = subprocess.getstatusoutput(extra_error_msg_cmds)
                print(output)
            raise Exception(error_msg)
        time.sleep(1)


def test():
    print('deleting existing deployment')
    subprocess.getstatusoutput('DEBUG= helm delete cwm-worker-deployment-minio')
    wait_for_cmd('DEBUG= kubectl get deployment/minio-server deployment/minio-nginx deployment/minio-logger',
                 1, 30, 'waited too long for minio deployment to be deleted')
    returncode, output = subprocess.getstatusoutput('DEBUG= helm upgrade --install cwm-worker-deployment-minio ./helm')
    assert returncode == 0, output
    minio_logs_commands = """
        DEBUG= kubectl describe pods
        DEBUG= kubectl logs deployment/minio-server -c http
        DEBUG= kubectl logs deployment/minio-logger -c logger
        DEBUG= kubectl logs deployment/minio-logger -c redis
        DEBUG= kubectl logs deployment/minio-nginx -c nginx
    """
    wait_for_cmd('bash -c \'[ "$(DEBUG= kubectl get pods | grep 1/1 | grep Running | wc -l)" == "2" ]\'',
                 0, 300, 'waited too long for minio deployment to be deployed',
                 extra_error_msg_cmds=minio_logs_commands)
    http_bucketname = str(uuid.uuid4())
    https_bucketname = str(uuid.uuid4())
    miniopf = subprocess.Popen('exec kubectl port-forward service/minio-nginx 8080:8080 8443:8443', shell=True)
    try:
        time.sleep(12)
        results = {'http': False, 'https': False}
        for method in ['http', 'https']:
            for try_num in [1, 2, 3]:
                print('Testing {}: attempt {} / 3'.format(method, try_num))
                time.sleep(3)
                if method == 'http':
                    returncode, output = subprocess.getstatusoutput('warp mixed --host localhost:8080 --access-key dummykey --secret-key dummypass --objects 50 --duration 0m10s --bucket {}'.format(http_bucketname))
                else:
                    returncode, output = subprocess.getstatusoutput('warp mixed --tls --insecure --host localhost:8443 --access-key dummykey --secret-key dummypass --objects 50 --duration 0m10s  --bucket {}'.format(https_bucketname))
                if returncode == 0:
                    results[method] = True
                    break
                else:
                    print('{} failed: {}'.format(method, output))
        if not results['http'] or not results['https']:
            _, logs_output = subprocess.getstatusoutput(minio_logs_commands)
            print("-- logs_output")
            print(logs_output)
            raise Exception("Failed warp")
    finally:
        miniopf.terminate()
