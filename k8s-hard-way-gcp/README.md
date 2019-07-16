# k8s the hard way with Pulumi

## Table of Contents
+ [About](#about)
+ [Getting Started](#getting_started)
+ [Usage](#usage)
+ [Author](#author)

## About <a name = "about"></a>
This is pretty much a repeated [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way/) augmented with [Pulumi](https://www.pulumi.com/) to create infra on GCP (and sample k8s app on top).

## Getting Started <a name = "getting_started"></a>
Run aforementioned guide manually - it's all the same as the original tutorial with the exception it runs latest _kubernetes_ **1.15.0** (and other components as well like _containerd_).

### Prerequisites
Following prerequisites must be met to run this tutorial:
- [Python3.7](https://www.python.org/downloads/)
- [Google Cloud Platform account](https://cloud.google.com/gcp/getting-started/)
- [gcloud SDK](https://cloud.google.com/sdk/install)
- [Pulumi CLI tool](https://www.pulumi.com/docs/reference/install/)
- [Pulumi account](https://app.pulumi.com/signup)


### Installing

Install **venv** and requirements with the following shell script.
```shell session
./bootstrap.sh
```

## Usage <a name = "usage"></a>

Initialize new project with Pulumi (you will get a prompt to login with an access token that you need to generate on Pulumi website)
```shell session
pulumi new gcp-python -f -d . -n k8s-hard-way
```

[Bring up the infra on GCP](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md)
```shell session
pulumi up
```

*`Any resources created manually after this step must be also manually destroyed since infra state will not match the actual state`*

[Provisioning a CA and Generating TLS Certificates](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md)
```shell session
ca-tls-certs/generate_certs.sh
```

[Generating Kubernetes Configuration Files for Authentication](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md)
```shell session
kubeconfigs/generate_kubeconfigs.sh
```

[Generating the Data Encryption Config and Key](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/06-data-encryption-keys.md)
```shell session
encryption_key/generate_encryption_key.sh
```

* [Bootstrapping the etcd Cluster](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md) *`services/generate_etcd_cfg.sh`* will be distributed to controller nodes

* [Bootstraping the Kubernetes Control Plane](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md) 
    - *`services/bootstrap_k8s_ctrl_plane.sh`* will be distributed to controller nodes
    - *`services/rbac_for_kubelet_authorization.sh`* will be distributed to controller nodes

* [Bootstrapping the Kubernetes Worker Nodes](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md) *`services/bootstrap_k8s_workers.sh`* will be distributed to worker nodes

[Provision network loadbalancer to API server](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#provision-a-network-load-balancer)
```shell session
services/provision_loadbalancer.sh
```

[Enable HTTP Health Checks](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#enable-http-health-checks)
```shell session
services/enable_http_healthchecks.sh
```

Distribute files to worker and controller nodes and run appropriate scripts
```shell session
./distribute_files.sh
```

[Configuring kubectl for Remote Access](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/10-configuring-kubectl.md)
```shell session
services/kubectl_remote_access.sh
```

[Provisioning Pod Network Routes](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/11-pod-network-routes.md)
```shell session
services/pod_routing.sh
```

[Deploying the DNS Cluster Add-on](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/12-dns-addon.md)
Instead of manually deploying CoreDNS service with `kubectl apply` it will be deployed with Pulumi as well to hold the state of the infrastructure. Additionally e.g. if *Deployment* fails i.e. no *Pods* are running then service pointing to them is not going to be deployed as well.
```shell session
cd apps/
pulumi u[]
```

[Smoke Test](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/13-smoke-test.md)
As in the orignal instruction.

**Clean Up**
>Anything created manually with *gcloud* must be removed manually
```shell session
gcloud compute firewall-rules delete kubernetes-the-hard-way-allow-health-check
gcloud compute firewall-rules delete kubernetes-the-hard-way-allow-nginx-service
gcloud compute routes delete kubernetes-route-10-200-0-0-24
gcloud compute routes delete kubernetes-route-10-200-1-0-24
gcloud compute routes delete kubernetes-route-10-200-2-0-24
```
> Delete CoreDNS (k8s app)
```shell session
cd apps/
pulumi destroy
```
> Delete GCP resources (root project folder)
```shell session
pulumi destroy
```

## Author <a name = "author"></a>
[LI](https://www.linkedin.com/in/mazurekmichal/)
[WEB](http://www.stackblog.net/)


