# NCache Kubernetes

This repository contains scripts and YAML files for deploying NCache on Kubernetes: Azure Kubernetes
Service (AKS), Amazon Elastic Kubernetes Service (EKS), Google Kubernetes Engine (GKE) and on-premises
Kubernetes.

| Edition | Directory | Docker image |
|---|---|---|
| NCache | [ncache/](ncache/README.md) | `alachisoft/ncache:5.3.800` |
| NCache Open Source (OSS) | [ncache-oss/](ncache-oss/README.md) | `alachisoft/ncache:5.3.603-oss` |

## Repository structure

```
.
├── README.md                          this file
├── ncache/                            NCache
│   ├── README.md                      folder layout, Helm vs YAML, ports
│   ├── aks/                           create an AKS cluster, deploy NCache on it
│   ├── eks/                           create an EKS cluster, deploy NCache on it
│   ├── gke/                           create a GKE cluster, deploy NCache on it
│   ├── kubernetes/                    build an on-premises cluster (kubeadm, Calico, MetalLB), deploy NCache on it
│   └── outproc-client/                optional: out-of-proc client cache and a sample app
└── ncache-oss/                        NCache Open Source: YAML files for any Kubernetes cluster
```

Every folder has a README that says what each file does and which commands to run.

## Quick start

**NCache:** open the folder for your platform under [ncache/](ncache/README.md) and run its two
scripts in order, for example on AKS:

```bash
cd ncache/aks
```

```bash
bash create-cluster.sh
```

```bash
bash deploy-ncache.sh aks
```

**NCache Open Source:**

```bash
kubectl apply -f ncache-oss/ncache.yaml -f ncache-oss/discoveryservice.yaml
```

### NOTE
These are basic sample files to set up NCache in a Kubernetes cluster quickly. You might need to adjust
settings such as the [CPU](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-that-is-too-big-for-your-nodes)
and [memory](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/#specify-a-memory-request-that-is-too-big-for-your-nodes)
of your cache server pods, or [persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/),
to your workload and business needs.

## Related Repos
- [alachisoft/ncache](https://hub.docker.com/r/alachisoft/ncache) for NCache Docker Images
- [Alachisoft/NCache-Docker](https://github.com/Alachisoft/NCache-Docker) for NCache Dockerfiles