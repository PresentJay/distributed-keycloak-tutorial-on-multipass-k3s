# Kubernetes 환경에서 Keycloak 분산 클러스터링 적용 tutorial

- 목표 Keycloak version: 18.0.0

# prerequisite
- multipass
- kubectl, helm

# QuickStart

check help messages: `scripts/cluster.sh`, `scripts/registry.sh`

1. `scripts/cluster.sh --install`
2. `scripts/registry.sh --bootstrap`

# cluster configuration & test suites
- 3 nodes : scaling nodes suite
- 3 keycloak-cluster
  - importing exist realm
  - connect with external postgreSQL pod (it will be clustered DB. . .?)
- testable web : nodejs (it will be clustered . .? << pm2 VS HPA Cluster OR SO?) 
- (언젠가) proxy 관련 설정 알아보기
  - https://www.keycloak.org/server/reverseproxy

# Tested on
- mac

# References
- [ ] https://www.keycloak.org/guides#server

# TODOs
- [ ] importing/exporting realm
- [ ] not operator deployment trial
- [ ] operator deployment trial (bitnami?)

