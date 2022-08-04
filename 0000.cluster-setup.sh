#!/bin/bash

set -vx
set -Ee

source .env # to set PROJECT_ID

CLUSTER_NAME=standard-$(date +%Y%m%d%H%M%S)-$(LANG=C tr -dc 'a-z0-9' < /dev/urandom|fold -w8|head -n1)
REGION=us-central1

# Setup GKE Standard cluster for Istio
gcloud services enable container.googleapis.com \
    --project=$PROJECT_ID

gcloud container clusters create    \
    $CLUSTER_NAME   \
    --project=$PROJECT_ID   \
    --region=$REGION    \
    --release-channel=stable    \
    --machine-type=n1-standard-2    \
    --num-nodes 1

gcloud container clusters get-credentials $CLUSTER_NAME \
    --project $PROJECT_ID   \
    --zone=$REGION

# setup k8s Web UI
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

cat <<EOM   > /dev/stderr
To access Web UI,
run "kubectl proxy" and access to
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
EOM

# setup Istio
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

istioctl install --set profile=demo -y

# setup kiali, istio dashboard
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/addons/kiali.yaml

cat <<EOM   > /dev/stderr
To access kiali UI,
run
kubectl port-forward svc/kiali 20001:20001 -n istio-system
and access to
http://localhost:20001/
EOM

# setup keycloak
curl https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes-examples/keycloak.yaml    |
istioctl kube-inject -f -   |
kubectl apply -f -
