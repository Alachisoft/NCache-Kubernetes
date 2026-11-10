# NCache Open Source Kubernetes Scripts

Creates a Kubernetes cluster without load balancers, then deploys NCache Open Source from its manifests, which create no load balancers either.

For each provider, run the two scripts in order from this folder. Set the listed values at the top of the create script first; the deploy script needs none.

## EKS

### 1. Create the cluster

Set in `create-eks-cluster.sh`: `CLUSTER_NAME`, `REGION`, `SUBNET_IDS`, `IAM_ROLE`, `NODE_COUNT`, `NODE_TYPE`

`IAM_ROLE` must trust `eks.amazonaws.com` and `ec2.amazonaws.com`, and have `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy` and `AmazonEC2ContainerRegistryReadOnly`. The user running the script needs `iam:PassRole` on it.

```bash
bash create-eks-cluster.sh
```

| Step | Commands the script runs |
|---|---|
| Create cluster | `aws iam get-role`, `aws eks create-cluster`, `aws eks wait cluster-active` |
| Create nodes | `aws eks create-nodegroup`, `aws eks wait nodegroup-active` |
| Connect kubectl | `aws eks update-kubeconfig` |
| Verify nodes | `kubectl get nodes` |

### 2. Deploy NCache

```bash
bash deploy-ncache.sh
```

| Step | Commands the script runs |
|---|---|
| Deploy NCache | `kubectl apply -f ncache.yaml`, `kubectl apply -f discoveryservice.yaml` |

## AKS

Nodes reach the internet through a NAT gateway.

### 1. Create the cluster

Set in `create-aks-cluster.sh`: `CLUSTER_NAME`, `REGION`, `RESOURCE_GROUP`, `NODE_COUNT`, `VM_SIZE`

```bash
bash create-aks-cluster.sh
```

| Step | Commands the script runs |
|---|---|
| Sign in | `az account show`, `az login` |
| Create cluster | `az group create`, `az aks create --outbound-type managedNATGateway` |
| Connect kubectl | `az aks get-credentials` |
| Verify nodes | `kubectl get nodes` |

### 2. Deploy NCache

```bash
bash deploy-ncache.sh
```

| Step | Commands the script runs |
|---|---|
| Deploy NCache | `kubectl apply -f ncache.yaml`, `kubectl apply -f discoveryservice.yaml` |

## GKE

### 1. Create the cluster

Set in `create-gke-cluster.sh`: `CLUSTER_NAME`, `ZONE`, `PROJECT_ID`, `NODE_COUNT`, `MACHINE_TYPE`

```bash
bash create-gke-cluster.sh
```

| Step | Commands the script runs |
|---|---|
| Sign in | `gcloud auth list`, `gcloud auth login` |
| Enable APIs | `gcloud services enable` |
| Create cluster | `gcloud container clusters create` |
| Connect kubectl | `gcloud container clusters get-credentials` |
| Verify nodes | `kubectl get nodes` |

### 2. Deploy NCache

```bash
bash deploy-ncache.sh
```

| Step | Commands the script runs |
|---|---|
| Deploy NCache | `kubectl apply -f ncache.yaml`, `kubectl apply -f discoveryservice.yaml` |

## On-premises

Builds the cluster with kubeadm on your own Ubuntu machines, with Calico networking. Run the create script with `sudo` on every machine, and join at least one worker: NCache runs on the workers only.

### 1. Create the cluster

On the control-plane node:

```bash
sudo bash create-onprem-cluster.sh control-plane
```

On each worker node, run the two commands the control-plane node printed:

```bash
sudo bash create-onprem-cluster.sh worker
```

```bash
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

| Step | Commands the script runs |
|---|---|
| Prepare every node | `apt-get install`, `swapoff`, `modprobe`, `sysctl` |
| Install containerd | `apt-get install containerd.io` |
| Install Kubernetes | `apt-get install kubeadm kubectl kubelet`, `apt-mark hold` |
| Create cluster (control plane only) | `kubeadm init` |
| Install network (control plane only) | `kubectl apply` Calico, `kubectl wait --for=condition=Ready nodes` |
| Print join command (control plane only) | `kubeadm token create --print-join-command` |

### 2. Deploy NCache

On the control-plane node:

```bash
bash deploy-ncache.sh
```

| Step | Commands the script runs |
|---|---|
| Deploy NCache | `kubectl apply -f ncache.yaml`, `kubectl apply -f discoveryservice.yaml` |
