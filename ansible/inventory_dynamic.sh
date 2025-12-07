#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="i-02390c9627aea5790"   # already provided in your Terraform outputs
REGION="ap-southeast-1"
OUTFILE="ansible/inventories/hosts.ini"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

if [[ "$PUBLIC_IP" == "None" ]]; then
  echo "ERROR: Instance has no public IP assigned!"
  exit 1
fi

mkdir -p ansible/inventories

cat > $OUTFILE <<EOF
[minikube]
$PUBLIC_IP ansible_user=ubuntu
EOF

echo "[INFO] Inventory generated: $OUTFILE"
echo "[INFO] EC2 Public IP = $PUBLIC_IP"
