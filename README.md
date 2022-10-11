# About
This repository contains YAML configuration files for NCache Kubernetes and Kubernetes based cloud services e.g AKS, EKS deployments.

Each folder has 3 yaml files (ncache, cachediscoveryservice, gatwayservice). You can use these files to deploy NCache inside any kubernetes (or kuberenetes based cloud service e.g AKS).

Let's see what information these files contains

## [ncache.yaml](kubernetes/ncache.yaml)

This YAML file, contains all the necessary information including replica count, node selector, image repository and ports details required by your Kubernetes cluster to create and run any number of NCache server pods using NCache docker image.

## [cachediscoveryservice.yaml](kubernetes/cachediscoveryservice.yaml)

This YAML file, is used to deploy a kubernetes `headless` service, which we called as `cache discovery service` for the clients to find the desired caches on the deployed NCache servers (pods) within the kubernetes cluster. This is required because because every pod is assigned a dynamic ip-address at pod start time which is not pre-determined, but to connect with a cache NCache clients needs the ip-address of the cache servers.

## [gatewayservice.yaml](kubernetes/gatewayservice.yaml)
Purpose of this file is to expose the NCache Web Manager outside of the Kubernetes cluster, to create, manager and monitor NCache from your workstation.\
This service is only required if you want to manage & monitor NCache from outside of the your Kubernetes cluster using its Web Manager.

### NOTE
These are the basic sample configuration files (*.yaml) to radily setup NCache within a Kubernetes cluster for a quick start. You might need to adujst few of the settings like hardware resources for your cache server pods, like [CPU](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-that-is-too-big-for-your-nodes), [Memory](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/#specify-a-memory-request-that-is-too-big-for-your-nodes), [Persistence Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) etc. according to your work load and business needs.

# Usage
## Deploy NCache Cache cluster
```yaml
kubectl create -f ncache.yaml
```

## Create Cache Discovery Service
```yaml
kubectl create -f cachediscoveryservice.yaml
```

## Create Gateway Service to Manage NCache remotly
```yaml
kubectl create -f gatewayservice.yaml
```

# Related Repos
- [alachisoft/ncache]() for NCache Docker Images
- [Alachisoft/NCache-Docker]() for NCache Dockerfiles
- [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes)


# Additional Resources
- [NCache Deployment in Azure Kubernetes Service](https://www.alachisoft.com/resources/docs/ncache/containerization/azure/index.html)
- [NCache Deployment in Elastic Kubernetes Service](https://www.alachisoft.com/resources/docs/ncache/containerization/amazon-eks/index.html)


# Feedback
- [Fill an issue](https://github.com/Alachisoft/NCache-Kubernetes/issues).
- [Contact Alachisoft Support](https://www.alachisoft.com/company/contact-us.html)