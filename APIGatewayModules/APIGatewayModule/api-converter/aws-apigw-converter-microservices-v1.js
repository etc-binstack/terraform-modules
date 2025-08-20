const baseOpenAPIJson = require('./swagger.json');
const fs = require('fs');

const ENV_VAR = {
  PROD: {
    basePath: 'http://prod-lcfca-backend-2bw-nlb-56cb15679feca759.elb.us-east-1.amazonaws.com:8087',
    cognitoId: ["arn:aws:cognito-idp:us-east-1:194722438735:userpool/us-east-1_pK4Y6Qumn", true],
    connectionId: "bzvtd7",
    api_title: "prod-isosubm-isoappwf-apigw",
    description: "prod",
    host: "api.prod.example.com",
    enable_api_key: false,
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info", "v1/iso/system/app/version"]
  },
  UAT: {
    basePath: 'http://uat-lcfca-backend-459-nlb-4de34fbfcb83cb0d.elb.us-east-1.amazonaws.com:8087',
    cognitoId: ["arn:aws:cognito-idp:us-east-1:491085406230:userpool/us-east-1_MAu1f6ZQn", true],
    connectionId: "4598s0",
    api_title: "uat-isosubm-isoappwf-apigw",
    description: "uat",
    host: "api.uat.example.com",
    enable_api_key: false,
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info"]
  },
  DEV: {
    basePath: 'http://dev-lcfca-backend-nxw-nlb-ed157f9d3320f31b.elb.us-east-1.amazonaws.com:8087',
    cognitoId: ["arn:aws:cognito-idp:us-east-1:509399633990:userpool/us-east-1_kB7SM3JTd", true],
    connectionId: "sw9dua",
    api_title: "dev-isosubm-isoappwf-apigw",
    description: "dev",
    host: "api.dev.example.com",
    enable_api_key: true,
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info"]
  },
  TF_VAR: {
    basePath: 'http://${nlb_uri}:8087',
    cognitoId: ["${cognito_arn}", true],
    connectionId: "${vpc_link_id}",
    api_title: "${api_title}",
    description: "${env}",
    host: "${api_custom_domain}",
    enable_api_key: "${enable_api_key}",
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info"]
  }
};

// Helper function to get Cognito configuration
function getCognitoConfig(envVars) {
  if (Array.isArray(envVars.cognitoId)) {
    return {
      arn: envVars.cognitoId[0],
      enabled: envVars.cognitoId[1]
    };
  }
  return {
    arn: envVars.cognitoId,
    enabled: true
  };
}

// Timeout logic with exclusion for specific paths
function getTimeoutForPath(path, envVars) {
  if (envVars.excludedPaths.includes(path)) {
    return envVars.excludedTimeoutMs || 29000;
  }
  return envVars.intTimeoutMs || 60000;
}

// Function to generate request parameters for paths
function getParams(params) {
  if (!params) return {};
  let obj = {};
  params.forEach(param => {
    if (param.in === 'path') {
      obj[`integration.request.path.${param.name}`] = `method.request.path.${param.name}`;
    } else if (param.in === 'query') {
      obj[`integration.request.querystring.${param.name}`] = `method.request.querystring.${param.name}`;
    }
  });
  return obj;
}

// Function to generate the AWS API Gateway modal
function getAwsAPIModal(envVars) {
  const cognitoConfig = getCognitoConfig(envVars);
  const baseModal = {
    swagger: "2.0",
    info: {
      description: envVars.description,
      version: "v0",
      title: envVars.api_title
    },
    host: envVars.host || "",
    schemes: ["https"],
    paths: {},
    securityDefinitions: {},
    "x-amazon-apigateway-gateway-responses": {
      DEFAULT_4XX: {
        responseParameters: {
          "gatewayresponse.header.Access-Control-Allow-Methods": "'GET,POST,DELETE,PATCH,OPTIONS'",
          "gatewayresponse.header.Access-Control-Allow-Origin": "'*'",
          "gatewayresponse.header.Access-Control-Allow-Headers": "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        },
        responseTemplates: {
          "application/json": "{\"message\":$context.error.messageString}"
        }
      },
      DEFAULT_5XX: {
        responseParameters: {
          "gatewayresponse.header.Access-Control-Allow-Methods": "'GET,POST,DELETE,PATCH,OPTIONS'",
          "gatewayresponse.header.Access-Control-Allow-Origin": "'*'",
          "gatewayresponse.header.Access-Control-Allow-Headers": "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        },
        responseTemplates: {
          "application/json": "{\"message\":$context.error.messageString}"
        }
      }
    }
  };

  if (cognitoConfig.enabled && cognitoConfig.arn && cognitoConfig.arn !== "${cognito_arn}") {
    baseModal.securityDefinitions["cognito-auth"] = {
      type: "apiKey",
      name: "Authorization",
      in: "header",
      "x-amazon-apigateway-authtype": "cognito_user_pools",
      "x-amazon-apigateway-authorizer": {
        type: "cognito_user_pools",
        providerARNs: [cognitoConfig.arn]
      }
    };
  }

  if (envVars.enable_api_key === true || envVars.enable_api_key === "true") {
    baseModal.securityDefinitions["api_key"] = {
      type: "apiKey",
      name: "x-api-key",
      in: "header"
    };
  }

  return baseModal;
}

// Function to check if security should be excluded for a specific path
function shouldExcludeSecurity(path, cognitoEnabled, envVars) {
  if (!cognitoEnabled) return true;
  return envVars.excludedPaths.includes(path);
}

// Function to generate the canonical modal for each path and method
function getCanonicalModal(path, method, pathDetails, envVars) {
  const cognitoConfig = getCognitoConfig(envVars);
  const { parameters, operationId } = pathDetails[method] || {};
  const excludeSecurity = shouldExcludeSecurity(path, cognitoConfig.enabled, envVars);
  const timeout = getTimeoutForPath(path, envVars);

  const methodSpec = {
    operationId: operationId || `${method}${path.replace(/\//g, '_')}`,
    responses: {
      200: {
        description: "200 response",
        headers: {
          "Access-Control-Allow-Origin": { type: "string" }
        }
      }
    },
    parameters: parameters || [],
    "x-amazon-apigateway-integration": {
      connectionId: envVars.connectionId,
      connectionType: "VPC_LINK",
      type: "http_proxy",
      httpMethod: method.toUpperCase(),
      uri: `${envVars.basePath}${path}`,
      requestParameters: getParams(parameters),
      responses: {
        default: { statusCode: "200" }
      },
      passthroughBehavior: "when_no_match",
      timeoutInMillis: timeout
    }
  };

  if (!excludeSecurity) {
    methodSpec.security = [];
    if (cognitoConfig.enabled && cognitoConfig.arn && cognitoConfig.arn !== "${cognito_arn}") {
      methodSpec.security.push({ "cognito-auth": [] });
    }
    if (envVars.enable_api_key === true || envVars.enable_api_key === "true") {
      methodSpec.security.push({ "api_key": [] });
    }
  }

  return methodSpec;
}

// Initialization function to generate the complete AWS API model
function init() {
  const [env] = process.argv.slice(2);
  if (!env) {
    throw new Error('Please provide an environment argument (e.g., DEV, UAT, PROD, TF_VAR)');
  }

  const envVars = ENV_VAR[env];
  if (!envVars) {
    throw new Error(`Environment ${env} not found in ENV_VAR`);
  }

  // Validate required fields
  const requiredFields = ['basePath', 'cognitoId', 'connectionId', 'api_title', 'description'];
  const missingFields = [];
  requiredFields.forEach(field => {
    if (!envVars[field]) {
      missingFields.push(field);
    } else if (field === 'cognitoId' && Array.isArray(envVars.cognitoId)) {
      if (envVars.cognitoId.length !== 2 || !envVars.cognitoId[0] || typeof envVars.cognitoId[1] !== 'boolean') {
        missingFields.push(`${field} (must be array with [arn, boolean])`);
      }
    }
  });

  if (missingFields.length > 0) {
    throw new Error(`Invalid or missing fields for environment ${env}: ${missingFields.join(', ')}`);
  }

  if (!baseOpenAPIJson.paths || Object.keys(baseOpenAPIJson.paths).length === 0) {
    throw new Error('No paths defined in swagger.json');
  }

  const awsAPIModal = getAwsAPIModal(envVars);
  const paths = Object.keys(baseOpenAPIJson.paths);

  paths.forEach(path => {
    const pathDetails = baseOpenAPIJson.paths[path];
    const methods = Object.keys(pathDetails).filter(m => m !== 'options');
    awsAPIModal.paths[path] = {};

    methods.forEach(method => {
      if (pathDetails[method].operationId) {
        awsAPIModal.paths[path][method] = getCanonicalModal(path, method, pathDetails, envVars);
      } else {
        console.warn(`Skipping ${method} for path ${path}: missing operationId`);
      }
    });

    // Add OPTIONS method for CORS
    awsAPIModal.paths[path].options = {
      responses: {},
      "x-amazon-apigateway-integration": {
        connectionId: envVars.connectionId,
        connectionType: "VPC_LINK",
        type: "http_proxy",
        httpMethod: "OPTIONS",
        uri: `${envVars.basePath}${path}`,
        requestParameters: getParams(pathDetails[method]?.parameters),
        responses: {
          default: { statusCode: "200" }
        },
        passthroughBehavior: "when_no_match"
      }
    };
  });

  // Write output to file
  const outputFile = `swagger-converted-${env}.json`;
  fs.writeFileSync(outputFile, JSON.stringify(awsAPIModal, null, 2));
  console.log(`Generated API Gateway specification written to ${outputFile}`);
}

try {
  init();
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}