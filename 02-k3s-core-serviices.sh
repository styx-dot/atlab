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
echo "▶ 02-k3s-core-services.sh"
echo "──────────────────────────────────────────────"
echo ""

########################################
# 1. Create cert-manager namespace
########################################
run "[1/6] Creating cert-manager namespace" \
    bash -c "kubectl create namespace cert-manager 2>/dev/null || true"

########################################
# 2. Install cert-manager CRDs + components
########################################
run "[2/6] Installing cert-manager" \
    bash -c "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml"

########################################
# 3. Wait for cert-manager deployments
########################################
run "[3/6] Waiting for cert-manager components" \
    bash -c '
        kubectl wait -n cert-manager --for=condition=available deploy/cert-manager --timeout=180s
        kubectl wait -n cert-manager --for=condition=available deploy/cert-manager-cainjector --timeout=180s
        kubectl wait -n cert-manager --for=condition=available deploy/cert-manager-webhook --timeout=180s
    '

########################################
# 4. Deploy AT-LAB CA resources
########################################
run "[4/6] Applying AT-LAB CA (root, cert, issuer, wildcard)" \
    bash -c '
        kubectl apply -f ./cert-manager/00-root-ca.yaml &&
        kubectl apply -f ./cert-manager/01-root-ca-cert.yaml &&
        kubectl apply -f ./cert-manager/02-atlab-ca-issuer.yaml &&
        kubectl apply -f ./cert-manager/03-wildcard-atlab.yaml
    '

########################################
# 5. Extract Root CA for registry/Jenkins/Bitbucket
########################################
run "[5/6] Extracting AT-LAB Root CA" \
    bash -c '
        mkdir -p ./certs
        kubectl get secret atlab-root-ca-secret \
          -n cert-manager \
          -o jsonpath="{.data.ca\.crt}" | base64 --decode > ./certs/atlab-rootCA.crt
    '

########################################
# 8. kubectl alias + autocomplete
########################################
run "[6/6] Adding kubectl alias + autocomplete" \
    bash -c '
        cat <<EOF >> ~/.bashrc

# kubectl shortcut + autocompletion
alias k=kubectl
source /etc/bash_completion
source <(kubectl completion bash)
complete -F __start_kubectl k

EOF

        # Enable immediately
        source /etc/bash_completion || true
        source <(kubectl completion bash) || true
        alias k=kubectl
        complete -F __start_kubectl k
    '

echo ""
echo "✔ cert-manager, CA, CoreDNS + kubectl autocomplete configured successfully."
echo "──────────────────────────────────────────────"

