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
                kubectl apply -f objects/postgresql.yaml
                scripts/keycloak.sh --watch db
            ;;
            standalone)
                kubectl apply -f objects/keycloak.yaml
                scripts/keycloak.sh --watch standalone
            ;;
            ingress)
                LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
                cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-app
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
    - host: keycloak.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: keycloak-app
              port:
                number: 8080
        - path: /auth
          pathType: Prefix
          backend:
            service:
              name: keycloak-app
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
                deleteSequence pvc keycloak-postgresql-data
            ;;
            standalone)
                deleteSequence service keycloak-app
                deleteSequence deployment keycloak-app
                find=$(getObjectNameByAppname pod keycloak-app) && \
                    deleteSequence pod ${find}
            ;;
            ingress)
                deleteSequence ingress keycloak-app
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
                kubectl get pvc keycloak-postgresql-data
                kubectl get statefulset keycloak-postgresql -w
            ;;
            standalone)
                logInfo "if you want to pause watch, Run \"Ctrl+C\""
                kubectl get service keycloak-app
                kubectl get deployment keycloak-app -w
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
                getObjectNameByAppname pod keycloak-postgresql && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl logs -f $(getObjectNameByAppname pod keycloak-postgresql)
            ;;
            standalone)
                getObjectNameByAppname pod keycloak-app && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl logs -f $(getObjectNameByAppname pod keycloak-app)
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
                getObjectNameByAppname pod keycloak-app && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl exec $(getObjectNameByAppname pod keycloak-app) -it -- sh
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
                PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[0].nodePort}")
                NODEPORT=$(kubectl get svc keycloak-app -o jsonpath="{.spec.ports[0].nodePort}")
                PREFER_PROTOCOL="http"
                if [[ -n $(kubectl get ingress keycloak-app) ]]; then
                    URL=$(kubectl get ingress keycloak-app | grep keycloak-app | awk '{print $3}')
                    echo "${PREFER_PROTOCOL}://${URL}:${NODEPORT}"
                    eval "${RUN} ${PREFER_PROTOCOL}://${URL}:${NODEPORT}"
                else
                    echo -e "${PREFER_PROTOCOL}://${LOCAL_ADDRESS}:${NODEPORT}"
                    eval "${RUN} ${PREFER_PROTOCOL}://${LOCAL_ADDRESS}:${NODEPORT}"
                fi
            ;;
            h | help | ? | *)
                logKill "supporting open: [postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    h | help | ? | *)
        logHelpHead "scripts/keycloak.sh"
        logHelpContent i install "install keycloak"
        logHelpContent u uninstall "uninstall keycloak"
        logHelpContent l log "show log of keycloak"
        logHelpContent set-ingress "set ingress of pod"
        logHelpContent watch "watch status of pod"
        logHelpTail
    ;;
esac