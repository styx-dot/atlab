helm repo add minio https://charts.min.io/
helm repo update

helm install minio minio/minio -n minio -f minio-values.yaml
kubectl get pods -n minio

