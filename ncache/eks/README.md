# NCache on EKS

Creates an EKS (Amazon Elastic Kubernetes Service) cluster and deploys NCache on it.

| File | What it does |
|---|---|
| `create-cluster.sh` | Creates the EKS cluster and its node group in an existing VPC with an existing IAM role, connects `kubectl` to it, tags the subnets and installs the AWS Load Balancer Controller. |
| `deploy-ncache.sh` | Installs NCache on the cluster with the NCache Helm chart, including the gateway load balancers. |
| `ncache.yaml` | NCache without Helm: StatefulSet, service account and permissions, `ncache-store` ConfigMap and the headless `ncache-cacheserver` Service. |
| `client-gatewayservice.yaml` | Internal AWS Network Load Balancer for NCache clients (ports 9800, 9803-9849; 48 listeners, under the default quota of 50). |
| `mgmt-gatewayservice.yaml` | Internet-facing AWS Network Load Balancer for the Management Center (9801, 9802) and the Cloud Portal (9998, 9999). |

## What the scripts do

### `create-cluster.sh`

1. **Sign in:** none; it uses the AWS CLI credentials you already have.
2. **IAM role:** looks up the role named in `IAM_ROLE`.
3. **Cluster:** creates the EKS cluster in your VPC and subnets, unless it already exists. Takes 10-15 minutes.
4. **Nodes:** creates the `ncache-nodes` node group with `NODE_COUNT` nodes of type `NODE_TYPE`. Takes 3-5 minutes.
5. **kubectl:** connects `kubectl` to the new cluster.
6. **Subnet tags:** tags your subnets so AWS can place load balancers in them.
7. **Load balancer controller:** installs the AWS Load Balancer Controller with Helm; it creates the AWS load balancers.
8. **Check:** lists the nodes.

### `deploy-ncache.sh`

1. Checks that you gave the platform, that `NCACHE_KEY` is set and that `helm` is installed.
2. Installs NCache with the NCache Helm chart (version 5.3.8), using your key and the platform.
3. The chart creates 2 NCache servers, each on a different node, and the two gateway load balancers:
   - client gateway: internal AWS Network Load Balancer (reachable inside your VPC)
   - management gateway: internet-facing AWS Network Load Balancer

## Run

1. Set `CLUSTER_NAME`, `REGION`, `VPC_ID`, `SUBNET_IDS`, `IAM_ROLE`, `NODE_COUNT` and `NODE_TYPE` ([VM sizes](#vm-sizes-node_type)) at the top of `create-cluster.sh`, then:

   ```bash
   bash create-cluster.sh
   ```

   `IAM_ROLE` must trust `eks.amazonaws.com` and `ec2.amazonaws.com`, and have `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly` and [`AWSLoadBalancerControllerIAMPolicy`](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json). You need `iam:PassRole` on it.

2. Set `NCACHE_KEY` at the top of `deploy-ncache.sh`, then:

   ```bash
   bash deploy-ncache.sh eks
   ```

Without Helm, set the license key in `ncache.yaml` and apply the three YAML files instead of step 2:

```bash
kubectl apply -f ncache.yaml -f client-gatewayservice.yaml -f mgmt-gatewayservice.yaml
```

## VM sizes (`NODE_TYPE`)

The NCache edition size (for example **ENT-8/2** = 8 GB RAM, 2 vCPUs) decides the instance size. The
"Recommended" column is from *cloud-VM-Mapping-az-aws-gke.docx*. **If the recommended size is not
available in your location, use the first size from "If not available" that is, or move the
cluster to another location.** Every alternative has the same RAM and vCPUs. `create-cluster.sh`
defaults to **ENT-8/2** (`m5.large`).

| NCache | RAM / vCPUs | Recommended | If not available |
|---|---|---|---|
| DEV-4/2, ENT-4/2 | 4 / 2 | `t3.medium` | `t3a.medium` |
| **ENT-8/2** | 8 / 2 | `m5.large` | `m6i.large`, `m6a.large`, `m5a.large`, `t3.large` |
| ENT-8/4 | 8 / 4 | `c5a.xlarge` | `c6a.xlarge`, `c6i.xlarge`, `c5.xlarge` |
| ENT-16/2 | 16 / 2 | `r5.large` | `r6i.large`, `r6a.large`, `r5a.large` |
| ENT-16/4 | 16 / 4 | `m5.xlarge` | `m6i.xlarge`, `m6a.xlarge`, `m5a.xlarge` |
| ENT-16/8 | 16 / 8 | `c5a.2xlarge` | `c6a.2xlarge`, `c6i.2xlarge`, `c5.2xlarge` |
| ENT-32/4 | 32 / 4 | `r5.xlarge` | `r6i.xlarge`, `r6a.xlarge`, `r5a.xlarge` |
| ENT-32/8 | 32 / 8 | `m5.2xlarge` | `m6i.2xlarge`, `m6a.2xlarge`, `m5a.2xlarge` |
| ENT-32/16 | 32 / 16 | `c5a.4xlarge` | `c6a.4xlarge`, `c6i.4xlarge`, `c5.4xlarge` |
| ENT-64/8 | 64 / 8 | `r5.2xlarge` | `r6i.2xlarge`, `r6a.2xlarge`, `r5a.2xlarge` |
| ENT-64/16 | 64 / 16 | `m5.4xlarge` | `m6i.4xlarge`, `m6a.4xlarge`, `m5a.4xlarge` |
| ENT-64/32 | 64 / 32 | `c5a.8xlarge` | `c6a.8xlarge`, `c6i.8xlarge` |
| ENT-128/16 | 128 / 16 | `r5.4xlarge` | `r6i.4xlarge`, `r6a.4xlarge`, `r5a.4xlarge` |
| ENT-128/32 | 128 / 32 | `m5.8xlarge` | `m6i.8xlarge`, `m6a.8xlarge`, `m5a.8xlarge` |
| ENT-128/64 | 128 / 64 | `c5a.16xlarge` | `c6a.16xlarge`, `c6i.16xlarge` |
| ENT-256/32 | 256 / 32 | `r5.8xlarge` | `r6i.8xlarge`, `r6a.8xlarge`, `r5a.8xlarge` |
| ENT-256/64 | 256 / 64 | `m5.16xlarge` | `m6i.16xlarge`, `m6a.16xlarge`, `m5a.16xlarge` |

On AWS a size is offered per **availability zone**: if it is missing from one of your subnets' zones,
use an alternative or subnets in other zones.
