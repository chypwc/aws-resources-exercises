#!/bin/bash
set -euo pipefail

# Check if job name is provided
if [ -z "${1:-}" ]; then
  echo "❌ Usage: $0 <glue-job-name>"
  exit 1
fi

JOB_NAME="$1"

# Start Glue job and capture JobRunId
echo "🚀 Starting Glue job '$JOB_NAME'..."
JOB_RUN_ID=$(aws glue start-job-run \
  --job-name "$JOB_NAME" \
  --query 'JobRunId' \
  --output text 2>/dev/null || true)

# Validate JobRunId
if [ -z "$JOB_RUN_ID" ] || [ "$JOB_RUN_ID" == "None" ]; then
  echo "❌ Failed to start Glue job '$JOB_NAME' or retrieve JobRunId"
  exit 1
fi

echo "✅ Glue job started with JobRunId: $JOB_RUN_ID"

# Poll job status
STATUS="STARTING"
while [[ "$STATUS" == "STARTING" || "$STATUS" == "RUNNING" ]]; do
  echo "⏳ Waiting for Glue job to finish... (current status: $STATUS)"
  sleep 20
  STATUS=$(aws glue get-job-run \
    --job-name "$JOB_NAME" \
    --run-id "$JOB_RUN_ID" \
    --query 'JobRun.JobRunState' \
    --output text 2>/dev/null || echo "FAILED")
done

# Final status
if [[ "$STATUS" == "SUCCEEDED" ]]; then
  echo "✅ Glue job '$JOB_NAME' succeeded!"
  exit 0
else
  echo "❌ Glue job '$JOB_NAME' failed with status: $STATUS"
  exit 1
fi