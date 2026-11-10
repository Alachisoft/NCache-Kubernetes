# NCache on on-premises Kubernetes

Builds a Kubernetes cluster with kubeadm on your own Ubuntu machines and deploys NCache on it.

| File | What it does |
|---|---|
| `create-cluster.sh` | Installs containerd and Kubernetes on a node. On the control-plane node it also creates the cluster, installs Calico networking and MetalLB with your IP range, and prints the command that joins a worker node. |
| `deploy-ncache.sh` | Installs NCache on the cluster with the NCache Helm chart, including the gateway load balancers. |
| `ncache.yaml` | NCache without Helm: StatefulSet, service account and permissions, `ncache-store` ConfigMap and the headless `ncache-cacheserver` Service. |
| `client-gatewayservice.yaml` | MetalLB load balancer for NCache clients (ports 9800, 9803-9997). |
| `mgmt-gatewayservice.yaml` | MetalLB load balancer for the Management Center (9801, 9802) and the Cloud Portal (9998, 9999). Shares one IP with the client gateway. |

## Run

1. Set `IP_RANGE` (free addresses on the nodes' network) at the top of `create-cluster.sh`. On the control-plane node:

   ```bash
   sudo bash create-cluster.sh control-plane
   ```

2. On each worker node, run the two commands the control-plane node printed:

   ```bash
   sudo bash create-cluster.sh worker
   ```

   ```bash
   sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
   ```

3. Set `NCACHE_KEY` at the top of `deploy-ncache.sh`, then on the control-plane node (needs [Helm](https://helm.sh/docs/intro/install/) installed there):

   ```bash
   bash deploy-ncache.sh on-prem
   ```

Without Helm, set the license key in `ncache.yaml` and apply the three YAML files instead of step 3:

```bash
kubectl apply -f ncache.yaml -f client-gatewayservice.yaml -f mgmt-gatewayservice.yaml
```

## Machine sizes

Use Ubuntu machines on the same network. NCache runs on the worker nodes only, one NCache server per
node, and deploys 2 servers by default, so join at least 2 workers.

| Node | Minimum |
|---|---|
| Control plane | 2 vCPUs, 2 GB RAM |
| Each worker | the RAM and vCPUs of your NCache edition, e.g. **ENT-8/2** = 8 GB RAM, 2 vCPUs |
