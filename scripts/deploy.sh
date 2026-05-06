#!/bin/bash
# Usage: ./scripts/deploy.sh <environment> <ecr_image_uri> [aws_region]
set -e

ENVIRONMENT=$1
ECR_IMAGE_URI=$2
AWS_REGION=${3:-eu-west-2}

if [ -z "$ENVIRONMENT" ] || [ -z "$ECR_IMAGE_URI" ]; then
  echo "Usage: $0 <environment> <ecr_image_uri> [aws_region]" >&2
  exit 1
fi

CLUSTER="${ENVIRONMENT}-cluster"
SERVICE="${ENVIRONMENT}-service"

echo "Deploying $ECR_IMAGE_URI to ECS $CLUSTER/$SERVICE..."

aws ecs update-service \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --query "service.serviceName" \
  --output text

echo "Waiting for service to stabilize..."

aws ecs wait services-stable \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

echo "Deployment complete: $SERVICE is stable."
