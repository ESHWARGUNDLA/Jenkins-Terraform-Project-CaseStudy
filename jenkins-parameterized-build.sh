#!/bin/bash

# Jenkins Execute Shell Build Steps for Terraform Azure Case Study (Parameterized)
# This script handles different actions: plan, apply, destroy
# Add a Choice Parameter named "ACTION" in Jenkins job with values: plan, apply, destroy

echo "=========================================="
echo "Jenkins Terraform Build - Action: ${ACTION}"
echo "=========================================="

# Validate ACTION parameter
if [ -z "${ACTION}" ]; then
    echo "ERROR: ACTION parameter is required"
    echo "Valid options: plan, apply, destroy"
    exit 1
fi

# Set Azure credentials
echo "Setting up Azure credentials..."
export ARM_CLIENT_ID=${AZURE_CLIENT_ID}
export ARM_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
export ARM_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
export ARM_TENANT_ID=${AZURE_TENANT_ID}

# Verify Terraform installation
terraform version
if [ $? -ne 0 ]; then
    echo "ERROR: Terraform is not installed"
    exit 1
fi

# Navigate to workspace
cd ${WORKSPACE}
echo "Working directory: $(pwd)"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init
if [ $? -ne 0 ]; then
    echo "ERROR: Terraform initialization failed"
    exit 1
fi

# Execute based on ACTION parameter
case "${ACTION}" in
    "plan")
        echo "========== TERRAFORM PLAN =========="
        terraform fmt -check
        terraform validate
        terraform plan -detailed-exitcode
        ;;
        
    "apply")
        echo "========== TERRAFORM APPLY =========="
        terraform fmt -check
        terraform validate
        terraform plan -out=tfplan
        if [ $? -eq 0 ]; then
            terraform apply tfplan
            if [ $? -eq 0 ]; then
                echo "Terraform outputs:"
                terraform output
            else
                echo "ERROR: Terraform apply failed"
                exit 1
            fi
        else
            echo "ERROR: Terraform plan failed"
            exit 1
        fi
        ;;
        
    "destroy")
        echo "========== TERRAFORM DESTROY =========="
        echo "WARNING: This will destroy all resources!"
        terraform plan -destroy -out=destroy-plan
        if [ $? -eq 0 ]; then
            terraform apply destroy-plan
        else
            echo "ERROR: Terraform destroy plan failed"
            exit 1
        fi
        ;;
        
    *)
        echo "ERROR: Invalid ACTION parameter: ${ACTION}"
        echo "Valid options: plan, apply, destroy"
        exit 1
        ;;
esac

echo "=========================================="
echo "Action '${ACTION}' completed successfully"
echo "=========================================="
