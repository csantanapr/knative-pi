#!/bin/bash

set -eo pipefail

serving_version=${serving_version:-latest}
knative_net_contour_version=${knative_net_contour_version:-latest}
set -u

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/serving/${serving_version}/serving-crds.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/serving/latest/serving-core.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -n knative-serving -l '!job-name'

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/net-contour/${knative_net_contour_version}/contour.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd
kubectl wait pod --timeout=-1s --for=condition=Ready -n contour-external -l '!job-name'
kubectl wait pod --timeout=-1s --for=condition=Ready -n contour-internal -l '!job-name'

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/net-contour/${knative_net_contour_version}/net-contour.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -n knative-serving -l '!job-name'

kubectl patch configmap/config-network \
--namespace knative-serving \
--type merge \
--patch '{"data":{"ingress.class":"contour.ingress.networking.knative.dev"}}'

EXTERNAL_IP="$(kubectl get svc envoy -n contour-external  -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo EXTERNAL_IP==$EXTERNAL_IP

KNATIVE_DOMAIN="$EXTERNAL_IP.nip.io"
echo KNATIVE_DOMAIN=$KNATIVE_DOMAIN

kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"


cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
      - image: csantanapr/helloworld-go:latest
        ports:
        - containerPort: 8080
        env:
        - name: TARGET
          value: "Knative"
EOF
kubectl wait ksvc hello --all --timeout=-1s --for=condition=Ready
SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')
echo "The SERVICE_ULR is $SERVICE_URL"
curl $SERVICE_URL