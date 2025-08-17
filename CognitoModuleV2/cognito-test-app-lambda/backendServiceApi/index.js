exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*' // Allow CORS for SPA
    },
    body: JSON.stringify({
      message: 'Successfully authenticated! JWT is valid.'
    })
  };
};
