#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/env.sh
source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

# cluster management
case $(checkOpt iublx $@) in
    b | bootstrap)
        # TODO
    ;;
    i | install)
        case $2 in
            # TODO
            config)
                kubectl create configmap keycloak-postgresql-config \
                    --from-literal POSTGRES_DB=${AUTH_KEYCLOAK_DB_DATABASE} \
                    --from-literal POSTGRES_USER=${AUTH_KEYCLOAK_DB_USER} \
                    --from-literal POSTGRES_PASSWORD=${AUTH_KEYCLOAK_DB_PASSWORD}
                kubectl create configmap keycloak-config \
                    --from-literal KC_DB=${AUTH_KEYCLOAK_DB_VENDOR} \
                    --from-literal KC_DB_URL=${AUTH_KEYCLOAK_DB_URL} \
                    --from-literal KC_DB_USERNAME=${AUTH_KEYCLOAK_DB_USER} \
                    --from-literal KC_DB_PASSWORD=${AUTH_KEYCLOAK_DB_PASSWORD} \
                    --from-literal KC_HEALTH_ENABLED=true \
                    --from-literal KEYCLOAK_ADMIN=${AUTH_KEYCLOAK_USER} \
                    --from-literal KEYCLOAK_ADMIN_PASSWORD=${AUTH_KEYCLOAK_PASSWORD}
            ;;
            db | postgres | postgresql)
                createPVC keycloak-postgresql longhorn 5
                # createCertPem localhost keycloak
                # createPVC keycloak-app longhorn 1
                kubectl apply -f objects/postgresql.yaml
                sleep 20
                scripts/keycloak.sh -l db
                # find=$(getObjectNameByAppname pod keycloak-postgresql) && \
                #     checkStatus pod ${find} Running && \
                #     kubectl cp config/cert-crt-keycloak.pem ${find}:/auth/keycloak-crt.pem && \
                #     kubectl cp config/cert-key-keycloak.pem ${find}:/auth/keycloak-key.pem && \
                #     rm config/cert-crt-keycloak.pem config/cert-key-keycloak.pem
            ;;
            standalone)
                # kubectl apply -f objects/keycloak.yaml
                # sleep 20
                # find=$(getObjectNameByAppname pod keycloak-app) && \
                #     scripts/keycloak.sh -l standalone
                kubectl apply -f objects/keycloak-dev.yaml
                sleep 20
                find=$(getObjectNameByAppname pod keycloak-dev) && \
                    scripts/keycloak.sh -l standalone
            ;;
            ingress)
                LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
#                 cat <<EOF | kubectl apply -f -
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: keycloak-app
#   annotations:
#     kubernetes.io/tls-acme: "true"
#     kubernetes.io/ingress.class: "nginx"
#     ingress.kubernetes.io/force-ssl-redirect: "true"
#     nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
#     nginx.ingress.kubernetes.io/proxy-buffer-size: "12k"
# spec:
#   tls:
#     - hosts:
#       - keycloak.${LOCAL_ADDRESS}.nip.io
#   rules:
#     - host: keycloak.${LOCAL_ADDRESS}.nip.io
#       http:
#         paths:
#         - path: /
#           pathType: Prefix
#           backend:
#             service:
#               name: keycloak-app
#               port:
#                 number: 8443
#         - path: /auth
#           pathType: Prefix
#           backend:
#             service:
#               name: keycloak-app
#               port:
#                 number: 8443
# EOF
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-dev
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "12k"
spec:
  rules:
    - host: keycloak.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: keycloak-dev
              port:
                number: 8080
EOF
            ;;
            h | help | ? | *)
                logKill "supporting installations: [config, postgresql, standalone, ingress]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    u | uninstall)
        case $2 in
            # TODO
            config)
                deleteSequence configmap keycloak-postgresql-config
                deleteSequence configmap keycloak-config
            ;;
            db | postgres | postgresql)
                deleteSequence service keycloak-postgresql
                deleteSequence statefulset keycloak-postgresql
                find=$(getObjectNameByAppname pod keycloak-postgresql) && \
                    deleteSequence pod ${find}
                find=$(getObjectNameByAppname replicaset keycloak-postgresql) && \
                    deleteSequence replicaset ${find}
                deleteSequence pvc keycloak-postgresql
                # deleteSequence pvc keycloak-app
            ;;
            standalone)
                # deleteSequence service keycloak-app
                # deleteSequence deployment keycloak-app
                # find=$(getObjectNameByAppname pod keycloak-app) && \
                #     deleteSequence pod ${find}
                deleteSequence service keycloak-dev
                deleteSequence deployment keycloak-dev
                find=$(getObjectNameByAppname pod keycloak-dev) && \
                    deleteSequence pod ${find}
            ;;
            ingress)
                # deleteSequence ingress keycloak-app
                deleteSequence ingress keycloak-dev
            ;;
            h | help | ? | *)
                logKill "supporting uninstallations: [config, postgresql, standalone, ingress]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    watch)
        case $2 in
            config)
                kubectl get configmap keycloak-postgresql-config
                kubectl get configmap keycloak-config
            ;;
            db | postgres | postgresql)
                logInfo "if you want to pause watch, Run \"Ctrl+C\""
                kubectl get service keycloak-postgresql
                kubectl get pvc keycloak-postgresql
                kubectl get statefulset keycloak-postgresql -w
            ;;
            standalone)
                logInfo "if you want to pause watch, Run \"Ctrl+C\""
                # kubectl get service keycloak-app
                # kubectl get deployment keycloak-app -w
                kubectl get service keycloak-dev
                kubectl get deployment keycloak-dev -w
            ;;
            h | help | ? | *)
                logKill "supporting watch: [config, postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    l | log)
        case $2 in
            db | postgres | postgresql)
                find=$(getObjectNameByAppname pod keycloak-postgresql) && \
                    checkStatus pod ${find} Running && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl logs -f ${find}
            ;;
            standalone)
                # getObjectNameByAppname pod keycloak-app && \
                #     logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                #     kubectl logs -f $(getObjectNameByAppname pod keycloak-app)
                getObjectNameByAppname pod keycloak-dev && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl logs -f $(getObjectNameByAppname pod keycloak-dev)
            ;;
            h | help | ? | *)
                logKill "supporting watch: [postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    x | exec)
        case $2 in
            db | postgres | postgresql)
                getObjectNameByAppname pod keycloak-postgresql && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl exec $(getObjectNameByAppname pod keycloak-postgresql) -it -- sh
            ;;
            standalone)
                # getObjectNameByAppname pod keycloak-app && \
                #     logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                #     kubectl exec $(getObjectNameByAppname pod keycloak-app) -it -- sh
                getObjectNameByAppname pod keycloak-dev && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl exec $(getObjectNameByAppname pod keycloak-dev) -it -- sh
            ;;
            h | help | ? | *)
                logKill "supporting watch: [postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    open)
        if [[ ${PREFER_PROTOCOL}="http" ]]; then
            IS_HTTPS=$FALSE
        elif [[ ${PREFER_PROTOCOL}="https" ]]; then
            IS_HTTPS=$TRUE
        fi
        PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[$IS_HTTPS].nodePort}")
        LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
        [[ -z ${PORT} ]] && logKill "${PORT} can't find ingress port"

        case $_OS_ in
            linux) RUN="open" ;;
            windows) RUN="start" ;;
        esac

        case $2 in
            db | postgres | postgresql)
                NODEPORT=$(kubectl get svc keycloak-postgresql -o jsonpath="{.spec.ports[0].nodePort}")
                echo -e "\t[ACCESS-HOST]: ${LOCAL_ADDRESS}"
                echo -e "\t[ACCESS-PORT]: ${NODEPORT}"
            ;;
            standalone)
                PREFER_PROTOCOL=http
                IS_HTTPS=$TRUE
                PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[$IS_HTTPS].nodePort}")
                if [[ -n $(kubectl get ingress keycloak-dev) ]]; then
                    URL=$(kubectl get ingress keycloak-dev | grep keycloak-dev | awk '{print $3}')
                    echo "${PREFER_PROTOCOL}://${URL}:${PORT}"
                    eval "${RUN} ${PREFER_PROTOCOL}://${URL}:${PORT}"
                else
                    NODEPORT=$(kubectl get svc keycloak-dev -o jsonpath="{.spec.ports[0].nodePort}")
                    echo -e "http://${LOCAL_ADDRESS}:${NODEPORT}"
                    eval "${RUN} http://${LOCAL_ADDRESS}:${NODEPORT}"
                fi
            ;;
            get-url)
                # find=$(kubectl get ingress | grep keycloak-app || echo "")
                # if [[ -n ${find} ]]; then
                #     URL=$(kubectl get ingress keycloak-app | grep keycloak-app | awk '{print $3}')
                #     echo "${PREFER_PROTOCOL}://${URL}:${PORT}"
                #     eval "${RUN} ${PREFER_PROTOCOL}://${URL}:${PORT}"
                # else
                #     NODEPORT=$(kubectl get svc keycloak-app -o jsonpath="{.spec.ports[0].nodePort}")
                #     echo "${PREFER_PROTOCOL}://${LOCAL_ADDRESS}:${NODEPORT}"
                # fi
                PREFER_PROTOCOL=http
                IS_HTTPS=$TRUE
                URL=$(kubectl get ingress keycloak-dev | grep keycloak-dev | awk '{print $3}')
                PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[$IS_HTTPS].nodePort}")
                # NODEPORT=$(kubectl get svc keycloak-dev -o jsonpath="{.spec.ports[0].nodePort}")
                echo "${PREFER_PROTOCOL}://${URL}:${PORT}"
            ;;
            h | help | ? | *)
                logKill "supporting open: [postgresql, standalone, get-url]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    ssl)
        # $1 ex: keycloak.${LOCAL_ADDRESS}.nip.io
        # $2 ex: tls-keycloak
        # $3 ex: cert-keycloak
        case $2 in
            i | install)
                LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
                createCertKey keycloak.${LOCAL_ADDRESS}.nip.io keycloak
                kubectl create secret tls tls-keycloak --key config/cert-keycloak.key --cert config/cert-keycloak.crt
            ;;
            u | uninstall)
                kubectl delete secret tls-keycloak
                rm config/cert-keycloak.key
                rm config/cert-keycloak.crt
            ;;
        esac
    ;;
    h | help | ? | *)
        logHelpHead "scripts/keycloak.sh"
        logHelpContent i install "install keycloak"
        logHelpContent u uninstall "uninstall keycloak"
        logHelpContent l log "show log of keycloak"
        logHelpContent watch "watch status of pod"
        logHelpTail
    ;;
esac