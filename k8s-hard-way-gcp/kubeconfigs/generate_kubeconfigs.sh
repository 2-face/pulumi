#!/bin/sh

CA_TLS_CERTS_DIR="../ca-tls-certs"

#generate kubeconfigs for kubelets
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe `gcloud compute addresses list | awk '{print $1}' | grep kubernetes-the-hard-way` --region $(gcloud config get-value compute/region) --format 'value(address)')

for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${CA_TLS_CERTS_DIR}/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${CA_TLS_CERTS_DIR}/${instance}.pem \
    --client-key=${CA_TLS_CERTS_DIR}/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done


#generate kubeconfigs for kube-proxy
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${CA_TLS_CERTS_DIR}/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
    --client-certificate=${CA_TLS_CERTS_DIR}/kube-proxy.pem \
    --client-key=${CA_TLS_CERTS_DIR}/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


#generate kubeconfigs for kube-controller-manager
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${CA_TLS_CERTS_DIR}/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=${CA_TLS_CERTS_DIR}/kube-controller-manager.pem \
    --client-key=${CA_TLS_CERTS_DIR}/kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig


#generate kubeconfigs for kube-controller-manager
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${CA_TLS_CERTS_DIR}/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=${CA_TLS_CERTS_DIR}/kube-scheduler.pem \
    --client-key=${CA_TLS_CERTS_DIR}/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig


#generate kubeconfigs for admin user
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=${CA_TLS_CERTS_DIR}/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=${CA_TLS_CERTS_DIR}/admin.pem \
    --client-key=${CA_TLS_CERTS_DIR}/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig