#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/env.sh
source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl)
checkPrerequisite multipass
checkPrerequisite kubectl

# cluster management
case $(checkOpt "iu" $@) in
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

                multipass exec node1 sudo cat /etc/rancher/k3s/k3s.yaml > config/kubeconfig.yaml
            else
                # Worker node : k3s 설치 (Master Node에 대해 K3S_TOKEN을 통한 인증)
                multipass exec node${ITER} -- bash -c "curl -sfL: https://get.k3s.io | \
                    INSTALL_K3S_VERSION=${K3S_VERSION} K3S_URL=\"${K3S_URL_FULL}\" K3S_TOKEN=\"${K3S_TOKEN}\" sh -"
            fi
            
            success "node${ITER} is set for k3s"
            sed -i '' "s/127.0.0.1/${K3S_URL}/" config/kubeconfig.yaml

            ITER=$(( ITER+1 ))
        done

        # finalizer
        finalize cluster-install

        # check finalize-done
        checkEnv ITER
        checkEnv K3S_URL
    ;;
    # u | uninstall)
    #     # TODO 
    # ;;
esac