#!/bin/sh

#Transfer certificates and private keys to worker and controller nodes
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca-tls-certs/ca.pem ca-tls-certs/${instance}-key.pem ca-tls-certs/${instance}.pem ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca-tls-certs/ca.pem ca-tls-certs/ca-key.pem ca-tls-certs/kubernetes-key.pem ca-tls-certs/kubernetes.pem \
    ca-tls-certs/service-account-key.pem ca-tls-certs/service-account.pem ${instance}:~/
done


#Transfer kubeconfig files to worker and controller nodes
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp kubeconfigs/${instance}.kubeconfig kubeconfigs/kube-proxy.kubeconfig ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp kubeconfigs/admin.kubeconfig kubeconfigs/kube-controller-manager.kubeconfig kubeconfigs/kube-scheduler.kubeconfig ${instance}:~/
done


#Transfer encryption key to controllers
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption_key/encryption-config.yaml ${instance}:~/
done


#Transfer etcd config and start service
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp services/generate_etcd_cfg.sh ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute ssh ${instance} --command "chmod +x generate_etcd_cfg.sh ; ./generate_etcd_cfg.sh"
done


#Transfer k8s configs and start services
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp services/bootstrap_k8s_ctrl_plane.sh ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute ssh ${instance} --command "chmod +x bootstrap_k8s_ctrl_plane.sh ; ./bootstrap_k8s_ctrl_plane.sh"
done


#Enable HTTP Healthchecks
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp services/enable_http_healtchecks.sh ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute ssh ${instance} --command "chmod +x enable_http_healtchecks.sh ; ./enable_http_healtchecks.sh"
done


#RBAC for Kubelet Authorization (it can be done on a single node since etcd runs on all nodes)
gcloud compute scp services/rbac_for_kubelet_authorization.sh controller-0:~/
gcloud compute ssh controller-0 --command "chmod +x rbac_for_kubelet_authorization.sh ; ./rbac_for_kubelet_authorization.sh"


#Transfer k8s configs and start services
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp services/bootstrap_k8s_workers.sh ${instance}:~/
done

for instance in worker-0 worker-1 worker-2; do
  gcloud compute ssh ${instance} --command "chmod +x bootstrap_k8s_workers.sh ; ./bootstrap_k8s_workers.sh"
done


