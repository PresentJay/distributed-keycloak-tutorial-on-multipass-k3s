#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/env.sh
source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

# cluster management
case $(checkOpt iubl $@) in
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
            h | help | ? | *)
                logKill "supporting installations: [config, postgresql, standalone]"
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
                deleteSequence pvc keycloak-postgresql-data
            ;;
            standalone)
                deleteSequence service keycloak-app
                deleteSequence deployment keycloak-app
            ;;
            h | help | ? | *)
                logKill "supporting uninstallations: [config, postgresql, standalone]"
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
                getPodnameByAppname keycloak-postgresql && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl logs -f $(getPodnameByAppname keycloak-postgresql)
            ;;
            standalone)
                getPodnameByAppname keycloak-app && \
                    logInfo "if you want to pause watch, Run \"Ctrl+C\"" && \
                    kubectl logs -f $(getPodnameByAppname keycloak-app)
            ;;
            h | help | ? | *)
                logKill "supporting watch: [postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    set-ingress)
        case $2 in
            # TODO
            h | help | ? | *)
                logKill "supporting ingresses: ["
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