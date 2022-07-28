#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/env.sh
source ./scripts/common.sh

# Prerequisite 검사 (kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

# cluster management
case $(checkOpt iub $@) in
    b | bootstrap)
        scripts/registry.sh -i ingress-nginx
        scripts/registry.sh -i cert-manager
        scripts/registry.sh -i longhorn
        scripts/registry.sh -i k8s-dashboard
        logInfo "please run scripts/registry.sh --set-ingress k8s-dashboard after k8s-dashboard is fully installed."
        logInfo "please run scripts/registry.sh --set-ingress longhorn after longhorn is fully installed."
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
            cert-manager)
                kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
                kubectl apply -f objects/cert-selfissuer.yaml
            ;;
            kube-oidc-proxy)
                helm upgrade --install $2 objects/charts/$2 \
                    --values objects/$2-value.yml
            ;;
            h | help | ? | *)
                logKill "supporting registries: [ingress-nginx], [longhorn], [k8s-dashboard], [cert-manager], [kube-oidc-proxy]"
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
            cert-manager)
                kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
            ;;
            kube-oidc-proxy)
                helm uninstall kube-oidc-proxy
            ;;
            h | help | ? | *)
                logKill "supporting registries: [ingress-nginx], [longhorn], [k8s-dashboard], [cert-manager], [kube-oidc-proxy]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    set-ingress)
        LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)

        if [[ ${PREFER_PROTOCOL}="https" ]]; then
            PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.spec.ports[1].nodePort}")
        elif [[ ${PREFER_PROTOCOL}="http" ]]; then
            PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.spec.ports[0].nodePort}")
        else
            logKill "PREFER_PROTOCOL env error: please check your config/.env"
        fi

        case $_OS_ in
            linux)
                RUN="open"
                EXP="sh"
            ;;
            windows)
                RUN="start"
                EXP="bat"
            ;;
        esac

        case $2 in
            longhorn)
                cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ui-ingress
  namespace: longhorn-system
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: dashboard.longhorn.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
          - pathType: ImplementationSpecific
            backend:
              service:
                name: longhorn-frontend
                port:
                  name: http
EOF
                [ -e longhorn.${EXP} ] && rm longhorn.${EXP}

                DEST="${PREFER_PROTOCOL}://dashboard.longhorn.${LOCAL_ADDRESS}.nip.io:${PORT}"

                if [[ ! -e longhorn.${EXP} ]]; then
                    cat << EOF > longhorn.${EXP}
#!/bin/bash
echo "${DEST}"
${RUN} ${DEST}
EOF
                fi

                chmod +x longhorn.${EXP}
                chmod 777 longhorn.${EXP}

                [[ ${OS_name} -eq "linux" ]] && cp longhorn.${EXP} /usr/local/bin/longhorn
            ;;
            k8s-dashboard)
                cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  tls:
    - hosts:
        - dashboard.k8s.${LOCAL_ADDRESS}.nip.io
  rules:
    - host: dashboard.k8s.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
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
---
EOF
                sleep 20
                DEST="${PREFER_PROTOCOL}://dashboard.k8s.${LOCAL_ADDRESS}.nip.io:${PORT}"
                KUBEBOARD_SECRETNAME=$(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}")
                KUBEBOARD_TOKEN=$(kubectl get secret ${KUBEBOARD_SECRETNAME} -n kubernetes-dashboard -o go-template="{{.data.token | base64decode}}")
                cat > k8s.${EXP} << EOF
#!/bin/bash
KUBEBOARD_TOKEN="${KUBEBOARD_TOKEN}"
echo "[URL]"
echo "${DEST}"
echo "[TOKEN]"
echo "${KUBEBOARD_TOKEN}"
${RUN} ${DEST}
EOF

                chmod +x k8s.${EXP}
                chmod 777 k8s.${EXP}

                [[ ${OS_name} -eq "linux" ]] && cp k8s.${EXP} /usr/local/bin/k8s
            ;;
            kube-oidc-proxy)
                LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
                cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kube-oidc-proxy
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-production
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  rules:
    - host: k8s.sso.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: kube-oidc-proxy
              port:
                name: https
EOF
            ;;
            jupyter-hub | jh | hub)
              LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
              cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hub
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  rules:
    - host: jupyter.hub.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: proxy-public
              port:
                name: https
EOF
                
                [ -e longhorn.${EXP} ] && rm longhorn.${EXP}

                DEST="${PREFER_PROTOCOL}://jupyter.hub.${LOCAL_ADDRESS}.nip.io:${PORT}"

                [[ ! -e hub.${EXP} ]] && cat << EOF > hub.${EXP}
#!/bin/bash
echo "${DEST}"
${RUN} ${DEST}
EOF

                chmod +x hub.${EXP}
                chmod 777 hub.${EXP}

                [[ ${OS_name} -eq "linux" ]] && cp hub.${EXP} /usr/local/bin/hub
            ;;
            h | help | ? | *)
                logKill "supporting ingresses: [longhorn], [k8s-dashboard], [kube-oidc-proxy]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    h | help | ? | *)
        logHelpHead "scripts/registry.sh"
        logHelpContent i install "install registry"
        logHelpContent u uninstall "uninstall registry"
        logHelpContent set-ingress "set ingress of pod"
        logHelpTail
    ;;
esac