#!/bin/bash
set -e

echo "🔐 Fetching Redshift credentials from Secrets Manager..."
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id RedshiftCreds \
  --query SecretString \
  --output text)

USERNAME=$(echo "$SECRET" | jq -r .username)
PASSWORD=$(echo "$SECRET" | jq -r .password)

echo "🔍 Getting Redshift endpoint..."
HOST=$(aws redshift describe-clusters \
  --cluster-identifier redshift-demo-cluster \
  --query "Clusters[0].Endpoint.Address" \
  --output text)

echo "🛠️ Creating ~/.dbt/profiles.yml..."
mkdir -p ~/.dbt
cat > ~/.dbt/profiles.yml <<EOF
default:
  target: dev
  outputs:
    dev:
      type: redshift
      host: $HOST
      user: $USERNAME
      password: $PASSWORD
      port: 5439
      dbname: dev
      schema: public
      threads: 1
      ssl: true
EOF