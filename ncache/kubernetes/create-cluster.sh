#!/usr/bin/env bash
#
# Builds an on-premises Kubernetes cluster with kubeadm on Ubuntu, with Calico networking and MetalLB
# for the NCache LoadBalancer Services. Edit the values below before running.
#
# Usage: sudo bash create-cluster.sh control-plane     on the first node; prints the worker join command
#        sudo bash create-cluster.sh worker            on every other node, then run the printed join command

set -euo pipefail

POD_CIDR="10.20.30.0/21"
CALICO_VERSION="v3.27.3"
METALLB_VERSION="v0.14.5"
IP_RANGE="<START_IP>-<END_IP>"    # free addresses on the nodes' network for MetalLB, e.g. 10.0.0.200-10.0.0.250 or a CIDR
ROLE="${1:-}"

log(){ echo "[INFO] $1"; }

[ "$(id -u)" -ne 0 ] && echo "Error: Please run this script as root or using sudo." >&2 && exit 1
case "$ROLE" in control-plane|worker) ;; *) echo "Error: no role specified '$ROLE'. Usage: $0 <control-plane|worker>" >&2; exit 1 ;; esac
if [ "$ROLE" = "control-plane" ]; then case "$IP_RANGE" in *"<"*|"") echo "Error: IP_RANGE is not set. Set it at the top of this script." >&2; exit 1 ;; esac; fi

log "Installing dependencies ..."
apt-get update
apt-get install -y curl ca-certificates apt-transport-https gpg

log "Disabling swap ..."
swapoff -a
sed -i '/\sswap\s/s/^/#/' /etc/fstab

log "Loading kernel modules ..."
printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/k8s.conf
modprobe overlay
modprobe br_netfilter
printf 'net.ipv4.ip_forward=1\nnet.bridge.bridge-nf-call-iptables=1\nnet.bridge.bridge-nf-call-ip6tables=1\n' > /etc/sysctl.d/k8s.conf
sysctl --system

log "Installing containerd ..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

log "Installing Kubernetes components ..."
K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt | sed 's/v\([0-9]*\)\.\([0-9]*\).*/v\1.\2/')
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm kubectl kubelet
apt-mark hold kubeadm kubectl kubelet

if [ "$ROLE" = "worker" ]; then
    echo
    echo "Worker node is ready. Now run the 'sudo kubeadm join ...' command printed by the control-plane node."
    exit 0
fi

log "Initializing Kubernetes control plane ..."
MASTER_IP=$(hostname -I | awk '{print $1}')
kubeadm config images pull
kubeadm init --apiserver-advertise-address="$MASTER_IP" --pod-network-cidr="$POD_CIDR" | tee /root/kubeadm-init-output.txt

log "Configuring kubectl ..."
mkdir -p "$HOME/.kube"
cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
if [ -n "${SUDO_USER:-}" ]; then USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6); mkdir -p "$USER_HOME/.kube"; cp /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"; chown -R "$SUDO_USER": "$USER_HOME/.kube"; fi

log "Installing Calico $CALICO_VERSION network ..."
kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/calico.yaml"
kubectl rollout status daemonset/calico-node -n kube-system --timeout=300s
kubectl wait --for=condition=Ready nodes --all --timeout=300s

log "Installing MetalLB $METALLB_VERSION ..."
kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/config/manifests/metallb-native.yaml"
kubectl patch deployment controller -n metallb-system --type=json -p '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'
kubectl rollout status deployment/controller -n metallb-system --timeout=180s
kubectl rollout status daemonset/speaker -n metallb-system --timeout=180s

log "Applying MetalLB IP pool $IP_RANGE ..."
kubectl apply -f - <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - $IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
YAML

log "Control plane is ready"

JOIN_COMMAND="$(kubeadm token create --print-join-command)"
echo
echo "To add a worker node, run these two commands on that node (copy this script there first):"
echo
echo "  sudo bash create-cluster.sh worker"
echo "  sudo $JOIN_COMMAND"
echo
