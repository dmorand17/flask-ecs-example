#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

CLUSTER_NAME=$1
aws ecs create-cluster --cluster-name ${CLUSTER_NAME}

aws ecs create-express-gateway-service \
    --execution-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole" \
    --infrastructure-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsInfrastructureRoleForExpressServices" \
    --primary-container '{
        "image": "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/flask-ecs-example:latest",
        "containerPort": 5000,
        "environment": [{
            "name": "ENV",
            "value": "Prod"
        },
        {
            "name": "DEBUG",
            "value": "false"
        }]
    }' \
    --cluster ${CLUSTER_NAME} \
    --service-name "flask-ecs-app" \
    --cpu "1024" \
    --memory "2048" \
    --health-check-path "/health" \
    --scaling-target '{"minTaskCount":1,"maxTaskCount":2}' \
    --monitor-resources
