#!/bin/sh

#generate CA certificate and private key
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

#generate admin client certificate and private key
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

#generate kubelet client certificates
for instance in worker-0 worker-1 worker-2; do
EXTERNAL_IP=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
INTERNAL_IP=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].networkIP)')
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} -profile=kubernetes ${instance}-csr.json \
| cfssljson -bare ${instance}
done

#generate kube controller manager client certficate and private key
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

#generate kube proxy client certificate and private key
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

#generate kube scheduler client certificate and private key
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

#generate kube scheduler server certificate and private key
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe `gcloud compute addresses list | awk '{print $1}' | grep kubernetes-the-hard-way` --region $(gcloud config get-value compute/region) --format 'value(address)')
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
-profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

#generate service-account certificate and private key
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes service-account-csr.json | cfssljson -bare service-account