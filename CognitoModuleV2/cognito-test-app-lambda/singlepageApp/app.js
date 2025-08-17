const poolData = {
  UserPoolId: 'YOUR_USER_POOL_ID', // Replace with your Cognito User Pool ID
  ClientId: 'YOUR_CLIENT_ID' // Replace with your Cognito App Client ID
};
const apiUrl = 'YOUR_API_GATEWAY_URL'; // Replace with your API Gateway endpoint
const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

function displayOutput(message) {
  document.getElementById('output').textContent = message;
  document.getElementById('error').textContent = '';
}

function displayError(error) {
  document.getElementById('error').textContent = error.message || error;
  document.getElementById('output').textContent = '';
}

async function signUp() {
  const email = document.getElementById('signup-email').value;
  const password = document.getElementById('signup-password').value;
  const tenantId = document.getElementById('signup-tenant').value;

  const attributeList = [
    new AmazonCognitoIdentity.CognitoUserAttribute({
      Name: 'email',
      Value: email
    })
  ];
  if (tenantId) {
    attributeList.push(
      new AmazonCognitoIdentity.CognitoUserAttribute({
        Name: 'custom:tenant_id',
        Value: tenantId
      })
    );
  }

  try {
    const result = await new Promise((resolve, reject) => {
      userPool.signUp(email, password, attributeList, null, (err, result) => {
        if (err) reject(err);
        else resolve(result);
      });
    });
    displayOutput(`Sign-up successful for ${result.user.getUsername()}. Please verify your email.`);
  } catch (error) {
    displayError(error);
  }
}

async function signIn() {
  const email = document.getElementById('signin-email').value;
  const password = document.getElementById('signin-password').value;

  const authenticationDetails = new AmazonCognitoIdentity.AuthenticationDetails({
    Username: email,
    Password: password
  });

  const cognitoUser = new AmazonCognitoIdentity.CognitoUser({
    Username: email,
    Pool: userPool
  });

  try {
    const session = await new Promise((resolve, reject) => {
      cognitoUser.authenticateUser(authenticationDetails, {
        onSuccess: (session) => resolve(session),
        onFailure: (err) => reject(err)
      });
    });
    const idToken = session.getIdToken().getJwtToken();
    document.getElementById('jwt-token').value = idToken;
    displayOutput('Sign-in successful! JWT copied to textarea.');
  } catch (error) {
    displayError(error);
  }
}

function copyJwt() {
  const jwtField = document.getElementById('jwt-token');
  jwtField.select();
  document.execCommand('copy');
  displayOutput('JWT copied to clipboard!');
}

async function testApi() {
  const jwt = document.getElementById('jwt-token').value;
  if (!jwt) {
    displayError('No JWT available. Please sign in first.');
    return;
  }

  try {
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${jwt}`
      }
    });
    const data = await response.json();
    if (response.ok) {
      displayOutput(`API Response: ${JSON.stringify(data, null, 2)}`);
    } else {
      displayError(`API Error: ${data.message || response.statusText}`);
    }
  } catch (error) {
    displayError(error);
  }
}
