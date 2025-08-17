const jwksRsa = require('jwks-rsa');
const jwt = require('jsonwebtoken');

const userPoolId = 'YOUR_USER_POOL_ID'; // Replace with your Cognito User Pool ID
const region = 'us-east-1'; // Replace with your AWS region
const jwksUri = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`;

const client = jwksRsa({
  cache: true,
  rateLimit: true,
  jwksUri
});

function getSigningKey(kid, callback) {
  client.getSigningKey(kid, (err, key) => {
    if (err) return callback(err);
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
}

exports.handler = async (event) => {
  const token = event.authorizationToken.replace('Bearer ', '');

  try {
    const decoded = jwt.decode(token, { complete: true });
    if (!decoded || !decoded.header.kid) {
      throw new Error('Invalid token');
    }

    const signingKey = await new Promise((resolve, reject) => {
      getSigningKey(decoded.header.kid, (err, key) => {
        if (err) reject(err);
        resolve(key);
      });
    });

    const verified = await new Promise((resolve, reject) => {
      jwt.verify(token, signingKey, {
        issuer: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`,
        algorithms: ['RS256']
      }, (err, decoded) => {
        if (err) reject(err);
        resolve(decoded);
      });
    });

    // Optional: Validate tenant_id for multi-tenant apps
    if (verified['custom:tenant_id']) {
      console.log(`Tenant ID: ${verified['custom:tenant_id']}`);
    }

    return generatePolicy(verified.sub, 'Allow', event.methodArn);
  } catch (error) {
    console.error('Authorization error:', error);
    return generatePolicy('user', 'Deny', event.methodArn);
  }
};

function generatePolicy(principalId, effect, resource) {
  return {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [{
        Action: 'execute-api:Invoke',
        Effect: effect,
        Resource: resource
      }]
    }
  };
}
