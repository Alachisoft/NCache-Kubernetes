# NCache Open Source on Kubernetes

Deploys NCache Open Source servers on any Kubernetes cluster with plain YAML files.

| File | What it does |
|---|---|
| `ncache.yaml` | `ncache` StatefulSet with 2 NCache Open Source servers (`alachisoft/ncache:5.3.603-oss`). |
| `discoveryservice.yaml` | Headless `cacheserver` Service. Pods get new IP addresses when they start, so clients in the cluster find the cache servers through it. |

## Run

```bash
kubectl apply -f ncache.yaml -f discoveryservice.yaml
```

These are quick-start files. Adjust CPU and memory requests, persistent volumes and so on to your workload.
