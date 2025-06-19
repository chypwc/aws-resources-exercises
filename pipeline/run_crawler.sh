#!/bin/bash
set -euo pipefail

echo "Triggering AWS Glue crawler..."
aws glue start-crawler --name "${CrawlerName}"

echo "Waiting for crawler to complete..."

for i in {1..60}; do
  STATE=$(aws glue get-crawler --name "${CrawlerName}" --query 'Crawler.State' --output text || echo "UNKNOWN")
  LAST_STATUS=$(aws glue get-crawler --name "${CrawlerName}" --query 'Crawler.LastCrawl.Status' --output text || echo "NONE")

  echo "[$i] Crawler state: $STATE | Last crawl status: $LAST_STATUS"

  if [[ "$STATE" == "READY" && "$LAST_STATUS" == "SUCCEEDED" ]]; then
    echo "✅ Crawler finished successfully."
    exit 0
  fi

  sleep 10
done

echo "❌ Timeout waiting for crawler to complete."
exit 1