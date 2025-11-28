#!/bin/bash

# NO set -e HERE — as requested

# Always restore cursor
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
        # strict mode INSIDE THE STEP ONLY
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

echo "▶ 00-system-bootstrap.sh"
echo "──────────────────────────────────────────────"
echo ""

# ─────────────────────────────────────────────
# 1. SYSTEM UPDATE
# ─────────────────────────────────────────────
run "[1/8] Updating system" \
    bash -c "apt update && apt upgrade -y"

# ─────────────────────────────────────────────
# 2. BASE PACKAGES
# ─────────────────────────────────────────────
run "[2/8] Installing base packages" \
    bash -c "apt install -y curl wget net-tools podman git unzip bash-completion ca-certificates jq vim software-properties-common"

# ─────────────────────────────────────────────
# 3. TERRAFORM
# ─────────────────────────────────────────────
run "[3/8] Installing Terraform" \
    bash -c '
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
            > /etc/apt/sources.list.d/hashicorp.list
        apt update
        apt install -y terraform
    '

# ─────────────────────────────────────────────
# 4. ANSIBLE
# ─────────────────────────────────────────────
run "[4/8] Installing Ansible" \
    bash -c '
        add-apt-repository --yes --update ppa:ansible/ansible
        apt install -y ansible
    '

# ─────────────────────────────────────────────
# 5. AWS CLI
# ─────────────────────────────────────────────
run "[5/8] Installing AWS CLI" \
    bash -c '
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
        unzip -q awscliv2.zip
        ./aws/install
        rm -rf aws awscliv2.zip
    '

# ─────────────────────────────────────────────
# 6. NETPLAN
# ─────────────────────────────────────────────
run "[6/8] Configuring netplan" \
    bash -c '
        cat <<EOF > /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens5:
      dhcp4: true
    ens6:
      dhcp4: true
EOF
        netplan generate
        netplan apply
    '

# ─────────────────────────────────────────────
# 7. HOSTS FILE
# ─────────────────────────────────────────────
ENS6_IP=$(ip -4 addr show ens6 | grep -oP "(?<=inet\s)\d+(\.\d+){3}" || true)

run "[7/8] Updating /etc/hosts" \
    bash -c "
        echo '
# AT-LAB HOSTS
$ENS6_IP   jenkins.at-lab.lab
$ENS6_IP   bitbucket.at-lab.lab
$ENS6_IP   s3.at-lab.lab
$ENS6_IP   api-s3.at-lab.lab
$ENS6_IP   registry.at-lab.lab
' >> /etc/hosts
    "

echo ""
echo "✔ Bootstrap completed successfully."

