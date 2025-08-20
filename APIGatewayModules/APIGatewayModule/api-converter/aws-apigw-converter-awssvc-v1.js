const baseOpenAPIJson = require('./swagger.json');
const fs = require('fs');

const ENV_VAR = {
  DEV: {
    sqs_queue_name: "dev-case-queue",
    aws_account_id: "509399633990",
    sqs_iam_role: "arn:aws:iam::509399633990:role/dev-apigw-sqs-role",
    aws_region: "us-east-1",
    api_title: "dev-sqs-apigw",
    description: "dev",
    host: "api.dev.example.com",
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info"]
  },
  UAT: {
    sqs_queue_name: "swf-dev-case-queue",
    aws_account_id: "509399633990",
    sqs_iam_role: "arn:aws:iam::509399633990:role/swf-dev-apigw-sqs-role",
    aws_region: "us-east-1",
    api_title: "dev-appflow-salewf-sqs-apigw",
    description: "dev",
    host: "api.swf-dev.example.com",
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info"]
  },
  TF_VAR: {
    sqs_queue_name: "${sqs_queue_name}",
    aws_account_id: "${aws_account_id}",
    sqs_iam_role: "${sqs_iam_role}",
    aws_region: "${aws_region}",
    api_title: "${api_title}",
    description: "${env}",
    host: "${api_custom_domain}",
    intTimeoutMs: 60000,
    excludedTimeoutMs: 29000,
    excludedPaths: ["/public/healthcheck", "/public/status", "/public/info"]
  }
};

// Helper function to check if a path is an SQS endpoint
function isSqsPath(path) {
  return path === "/v1/case/event";
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

  return baseModal;
}

// Function to generate the canonical modal for each path and method
function getCanonicalModal(path, method, pathDetails, envVars) {
  const { parameters, operationId } = pathDetails[method] || {};
  const timeout = getTimeoutForPath(path, envVars);

  const integration = {
    type: "aws",
    httpMethod: "POST",
    uri: `arn:aws:apigateway:${envVars.aws_region}:sqs:path/${envVars.aws_account_id}/${envVars.sqs_queue_name}`,
    credentials: envVars.sqs_iam_role || "",
    requestParameters: {
      "integration.request.header.Content-Type": "'application/x-www-form-urlencoded'"
    },
    requestTemplates: {
      "application/json": "Action=SendMessage&MessageBody=$input.body"
    },
    responses: {
      default: { statusCode: "200" }
    },
    passthroughBehavior: "when_no_match",
    timeoutInMillis: timeout
  };

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
    "x-amazon-apigateway-integration": integration
  };

  return methodSpec;
}

// Initialization function to generate the complete AWS API model
function init() {
  const [env] = process.argv.slice(2);
  if (!env) {
    throw new Error('Please provide an environment argument (e.g., DEV, UAT, PROD , TF_VAR)');
  }

  const envVars = ENV_VAR[env];
  if (!envVars) {
    throw new Error(`Environment ${env} not found in ENV_VAR`);
  }

  // Validate required fields
  const requiredFields = ['sqs_queue_name', 'aws_account_id', 'sqs_iam_role', 'aws_region', 'api_title', 'description'];
  const missingFields = [];
  requiredFields.forEach(field => {
    if (!envVars[field] || envVars[field] === "") {
      missingFields.push(field);
    }
  });

  if (missingFields.length > 0) {
    throw new Error(`Invalid or missing fields for environment ${env}: ${missingFields.join(', ')}`);
  }

  if (!baseOpenAPIJson.paths || Object.keys(baseOpenAPIJson.paths).length === 0) {
    throw new Error('No paths defined in swagger.json');
  }

  const awsAPIModal = getAwsAPIModal(envVars);
  const paths = Object.keys(baseOpenAPIJson.paths).filter(path => isSqsPath(path));

  if (paths.length === 0) {
    throw new Error('No SQS-compatible paths found in swagger.json');
  }

  paths.forEach(path => {
    const pathDetails = baseOpenAPIJson.paths[path];
    const methods = Object.keys(pathDetails).filter(m => m === 'post');
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
        type: "mock",
        requestTemplates: {
          "application/json": "{\"statusCode\": 200}"
        },
        responses: {
          default: {
            statusCode: "200",
            responseParameters: {
              "method.response.header.Access-Control-Allow-Methods": "'POST,OPTIONS'",
              "method.response.header.Access-Control-Allow-Origin": "'*'",
              "method.response.header.Access-Control-Allow-Headers": "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
            }
          }
        },
        passthroughBehavior: "when_no_match"
      }
    };
  });

  // Write output to file
  const outputFile = `swagger-converted-sqs-${env}.json`;
  fs.writeFileSync(outputFile, JSON.stringify(awsAPIModal, null, 2));
  console.log(`Generated SQS API Gateway specification written to ${outputFile}`);
}

try {
  init();
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}