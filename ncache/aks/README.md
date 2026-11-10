# NCache on AKS

Creates an AKS (Azure Kubernetes Service) cluster and deploys NCache on it.

| File | What it does |
|---|---|
| `create-cluster.sh` | Signs in to Azure, creates the resource group and the AKS cluster with a Standard load balancer, and connects `kubectl` to it. |
| `deploy-ncache.sh` | Installs NCache on the cluster with the NCache Helm chart, including the gateway load balancers. |
| `ncache.yaml` | NCache without Helm: StatefulSet, service account and permissions, `ncache-store` ConfigMap and the headless `ncache-cacheserver` Service. |
| `client-gatewayservice.yaml` | Public Azure load balancer for NCache clients (ports 9800, 9803-9997). |
| `mgmt-gatewayservice.yaml` | Public Azure load balancer for the Management Center (9801, 9802) and the Cloud Portal (9998, 9999). |

## What the scripts do

### `create-cluster.sh`

1. **Sign in:** logs in to Azure, only if you are not signed in already.
2. **Resource group:** creates the resource group that holds the cluster.
3. **Cluster:** creates the AKS cluster with `NODE_COUNT` nodes of size `VM_SIZE` and a Standard load balancer. Takes 5-10 minutes.
4. **kubectl:** connects `kubectl` to the new cluster.
5. **Check:** lists the nodes.

Azure creates the load balancers itself; nothing extra is installed.

### `deploy-ncache.sh`

1. Checks that you gave the platform, that `NCACHE_KEY` is set and that `helm` is installed.
2. Installs NCache with the NCache Helm chart (version 5.3.8), using your key and the platform.
3. The chart creates 2 NCache servers, each on a different node, and the two gateway load balancers:
   - client gateway: public Azure load balancer
   - management gateway: public Azure load balancer

## Run

1. Set `CLUSTER_NAME`, `REGION`, `RESOURCE_GROUP`, `NODE_COUNT` and `VM_SIZE` ([VM sizes](#vm-sizes-vm_size)) at the top of `create-cluster.sh`, then:

   ```bash
   bash create-cluster.sh
   ```

2. Set `NCACHE_KEY` at the top of `deploy-ncache.sh`, then:

   ```bash
   bash deploy-ncache.sh aks
   ```

Without Helm, set the license key in `ncache.yaml` and apply the three YAML files instead of step 2:

```bash
kubectl apply -f ncache.yaml -f client-gatewayservice.yaml -f mgmt-gatewayservice.yaml
```

## VM sizes (`VM_SIZE`)

The NCache edition size (for example **ENT-8/2** = 8 GB RAM, 2 vCPUs) decides the VM size. The
"Recommended" column is from *cloud-VM-Mapping-az-aws-gke.docx*. **If the recommended size is not
available in your location, use the first size from "If not available" that is, or move the
cluster to another location.** Every alternative has the same RAM and vCPUs. `create-cluster.sh`
defaults to **ENT-4/2** (`Standard_B2s`).

Write sizes with the `Standard_` prefix and underscores: *D2as v5* is `Standard_D2as_v5`.

| NCache | RAM / vCPUs | Recommended | If not available |
|---|---|---|---|
| ENT-4/2 | 4 / 2 | `Standard_B2als_v2` | `Standard_B2s`, `Standard_B2ls_v2` |
| **ENT-8/2** | 8 / 2 | `Standard_D2as_v5` | `Standard_D2as_v6`, `Standard_D2s_v5`, `Standard_D2s_v6`, `Standard_D2as_v4` |
| ENT-8/4 | 8 / 4 | `Standard_D4ls_v5` | `Standard_D4als_v6`, `Standard_D4ls_v6` |
| ENT-16/2 | 16 / 2 | `Standard_E2as_v5` | `Standard_E2as_v6`, `Standard_E2s_v5`, `Standard_E2s_v6` |
| ENT-16/4 | 16 / 4 | `Standard_D4as_v5` | `Standard_D4as_v6`, `Standard_D4s_v5`, `Standard_D4s_v6` |
| ENT-16/8 | 16 / 8 | `Standard_D8ls_v5` | `Standard_D8als_v6`, `Standard_D8ls_v6` |
| ENT-32/4 | 32 / 4 | `Standard_E4as_v5` | `Standard_E4as_v6`, `Standard_E4s_v5`, `Standard_E4s_v6` |
| ENT-32/8 | 32 / 8 | `Standard_D8as_v5` | `Standard_D8as_v6`, `Standard_D8s_v5`, `Standard_D8s_v6` |
| ENT-32/16 | 32 / 16 | `Standard_D16ls_v5` | `Standard_D16als_v6`, `Standard_D16ls_v6` |
| ENT-64/8 | 64 / 8 | `Standard_E8as_v5` | `Standard_E8as_v6`, `Standard_E8s_v5`, `Standard_E8s_v6` |
| ENT-64/16 | 64 / 16 | `Standard_D16as_v5` | `Standard_D16as_v6`, `Standard_D16s_v5`, `Standard_D16s_v6` |
| ENT-64/32 | 64 / 32 | `Standard_D32ls_v5` | `Standard_D32als_v6`, `Standard_D32ls_v6` |
| ENT-128/16 | 128 / 16 | `Standard_E16as_v5` | `Standard_E16as_v6`, `Standard_E16s_v5`, `Standard_E16s_v6` |
| ENT-128/32 | 128 / 32 | `Standard_D32as_v5` | `Standard_D32as_v6`, `Standard_D32s_v5`, `Standard_D32s_v6` |
| ENT-128/64 | 128 / 64 | `Standard_D64ls_v5` | `Standard_D64als_v6`, `Standard_D64ls_v6` |
| ENT-256/32 | 256 / 32 | `Standard_E32as_v5` | `Standard_E32as_v6`, `Standard_E32s_v5`, `Standard_E32s_v6` |
| ENT-256/64 | 256 / 64 | `Standard_D64as_v5` | `Standard_D64as_v6`, `Standard_D64s_v5`, `Standard_D64s_v6` |

A subscription can refuse a size in a region ("not allowed in your subscription in location"); use
another size from the same row, or another `REGION`.

Azure can also refuse a size for **quota** ("Insufficient regional vcpu quota"). A different size does
not help then; use another `REGION` or free up vCPUs. A cluster of 2 × 2-vCPU nodes needs 4 vCPUs.
