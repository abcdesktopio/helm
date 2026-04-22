#! /bin/bash

VERSION=$(grep appVersion "charts/abcdesktop/Chart.yaml" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')

echo "NAMESPACE=abcdesktop"
NAMESPACE=abcdesktop
sleep 3
echo "helm repo add abcdesktop https://abcdesktopio.github.io/helm/"
helm repo add abcdesktop https://abcdesktopio.github.io/helm/
sleep 3
echo "helm install my-abcdesktop abcdesktop/abcdesktop --version ${VERSION} --create-namespace -n \${NAMESPACE}"
helm install my-abcdesktop abcdesktop/abcdesktop --version ${VERSION} --create-namespace -n ${NAMESPACE}
sleep 10
