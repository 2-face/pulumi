#!/bin/sh

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe `gcloud compute addresses list | awk '{print $1}' | grep kubernetes-the-hard-way` --region $(gcloud config get-value compute/region) --format 'value(address)')

kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=../ca-tls-certs/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
    --client-certificate=../ca-tls-certs/admin.pem \
    --client-key=../ca-tls-certs/admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

kubectl config use-context kubernetes-the-hard-way