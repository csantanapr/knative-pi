#!/bin/bash

set -ex
KNATIVE_VERSION=${KNATIVE_VERSION:latest}
KNATIVE_NET_CONTOUR_VERSION=${KNATIVE_NET_KOURIER_VERSION:latest}

kubectl apply -f https://storage.googleapis.com/knative-nightly/serving/${KNATIVE_VERSION}/serving-crds.yaml
kubectl apply -f https://storage.googleapis.com/knative-nightly/serving/latest/serving-core.yaml
kubectl wait pod --timeout=-1s --for=condition=Ready -n knative-serving -l '!job-name'

curl -s -L https://storage.googleapis.com/knative-nightly/net-contour/${KNATIVE_NET_CONTOUR_VERSION}/contour.yaml | \
sed "s/envoy:v1.15.1/envoy:v1.16.0/g" | \
kubectl apply -f -

kubectl wait pod --timeout=-1s --for=condition=Ready -n contour-external -l '!job-name'
kubectl wait pod --timeout=-1s --for=condition=Ready -n contour-internal -l '!job-name'

kubectl apply --filename https://storage.googleapis.com/knative-nightly/net-contour/latest/net-contour.yaml
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