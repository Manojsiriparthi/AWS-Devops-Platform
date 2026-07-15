#!/bin/bash

# Script to update CodeBuild projects with correct environment variables

# Update QA CodeBuild project
aws codebuild update-project \
  --name "your-qa-codebuild-project-name" \
  --environment '{
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",
    "computeType": "BUILD_GENERAL1_MEDIUM",
    "environmentVariables": [
      {
        "name": "ENV",
        "value": "qa",
        "type": "PLAINTEXT"
      }
    ]
  }'

# Update Prod CodeBuild project
aws codebuild update-project \
  --name "your-prod-codebuild-project-name" \
  --environment '{
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",
    "computeType": "BUILD_GENERAL1_MEDIUM",
    "environmentVariables": [
      {
        "name": "ENV",
        "value": "prod",
        "type": "PLAINTEXT"
      }
    ]
  }'

echo "CodeBuild projects updated with correct environment variables"