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
                log_kill "supporting installations: [config, postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    u | uninstall)
        case $2 in
            # TODO
            config)
                delete_sequence configmap keycloak-postgresql-config
                delete_sequence configmap keycloak-config
            ;;
            db | postgres | postgresql)
                delete_sequence service keycloak-postgresql
                delete_sequence statefulset keycloak-postgresql
                delete_sequence pvc keycloak-postgresql-data
            ;;
            standalone)
                delete_sequence service keycloak-app
                delete_sequence deployment keycloak-app
            ;;
            h | help | ? | *)
                log_kill "supporting uninstallations: [config, postgresql, standalone]"
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
                log_info "if you want to pause watch, Run \"Ctrl+C\""
                kubectl get service keycloak-postgresql
                kubectl get pvc keycloak-postgresql-data
                kubectl get statefulset keycloak-postgresql -w
            ;;
            standalone)
                log_info "if you want to pause watch, Run \"Ctrl+C\""
                kubectl get service keycloak-app
                kubectl get deployment keycloak-app -w
            ;;
            h | help | ? | *)
                log_kill "supporting watch: [config, postgresql, standalone]"
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    set-ingress)
        case $2 in
            # TODO
            h | help | ? | *)
                log_kill "supporting ingresses: ["
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    h | help | ? | *)
        log_help_head "scripts/keycloak.sh"
        log_help_content i install "install keycloak"
        log_help_content u uninstall "uninstall keycloak"
        log_help_content set-ingress "set ingress of pod"
        log_help_content watch "watch status of pod"
        log_help_tail
    ;;
esac