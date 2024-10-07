# Google Cloud VM Setup

This script automates the setup of a Virtual Machine (VM) in Google Cloud using `gcloud` and `terraform`. 
Follow the steps below to get started.

Be sure to use the `clean up` step at the end

## Prerequisites

Before running the script, ensure you have the following installed:

- A Google Account Set Up https://console.cloud.google.com/
- Google Cloud SDK (`gcloud`)
- Terraform

## Usage

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Matcham89/gcp-compute-vm.git
   cd gcp-compute-vm
   ```

2. **Make the Script Executable**

   ```bash
   chmod +x startup-script.sh
   ```

3. **Run the Script**

   ```bash
   ./setup_vm.sh
   ```

## Script Details

### Error Handling

The script includes error handling to exit on any command failure and display the line number where the error occurred.

### Checking Dependencies

The script checks if `gcloud` and `terraform` are installed. If not, it prompts the user to install them.

### Google Cloud Initialization

The script initializes `gcloud` and prompts the user to select the compute region and zone.

### Authentication

The script authenticates the user with Google Cloud and captures the current project, region, and zone.

### Billing and API Enablement

The script links the project to a billing account and enables the Compute Engine API.

### IAM Policy Binding

The script adds the necessary IAM policy binding for the user to manage Compute Engine instances.

### Terraform Initialization and Application

The script initializes and applies the Terraform configuration to set up the VM.

### Connecting to the VM

The script connects to the newly created VM using SSH.

## Troubleshooting

- Ensure you have the necessary permissions in your Google Cloud project.
- Verify that your billing account is active and linked to the project.
- Check the Google Cloud documentation for more details on any errors encountered.

## Clean Up

To avoid incurring charges to your Google Cloud account for the resources used on this page, delete the Google Cloud project with the resources.

The Shell will run the following command to delete the Terraform resources when you disconnect from your VM:

```bash
terraform destroy
```