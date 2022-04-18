# Parquet Format

The uncompressed [Parquet](https://en.wikipedia.org/wiki/Apache_Parquet) format
is also supported but it not enabled by default since a crafted input with
hostile intention can easily crash the server. Also, it may not be fully supported
see [this comment](https://github.com/minio/minio/issues/14016#issuecomment-1003582156).
However, it can be enabled by setting the environment variable
`MINIO_API_SELECT_PARQUET=on`.

For development with [`docker-compose`](#using-docker-compose) or
[`docker-compose-gateway*`](#gateway-mode), enable it like this via `.env` file:

```text
MINIO_API_SELECT_PARQUET=on
```

For development with [helm](#using-helm), you can enable the Parquet format via
`.value.yaml` file like this:

```yaml
minio:
  # ...
  enableParquetFormat: true
```

For MinIO client (`mc`), `mc sql` subcommand can be used.
You need to create alias with `--api s3v4` like this:

```shell
./mc alias set minio http://localhost:8080 12345678 12345678 --api s3v4
```

For the detailed help and syntax for SELECT queries, follow these links:

- [`mc sql` command](https://docs.min.io/docs/minio-client-complete-guide#sql)
- [AWS S3 SELECT Command](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-glacier-select-sql-reference-select.html)
