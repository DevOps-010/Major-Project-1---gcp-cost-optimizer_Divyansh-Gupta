
# GCP Idle Resource Cleanup Script

echo "GCP Idle Resource Cleanup Tool"
echo "============================="

mkdir -p ../reports
DATE=$(date +"%Y-%m-%d")
REPORT_FILE="../reports/cleanup_report_$DATE.txt"

echo "GCP Resource Cleanup Report - $DATE" > $REPORT_FILE
echo "===================================" >> $REPORT_FILE

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1; then
  echo "You are not authenticated with GCP. Please run 'gcloud auth login' first."
  exit 1
fi

PROJECT=$(gcloud config get-value project)
echo "Project: $PROJECT" >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "Finding stopped instances..."
echo "STOPPED INSTANCES:" >> $REPORT_FILE
echo "----------------" >> $REPORT_FILE
STOPPED_INSTANCES=$(gcloud compute instances list --filter="status=TERMINATED" --format="table[no-heading](name,zone,status)")

if [ -z "$STOPPED_INSTANCES" ]; then
  echo "No stopped instances found." >> $REPORT_FILE
else
  echo "$STOPPED_INSTANCES" >> $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "To delete a stopped instance, run:" >> $REPORT_FILE
  echo "gcloud compute instances delete INSTANCE_NAME --zone=ZONE" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE

echo "Finding unattached disks..."
echo "UNATTACHED DISKS:" >> $REPORT_FILE
echo "----------------" >> $REPORT_FILE
UNATTACHED_DISKS=$(gcloud compute disks list --filter="NOT users:*" --format="table[no-heading](name,zone,sizeGb)")

if [ -z "$UNATTACHED_DISKS" ]; then
  echo "No unattached disks found." >> $REPORT_FILE
else
  echo "$UNATTACHED_DISKS" >> $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "To delete an unattached disk, run:" >> $REPORT_FILE
  echo "gcloud compute disks delete DISK_NAME --zone=ZONE" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE

echo "Finding unused static IPs..."
echo "UNUSED STATIC IPs:" >> $REPORT_FILE
echo "----------------" >> $REPORT_FILE
UNUSED_IPS=$(gcloud compute addresses list --filter="status=RESERVED AND NOT users:*" --format="table[no-heading](name,address,region)")

if [ -z "$UNUSED_IPS" ]; then
  echo "No unused static IPs found." >> $REPORT_FILE
else
  echo "$UNUSED_IPS" >> $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "To delete an unused static IP, run:" >> $REPORT_FILE
  echo "gcloud compute addresses delete IP_NAME --region=REGION" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE

echo "Finding old snapshots..."
echo "OLD SNAPSHOTS (>30 days):" >> $REPORT_FILE
echo "-----------------------" >> $REPORT_FILE

THIRTY_DAYS_AGO=$(date -d "30 days ago" +%Y-%m-%d)

OLD_SNAPSHOTS=$(gcloud compute snapshots list --filter="creationTimestamp<$THIRTY_DAYS_AGO" --format="table[no-heading](name,diskSizeGb,creationTimestamp)")

if [ -z "$OLD_SNAPSHOTS" ]; then
  echo "No old snapshots found." >> $REPORT_FILE
else
  echo "$OLD_SNAPSHOTS" >> $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "To delete an old snapshot, run:" >> $REPORT_FILE
  echo "gcloud compute snapshots delete SNAPSHOT_NAME" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE

echo "Finding potentially idle Cloud SQL instances..."
echo "POTENTIALLY IDLE CLOUD SQL INSTANCES:" >> $REPORT_FILE
echo "---------------------------------" >> $REPORT_FILE
SQL_INSTANCES=$(gcloud sql instances list --format="table[no-heading](name,databaseVersion,tier,region)")

if [ -z "$SQL_INSTANCES" ]; then
  echo "No Cloud SQL instances found." >> $REPORT_FILE
else
  echo "$SQL_INSTANCES" >> $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "Note: Check usage metrics in Cloud Console to confirm if these instances are idle." >> $REPORT_FILE
  echo "To delete a Cloud SQL instance, run:" >> $REPORT_FILE
  echo "gcloud sql instances delete INSTANCE_NAME" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE

echo "CLEANUP RECOMMENDATIONS:" >> $REPORT_FILE
echo "----------------------" >> $REPORT_FILE
echo "1. Delete stopped instances that are no longer needed" >> $REPORT_FILE
echo "2. Delete unattached disks after confirming they contain no important data" >> $REPORT_FILE
echo "3. Delete unused static IPs to avoid unnecessary charges" >> $REPORT_FILE
echo "4. Delete old snapshots after confirming they are no longer needed" >> $REPORT_FILE
echo "5. Consider stopping or deleting idle Cloud SQL instances" >> $REPORT_FILE
echo "6. Set up a regular cleanup schedule to avoid accumulating unused resources" >> $REPORT_FILE

echo "Cleanup report generated: $REPORT_FILE"
echo "Review the report and manually delete resources as needed."
