# Cognito Test Application

This project provides a single-page application (SPA) and a backend API to test AWS Cognito User Pool functionality, including SignUp, SignIn, JWT retrieval, and API authentication. The SPA is hosted on S3, and the backend API is deployed via API Gateway with a Lambda authorizer.

## Folder Structure
```
cognito-test-app/
├── singlepageApp/           # SPA for SignUp, SignIn, and JWT testing
│   ├── index.html
│   ├── app.js
├── backendServiceApi/       # Backend API and authorizer Lambda
│   ├── index.js
│   ├── authorizer.js
├── terraform/               # Terraform configuration for deployment
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
├── README.md
```

## Prerequisites
- AWS account with permissions to create S3 buckets, Lambda functions, API Gateway, and IAM roles.
- AWS Cognito User Pool with a client ID (configured using the provided Cognito module).
- Terraform >= 1.0 and AWS CLI configured.
- Node.js dependencies (`jsonwebtoken`, `jwks-rsa`) installed in `backendServiceApi/`.

## Setup
1. **Configure Cognito User Pool**:
   - Deploy a Cognito User Pool using the provided module (e.g., with `enable_multi_tenant_saas = true` for tenant support).
   - Note the User Pool ID and Client ID from the module outputs (`cognito_user_pool_id`, `cognito_user_pool_client_ids[0]`).

2. **Update SPA and Authorizer**:
   - In `singlepageApp/app.js`, replace:
     ```javascript
     const poolData = {
       UserPoolId: 'YOUR_USER_POOL_ID',
       ClientId: 'YOUR_CLIENT_ID'
     };
     const apiUrl = 'YOUR_API_GATEWAY_URL';
     ```
     with your Cognito User Pool ID, Client ID, and API Gateway URL (from Terraform outputs).
   - In `backendServiceApi/authorizer.js`, replace:
     ```javascript
     const userPoolId = 'YOUR_USER_POOL_ID';
     const region = 'us-east-1';
     ```
     with your User Pool ID and AWS region.

3. **Install Backend Dependencies**:
   ```bash
   cd backendServiceApi
   npm install jsonwebtoken jwks-rsa
   ```

4. **Deploy with Terraform**:
   ```bash
   cd terraform
   terraform init
   terraform apply -var="region=us-east-1" -var="user_pool_id=<your-user-pool-id>" -var="user_pool_client_id=<your-client-id>" -var="environment=dev"
   ```

5. **Access the SPA**:
   - Open the S3 website URL from the Terraform output (`spa_url`).
   - Use the SPA to SignUp, SignIn, retrieve the JWT, and test the API.

## Usage
1. **Sign Up**:
   - Enter an email, password, and optional `tenant_id` (e.g., `tenant_123`).
   - Click "Sign Up" to register. Verify the email via the Cognito confirmation code (if auto-verification is disabled).

2. **Sign In**:
   - Enter the email and password.
   - Click "Sign In" to authenticate and retrieve the JWT (displayed in the textarea).

3. **Copy JWT**:
   - Click "Copy JWT" to copy the token to your clipboard.

4. **Test API**:
   - Click "Call API" to send a GET request to the backend API with the JWT.
   - If the JWT is valid, the API returns:
     ```json
     {
       "message": "Successfully authenticated! JWT is valid."
     }
     ```

## Outputs
| Name      | Description                          |
|-----------|--------------------------------------|
| `spa_url` | URL of the SPA hosted on S3          |
| `api_url` | URL of the API Gateway endpoint      |

## Notes
- Ensure the Cognito User Pool allows email sign-in and has `custom:tenant_id` in `read_attributes` for multi-tenant setups.
- The backend API requires the Essentials or Plus tier for access token customization (if using `custom:tenant_id`).
- Update CORS settings in `backendServiceApi/index.js` if the SPA is hosted on a different domain.
- The authorizer validates JWT signatures using the Cognito JWKS. Add custom logic (e.g., `tenant_id` validation) as needed.

## Troubleshooting
- **SignUp/SignIn Errors**: Verify User Pool ID, Client ID, and email verification settings.
- **API Errors**: Ensure the JWT is valid and the API Gateway authorizer has correct permissions.
- **CORS Issues**: Check the `Access-Control-Allow-Origin` header in `index.js`.


<br><br><br>
# Integration with Cognito Module
To use this with the Cognito module from previous messages:
```hcl
module "cognito_pool" {
  source = "./path/to/cognito/module"

  enable_module     = true
  environment       = "dev"
  cognito_pool_name = "test-app"
  enable_multi_tenant_saas = true
  jwt_custom_claims = ["tenant_id"]

  custom_schemas = [
    {
      name                     = "tenant_id"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = true
      min_length               = 1
      max_length               = 50
    }
  ]

  app_clients = [
    {
      name                 = "test-client"
      callback_urls        = ["http://localhost:3000"]
      logout_urls          = ["http://localhost:3000"]
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["email", "openid", "profile"]
      generate_secret      = false
      read_attributes      = ["email", "custom:tenant_id"]
      write_attributes     = ["email", "custom:tenant_id"]
      access_token_validity = 1
      id_token_validity     = 1
      refresh_token_validity = 30
      token_validity_units   = "days"
    }
  ]

  sign_in_attribute       = ["email"]
  auto_verified_attributes = ["email"]
  tags = {
    Environment = "dev"
  }
}

module "cognito_test_app" {
  source = "./path/to/test/app/terraform"

  region             = "us-east-1"
  user_pool_id       = module.cognito_pool.cognito_user_pool_id
  user_pool_client_id = module.cognito_pool.cognito_user_pool_client_ids[0]
  environment        = "dev"
}
```
