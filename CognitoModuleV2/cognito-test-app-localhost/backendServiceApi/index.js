const express = require('express');
const cors = require('cors');
const authorize = require('./authorizer');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.get('/api/test', authorize, (req, res) => {
  const response = {
    message: 'Successfully authenticated! JWT is valid.',
    user: {
      sub: req.user.sub,
      email: req.user.email
    }
  };
  if (req.tenant) {
    response.tenant = {
      tenant_id: req.tenant.tenant_id,
      name: req.tenant.name
    };
  }
  res.json(response);
});

app.listen(port, () => {
  console.log(`Backend API running at http://localhost:${port}`);
});