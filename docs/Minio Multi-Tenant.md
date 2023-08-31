# Minio Multi-Tenant

This document describes how to use Minio multi-tenant instead of the single-tenant we used previously.

## Deploy DirectPV

```
kubectl krew install directpv
kubectl directpv install --tolerations "cwmc-role=worker:NoSchedule"
kubectl patch deployment controller -n directpv --type='json' -p='[{"op": "add", "path": "/spec/template/spec/tolerations", "value": [{"key": "cwmc-role", "operator": "Equal", "value": "worker", "effect": "NoSchedule"}]}]'
```

Wait for directpv pods to be ready

Generate drives.yaml file:

```
kubectl directpv discover
```

Review the file and apply it - be careful, this will delete all the data on those drives:

```
kubectl directpv init drives.yaml --dangerous
```

## Deploy Minio Operator and example tenants

Set env vars:

```
GLOBAL_DOMAIN_SUFFIX=".example.com"
CLUSTER_NAME=
WORKER_NODE_EXTERNAL_IP=
CLUSTER_DOMAIN_SUFFIX=".${CLUSTER_NAME}-admin${GLOBAL_DOMAIN_SUFFIX}"
SIMPLE_TENANT_ROOT_USER=
SIMPLE_TENANT_ROOT_PASSWORD=
SIMPLE_TENANT_USER_USER=
SIMPLE_TENANT_USER_PASSWORD=
COMPLEX_TENANT_ROOT_USER=
COMPLEX_TENANT_ROOT_PASSWORD=
COMPLEX_TENANT_USER_USER=
COMPLEX_TENANT_USER_PASSWORD=
```

Set DNS:

```
cwm-worker-cluster route53 set-cloudwm-obj-subdomain-a-record minio-operator.${CLUSTER_NAME}-admin ${WORKER_NODE_EXTERNAL_IP}
cwm-worker-cluster route53 set-cloudwm-obj-subdomain-a-record minio-tenant-simple.${CLUSTER_NAME}-admin ${WORKER_NODE_EXTERNAL_IP}
cwm-worker-cluster route53 set-cloudwm-obj-subdomain-a-record minio-tenant-simple-console.${CLUSTER_NAME}-admin ${WORKER_NODE_EXTERNAL_IP}
cwm-worker-cluster route53 set-cloudwm-obj-subdomain-a-record minio-tenant-complex.${CLUSTER_NAME}-admin ${WORKER_NODE_EXTERNAL_IP}
cwm-worker-cluster route53 set-cloudwm-obj-subdomain-a-record minio-tenant-complex-console.${CLUSTER_NAME}-admin ${WORKER_NODE_EXTERNAL_IP}
```

Create tenants configuration:

```
echo "
tenants:
  - name: simple
    root_user: $SIMPLE_TENANT_ROOT_USER
    root_password: $SIMPLE_TENANT_ROOT_PASSWORD
    storage_class_standard: 'EC:0'
    domain_suffix: $CLUSTER_DOMAIN_SUFFIX
    user_user: $SIMPLE_TENANT_USER_USER
    user_password: $SIMPLE_TENANT_USER_PASSWORD
  - name: complex
    root_user: $COMPLEX_TENANT_ROOT_USER
    root_password: $COMPLEX_TENANT_ROOT_PASSWORD
    storage_class_standard: 'EC:2'
    domain_suffix: $CLUSTER_DOMAIN_SUFFIX
    user_user: $COMPLEX_TENANT_USER_USER
    user_password: $COMPLEX_TENANT_USER_PASSWORD
" > helm-minio-mt/values-tenants.yaml
```

Run the following while connected to the relevant cluster:

```
kubectl create ns simple
kubectl create ns complex
helm dependency update helm-minio-mt
helm upgrade --install minio-mt helm-minio-mt --namespace minio-operator --create-namespace \
    --set operator.console.ingress.host=minio-operator${CLUSTER_DOMAIN_SUFFIX} \
    --set operator.console.ingress.tls[0].hosts[0]=minio-operator${CLUSTER_DOMAIN_SUFFIX} \
    --set operator.console.ingress.tls[0].secretName=console-tls \
    --values helm-minio-mt/values-tenants.yaml
```

## Login to Minio Operator Console

Get the JWT Token:

```
kubectl -n minio-operator  get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode
```

Login at https://minio-operator.CLUSTER_NAME-admin.cloudwm-obj.com

## Login to the tenants

```
echo "
-- Simple --

https://minio-tenant-simple.${CLUSTER_NAME}-admin${GLOBAL_DOMAIN_SUFFIX}

root user:
${SIMPLE_TENANT_ROOT_USER}
${SIMPLE_TENANT_ROOT_PASSWORD}

tenant user:
${SIMPLE_TENANT_USER_USER}
${SIMPLE_TENANT_USER_PASSWORD}

-- Complex --

https://minio-tenant-complex.${CLUSTER_NAME}-admin${GLOBAL_DOMAIN_SUFFIX}

root user:
${COMPLEX_TENANT_ROOT_USER}
${COMPLEX_TENANT_ROOT_PASSWORD}

tenant user:
${COMPLEX_TENANT_USER_USER}
${COMPLEX_TENANT_USER_PASSWORD}
"
```
