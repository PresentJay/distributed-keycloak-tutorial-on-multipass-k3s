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
            h | help | ? | *)
                log_kill "supporting installations: "
                scripts/keycloak.sh --help
            ;;
        esac
    ;;
    u | uninstall)
        case $2 in
            # TODO
            h | help | ? | *)
                log_kill "supporting uninstallations: "
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
        log_help_tail
    ;;
esac