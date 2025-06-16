#!/bin/bash
set -e

echo "Uploading CSV files to s3://${SourceBucketName}/input/"
aws s3 cp ./data/ s3://${SourceBucketName}/input/ --recursive --exclude "*" --include "*.csv"

echo "Triggering AWS Glue crawler..."
aws glue start-crawler --name ${CrawlerName}

echo "Waiting for crawler to complete..."
status=""
crawl_status=""
count=0
max_attempts=60

while [[ "$crawl_status" != "SUCCEEDED" && $count -lt $max_attempts ]]; do
  status=$(aws glue get-crawler --name ${CrawlerName} --query 'Crawler.State' --output text)
  crawl_status=$(aws glue get-crawler-metrics --crawler-name-list ${CrawlerName} \
                  --query "CrawlerMetricsList[0].LastRuntimeSuccessful" --output text)

  echo "Crawler state: $status"
  echo "Last successful crawl time: $crawl_status"

  if [[ "$status" == "READY" ]]; then
    last_crawl_status=$(aws glue get-crawler --name ${CrawlerName} \
      --query 'Crawler.LastCrawl.Status' --output text)
    echo "LastCrawl.Status: $last_crawl_status"

    if [[ "$last_crawl_status" == "SUCCEEDED" ]]; then
      echo "✅ Crawler completed successfully."
      exit 0
    fi
  fi

  sleep 10
  ((count++))
done

echo "❌ Crawler did not finish successfully within expected time."
exit 1