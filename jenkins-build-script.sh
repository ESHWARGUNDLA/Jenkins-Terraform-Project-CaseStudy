#!/bin/bash

# Jenkins Execute Shell Build Steps for Terraform Azure Case Study
# This script should be placed in the "Execute shell" section of your Jenkins job

echo "=========================================="
echo "Starting Jenkins Terraform Build Process"
echo "=========================================="

# Step 1: Set environment variables for Azure authentication
echo "Step 1: Setting up Azure credentials..."
export ARM_CLIENT_ID=${AZURE_CLIENT_ID}
export ARM_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
export ARM_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
export ARM_TENANT_ID=${AZURE_TENANT_ID}

# Step 2: Verify Terraform installation
echo "Step 2: Verifying Terraform installation..."
terraform version
if [ $? -ne 0 ]; then
    echo "ERROR: Terraform is not installed or not in PATH"
    exit 1
fi

# Step 3: Navigate to workspace directory
echo "Step 3: Navigating to workspace directory..."
cd ${WORKSPACE}
pwd
ls -la

# Step 4: Initialize Terraform
echo "Step 4: Initializing Terraform..."
terraform init
if [ $? -ne 0 ]; then
    echo "ERROR: Terraform initialization failed"
    exit 1
fi

# Step 5: Format and validate Terraform code
echo "Step 5: Formatting and validating Terraform configuration..."
terraform fmt -check
terraform validate
if [ $? -ne 0 ]; then
    echo "ERROR: Terraform validation failed"
    exit 1
fi

# Step 6: Create Terraform plan
echo "Step 6: Creating Terraform execution plan..."
terraform plan -out=tfplan -detailed-exitcode
PLAN_EXIT_CODE=$?

case $PLAN_EXIT_CODE in
    0)
        echo "No changes detected in Terraform plan"
        ;;
    1)
        echo "ERROR: Terraform plan failed"
        exit 1
        ;;
    2)
        echo "Changes detected in Terraform plan"
        ;;
esac

# Step 7: Apply Terraform changes (only if changes detected)
if [ $PLAN_EXIT_CODE -eq 2 ]; then
    echo "Step 7: Applying Terraform changes..."
    terraform apply tfplan
    if [ $? -ne 0 ]; then
        echo "ERROR: Terraform apply failed"
        exit 1
    fi
    
    # Step 8: Display outputs
    echo "Step 8: Displaying Terraform outputs..."
    terraform output
else
    echo "Step 7: Skipping apply - no changes needed"
fi

# Step 9: Save state file (for backup)
echo "Step 9: Backing up Terraform state..."
if [ -f "terraform.tfstate" ]; then
    cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
fi

echo "=========================================="
echo "Jenkins Terraform Build Process Completed"
echo "=========================================="
