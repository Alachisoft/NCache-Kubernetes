# NCache Kubernetes Scripts

Scripts that create a Kubernetes cluster and deploy NCache on it. There is one folder per
platform. Each folder works on its own: pick the folder for your platform, follow its README, and run
the scripts from inside that folder.

## Directory structure

```
ncache/
├── README.md                        this file: layout and ports
├── aks/                             Azure Kubernetes Service
├── eks/                             Amazon Elastic Kubernetes Service
├── gke/                             Google Kubernetes Engine
├── kubernetes/                      on-premises Kubernetes (kubeadm, Calico, MetalLB)
└── outproc-client/                  optional: out-of-proc client cache and a sample app, on any platform
```

Every platform folder has the same files:

```
<platform>/
├── README.md                        what each file does, the commands to run, and VM / machine sizes
├── create-cluster.sh                1. creates the cluster and connects kubectl to it
├── deploy-ncache.sh                 2. installs NCache with the NCache Helm chart
├── ncache.yaml                      NCache without Helm (StatefulSet, RBAC, ConfigMap, headless Service)
├── client-gatewayservice.yaml       load balancer that NCache clients connect through
└── mgmt-gatewayservice.yaml         load balancer for the Management Center and Cloud Portal
```

| Folder | `create-cluster.sh` creates | Load balancers come from |
|---|---|---|
| [aks](aks/README.md) | AKS cluster in a new resource group | Azure Standard load balancer |
| [eks](eks/README.md) | EKS cluster and node group in an existing VPC | AWS Load Balancer Controller (installed by the script) |
| [gke](gke/README.md) | GKE Standard cluster in the project's default network | Google Cloud load balancer |
| [kubernetes](kubernetes/README.md) | kubeadm cluster on your Ubuntu machines (run on every node) | MetalLB (installed by the script) |

[outproc-client](outproc-client/README.md) has no cluster script. Apply it to a cluster that already runs NCache.

## Two ways to deploy NCache

- **Helm:** `deploy-ncache.sh` installs the NCache Helm chart. The chart creates NCache and both gateways.
- **YAML:** `kubectl apply -f ncache.yaml -f client-gatewayservice.yaml -f mgmt-gatewayservice.yaml`.
  The gateway files in each folder match what the Helm chart creates on that platform.

Use one or the other on a cluster, not both.

## Ports

| Gateway | Ports | Used by |
|---|---|---|
| `ncache-client-gateway` | 9800, 9803-9997 (EKS: 9803-9849) | NCache client applications |
| `ncache-mgmt-gateway` | 9801, 9802 | NCache Management Center |
| | 9998, 9999 | NCache Cloud Portal |

EKS uses a smaller range because an AWS Network Load Balancer allows 50 listeners by default.
