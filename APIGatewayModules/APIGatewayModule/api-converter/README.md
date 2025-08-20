# AWS API Gateway Converter Scripts

This repository contains two Node.js scripts for converting a base `swagger.json` into AWS API Gateway-compatible specifications. The scripts are designed to work with a Terraform module that deploys an API Gateway with support for microservices (VPC Link, Cognito, API keys) and AWS services (SQS). The scripts are split to separate concerns: one for microservices and another for AWS service integrations, with extensibility for future additions.

## Table of Contents
- [Design Approach](#design-approach)
- [Prerequisites](#prerequisites)
- [Scripts Overview](#scripts-overview)
  - [aws-apigw-converter-microservices-v1.js (Microservices)](#aws-apigw-converter-v1js-microservices)
  - [aws-apigw-converter-awssvc-v1.js (AWS Services - SQS)](#aws-apigw-converter-svc-v1js-aws-services---sqs)
- [Changes in the Split Scripts](#changes-in-the-split-scripts)
- [Using the Scripts with Terraform](#using-the-scripts-with-terraform)
- [What is an API Key and Where is it Required?](#what-is-an-api-key-and-where-is-it-required)
- [Example Usage](#example-usage)
- [Conclusion](#conclusion)
- [Next Steps](#next-steps)

## Design Approach

The scripts are designed to generate AWS API Gateway-compatible Swagger files from a base `swagger.json`, tailored for specific integrations and environments. They are split to handle distinct use cases:

### aws-apigw-converter-microservices-v1.js
- **Purpose**: Handles microservice-related integrations.
- **Integrations**: Supports VPC Link (Network Load Balancer), Cognito authorization, and API keys.
- **Environments**: Supports all environments (`DEV`, `UAT`, `PROD`, `TF_VAR`).
- **Variables**:
  - `basePath`: NLB URI (e.g., `http://${nlb_uri}:8087`).
  - `cognitoId`: Cognito User Pool ARN and enablement flag (e.g., `["${cognito_arn}", true]`).
  - `connectionId`: VPC Link ID (e.g., `${vpc_link_id}`).
  - `api_title`: API title (e.g., `${api_title}`).
  - `description`: Environment description (e.g., `${env}`).
  - `host`: Custom domain (e.g., `${api_custom_domain}`).
  - `enable_api_key`: Boolean or string to enable API key security (e.g., `"true"`).
  - `intTimeoutMs`, `excludedTimeoutMs`: Timeout settings for paths.
  - `excludedPaths`: Paths exempt from security (e.g., `/public/healthcheck`).
- **Output**: Generates Swagger with `x-amazon-apigateway-integration` for `http_proxy` (VPC Link) and security for Cognito and API keys.
- **Exclusions**: Does not handle SQS or other AWS service integrations.

### aws-apigw-converter-awssvc-v1.js
- **Purpose**: Handles AWS service integrations, specifically SQS (e.g., `/v1/case/event` endpoint).
- **Integrations**: Generates `x-amazon-apigateway-integration` for `aws` (SQS).
- **Environments**: Supports a subset of environments where SQS is relevant (`DEV`, `SWF_DEV`, `TF_VAR`).
- **Variables**:
  - `sqs_queue_name`: SQS queue name (e.g., `${sqs_queue_name}`).
  - `aws_account_id`: AWS account ID (e.g., `${aws_account_id}`).
  - `sqs_iam_role`: IAM role ARN for SQS (e.g., `${sqs_iam_role}`).
  - `aws_region`: AWS region (e.g., `${aws_region}`).
  - `api_title`, `description`, `host`: Same as microservices script.
  - `intTimeoutMs`, `excludedTimeoutMs`, `excludedPaths`: Same as microservices script.
- **Extensibility**: Designed to support additional AWS services (e.g., Lambda, SNS) via modular path checks (e.g., `isLambdaPath`).
- **Output**: Generates Swagger with `x-amazon-apigateway-integration` for `aws` (SQS) and `mock` for OPTIONS (CORS).

## Prerequisites
- **Node.js**: Version >= 12.
- **Dependencies**: None (uses Node.js built-in `fs` module).
- **Input File**: A valid `swagger.json` with paths, methods, and unique `operationId` values.
- **Terraform Module**: A compatible Terraform module that uses `aws_api_gateway_rest_api` with a `templatefile` function to consume the generated Swagger files.
- **Environment Setup**: Ensure environment variables (e.g., `nlb_uri`, `cognito_arn`) are defined for `TF_VAR` mode or hardcoded in `ENV_VAR` for specific environments.

## Scripts Overview

### aws-apigw-converter-microservices-v1.js (Microservices)
- **Description**: Converts `swagger.json` into an API Gateway-compatible specification for microservice endpoints using VPC Link, Cognito, and API keys.
- **Output File**: `swagger-converted-${env}.json`
- **Key Features**:
  - Processes all paths in `swagger.json` with `http_proxy` integration.
  - Supports Cognito authorization via `securityDefinitions` and `security` fields.
  - Supports API keys when `enable_api_key` is true.
  - Handles CORS with OPTIONS methods and gateway responses.
  - Configurable timeouts and excluded paths for security.

### aws-apigw-converter-awssvc-v1.js (AWS Services - SQS)
- **Description**: Converts `swagger.json` into an API Gateway-compatible specification for SQS endpoints (e.g., `/v1/case/event`).
- **Output File**: `swagger-converted-sqs-${env}.json`
- **Key Features**:
  - Filters paths to process only SQS endpoints.
  - Generates `x-amazon-apigateway-integration` with `type: aws` for SQS.
  - Uses `mock` integration for OPTIONS to simplify CORS.
  - Validates SQS-specific variables.
  - Extensible for other AWS services (e.g., Lambda, SNS).

## Changes in the Split Scripts

### aws-apigw-converter-microservices-v1.js
- **Removed**: SQS-related variables (`sqs_queue_name`, `aws_account_id`, `sqs_iam_role`, `aws_region`) from `ENV_VAR`.
- **Focus**: Processes all paths in `swagger.json` with `http_proxy` integration for VPC Link.
- **Security**: Supports Cognito (`cognito-auth`) and API keys (`api_key`) via conditional `securityDefinitions`.
- **Features**:
  - Maintains timeout logic (`intTimeoutMs`, `excludedTimeoutMs`).
  - Handles CORS with `Access-Control-Allow-*` headers.
  - Supports query and path parameters via `getParams`.
- **TF_VAR Mode**: Preserves Terraform placeholders (e.g., `${nlb_uri}`, `${cognito_arn}`).

### aws-apigw-converter-awssvc-v1.js
- **Included**: Only SQS-related variables and environments (`DEV`, `SWF_DEV`, `TF_VAR`).
- **Focus**: Processes only SQS endpoints (e.g., `/v1/case/event`) with `type: aws`.
- **Security**: Uses IAM roles (`sqs_iam_role`) for SQS; API keys can be added if needed.
- **Features**:
  - Uses `mock` integration for OPTIONS to simplify CORS.
  - Validates SQS-specific fields (`sqs_queue_name`, `aws_account_id`, `sqs_iam_role`, `aws_region`).
  - Extensible structure for future AWS services (e.g., add `isLambdaPath`).
- **TF_VAR Mode**: Preserves Terraform placeholders (e.g., `${sqs_queue_name}`).

### Common Features
- **Output**: Both scripts write to files (`swagger-converted-${env}.json` or `swagger-converted-sqs-${env}.json`).
- **Terraform Support**: `TF_VAR` mode preserves placeholders for use with Terraform's `templatefile`.
- **Error Handling**: Validates required fields and `swagger.json` paths/methods.
- **CORS**: Includes `Access-Control-Allow-*` headers in gateway responses.

## Using the Scripts with Terraform

### Microservices
1. **Generate Swagger File**:
   ```bash
   node aws-apigw-converter-microservices-v1.js TF_VAR
   ```
   - Output: `swagger-converted-TF_VAR.json`
   - Use when `var.integrate_sqs_queue` is `false` in the Terraform module.
2. **Terraform Configuration**:
   ```hcl
   module "api_gateway" {
     source            = "./path/to/module"
     enable_module     = true
     enable_api_key    = true
     api_key_name      = "my-api-key"
     usage_plan_name   = "my-usage-plan"
     swagger_file_path  = "./swagger-converted-TF_VAR.json"
     integrate_sqs_queue = false
     ...
   }
   ```

### SQS
1. **Generate Swagger File**:
   ```bash
   node aws-apigw-converter-awssvc-v1.js TF_VAR
   ```
   - Output: `swagger-converted-sqs-TF_VAR.json`
   - Use when `var.integrate_sqs_queue` is `true`.
2. **Terraform Configuration**:
   ```hcl
   module "api_gateway" {
     source            = "./path/to/module"
     enable_module     = true
     integrate_sqs_queue = true
     sqs_queue_name    = "my-queue"
     aws_account_id    = "123456789012"
     sqs_iam_role      = "arn:aws:iam::123456789012:role/apigw-sqs-role"
     swagger_file_path  = "./swagger-converted-sqs-TF_VAR.json"
     ...
   }
   ```

### Combined Use
If both microservices and SQS endpoints are needed:
1. Run both scripts:
   ```bash
   node aws-apigw-converter-microservices-v1.js TF_VAR
   node aws-apigw-converter-awssvc-v1.js TF_VAR
   ```
2. **Merge Swagger Files**:
   - Manually combine `swagger-converted-TF_VAR.json` and `swagger-converted-sqs-TF_VAR.json` into a single `swagger.json` with all paths.
   - Alternatively, update the base `swagger.json` to include both VPC Link and SQS integrations (e.g., using conditional logic like `${sqs_queue_name != '' ? 'aws' : 'http_proxy'}`).
3. **Terraform Configuration**:
   ```hcl
   module "api_gateway" {
     source            = "./path/to/module"
     enable_module     = true
     enable_api_key    = true
     integrate_sqs_queue = true
     swagger_file_path  = "./merged-swagger.json"
     ...
   }
   ```

## What is an API Key and Where is it Required?

### What is an API Key?
An API key is a unique identifier (e.g., `xY9z2aB7cD8eF9gH`) used to authenticate and control access to an API in AWS API Gateway.

- **Purpose**: Provides lightweight authentication to restrict access, track usage, and enforce quotas/throttling.
- **How it Works**: Clients include the API key in the `x-api-key` header of HTTP requests. API Gateway validates it against a configured API key resource and usage plan.
- **Security**: API keys are not highly secure alone (susceptible to interception without HTTPS). Use with IP whitelisting, Cognito, or IAM roles for stronger security.
- **Terraform Configuration**:
  - Enabled via `var.enable_api_key` (creates `aws_api_gateway_api_key`, `aws_api_gateway_usage_plan`, `aws_api_gateway_usage_plan_key`).
  - Key is output as `api_key_value` (sensitive).
  - Swagger file must include:
    ```json
    "securityDefinitions": {
      "api_key": {
        "type": "apiKey",
        "name": "x-api-key",
        "in": "header"
      }
    }
    ```

### Where is the API Key Required?

#### In the Terraform Module
- **When Enabled**: Set `var.enable_api_key = true` to create an API key and associate it with a usage plan for the API stage.
- **Usage Plan**: Defined by `var.usage_plan_name`, enforces quotas (`var.quota_limit`, `var.quota_period`) and throttling (`var.throttling_burst_limit`, `var.throttling_rate_limit`).
- **Endpoints**: Endpoints requiring API keys must have:
  ```json
  "/v1/user": {
    "get": {
      "security": [{"api_key": []}],
      ...
    }
  }
  ```
- **Use Case**: Restrict access to endpoints like `/v1/user` or `/v1/lead` for public-facing APIs or partner integrations.

#### In the Swagger File
- **Security Definitions**: Include `api_key` in `securityDefinitions` (as above).
- **Endpoint Security**: Apply `{"api_key": []}` to protected methods.
- **Script Support**:
  - `aws-apigw-converter-microservices-v1.js`: Adds `api_key` to `securityDefinitions` and non-excluded paths when `enable_api_key` is true.
  - `aws-apigw-converter-awssvc-v1.js`: Does not currently include API keys (SQS uses IAM roles). Add `enable_api_key` to `ENV_VAR` if needed.

#### In the Converter Scripts
- **aws-apigw-converter-microservices-v1.js**: Supports API keys for microservice endpoints (e.g., `/v1/user`) when `enable_api_key` is true (e.g., `DEV`, `SWF_DEV`).
- **aws-apigw-converter-awssvc-v1.js**: No API key support by default (SQS uses `sqs_iam_role`). Add `enable_api_key` to `ENV_VAR` and update `getAwsAPIModal` if required.
- **Usage**: Run with an environment where `enable_api_key` is true:
  ```bash
  node aws-apigw-converter-microservices-v1.js DEV
  ```

#### When is it Required?
- **Public/Partner APIs**: For external clients (e.g., third-party developers, partners) needing simple authentication.
- **Usage Tracking**: To monitor/limit API usage per client via usage plans.
- **Non-Cognito Scenarios**: When `var.use_cognito_auth` is false, API keys provide an alternative.
- **Specific Endpoints**: For endpoints not requiring Cognito (e.g., `/v1/lead`).

#### When is it Not Required?
- **Cognito/IAM Authentication**: If endpoints use Cognito (`var.use_cognito_auth`) or IAM roles (e.g., SQS in `aws-apigw-converter-awssvc-v1.js`).
- **Private APIs**: If `var.enable_private_endpoint` is true with VPC endpoints or IP whitelisting (`var.ip_white_list_enable`).
- **Excluded Paths**: Paths like `/public/healthcheck` (in `excludedPaths`) for open access.

## Example Usage

### Microservices Setup
1. **Prepare `swagger.json`**:
   - Ensure it includes paths like `/actuator/health`, `/v1/user` with unique `operationId` values.
2. **Run Converter**:
   ```bash
   node aws-apigw-converter-microservices-v1.js DEV
   ```
   - Output: `swagger-converted-DEV.json`
3. **Terraform Apply**:
   ```hcl
   module "api_gateway" {
     source            = "./path/to/module"
     enable_module     = true
     enable_api_key    = true
     api_key_name      = "my-api-key"
     usage_plan_name   = "my-usage-plan"
     swagger_file_path  = "./swagger-converted-DEV.json"
     integrate_sqs_queue = false
     use_cognito_auth  = true
     cognito_arn       = "arn:aws:cognito-idp:us-east-1:509399633990:userpool/us-east-1_kB7SM3JTd"
     nlb_uri           = "dev-backend-nxw-nlb-ed157f9d3320f31b.elb.us-east-1.amazonaws.com"
     vpc_link_id       = "sw9dua"
     ...
   }
   ```
4. **Client Request**:
   ```bash
   curl -H "x-api-key: xY9z2aB7cD8eF9gH" -H "Authorization: Bearer <cognito-token>" \
     https://api.dev.example.com/v1/user?userId=123
   ```

### SQS Setup
1. **Prepare `swagger.json`**:
   - Include `/v1/case/event` with a POST method and unique `operationId`.
2. **Run Converter**:
   ```bash
   node aws-apigw-converter-awssvc-v1.js SWF_DEV
   ```
   - Output: `swagger-converted-sqs-SWF_DEV.json`
3. **Terraform Apply**:
   ```hcl
   module "api_gateway" {
     source            = "./path/to/module"
     enable_module     = true
     integrate_sqs_queue = true
     sqs_queue_name    = "swf-dev-case-queue"
     aws_account_id    = "509399633990"
     sqs_iam_role      = "arn:aws:iam::509399633990:role/swf-dev-apigw-sqs-role"
     swagger_file_path  = "./swagger-converted-sqs-SWF_DEV.json"
     ...
   }
   ```
4. **Client Request**:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     -d '{"event": "case_update"}' \
     https://api.swf-dev.example.com/v1/case/event
   ```

## Conclusion
- **Split Scripts**:
  - `aws-apigw-converter-microservices-v1.js`: For microservices with VPC Link, Cognito, and API keys. Use for endpoints like `/actuator/health`, `/v1/user`.
  - `aws-apigw-converter-awssvc-v1.js`: For SQS integration (e.g., `/v1/case/event`). Extensible for other AWS services (e.g., Lambda, SNS).
  - Both support `TF_VAR` mode for Terraform and write output to files for `var.swagger_file_path`.
- **API Key**:
  - A unique string for lightweight authentication and usage tracking.
  - Required for public/partner APIs or non-Cognito scenarios.
  - Supported in `aws-apigw-converter-microservices-v1.js` via `enable_api_key`; can be added to `aws-apigw-converter-awssvc-v1.js` if needed.

## Next Steps
- **Test Scripts**:
  ```bash
  node aws-apigw-converter-microservices-v1.js TF_VAR
  node aws-apigw-converter-awssvc-v1.js TF_VAR
  ```
  Verify outputs (`swagger-converted-TF_VAR.json`, `swagger-converted-sqs-TF_VAR.json`) and test with Terraform `plan`/`apply`.
- **Extend for Other Services**: Add support for Lambda, SNS, etc., in `aws-apigw-converter-awssvc-v1.js` by defining new path checks (e.g., `isLambdaPath`) and integration types.
- **OpenAPI 3.0**: Update scripts to support OpenAPI 3.0 if needed (e.g., handle `servers` instead of `host`).
- **Documentation**: Regularly update this README with new features or environment configurations.