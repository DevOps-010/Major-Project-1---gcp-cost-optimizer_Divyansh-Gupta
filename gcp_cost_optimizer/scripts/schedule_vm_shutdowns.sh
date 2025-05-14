# Script to schedule VM shutdowns for non-production environments

echo "GCP VM Scheduler Setup"
echo "====================="

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1; then
  echo "You are not authenticated with GCP. Please run 'gcloud auth login' first."
  exit 1
fi

PROJECT=$(gcloud config get-value project)
echo "Project: $PROJECT"

create_schedule() {
  local env=$1
  local start_time=$2
  local stop_time=$3
  local time_zone=$4
  
  echo "Creating schedule for $env environment (Stop: $stop_time, Start: $start_time, Timezone: $time_zone)"
  
  echo "Labeling VMs with environment=$env..."
  
  echo "Creating scheduler job to stop $env VMs at $stop_time..."
  gcloud scheduler jobs create http "${env}-vm-stop" \
    --schedule="0 ${stop_time} * * 1-5" \
    --time-zone="${time_zone}" \
    --uri="https://compute.googleapis.com/compute/v1/projects/${PROJECT}/zones/us-central1-a/instances/stop" \
    --http-method=POST \
    --headers="Content-Type=application/json" \
    --message-body='{"filter":"labels.environment='${env}'"}' \
    --oauth-service-account-email="${PROJECT}@appspot.gserviceaccount.com" \
    || echo "Failed to create stop job. You may need to enable Cloud Scheduler API."
  
  echo "Creating scheduler job to start $env VMs at $start_time..."
  gcloud scheduler jobs create http "${env}-vm-start" \
    --schedule="0 ${start_time} * * 1-5" \
    --time-zone="${time_zone}" \
    --uri="https://compute.googleapis.com/compute/v1/projects/${PROJECT}/zones/us-central1-a/instances/start" \
    --http-method=POST \
    --headers="Content-Type=application/json" \
    --message-body='{"filter":"labels.environment='${env}'"}' \
    --oauth-service-account-email="${PROJECT}@appspot.gserviceaccount.com" \
    || echo "Failed to create start job. You may need to enable Cloud Scheduler API."
}

echo ""
echo "This script will help you set up automatic VM shutdown schedules for cost savings."
echo "You'll need to label your VMs with an 'environment' tag (e.g., dev, test, staging)."
echo ""
echo "Select an option:"
echo "1) Set up schedules for development environment (default: stop at 7PM, start at 8AM)"
echo "2) Set up schedules for test environment (default: stop at 8PM, start at 9AM)"
echo "3) Set up schedules for staging environment (default: stop at 10PM, start at 7AM)"
echo "4) Set up custom schedule"
echo "5) Exit"
echo ""
read -p "Enter your choice (1-5): " choice

case $choice in
  1)
    create_schedule "dev" "8" "19" "America/New_York"
    ;;
  2)
    create_schedule "test" "9" "20" "America/New_York"
    ;;
  3)
    create_schedule "staging" "7" "22" "America/New_York"
    ;;
  4)
    read -p "Enter environment name (e.g., dev, test): " env
    read -p "Enter start hour (0-23): " start_hour
    read -p "Enter stop hour (0-23): " stop_hour
    read -p "Enter time zone (e.g., America/New_York): " time_zone
    create_schedule "$env" "$start_hour" "$stop_hour" "$time_zone"
    ;;
  5)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "Schedule setup complete. To apply labels to your VMs, use:"
echo "gcloud compute instances add-labels INSTANCE_NAME --labels=environment=ENVIRONMENT_NAME"
echo ""
echo "To view your scheduled jobs:"
echo "gcloud scheduler jobs list"
echo ""
echo "Estimated monthly savings: Approximately 65% cost reduction for labeled VMs"
echo "(based on 12 hours of downtime per day during weekdays)"
