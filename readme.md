helm repo add twuni https://helm.twun.io
helm repo add joxit https://helm.joxit.dev
helm repo add jenkins https://charts.jenkins.io
helm repo add minio https://charts.min.io/
helm repo add bitnami https://charts.bitnami.com/bitnami


helm install registry twuni/docker-registry \
  -n registry \
  -f registry-value.yaml

helm upgrade registry-ui joxit/docker-registry-ui \
  -n registry \
  -f registry-gui.yaml

helm install jenkins jenkins/jenkins \
  -n jenkins \
  -f jenkins-values.yaml

helm install minio minio/minio \
  -n minio \
  -f minio-values.yaml

helm install bitbucket-postgresql bitnami/postgresql \
  -n bitbucket \
  -f postgresql-values.yaml

