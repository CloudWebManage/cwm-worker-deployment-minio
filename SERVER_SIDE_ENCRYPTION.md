# Server Side Encryption

- [Overview](#overview)
- [Configuration](#configuration)
  - [Generate TLS private key and certificate for KES Server](#generate-tls-private-key-and-certificate-for-kes-server)
  - [Generate TLS private key and certificate for MinIO](#generate-tls-private-key-and-certificate-for-minio)
  - [Configuration File of KES Server](#configuration-file-of-kes-server)
  - [Start the KES Server](#start-the-kes-server)
  - [Create the key](#create-the-key)
  - [Start the MinIO Server](#start-the-minio-server)
- [Docker Compose](#docker-compose)

## Overview

This document discusses how to configure the server side encryption (SSE) for
MinIO with the recommended configuration i.e.
[SSE-KMS](https://docs.min.io/minio/baremetal/security/server-side-encryption/minio-server-side-encryption.html).

SSE-KMS provides integrations with the following external KMSes:

- [AWS SecretsManager](https://docs.min.io/minio/baremetal/security/server-side-encryption/configure-minio-kes-aws.html#minio-sse-aws)
- [Google Cloud SecretManager](https://docs.min.io/minio/baremetal/security/server-side-encryption/configure-minio-kes-gcp.html#minio-sse-gcp)
- [Azure Key Vault](https://docs.min.io/minio/baremetal/security/server-side-encryption/configure-minio-kes-azure.html#minio-sse-azure)
- [HashiCorp KeyVault](https://docs.min.io/minio/baremetal/security/server-side-encryption/configure-minio-kes-hashicorp.html#minio-sse-vault)

However, for simplicity, this document uses this official guide
[MinIO Object Storage](https://github.com/minio/kes/wiki/MinIO-Object-Storage)
that uses filesystem as its keystore.

Following is the pictorial representation of the recommended configuration:

```text
╔═══════════════════════════════════════╗ 
║ ┌───────────┐          ┌────────────┐ ║        ┌─────────┐
║ │   MinIO   ├──────────┤ KES Server ├─╫────────┤   KMS   │
║ └───────────┘          └────────────┘ ║        └─────────┘
╚═══════════════════════════════════════╝
```

The KMS part is omitted in this document. It can be configured later according
to the KMS by following above listed guides. While configuring an external KMS,
[cache](https://github.com/minio/kes/wiki/Configuration#cache-configuration) may
also be configured to set the TTL for keys and cache refresh accordingly.

## Configuration

For SSE, MinIO and KES are required to communicate over mTLS.
MinIO will act as a client while talking with the KES server.

For simplicity, both KES Server and MinIO will be using self-signed certificates.

### Generate TLS private key and certificate for KES Server

To generate the TLS private key and certificate for the kes server, run the
following command:

```shell
kes tool identity new --server --key server.key --cert server.cert --ip '127.0.0.1' --dns 'localhost'
```

The private key and certificate (`server.key` and `server.cert`) for KES server
will be generated for IP address `127.0.0.1` and DNS `localhost`.

For `docker-compose`, the DNS `localhost` should be the name of the service that
the network configuration may be able to resolve e.g. `minio-kes`.

The command will be changed accordingly:

```shell
kes tool identity new --server --key server.key --cert server.cert --ip '127.0.0.1' --dns 'minio-kes'
```

### Generate TLS private key and certificate for MinIO

Run this command to generate the TLS private and certificate:

```shell
kes tool identity new --key minio.key --cert minio.cert MinIO
```

The private key and certificate (`minio.key` and `minio.cert`) will be
generated.

### Configuration File of KES Server

Following minimal configuration file (`server-config.yml`) will be used to run
KES server:

```yml
address: 0.0.0.0:7373

admin:
  identity: disabled # We disable the root identity since we don't need it in this guide

tls:
  key : server.key
  cert: server.cert

policy:
  minio:
    allow:
    - /v1/key/create/minio-key
    - /v1/key/generate/minio-key
    - /v1/key/decrypt/minio-key
    identities:
    - ${MINIO_IDENTITY}

keystore:
  fs:
    path: ./keys # Choose a location for your secret keys

log:
  error: on
  audit: on
```

For more detailed and granular configuration, please see the official section on
the [Configuration File](https://github.com/minio/kes/wiki/Configuration#config-file).

Depending on the KES server deployment e.g. single KES server for the whole
cluster or one KES server per MinIO deployment, the KES server policies may be
configured accordingly. Instead of hardcoding the key inside the configuration
file, the glob patterns may also be used. For more details on policies and glob
patterns, see [Policy Configuration](https://github.com/minio/kes/wiki/Configuration#policy-configuration).

### Start the KES Server

Start the server with the configuration file and `--auth off` because the
self-signed certificates are being used:

```shell
export MINIO_IDENTITY=$(kes tool identity of minio.cert)

kes server --config server-config.yml --auth off
```

### Create the key

From another terminal, create the allowed key (`minio-key`) with `kes` CLI:

```shell
export KES_CLIENT_CERT='minio.cert'
export KES_CLIENT_KEY='minio.key'

kes key create -k 'minio-key'
```

This step assumes that `kes server` is already up and running. Here, the `kes`
CLI is working as a `kes` **client** using the TLS private key and certificate
created for MinIO.

The key file (`minio-key`) should be created after this step and it should be
under `./keys` directory.

### Start the MinIO Server

Set the KMS KES environment variables:

```shell
export MINIO_KMS_KES_ENDPOINT='https://127.0.0.1:7373'
export MINIO_KMS_KES_CERT_FILE='minio.cert'
export MINIO_KMS_KES_KEY_FILE='minio.key'
export MINIO_KMS_KES_CAPATH='server.cert'
export MINIO_KMS_KES_KEY_NAME='minio-key'
```

Now, start MinIO:

```shell
export MINIO_ROOT_USER=minio
export MINIO_ROOT_PASSWORD=minio123

minio server ./data
```

For CWM MinIO instances, the auto encryption will be used. The auto encryption
can be turned on or off via `MINIO_KMS_AUTO_ENCRYPTION=on|off`.

The configuration with auto encryption will be:

```shell
export MINIO_KMS_AUTO_ENCRYPTION='on'
export MINIO_KMS_KES_ENDPOINT='https://127.0.0.1:7373'
export MINIO_KMS_KES_CERT_FILE='minio.cert'
export MINIO_KMS_KES_KEY_FILE='minio.key'
export MINIO_KMS_KES_CAPATH='server.cert'
export MINIO_KMS_KES_KEY_NAME='minio-key'
```

## Docker Compose

Putting it all together via `docker-compose`, we can configure and test it
locally. See [docker-compose-sse.yaml](./docker-compose-sse.yaml) for more
details.

See [minio-kes](./minio-kes) for the custom KES server:

- [Dockerfile](./minio-kes/Dockerfile): The custom Dockerfile uses the official
  docker [image](https://hub.docker.com/layers/minio/kes/v0.17.6/images/sha256-35cd78f86c858ab5a0bac879518f0b04be3a1327de9b774178cbacde4cb75f50).
- [init.sh](minio-kes/init.sh): The init script automates the generation of the
  TLS private keys and certificates both for KES server and MinIO. It sets up
  the configuration file and starts the server.
- [server-config.yaml](./minio-kes/server-config.yaml): The KES server's
  configuration file contains only the required configuration.
- [test.sh](./minio-kes/test.sh): The test script is not run automatically. You
  can run it to see the flow with SSE.

Start the `docker-compose` stack with
[docker-compose-sse.yaml](docker-compose-sse.yaml):

```shell
docker-compose -f docker-compose-sse.yaml up --build --abort-on-container-exit
```

Run test script on another terminal:

```shell
$ /minio-kes/test.sh 
Added `minio` successfully.
Bucket created successfully `minio/bucket`.
`test.file` -> `minio/bucket/test.file`
Total: 0 B, Transferred: 10 B, Speed: 1.50 KiB/s
Checking data with mc cat command via minio server...
---
test data
---
Checking data with cat command from storage directly...
MINIO_STORAGE_MOUNTPOINT: /var/lib/docker/volumes/cwm-worker-deployment-minio_storage/_data
---
 	��5W*�2[�S�Q񣖭������;��H/�3B�u
---
Removed `minio/bucket` successfully.
--- [DONE] ---
```

The output of the test script shows the difference between the `mc cat` and
`cat` commands. The `mc cat` command communicates with MinIO to get the contents
while the `cat` command directly accesses the filesystem and tries to print the
file.

**NOTE**: The TLS private keys and certificates are shared with `minio` via
`minio-kes` volume.
