#!/usr/bin/env bash
set -euo pipefail

OUTFILE="ansible/inventories/hosts.ini"

# values you already have
EC2_IP="13.213.17.163"
EC2_USER="ubuntu"

mkdir -p ansible/inventories

cat > $OUTFILE <<EOF
[minikube]
${EC2_IP} ansible_user=${EC2_USER}
EOF

echo "Inventory generated at $OUTFILE"
