#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error on line $1"
    exit 1
}

# Trap errors and call handle_error
trap 'handle_error $LINENO' ERR

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "gcloud not found. Please install gcloud before running this script."
    exit 1
else
    echo ""
    echo "gcloud is already installed"
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "terraform not found. Please install terraform before running this script."
    exit 1
else
    echo ""
    echo "terraform is already installed"
fi

# Connect to Google Cloud
echo ""
echo "Connecting to Google Cloud"
echo ""
echo "!Please read the options and select as needed!"
echo ""

echo "For Compute Region and Zone select the relevant option"

echo ""

echo "Connect CLI"
sleep 3
# Connect to console from CLI
gcloud auth application-default login



gcloud init --skip-diagnostics || { echo "Failed to initialize gcloud"; exit 1; }

# Capture project id
echo "Capturing current project"
current_project=$(gcloud config get-value project) || { echo "Failed to capture project"; exit 1; }
echo $current_project

# Capture current region
current_region=$(gcloud config get-value compute/region) || { echo "Failed to capture region"; exit 1; }
if [ -z "$current_region" ]; then
  gcloud config set compute/zone europe-west-2
  echo "Zone was not set. Defaulting to europe-west2."
else
  echo "Current zone is $current_zone."
fi

current_zone=$(gcloud config get-value compute/zone) || { echo "Failed to capture zone"; exit 1; }

if [ -z "$current_zone" ]; then
  gcloud config set compute/zone europe-west-2
  echo "Zone was not set. Defaulting to europe-west2-b."
else
  echo "Current zone is $current_zone."
fi

# Enable compute services API
gcloud services enable compute.googleapis.com || { echo "Failed to enable compute services"; exit 1; }
echo "enable compute.googleapis.com API"
sleep 3

# Connect billing account
billing_account=$(gcloud billing accounts list --filter="open=true" --format="value(ACCOUNT_ID)")
gcloud billing projects link $current_project --billing-account $billing_account || { echo "Failed to enable billing"; exit 1; }
echo "enable billing"
sleep 3

# Enter user email address
echo "Capturing Email Address"
current_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)") || { echo "Failed to capture account"; exit 1; }
echo $current_account


# Set user permissions
gcloud projects add-iam-policy-binding $current_project --member="user:${current_account}" --role=roles/compute.instanceAdmin.v1 || { echo "Failed to add IAM policy binding"; exit 1; }

echo "Google Cloud settings configured"
echo "Applying Terraform!"

export TF_VAR_project_id=$current_project
export TF_VAR_compute_name=$current_project"-vm"
export TF_VAR_region=$current_region
export TF_VAR_zone=$current_zone


terraform init || { echo "Terraform init failed"; exit 1; }
terraform plan || { echo "Terraform plan failed"; exit 1; }
terraform apply -auto-approve || { echo "Terraform apply failed"; exit 1; }


echo "Connecting to new VM"
gcloud compute ssh --zone=$current_zone $current_project"-vm" || { echo "Failed to connect to VM"; exit 1; }



# Clean Up 
echo ""
echo "You have exit your compute vm, clean up will now begin"
sleep 5

export TF_VAR_project_id=$current_project
export TF_VAR_compute_name=$current_project"-vm"
export TF_VAR_region=$current_region
export TF_VAR_zone=$current_zone

terraform destroy -auto-approve || { echo "Terraform destroy failed"; exit 1; }