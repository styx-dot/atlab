#!/bin/bash

# NO set -e HERE — as requested

trap 'tput cnorm' EXIT
clear_line() { printf "\r\033[K"; }

spinner() {
    local pid="$1"
    local msg="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    tput civis

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s... %s" "$msg" "${spin:i++%${#spin}:1}"
        sleep 0.12
    done

    wait "$pid"
    local status=$?

    clear_line

    if [[ $status -eq 0 ]]; then
        printf "\r\033[32m✔\033[0m %s done.\n" "$msg"
    else
        printf "\r\033[31m✘\033[0m %s FAILED (exit code %s)\n" "$msg" "$status"
    fi

    return $status
}

run() {
    local label="$1"
    shift

    (
        set -euo pipefail
        "$@"
    ) >/dev/null 2>&1 &

    local pid=$!
    spinner "$pid" "$label"
    local status=$?

    if [[ $status -ne 0 ]]; then
        exit "$status"
    fi
}

echo ""
echo "▶ 01-k3s-install.sh"
echo "──────────────────────────────────────────────"
echo ""

########################################
# Install K3s
########################################
run "[1/5] Installing K3s" \
    bash -c "curl -sfL https://get.k3s.io | sh -"

########################################
# Kubeconfig setup
########################################
run "[2/5] Configuring kubeconfig" \
    bash -c '
        mkdir -p ~/.kube
        cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
        chmod 600 ~/.kube/config
        chown $USER:$USER ~/.kube/config
    '

########################################
# Wait for K3s
########################################
run "[3/5] Waiting for K3s to start" \
    bash -c "
        for i in {1..20}; do
            if kubectl get nodes >/dev/null 2>&1; then
                exit 0
            fi
            sleep 2
        done
        exit 1
    "

run "[3b/5] Showing cluster status" \
    bash -c "kubectl get nodes && kubectl get pods -A || true"

########################################
# Install Helm
########################################
run "[4/5] Installing Helm" \
    bash -c 'curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash'

########################################
# Add Helm repos
########################################
run "[5/5] Adding Helm repositories" \
    bash -c "
        helm repo add twuni https://twuni.github.io/docker-registry.helm
        helm repo add joxit https://helm.joxit.dev
        helm repo add jenkins https://charts.jenkins.io
        helm repo add minio https://charts.min.io
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update
    "

echo ""
echo "✔ K3s + Helm installation complete."
echo "──────────────────────────────────────────────"

