#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/env.sh
source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl)
checkPrerequisite multipass
checkPrerequisite kubectl

# cluster management
case $(checkOpt iupr $@) in
    i | install)
        # .env에 정의한 cluster setup에 맞춰 노드 생성
        ITER=1
        while [[ ${ITER} -le ${CLUSTER_NODE_AMOUNT} ]]; do
            multipass launch \
                --name node${ITER} \
                --cpus ${CLUSTER_CPU_CAPACITY} \
                --mem ${CLUSTER_MEM_CAPACITY}G \
                --disk ${CLUSTER_DISK_AMOUNT}G \
                ${CLUSTER_UBUNTU_VERSION}

            # 각 노드별 필수 유틸리티 설치 (nfs, iscsi : virtual storage 위한 설치)
            multipass exec node${ITER} -- sudo apt-get update -y 
            multipass exec node${ITER} -- sudo apt-get install nfs-common open-iscsi nfs-kernel-server -y

            ITER=$(( ITER+1 ))
        done

        # 생성한 node에서 k3s cluster 구축
        # k3s 버전은 .env에 정의한 kubernetes를 기반으로 함
        ITER=1
        while [[ ${ITER} -le ${CLUSTER_NODE_AMOUNT} ]]; do
            if [[ ${ITER} -eq 1 ]]; then
                # Master node : k3s 설치
                # kubernetes version 고정, traefik 사용 해제(v1이기 때문), servicelb 사용 해제, 기본 스토리지 해제
                # feature gate 활성화: TTLAfterFinished(Job 자동삭제), CronJobControllerV2(크론잡 개선)
                multipass exec node${ITER} -- bash -c "curl -sfL https://get.k3s.io | \
                    INSTALL_K3S_VERSION=${K3S_VERSION} \
                    sh -s - server \
                    --disable traefik \
                    --disable servicelb \
                    --disable local-storage \
                    --kube-apiserver-arg feature-gates=TTLAfterFinished=true,CronJobControllerV2=true"

                # Master node에 접근할 수 있는 인증 토큰 및 Endpoint 정보 저장
                K3S_TOKEN=$(multipass exec node1 -- bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")
                K3S_URL=$(multipass info node1 | grep IPv4 | awk '{print $2}')
                K3S_URL_FULL="https://${K3S_URL}:6443"
            else
                # Worker node : k3s 설치 (Master Node에 대해 K3S_TOKEN을 통한 인증)
                multipass exec node${ITER} -- bash -c "curl -sfL: https://get.k3s.io | \
                    INSTALL_K3S_VERSION=${K3S_VERSION} K3S_URL=\"${K3S_URL_FULL}\" K3S_TOKEN=\"${K3S_TOKEN}\" sh -"
            fi
            
            logSuccess "node${ITER} is set for k3s"
            ITER=$(( ITER+1 ))
        done
        case $_OS_ in
            "linux")
                multipass exec node1 sudo cat /etc/rancher/k3s/k3s.yaml > ${KUBECONFIG}
                sed -i '' "s/127.0.0.1/${K3S_URL}/" ${KUBECONFIG}
            ;;
            "windows")
                multipass exec node1 -- bash -c "sudo cat /etc/rancher/k3s/k3s.yaml" > ${KUBECONFIG}
                sed -i "s/127.0.0.1/${K3S_URL}/" ${KUBECONFIG}
            ;;
        esac

        ### helm의 config permission error 제거 ###
        chmod o-r config/kubeconfig.yaml
        chmod g-r config/kubeconfig.yaml

        # finalizer
        finalize cluster-install
    ;;
    u | uninstall)
        # .env에 정의한 cluster setup에 맞춰 노드 삭제
        ITER=1
        while [[ ${ITER} -le ${CLUSTER_NODE_AMOUNT} ]]; do
            multipass delete node${ITER} -p &
            ITER=$(( ITER-1 ))
        done
    ;;
    p | pause)
        # .env에 정의한 cluster setup에 맞춰 노드 stop
        ITER=1
        while [[ ${ITER} -le ${CLUSTER_NODE_AMOUNT} ]]; do
            multipass stop node${ITER}
            ITER=$(( ITER+1 ))
        done
    ;;
    r | resume)
        # .env에 정의한 cluster setup에 맞춰 노드 restart
        ITER=1
        while [[ ${ITER} -le ${CLUSTER_NODE_AMOUNT} ]]; do
            multipass start node${ITER}
            ITER=$(( ITER+1 ))
        done
    ;;
    get-token)
        if [[ $# -eq 1 ]]; then
            logKill "give me second parameter: realmname"
        elif [[ $# -eq 2 ]]; then
            logKill "give me third parameter: clientname"
        elif [[ $# -eq 3 ]]; then
            logKill "give me fourth parameter: username (password default)"
        elif [[ $# -eq 4 ]]; then
            curl -k -X POST $(scripts/keycloak.sh --open get-url)/realms/$2/protocol/openid-connect/token \
                -d grant_type=password -d client_id=$3 -d username=$4 -d password=password -d scope=openid \
                -H "Content-type: application/x-www-form-urlencoded; charset=UTF-8"
        fi
    ;;
    get-localhost-ssl)
        createCertPem localhost localhost
    ;;
    delete-localhost-ssl)
        rm config/cert-crt-localhost.pem
        rm config/cert-key-localhost.pem
    ;;
    h | help | ? | *)
        logHelpHead "scripts/cluster.sh"
        logHelpContent i install "install clusters"
        logHelpContent u uninstall "uninstall clusters"
        logHelpContent p pause "pause clusters"
        logHelpContent r resume "resume paused clusters"
        logHelpContent get-token "get k8s-keycloak token"
        logHelpContent get-localhost-ssl "create ssl key of localhost"
        logHelpContent delete-localhost-ssl "delete ssl key of localhost"
        logHelpTail
    ;;
esac