# PLONK stack bootstrap

Supports Kubernetes on Docker for Mac and kind.

Before blindly executing any script make sure to look at what they do ;)

Prerequisites:
* Working docker setup
* faas-cli
* kind or enabled Kubernetes on Docker for Mac
* kubectl
* helm 2

There are 3 scripts of interest:
* `mac.sh` to boot up PLONK stack on the docker for MacOs
* `kind.sh` to boot up PLONK stack on the kind (kubernetes in docker)
* `down.sh` to remove PLONK stack from the cluster

To get the token to login to the kubernetes dashboard execute `kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')`

To access the Dashboard in the browser, exec
`kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 10443:443`
and access https://localhost:10443 afterwards.
Alternatively we can use `kubectl proxy` but the access url is longinsh like http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

Details here:
https://github.com/kubernetes/dashboard/blob/master/docs/user/accessing-dashboard/1.7.x-and-above.md#api-server


Creating basic auth secret manually is necesssary to boot everything up 
```sh 
PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1) kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"
```

