NAMESPACE_CORE="${NAMESPACE_CORE:-plonk}"
NAMESPACE_LOGIC="${NAMESPACE_LOGIC:-functions}"

kubectl delete namespaces $NAMESPACE_CORE $NAMESPACE_LOGIC
# this part is atm not overridable
kubectl delete clusterrole openfaas-prometheus

