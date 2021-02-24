import time
import uuid
import datetime
import subprocess


def set_github_secret():
    returncode, _ = subprocess.getstatusoutput('kubectl get secret github')
    if returncode != 0:
        print("Setting github pull secret")
        returncode, output = subprocess.getstatusoutput(
            """echo '{"auths":{"docker.pkg.github.com":{"auth":"'"$(echo -n "${PACKAGES_READER_GITHUB_USER}:${PACKAGES_READER_GITHUB_TOKEN}" | base64 -w0)"'"}}}' | kubectl create secret generic github --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=/dev/stdin""")
        assert returncode == 0, output


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
    subprocess.getstatusoutput('helm delete cwm-worker-deployment-minio')
    wait_for_cmd('kubectl get deployment minio',
                 1, 30, 'waited too long for minio deployment to be deleted')
    set_github_secret()
    returncode, output = subprocess.getstatusoutput('helm upgrade --install cwm-worker-deployment-minio ./helm')
    assert returncode == 0, output
    minio_logs_commands = """
        kubectl describe pod minio-
        kubectl logs deployment/minio -c http
        kubectl logs deployment/minio -c https
        kubectl logs deployment/minio -c logger
        kubectl logs deployment/minio -c redis
    """
    wait_for_cmd('kubectl get pods | grep minio- | grep 4/4 | grep Running',
                 0, 300, 'waited too long for minio deployment to be deployed',
                 extra_error_msg_cmds=minio_logs_commands)
    http_bucketname = str(uuid.uuid4())
    https_bucketname = str(uuid.uuid4())
    miniopf = subprocess.Popen('exec kubectl port-forward service/minio 8080 8443', shell=True)
    try:
        time.sleep(15)
        http_returncode, http_output = subprocess.getstatusoutput('warp mixed --host localhost:8080 --access-key dummykey --secret-key dummypass --objects 50 --duration 0m10s --bucket {}'.format(http_bucketname))
        https_returncode, https_output = subprocess.getstatusoutput('warp mixed --tls --insecure --host localhost:8443 --access-key dummykey --secret-key dummypass --objects 50 --duration 0m10s  --bucket {}'.format(https_bucketname))
        if http_returncode != 0 or https_returncode != 0:
            _, logs_output = subprocess.getstatusoutput(minio_logs_commands)
            print("-- logs_output")
            print(logs_output)
            print("-- http_output")
            print(http_output)
            print("-- https_output")
            print(https_output)
            raise Exception("Failed warp: http_returncode={} https_returncode={}".format(http_returncode, https_returncode))
    finally:
        miniopf.terminate()
