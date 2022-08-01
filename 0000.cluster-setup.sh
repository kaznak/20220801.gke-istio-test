#!/bin/bash

set -vxe

PROJECT_ID=${PROJECT_ID:-"sandbox-project"}
CLUSTER_NAME=standard-$(date +%Y%m%d%H%M%S)-$(LANG=C tr -dc 'a-z0-9' < /dev/urandom|fold -w8|head -n1)

gcloud services enable container.googleapis.com \
    --project=$PROJECT_ID

gcloud container clusters create    \
    $CLUSTER_NAME   \
    --project=$PROJECT_ID   \
    --region=us-central1    \
    --release-channel=stable    \
    --machine-type=n1-standard-2    \
    --num-nodes 3

gcloud container clusters get-credentials $CLUSTER_NAME \
    --project $PROJECT_ID   \
    --zone=us-central1-a

kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

istioctl install --set profile=demo -y
