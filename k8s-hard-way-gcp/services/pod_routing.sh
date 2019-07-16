#!/bin/bash

CLOUDSDK_COMPUTE_REGION=$(gcloud config get-value compute/region)
CLOUDSDK_COMPUTE_ZONE=$(gcloud config get-value compute/zone)
KUBERNETES_NETWORK=$(gcloud compute networks list | awk '{print $1}' | grep kubernetes-the-hard-way)

"""
Add routes for POD networks i.e. Route to a pod network on a specifc node via its networkIP address

10.240.0.20 10.200.0.0/24
10.240.0.21 10.200.1.0/24
10.240.0.22 10.200.2.0/24
"""
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network ${KUBERNETES_NETWORK} \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done