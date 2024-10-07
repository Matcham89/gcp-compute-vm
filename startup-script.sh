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

# Set project id
random_string=$(openssl rand -hex 5)
current_project="vm-quickstart-${random_string}"
gcloud projects create $current_project
gcloud config set project $current_project


# Capture project id
echo "capturing current project"
current_project=$(gcloud config get-value project) || { echo "Failed to capture project"; exit 1; }
echo $current_project

echo "connect gcloud CLI"
echo "answer 'Y' for all follow prompts"
sleep 3
# Connect to console from CLI
gcloud auth application-default login
gcloud auth application-default set-quota-project $current_project

# Capture current region
current_region=$(gcloud config get-value compute/region) || { echo "Failed to capture region"; exit 1; }

# If no region is set, default to europe-west2
if [ -z "$current_region" ]; then
  gcloud config set compute/region europe-west2
  echo "Region was not set. Defaulting to europe-west2."
else
  echo "Current region is $current_region."
fi

# Capture current zone
current_zone=$(gcloud config get-value compute/zone) || { echo "Failed to capture zone"; exit 1; }

# If no zone is set, default to europe-west2-b
if [ -z "$current_zone" ]; then
  gcloud config set compute/zone europe-west2-b
  echo "Zone was not set. Defaulting to europe-west2-b."
else
  echo "Current zone is $current_zone."
fi


# Connect billing account
echo "enable billing"
billing_account=$(gcloud billing accounts list --filter="open=true" --format="value(ACCOUNT_ID)")
gcloud billing projects link $current_project --billing-account $billing_account || { echo "Failed to enable billing"; exit 1; }
sleep 3

# Enable compute services API
echo "enable compute.googleapis.com API"
gcloud services enable compute.googleapis.com || { echo "Failed to enable compute services"; exit 1; }
sleep 3



# Enter user email address
echo "capturing email address"
current_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)") || { echo "Failed to capture account"; exit 1; }
echo $current_account


# Set user permissions
gcloud projects add-iam-policy-binding $current_project --member="user:${current_account}" --role=roles/compute.instanceAdmin.v1 || { echo "Failed to add IAM policy binding"; exit 1; }

echo "Applying Terraform!"
sleep 1

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

echo "close project"
gcloud projects delete $current_project

echo "clean up complete"
