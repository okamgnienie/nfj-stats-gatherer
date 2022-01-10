#!/bin/bash

# Job types of interest
job_types="frontend backend testing devops"
todays_date=$(date +%m-%d-%Y)

# Collect
for job_type in $job_types; do
  ./gather_job_offer_stats.sh -k -j $job_type -e b2b
  ./gather_job_offer_stats.sh -k -j $job_type -e permanent
  ./gather_job_offer_stats.sh -k -j $job_type -e b2b -r
  ./gather_job_offer_stats.sh -k -j $job_type -e permanent -r
done

# Store generated reports in the repository
git add ./reports
git commit -m "Add reports from ${todays_date}"
git push
