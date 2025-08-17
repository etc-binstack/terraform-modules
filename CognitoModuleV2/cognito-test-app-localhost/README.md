# Cognito Test Application (Local)

This project provides a locally runnable single-page application (SPA) and backend API to test AWS Cognito User Pool functionality, including SignUp, SignIn, JWT retrieval, and API authentication with database integration. The SPA runs on `localhost:5000`, and the backend API runs on `localhost:3000`.

## Folder Structure
```
cognito-test-app/
├── singlepageApp/           # SPA for SignUp, SignIn, and JWT testing
│   ├── index.html           # Main HTML page
│   ├── app.js               # Cognito logic
│   ├── styles.css           # Styling
│   ├── server.js            # Express server for SPA
├── backendServiceApi/       # Backend API with JWT validation and SQLite
│   ├── index.js             # API server
│   ├── authorizer.js        # JWT validation middleware
│   ├── database.js          # SQLite database logic
├── package.json             # Dependencies and scripts
├── README.md
```

## Prerequisites
- Node.js >= 18.x and npm installed.
- AWS Cognito User Pool with a client ID (e.g., from the provided Cognito module).
- SQLite (included via `sqlite3` package, no external setup needed).

## Setup
1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd cognito-test-app
   ```

2. **Install Dependencies**:
   ```bash
   npm install
   ```

3. **Configure Cognito**:
   - Update `singlepageApp/app.js` with your Cognito User Pool ID and Client ID:
     ```javascript
     const poolData = {
       UserPoolId: 'YOUR_USER_POOL_ID',
       ClientId: 'YOUR_CLIENT_ID'
     };
     const apiUrl = 'http://localhost:3000/api/test';
     ```
   - Update `backendServiceApi/authorizer.js` with your User Pool ID and region:
     ```javascript
     const userPoolId = 'YOUR_USER_POOL_ID';
     const region = 'us-east-1';
     ```

4. **Run the SPA**:
   ```bash
   npm run start-spa
   ```
   The SPA will be available at `http://localhost:5000`.

5. **Run the Backend API**:
   ```bash
   npm run start-api
   ```
   The API will be available at `http://localhost:3000/api/test`.

6. **Test the Application**:
   - Open `http://localhost:5000` in your browser.
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
   - Click "Call API" to send a GET request to `http://localhost:3000/api/test`.
   - If the JWT is valid and `tenant_id` (if provided) exists in the database, the API returns:
     ```json
     {
       "message": "Successfully authenticated! JWT is valid.",
       "user": {
         "sub": "<user-sub>",
         "email": "<user-email>"
       },
       "tenant": {
         "tenant_id": "<tenant-id>",
         "name": "<tenant-name>"
       }
     }
     ```

## Database
The backend uses a SQLite database (`tenants.db`) to store tenant information:
- Table: `tenants` with columns `tenant_id` (primary key) and `name`.
- Pre-seeded with `tenant_123` and `tenant_456` for testing.
- To add tenants, modify `database.js` or use a SQLite client.

## Notes
- Ensure the Cognito User Pool allows email sign-in and has `custom:tenant_id` in `read_attributes` for multi-tenant setups.
- The backend validates `tenant_id` against the SQLite database. Modify `authorizer.js` to skip tenant validation if not needed.
- The SPA and API run locally, so no AWS deployment is required.
- Use HTTPS in production to secure JWT transmission.

## Troubleshooting
- **SignUp/SignIn Errors**: Verify User Pool ID, Client ID, and email verification settings in Cognito.
- **API Errors**: Ensure the JWT is valid and the `tenant_id` exists in `tenants.db`.
- **CORS Issues**: The backend includes CORS headers for `localhost:5000`. Adjust if needed.

## Integration with Cognito Module
Use outputs from the Cognito module:
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
      callback_urls        = ["http://localhost:5000"]
      logout_urls          = ["http://localhost:5000"]
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
}
```
Update `app.js` and `authorizer.js` with `module.cognito_pool.cognito_user_pool_id` and `module.cognito_pool.cognito_user_pool_client_ids[0]`.


Thank you for the feedback! Regarding your question about the database in the `cognito-test-app` project, let me clarify where the database is installed or created and how it works based on the provided setup.


<br><br>
## Database Details
The project uses **SQLite** as the database, which is managed by the `sqlite3` Node.js package. SQLite is a lightweight, serverless, file-based database, meaning it doesn't require a separate database server installation like MySQL or PostgreSQL. Instead, it creates a database file locally in your project directory when the application runs.

In the provided code, the database logic is defined in `backendServiceApi/database.js`. Here's how it works:

1. **Database File Creation**:
   - The SQLite database file, named `tenants.db`, is automatically created in the `backendServiceApi/` directory the first time you run the backend API (`npm run start-api`).
   - The `database.js` file includes code to initialize the database and create a `tenants` table if it doesn't already exist:
     ```javascript
     db.run(`
       CREATE TABLE IF NOT EXISTS tenants (
         tenant_id TEXT PRIMARY KEY,
         name TEXT NOT NULL
       )
     `);
     ```
   - It also seeds the database with two test tenants (`tenant_123` and `tenant_456`) for testing purposes:
     ```javascript
     db.run(`INSERT OR IGNORE INTO tenants (tenant_id, name) VALUES (?, ?)`, ['tenant_123', 'Tenant One']);
     db.run(`INSERT OR IGNORE INTO tenants (tenant_id, name) VALUES (?, ?)`, ['tenant_456', 'Tenant Two']);
     ```

2. **No Separate Installation Required**:
   - You **do not need to install a separate database** or set up a database server. The `sqlite3` package, included in the `package.json` dependencies, handles everything.
   - When you run `npm install` in the `cognito-test-app/` directory, the `sqlite3` package is installed automatically, and it includes the necessary SQLite engine to create and manage the `tenants.db` file.

3. **Location of the Database File**:
   - The database file (`tenants.db`) is created in the `backendServiceApi/` directory, as specified in `database.js`:
     ```javascript
     const db = new sqlite3.Database(path.join(__dirname, 'tenants.db'));
     ```
   - `path.join(__dirname, 'tenants.db')` resolves to the `backendServiceApi/` directory, so `tenants.db` will appear there after running the backend API.

4. **How It’s Used**:
   - The backend API (`backendServiceApi/index.js`) uses the `authorize` middleware (`backendServiceApi/authorizer.js`) to validate JWTs.
   - If the JWT contains a `custom:tenant_id` claim, the middleware checks it against the `tenants` table in `tenants.db` to ensure the tenant exists:
     ```javascript
     getTenant(tenantId, (err, row) => {
       if (err || !row) {
         reject(new Error('Invalid tenant_id'));
       } else {
         req.tenant = row;
         resolve();
       }
     });
     ```

### Steps to Ensure the Database Works
1. **Install Dependencies**:
   Run the following command in the `cognito-test-app/` directory to install all dependencies, including `sqlite3`:
   ```bash
   npm install
   ```
   This installs `sqlite3`, `express`, `cors`, `jsonwebtoken`, and `jwks-rsa` as specified in `package.json`.

2. **Run the Backend API**:
   Start the backend API to create and initialize the `tenants.db` file:
   ```bash
   npm run start-api
   ```
   - The first time you run this, `tenants.db` will be created in `backendServiceApi/`.
   - The `tenants` table will be created with two test entries: `tenant_123` (Tenant One) and `tenant_456` (Tenant Two).

3. **Verify the Database File**:
   - After running `npm run start-api`, check the `backendServiceApi/` directory for `tenants.db`.
   - You can inspect the database using a SQLite client (e.g., `sqlite3` CLI, DB Browser for SQLite) to verify the `tenants` table:
     ```bash
     sqlite3 backendServiceApi/tenants.db
     SELECT * FROM tenants;
     ```
     Output:
     ```
     tenant_123|Tenant One
     tenant_456|Tenant Two
     ```

4. **Add More Tenants (Optional)**:
   - To add more tenants, modify `database.js` to include additional `INSERT` statements:
     ```javascript
     db.run(`INSERT OR IGNORE INTO tenants (tenant_id, name) VALUES (?, ?)`, ['tenant_789', 'Tenant Three']);
     ```
   - Alternatively, you can manually insert tenants using a SQLite client:
     ```bash
     sqlite3 backendServiceApi/tenants.db
     INSERT INTO tenants (tenant_id, name) VALUES ('tenant_789', 'Tenant Three');
     ```

### Troubleshooting Database Issues
- **Missing `tenants.db`**:
  - Ensure you’ve run `npm run start-api` at least once to create the database.
  - Verify that `npm install` installed `sqlite3` correctly (check `node_modules/sqlite3`).
  - If you encounter errors like "unable to open database file," check file permissions in `backendServiceApi/`.

- **SQLite Installation Issues**:
  - `sqlite3` requires a C++ compiler for installation. If you encounter build errors, ensure you have:
    - **Windows**: `build-tools` (via Visual Studio Build Tools).
    - **macOS**: Xcode Command Line Tools (`xcode-select --install`).
    - **Linux**: `build-essential` and `libsqlite3-dev` (`sudo apt-get install build-essential libsqlite3-dev`).
  - You can also try prebuilt binaries:
    ```bash
    npm install sqlite3 --build-from-source
    ```

- **Invalid `tenant_id`**:
  - If the API returns "Invalid tenant_id," ensure the `tenant_id` used during SignUp (e.g., `tenant_123`) exists in `tenants.db`.
  - If you don’t need tenant validation, modify `authorizer.js` to skip the `getTenant` check:
    ```javascript
    req.user = verified;
    next();
    ```

### Summary
- **Where is the database installed?** No separate installation is needed. The `sqlite3` package creates `tenants.db` in `backendServiceApi/` when you run `npm run start-api`.
- **How is it created?** The `database.js` script automatically creates the database file and `tenants` table with test data on the first run.
- **Where is the file located?** In `backendServiceApi/tenants.db`.
- **What do you need to do?** Just run `npm install` and `npm run start-api` to set it up.

If you want to use a different database (e.g., PostgreSQL, MySQL) or need help with specific database operations (e.g., adding more tables or queries), let me know, and I can modify the setup accordingly!