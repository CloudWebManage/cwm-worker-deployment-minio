#!/usr/bin/env bash

# Calico: https://docs.projectcalico.org/getting-started/kubernetes/minikube
# Enabling build-in Calico here for testing purposes

minikube start --driver=docker --kubernetes-version=v1.18.15 --network-plugin=cni --cni=calico
