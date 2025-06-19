#!/bin/bash

# Exit on error
set -e

# Check if ACCOUNT_ID is set
if [ -z "$ACCOUNT_ID" ]; then
  echo "❌ Error: ACCOUNT_ID environment variable is not set."
  exit 1
fi

# Set the profile directory and file path
PROFILE_DIR=~/.dbt
PROFILE_FILE=$PROFILE_DIR/profiles.yml

# Ensure the directory exists
mkdir -p "$PROFILE_DIR"

# Write the dbt profiles.yml file
cat > "$PROFILE_FILE" <<EOF
dbt_glue:  # <-- must match 'name' in dbt_project.yml
  target: dev
  outputs:
    dev:
      type: glue
      query-comment: "executed via dbt-glue"
      role_arn: arn:aws:iam::$ACCOUNT_ID:role/DbtGlueExecutionRole
      region: ap-southeast-2
      workers: 3
      worker_type: G.1X
      schema: sales_db
      session_provisioning_timeout_in_seconds: 120
      location: "s3://$SOURCE_BUCKET/imba"
      glue_version: "4.0"
      glue_session_reuse: true
      idle_timeout: 10
      query_timeout_in_minutes: 300
      seed_format: parquet
      seed_mode: overwrite
      default_arguments: "--enable-continuous-cloudwatch-log=true, --enable-spark-ui=true, --enable-metrics=true, --spark-event-logs-path=s3://$SOURCE_BUCKET/sparkui/"
      project_name: dbtGlueProject
EOF

echo "✅ profiles.yml has been created at $PROFILE_FILE"