#!/bin/sh

NAMESPACE_CORE="${NAMESPACE_CORE:-plonk}"
NAMESPACE_LOGIC="${NAMESPACE_LOGIC:-functions}"
CLUSTER_NAME="${CLUSTER_NAME:-plonk-on-kind}"
TEMPORARY_DIR=".temp"

mkdir $TEMPORARY_DIR || echo "Temporary dir already there."

# brew install kind

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi
reg_ip="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_ip}:${reg_port}"]
EOF

# At the moment not necessary
# KIND_KUBECONFIG="$(kind get kubeconfig --name="$CLUSTER_NAME")"

kubectl config use-context kind-$CLUSTER_NAME || exit 404
# add dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
kubectl apply -f ./yaml

git clone https://github.com/openfaas/faas-netes.git

helm template faas-netes/chart/openfaas \
    --name openfaas \
    --namespace $NAMESPACE_CORE  \
    --set basic_auth=true \
    --set functionNamespace=$NAMESPACE_LOGIC > ./$TEMPORARY_DIR/plonk.yaml

kubectl apply -f ./$TEMPORARY_DIR/plonk.yaml

PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
echo -n $PASSWORD
kubectl -n $NAMESPACE_CORE create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"

while [ -z "$open_faas_up" ]
do
    sleep 5
    echo "Checking if gateway is ready"
    open_faas_up=$(kubectl -n $NAMESPACE_CORE get deployments -l "release=openfaas, app=openfaas" | grep gateway | awk '{ print $2 }' | grep "1/1")
    echo $open_faas_up
done

existing_pid=$(ps | grep "[p]ort-forward -n $NAMESPACE_CORE" | awk '{print $1}')
[ -z "$existing_pid" ] || kill $existing_pid

nohup kubectl port-forward -n $NAMESPACE_CORE svc/gateway 31112:8080 > ./$TEMPORARY_DIR/port-forward.log 2>&1 &
# allow time for port forward to run
sleep 2

export OPENFAAS_URL=http://127.0.0.1:31112
echo $PASSWORD | faas-cli login --password-stdin


