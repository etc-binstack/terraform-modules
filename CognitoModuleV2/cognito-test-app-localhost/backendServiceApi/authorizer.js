const jwksRsa = require('jwks-rsa');
const jwt = require('jsonwebtoken');
const { getTenant } = require('./database');

const userPoolId = 'YOUR_USER_POOL_ID'; // Replace with your Cognito User Pool ID
const region = 'us-east-1'; // Replace with your AWS region
const jwksUri = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`;

const client = jwksRsa({
  cache: true,
  rateLimit: true,
  jwksUri
});

function getSigningKey(kid) {
  return new Promise((resolve, reject) => {
    client.getSigningKey(kid, (err, key) => {
      if (err) reject(err);
      resolve(key.getPublicKey());
    });
  });
}

module.exports = async (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }

  try {
    const decoded = jwt.decode(token, { complete: true });
    if (!decoded || !decoded.header.kid) {
      throw new Error('Invalid token');
    }

    const signingKey = await getSigningKey(decoded.header.kid);
    const verified = jwt.verify(token, signingKey, {
      issuer: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`,
      algorithms: ['RS256']
    });

    // Validate tenant_id if present
    const tenantId = verified['custom:tenant_id'];
    if (tenantId) {
      await new Promise((resolve, reject) => {
        getTenant(tenantId, (err, row) => {
          if (err || !row) {
            reject(new Error('Invalid tenant_id'));
          } else {
            req.user = verified;
            req.tenant = row;
            resolve();
          }
        });
      });
    } else {
      req.user = verified;
    }

    next();
  } catch (error) {
    res.status(401).json({ message: `Unauthorized: ${error.message}` });
  }
};