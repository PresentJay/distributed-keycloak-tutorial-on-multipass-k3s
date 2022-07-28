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
        createPVC $2-volume longhorn 1
        createJupyter $2 8888
        createService $2 8888
        LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
        cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $2-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: $2.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
          - pathType: ImplementationSpecific
            backend:
              service:
                name: $2
                port:
                  number: 8888
EOF
    ;;
    open)
        LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
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
        PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.spec.ports[1].nodePort}")
        DEST="${PREFER_PROTOCOL}://$2.${LOCAL_ADDRESS}.nip.io:${PORT}"
        eval "${RUN} ${DEST}"
    ;;
    h | help | ? | *)
        logHelpHead "scripts/jupyter.sh"
        logHelpContent i install "install jupyter"
        logHelpContent u uninstall "uninstall jupyter"
        logHelpContent l log "show log of jupyter"
        logHelpContent watch "watch status of pod"
        logHelpTail
    ;;
esac