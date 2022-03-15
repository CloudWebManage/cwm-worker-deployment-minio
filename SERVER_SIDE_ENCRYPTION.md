# Server Side Encryption

The server side encryption (SSE) for MinIO with the recommended configuration
i.e. [SSE-KMS](https://docs.min.io/minio/baremetal/security/server-side-encryption/minio-server-side-encryption.html)
has been configured via [docker-compose-sse.yaml](docker-compose-sse.yaml).

Following is its pictorial representation:

```text
╔═══════════════════════════════════════╗ 
║ ┌───────────┐          ┌────────────┐ ║        ┌─────────┐
║ │   MinIO   ├──────────┤ KES Server ├─╫────────┤   KMS   │
║ └───────────┘          └────────────┘ ║        └─────────┘
╚═══════════════════════════════════════╝
```

For `docker-compose-sse.yaml`, this official guide
[MinIO Object Storage](https://github.com/minio/kes/wiki/MinIO-Object-Storage)
has been followed with filesystem configured as its keystore.

Here are a few important points:

- For SSE, MinIO and KES are required to communicate over mTLS.
- MinIO will act as a client while talking with the KES server.
- For simplicity, both KES Server and MinIO use self-signed certificates.
- The [minio-kes/init.sh](./minio-kes/init.sh) script takes care of the
  generation of TLS private keys and certificates before running the KES server.
- The generated private keys and certificates are shared via `minio-kes` volume
  with `minio` service.
- The encryption key configured for `minio` via `MINIO_KMS_KES_KEY_NAME`
  environment variable is automatically created by the KES server on startup and
  is configured in
  [minio-kes/server-config.yaml](./minio-kes/server-config.yaml) under `keys`
  section.
- With `MINIO_KMS_AUTO_ENCRYPTION: "on"`, the en/decryption works automatically.

## Test with docker-compose

Start the `docker-compose` stack with
[docker-compose-sse.yaml](docker-compose-sse.yaml):

```shell
docker-compose -f docker-compose-sse.yaml up --build --abort-on-container-exit
```

On a different terminal, create alias:

```shell
mc alias set minio http://localhost:8080 12345678 12345678
```

Create a bucket:

```shell
mc mb minio/bucket
```

Create and upload a test file:

```shell
echo 'test data' > test.file
mc mv test.file minio/bucket
```

Check the stat of uploaded file (observe under **Encrypted** heading):

```shell
$ mc stat minio/bucket/test.file
mc stat minio/bucket/test.file
Name      : test.file
Date      : 2022-01-30 19:14:37 PKT 
Size      : 10 B   
ETag      : 332fc6a1a727454147566176ac7f98db 
Type      : file 
Metadata  :
  Content-Type: application/octet-stream 
Encrypted :
  X-Amz-Server-Side-Encryption               : aws:kms 
  X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id: minio 
```

The last section of the above output i.e.

```text
Encrypted :
  X-Amz-Server-Side-Encryption               : aws:kms 
  X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id: minio 
```

means that the object is encrypted.

Check the content of uploaded file:

```shell
$ mc cat minio/bucket/test.file
test data
```

Now, to make sure that the encryption is actually working, check the contents of
the uploaded object by using `cat` command via `minio:storage` volume:

```shell
MINIO_STORAGE_MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' cwm-worker-deployment-minio_storage)
sudo cat "$MINIO_STORAGE_MOUNTPOINT/bucket/test.file"
```

The output of the `cat` command should be encrypted and not visible at all.

**NOTE**: The [minio-kes/test.sh](./minio-kes/test.sh) script has also been
provided that automates all the above steps.
