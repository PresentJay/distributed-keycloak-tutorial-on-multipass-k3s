kubectl oidc-login setup \
    --oidc-issuer-url=https://keycloak.192.168.64.8.nip.io:32405/auth/realms/k8s-test \
    --oidc-client-id=kube-oidc-proxy \
    --oidc-client-secret=5d14eb5a-91f1-417d-b540-3a850e1fd183 \
    --grant-type=authcode \
    --insecure-skip-tls-verify