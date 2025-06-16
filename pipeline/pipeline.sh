#!/bin/bash
set -e

echo "Uploading CSV files to s3://${SourceBucketName}/input/"
aws s3 cp ./data/ s3://${SourceBucketName}/input/ --recursive --exclude "*" --include "*.csv"

echo "Triggering AWS Glue crawler..."
aws glue start-crawler --name ${CrawlerName}

echo "Waiting for crawler to complete..."
status=""
count=0
while [[ "$status" != "READY" && $count -lt 60 ]]; do
  status=$(aws glue get-crawler --name ${CrawlerName} --query 'Crawler.State' --output text)
  echo "Current crawler status: $status"
  sleep 10
  ((count++))
done

if [[ "$status" != "READY" ]]; then
  echo "❌ Timeout waiting for crawler to complete"
  exit 1
fi

echo "✅ Crawler finished successfully."