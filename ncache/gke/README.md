# NCache on GKE

Creates a GKE (Google Kubernetes Engine) Standard cluster and deploys NCache on it.

| File | What it does |
|---|---|
| `create-cluster.sh` | Signs in to Google Cloud, enables the GKE and Compute APIs, creates the cluster in the project's default network and connects `kubectl` to it. |
| `deploy-ncache.sh` | Installs NCache on the cluster with the NCache Helm chart, including the gateway load balancers. |
| `ncache.yaml` | NCache without Helm: StatefulSet, service account and permissions, `ncache-store` ConfigMap and the headless `ncache-cacheserver` Service. |
| `client-gatewayservice.yaml` | Internal Google Cloud load balancer for NCache clients (ports 9800, 9803-9997). |
| `mgmt-gatewayservice.yaml` | External Google Cloud load balancer for the Management Center (9801, 9802) and the Cloud Portal (9998, 9999). |

## Run

1. Set `CLUSTER_NAME`, `ZONE`, `PROJECT_ID`, `NODE_COUNT` and `MACHINE_TYPE` ([VM sizes](#vm-sizes-machine_type)) at the top of `create-cluster.sh`, then:

   ```bash
   bash create-cluster.sh
   ```

2. Set `NCACHE_KEY` at the top of `deploy-ncache.sh`, then:

   ```bash
   bash deploy-ncache.sh gke
   ```

Without Helm, set the license key in `ncache.yaml` and apply the three YAML files instead of step 2:

```bash
kubectl apply -f ncache.yaml -f client-gatewayservice.yaml -f mgmt-gatewayservice.yaml
```

## VM sizes (`MACHINE_TYPE`)

The NCache edition size (for example **ENT-8/2** = 8 GB RAM, 2 vCPUs) decides the machine size. The
"Recommended" column is from *cloud-VM-Mapping-az-aws-gke.docx*. **If the recommended size is not
available in your location, use the first size from "If not available" that is, or move the
cluster to another location.** Every alternative has the same RAM and vCPUs. `create-cluster.sh`
defaults to **ENT-8/2** (`e2-standard-2`).

The mapping document lists **`c4a`** machines. **`c4a` is Arm (Google Axion), not x86.** NCache pods
run on it only if the NCache container image has an Arm (arm64) build; confirm that before using
`c4a`. The x86 machines in "If not available" work with an x86-only image, and the script uses one
(`e2-standard-2`).

| NCache | RAM / vCPUs | Recommended | If not available (x86) |
|---|---|---|---|
| ENT-4/2 | 4 / 2 | `c4a-standard-1` (4 GB, **1** vCPU) | `e2-medium` (4 GB, 2 shared vCPUs) |
| **ENT-8/2** | 8 / 2 | `c4a-standard-2` | `e2-standard-2`, `n2d-standard-2`, `n2-standard-2` |
| ENT-8/4 | 8 / 4 | `c4a-highcpu-4` | `c2d-highcpu-4`, `c3-highcpu-4`, `c3d-highcpu-4` |
| ENT-16/2 | 16 / 2 | `c4a-highmem-2` | `e2-highmem-2`, `n2d-highmem-2`, `n2-highmem-2` |
| ENT-16/4 | 16 / 4 | `c4a-standard-4` | `e2-standard-4`, `n2d-standard-4`, `n2-standard-4` |
| ENT-16/8 | 16 / 8 | `c4a-highcpu-8` | `c2d-highcpu-8`, `c3-highcpu-8`, `c3d-highcpu-8` |
| ENT-32/4 | 32 / 4 | `c4a-highmem-4` | `e2-highmem-4`, `n2d-highmem-4`, `n2-highmem-4` |
| ENT-32/8 | 32 / 8 | `c4a-standard-8` | `e2-standard-8`, `n2d-standard-8`, `n2-standard-8` |
| ENT-32/16 | 32 / 16 | `c4a-highcpu-16` | `c2d-highcpu-16`, `c3d-highcpu-16`, `n2d-custom-16-32768` |
| ENT-64/8 | 64 / 8 | `c4a-highmem-8` | `e2-highmem-8`, `n2d-highmem-8`, `n2-highmem-8` |
| ENT-64/16 | 64 / 16 | `c4a-standard-16` | `e2-standard-16`, `n2d-standard-16`, `n2-standard-16` |
| ENT-64/32 | 64 / 32 | `c4a-highcpu-32` | `c2d-highcpu-32`, `n2d-custom-32-65536`, `n2-custom-32-65536` |
| ENT-128/16 | 128 / 16 | `c4a-highmem-16` | `e2-highmem-16`, `n2d-highmem-16`, `n2-highmem-16` |
| ENT-128/32 | 128 / 32 | `c4a-standard-32` | `e2-standard-32`, `n2d-standard-32`, `n2-standard-32` |
| ENT-128/64 | 128 / 64 | `c4a-highcpu-64` | `n2d-custom-64-131072`, `n2-custom-64-131072` |
| ENT-256/32 | 256 / 32 | `c4a-highmem-32` | `n2d-highmem-32`, `n2-highmem-32` |
| ENT-256/64 | 256 / 64 | `c4a-standard-64` | `n2d-standard-64`, `n2-standard-64` |

Note: the mapping document lists `c4a-standard-1` (1 vCPU) for ENT-4/2, which has 2 vCPUs.
On x86, Google's `highcpu` machines have 1 GB per vCPU, so the 2-GB-per-vCPU rows use `c2d-highcpu`,
`c3-highcpu` / `c3d-highcpu` or a custom type (`n2d-custom-<vCPUs>-<MB>`).

Google can also **run out of a machine type in a zone** even when it is offered there. The cluster
then stays in `PROVISIONING`, and its nodes report `ZONE_RESOURCE_POOL_EXHAUSTED` (this happened with
`n2d-standard-2` in `us-central1-a`). Use another machine type from the table, or another `ZONE`.
