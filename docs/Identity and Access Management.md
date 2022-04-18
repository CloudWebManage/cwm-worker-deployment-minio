# Identity and Access Management

## Using docker-compose

Start the ETCD server:

```
docker-compose up -d etcd
```

Set the following in the `.env` file:

```
MINIO_ETCD_ENDPOINTS=http://etcd:2379
```

Start the default Minio stack

```
docker-compose up --build
```

Add an mc alias

```
mc alias set minio http://localhost:8080 12345678 12345678
```

Add a user

```
mc admin user add minio testkey testsecret
```

Add an alias for that user

```
mc alias set testkey http://localhost:8080 testkey testsecret
```

Try to list buckets (this will fail with access denied)

```
./mc ls testkey
```

Set readwrite policy on the user

```
./mc admin policy set minio readwrite user=testkey
```

Try to list buckets again (will work this time)

```
./mc ls testkey
```

Restart minio server

```
docker-compose restart minio
```

User still has access

```
./mc ls testkey
```