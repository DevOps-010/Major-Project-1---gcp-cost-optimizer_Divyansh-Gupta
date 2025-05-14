
# Run the GCP Cost Analyzer

mkdir -p ../reports

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1; then
  echo "You are not authenticated with GCP. Please run 'gcloud auth login' first."
  exit 1
fi

python3 -v gcp_cost_analyzer.py

echo "Cost analysis complete. Check the reports directory for results."
