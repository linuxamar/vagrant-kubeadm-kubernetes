#!/bin/bash
#
# Deploys the Kubernetes dashboard when enabled in settings.yaml

set -euxo pipefail

config_path="/vagrant/configs"

# DASHBOARD_VERSION=$(grep -E '^\s*dashboard:' /vagrant/settings.yaml | sed -E -e 's/[^:]+: *//' -e 's/\r$//')
if [ -n "${DASHBOARD_VERSION}" ]; then
  # echo 'Waiting 1 minutes'
  # sleep 60

  while sudo -i -u vagrant kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'Waiting for metrics server to be ready...'
    sleep 5
  done

  echo 'Metrics server is ready. Installing dashboard environment...'

  # echo "Deploying the dashboard..."
  # since 7.0.0, no more yaml. we should use HELM
  # source: https://github.com/kubernetes/dashboard
  # sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v${DASHBOARD_VERSION}/aio/deploy/recommended.yaml"
  
#   echo "
# Use this command to access to (https://localhost:8443) :
# kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
# "
#   echo "
# Use it to log in at (kubectl proxy):
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard
# "
  # echo "Creating the namespace..."

  # sudo -i -u vagrant kubectl create namespace kubernetes-dashboard

  echo "Creating the dashboard user..."

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
EOF

  sudo -i -u vagrant kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}" >> "${config_path}/token"
  echo "The following token was also saved to: configs/token"
  cat "${config_path}/token"

#   echo "
# To install Dashboard, use HELM.
# # Add kubernetes-dashboard repository
# helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# # Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
# helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kubernetes-dashboard
# "

fi

#  kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443