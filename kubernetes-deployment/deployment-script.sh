#!/bin/bash

######################################
# Utility Function

pre_error() {
    echo -n -e "${RED}"
    echo "========================================================="
    echo "ERROR: $1"
    echo "========================================================="
    echo -e "${NC}"
    exit 1
}

check_command() {
    command -v $1 > /dev/null || pre_error "missing command $1"
}

#########################################
# Pre-flight validation
check_command minikube
check_command kubectl
check_command helm

do_setup_minikube() {
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
}

do_setup_kube() {
    sudo apt-get install -y kubectl
}

do_setup_helm() {
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

#########################################
# Start Cluster through Minikube

do_start_local_cluster() {
    minikube start
    minikube addons enable ingress
}

do_setup_certmanager() {
    # Create a dedicated Kubernetes namespace for cert-manager
    kubectl create namespace cert-manager

    # Add official cert-manager repository to helm CLI
    helm repo add jetstack https://charts.jetstack.io
    
    # Update Helm repository cache (think of apt update)
    helm repo update
    
    # Install cert-manager on Kubernetes
    ## cert-manager relies on several Custom Resource Definitions (CRDs)
    ## Helm can install CRDs in Kubernetes (version >= 1.15) starting with Helm version 3.2
    helm install certmgr jetstack/cert-manager \
        --set installCRDs=true \
        --version v1.8 \
        --namespace cert-manager
}

main() {
    echo " Deploying the application into Default namespace"
    kubectl apply -f ./deployment-yaml/*
}

cleanup() {
    kubectl delete -f ./deployment-yaml/*
    helm remove certmgr -n cert-manager
    minikube stop
    echo " Note: This script will not uninstall any packages installed during the script"
}

do_setup() {
    do_setup_kube
    do_setup_minikube
    do_setup_helm
    exit
}

do_install() {
    do_start_local_cluster
    do_setup_certmanager
    main
    exit
}

do_cleanup() {
    cleanup
    exit
}

do_echo() {
    echo " Please pass in the correct argument to continue. Acceptable arguments are setup, install and cleanup"
}

case $1 in
    setup) do_setup ;;
    cleanup) do_cleanup ;;
    install) do_install ;;
            *) do_echo ;;
esac
