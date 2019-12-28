#!/bin/bash
# Parse YAML configs in .cluster-dev/*
source ./bin/yaml.sh # provides parse_yaml and create_variables

# Variables passed by Github Workflow to Action
CLUSTER_CONFIG_PATH=$1
CLOUD_USER=$2
CLOUD_PASS=$3
# For local testing run: ./entrypoint.sh .cluster.dev/minikube-one.yaml AWSUSER AWSPASS

echo "Starting job in repo: $GITHUB_REPOSITORY with arguments  \
      CLUSTER_CONFIG_PATH: $CLUSTER_CONFIG_PATH, CLOUD_USER: $CLOUD_USER" 

# Iterate trough provided manifests and reconcile clusters
for CLUSTER_MANIFEST_FILE in $(find $CLUSTER_CONFIG_PATH -type f); do

parse_yaml $CLUSTER_MANIFEST_FILE
create_variables $CLUSTER_MANIFEST_FILE

case $cluster_cloud_provider in
aws)
# Define AWS credentials
export AWS_ACCESS_KEY_ID=$CLOUD_USER
export AWS_SECRET_ACCESS_KEY=$CLOUD_PASS
export AWS_DEFAULT_REGION=$cluster_cloud_region

case $cluster_provisioner_type in 
minikube)
echo "Cloud Provider AWS. Provisioner: Minikube" 

#GITHUB_REPOSITORY="shalb/cluster.dev"
# create uniqe s3 bucket from repo name and cluster name
S3_BACKEND_BUCKET=$(echo $GITHUB_REPOSITORY|awk -F "/" '{print$1}')-$cluster_name
# make sure it is not larger than 63 symbols 
S3_BACKEND_BUCKET=$(echo $S3_BACKEND_BUCKET| cut -c 1-63)
echo "Terrafrom S3 bucket:" $S3_BACKEND_BUCKET

# Create and init backend.
cd terraform/aws/backend/
terraform init && terraform apply -auto-approve -var="region=$cluster_cloud_region" -var="s3_backend_bucket=$S3_BACKEND_BUCKET"
aws s3 
#        -backend-config="bucket=$S3_BACKEND_BUCKET" \
#        -backend-config="key=$cluster_name/terraform.state" \
#        -backend-config="region=$cluster_cloud_region" \
#        -backend-config="access_key=$CLOUD_USER" \
#        -backend-config="secret_key=$CLOUD_PASS" 

;;

eks)
echo "Cloud Provider AWS. Provisioner: EKS" 
;;
esac
;;

gcp)
echo "Cloud Provider Google"
;;

azure)
echo "Cloud Provider Azure"
;;

esac

done

echo ::set-output name=status::\ exit_status=$?  