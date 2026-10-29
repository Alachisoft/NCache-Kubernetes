# About
This repository contains YAML configuration files for deploying NCache in Kubernetes and Kubernetes based cloud services e.g. AKS, EKS.

Files are provided for both NCache editions:

| Edition | Directory | Docker image |
|---|---|---|
| NCache Enterprise | [ncache/](ncache/) | `alachisoft/ncache:5.3.800` |
| NCache Open Source (OSS) | [ncache-oss/](ncache-oss/) | `alachisoft/ncache:5.3.603-oss` |

Click any file name below to open it directly.

# NCache Enterprise
Directory: [ncache/](ncache/)

## Cache Server
| File | Description |
|---|---|
| [ncache.yaml](ncache/ncache.yaml) | Deploys the NCache servers as a `StatefulSet`, along with the `ServiceAccount`, `ClusterRole` / `ClusterRoleBinding`, `ConfigMap` and the headless `ncache-cacheserver` service that clients use to discover the cache servers. Pod anti-affinity is **required** by default, so each cache server runs on a separate node. Set `NC_LICENSE_KEY` (or the evaluation key `NC_KEY`) before deploying. |

## Gateway Services
Gateway services expose NCache outside of the Kubernetes cluster. Choose the folder that matches your platform:

| Platform | Client gateway | Management gateway |
|---|---|---|
| Azure Kubernetes Service (AKS) | [AKS/client-gatewayservice.yaml](ncache/AKS/client-gatewayservice.yaml) | [AKS/mgmt-gatewayservice.yaml](ncache/AKS/mgmt-gatewayservice.yaml) |
| Amazon Elastic Kubernetes Service (EKS) | [EKS/client-gatewayservice.yaml](ncache/EKS/client-gatewayservice.yaml) | [EKS/mgmt-gatewayservice.yaml](ncache/EKS/mgmt-gatewayservice.yaml) |
| On-premises Kubernetes (MetalLB) | [Kubernetes/client-gatewayservice.yaml](ncache/Kubernetes/client-gatewayservice.yaml) | [Kubernetes/mgmt-gatewayservice.yaml](ncache/Kubernetes/mgmt-gatewayservice.yaml) |

- **Client gateway** (`ncache-client-gateway`): exposes the client ports (9800, 9803+) so applications outside the cluster can connect to the cache.
- **Management gateway** (`ncache-mgmt-gateway`): exposes the NCache Management Center (9801, 9802) and Cloud Portal (9998, 9999).

## OutProc Client (optional)
| File | Description |
|---|---|
| [ncache-client-outproc.yaml](ncache/ncache-client-outproc.yaml) | Deploys an NCache out-of-proc client cache (`ncache-client`) inside the cluster, connecting to an NCache server. |
| [app.yaml](ncache/app.yaml) | Sample application (`myapp`) that connects to the out-of-proc client cache. |
| [.env](ncache/.env) | Variables (`IMAGE_REPOSITORY`, `IMAGE_TAG`, `NCACHE_KEY`, `APP_IMAGE`) substituted into the OutProc client YAML files. |

## Usage
```bash
kubectl apply -f ncache/ncache.yaml
```

Then apply the gateway services for your platform, e.g. for AKS:
```bash
kubectl apply -f ncache/AKS/client-gatewayservice.yaml
kubectl apply -f ncache/AKS/mgmt-gatewayservice.yaml
```

# NCache Open Source (OSS)
Directory: [ncache-oss/](ncache-oss/)

| File | Description |
|---|---|
| [ncache.yaml](ncache-oss/ncache.yaml) | Deploys the NCache OSS servers as a `StatefulSet` using the public `alachisoft/ncache:5.3.603-oss` image. |
| [discoveryservice.yaml](ncache-oss/discoveryservice.yaml) | Headless `cacheserver` service that lets clients find the cache servers inside the cluster. This is required because every pod gets a dynamic IP address at start time, but NCache clients need the cache servers' IP addresses to connect. |
| [client-gatewayservice.yaml](ncache-oss/client-gatewayservice.yaml) | `gateway` service (`NodePort`) to access, manage and monitor NCache from your workstation. Only required if you want to reach NCache from outside the cluster. |

## Usage
```bash
kubectl apply -f ncache-oss/ncache.yaml
kubectl apply -f ncache-oss/discoveryservice.yaml
kubectl apply -f ncache-oss/client-gatewayservice.yaml
```

### NOTE
These are basic sample configuration files (*.yaml) to readily set up NCache within a Kubernetes cluster for a quick start. You might need to adjust some settings, such as hardware resources for your cache server pods like [CPU](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-that-is-too-big-for-your-nodes), [Memory](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/#specify-a-memory-request-that-is-too-big-for-your-nodes), [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) etc., according to your workload and business needs.

# Related Repos
- [alachisoft/ncache](https://hub.docker.com/r/alachisoft/ncache) for NCache Docker Images
- [Alachisoft/NCache-Docker](https://github.com/Alachisoft/NCache-Docker) for NCache Dockerfiles
- [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes)


# Additional Resources
- [NCache Deployment in Azure Kubernetes Service](https://www.alachisoft.com/resources/docs/ncache/containerization/azure/index.html)
- [NCache Deployment in Elastic Kubernetes Service](https://www.alachisoft.com/resources/docs/ncache/containerization/amazon-eks/index.html)


# Feedback
- [File an issue](https://github.com/Alachisoft/NCache-Kubernetes/issues).
- [Contact Alachisoft Support](https://www.alachisoft.com/company/contact-us.html)
