NAMESPACE_CORE="${NAMESPACE_CORE:-plonk}"
NAMESPACE_LOGIC="${NAMESPACE_LOGIC:-functions}"
TEMPORARY_DIR=".temp"

mkdir $TEMPORARY_DIR || echo "Temporary dir already there."

kubectl config use-context docker-desktop

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

sleep 10

export OPENFAAS_URL=http://127.0.0.1:31112
echo $PASSWORD | faas-cli login --password-stdin


