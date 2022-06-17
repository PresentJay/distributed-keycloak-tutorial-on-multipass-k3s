#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/env.sh
source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

# cluster management
case $(checkOpt iub $@) in
    b | bootstrap)
        scripts/registry.sh -i ingress-nginx
        scripts/registry.sh -i longhorn
        scripts/registry.sh -i k8s-dashboard
    ;;
    i | install)
        case $2 in
            ingress-nginx)
                ### Ingress-Nginx 설치 (클러스터 내 트래픽 관리) ###
                helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
                helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
                    --namespace ingress-nginx \
                    --create-namespace \
                    --version ${INGRESS_NGINX_VERSION}
            ;;
            longhorn)
                ### Longhorn Storage 설치 (클러스터 내 가상 스토리지 관리) ###
                helm repo add longhorn https://charts.longhorn.io && helm repo update
                case $_OS_ in
                    linux)
                        helm upgrade --install longhorn longhorn/longhorn \
                            --namespace longhorn-system \
                            --create-namespace \
                            --set csi.kubeletRootDir=/var/lib/kubelet \
                            --version ${LONGHORN_VERSION}
                    ;;
                    windows)
                        helm upgrade --install longhorn longhorn/longhorn \
                            --install longhorn \
                            --namespace longhorn-system \
                            --create-namespace \
                            --version ${LONGHORN_VERSION}
                    ;;
                esac
            ;;
            k8s-dashboard)
                ### Kubernetes Dashboard 설치 (클러스터 모니터링 도구) ###
                helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard && helm repo update
                helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
                    --namespace kubernetes-dashboard \
                    --create-namespace \
                    --version ${K8S_DASHBOARD_VERSION} \
                    --set=extraArgs="{--token-ttl=0}"
            ;;
            h | help | ? | *)
                log_kill "supporting registries: [ingress-nginx], [longhorn], [k8s-dashboard]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    u | uninstall)
        case $2 in
            ingress-nginx)
                ### Ingress-Nginx 삭제 ###
                helm uninstall ingress-nginx
                kubectl delete namespace ingress-nginx
            ;;
            longhorn)
                ### Longhorn Storage 삭제 ###
                helm uninstall longhorn
                kubectl delete namespace longhorn-system
            ;;
            k8s-dashboard)
                ### Kubernetes Dashboard 삭제 ###
                helm uninstall kubernetes-dashboard
                kubectl delete namespace kubernetes-dashboard
            ;;
            h | help | ? | *)
                log_kill "supporting registries: [ingress-nginx], [longhorn], [k8s-dashboard]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    h | help | ? | *)
        log_help_head "scripts/registry.sh"
        log_help_content i install "install registry"
        log_help_content u uninstall "uninstall registry"
        log_help_tail
    ;;
esac