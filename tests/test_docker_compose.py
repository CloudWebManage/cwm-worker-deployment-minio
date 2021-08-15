import uuid
import time
import redis
import boto3
import pytest
import datetime
import traceback
import subprocess
from botocore.client import Config


def connect():
    start_time = datetime.datetime.now()
    http_num_requests_misc = 0
    https_num_requests_misc = 0
    while (datetime.datetime.now() - start_time).total_seconds() <= 120:
        try:
            r = redis.client.Redis()
            for key in r.keys('*'):
                r.delete(key)
            resource_kwargs = dict(aws_access_key_id='12345678',
                                   aws_secret_access_key='12345678',
                                   region_name='us-east-1',
                                   config=Config(signature_version='s3v4', connect_timeout=5, read_timeout=5))
            s3_http = boto3.resource('s3', endpoint_url='http://localhost:8080', **resource_kwargs)
            s3_https = boto3.resource('s3', endpoint_url='https://localhost:8443', verify=False, **resource_kwargs)
            list(s3_http.buckets.all())
            http_num_requests_misc += 1
            list(s3_https.buckets.all())
            https_num_requests_misc += 1
            return r, s3_http, s3_https, http_num_requests_misc, https_num_requests_misc
        except:
            print('--------- unexpected exception --------- ')
            traceback.print_exc()
            print('--------- docker-compose logs ---------')
            subprocess.check_call(['docker-compose', 'logs'])
            print('---------------------------------------')
            print("Unexpected exception, will retry in 5 seconds...")
            time.sleep(5)
    raise Exception("Failed to connect to redis or minio")


@pytest.mark.filterwarnings("ignore:Unverified HTTPS request is being made to host 'localhost'")
def test():
    r, s3_http, s3_https, http_num_requests_misc, https_num_requests_misc = connect()
    http_num_requests_in = 0
    http_num_requests_out = 0
    bucket_name = str(uuid.uuid4())
    s3_http.create_bucket(Bucket=bucket_name)
    http_num_requests_misc += 1
    with pytest.raises(Exception, match='BucketAlreadyOwnedByYou'):
        s3_https.create_bucket(Bucket=bucket_name)
    https_num_requests_misc += 1
    bucket = s3_http.Bucket(bucket_name)
    with open('LICENSE', 'rb') as f:
        bucket.put_object(Key='LICENSE1.txt', Body=f)
        bucket.put_object(Key='LICENSE2.txt', Body=f)
        http_num_requests_in += 2
    object = bucket.Object('LICENSE2.txt')
    assert object.metadata == {}
    http_num_requests_misc += 1
    object.get()['Body'].read()
    http_num_requests_out += 1
    time.sleep(6)
    assert {key.decode() for key in r.keys('*')} == {
        'deploymentid:minio-metrics:docker-compose-http:num_requests_in',
        'deploymentid:minio-metrics:docker-compose-http:num_requests_out',
        'deploymentid:minio-metrics:docker-compose-http:num_requests_misc',
        'deploymentid:minio-metrics:docker-compose-http:bytes_out',
        'deploymentid:minio-metrics:docker-compose-http:bytes_in',
        'deploymentid:last_action:docker-compose-http'
    }
    assert int(r.get(b'deploymentid:minio-metrics:docker-compose-http:num_requests_in')) == http_num_requests_in
    assert int(r.get(b'deploymentid:minio-metrics:docker-compose-http:num_requests_out')) == http_num_requests_out
    assert int(r.get(b'deploymentid:minio-metrics:docker-compose-http:num_requests_misc')) == http_num_requests_misc + https_num_requests_misc
    assert int(r.get(b'deploymentid:minio-metrics:docker-compose-http:bytes_out')) > 40
    assert int(r.get(b'deploymentid:minio-metrics:docker-compose-http:bytes_in')) > 40
