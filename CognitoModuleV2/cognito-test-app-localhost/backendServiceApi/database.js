const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const db = new sqlite3.Database(path.join(__dirname, 'tenants.db'));

// Initialize database
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS tenants (
      tenant_id TEXT PRIMARY KEY,
      name TEXT NOT NULL
    )
  `);
  // Seed some test tenants
  db.run(`INSERT OR IGNORE INTO tenants (tenant_id, name) VALUES (?, ?)`, ['tenant_123', 'Tenant One']);
  db.run(`INSERT OR IGNORE INTO tenants (tenant_id, name) VALUES (?, ?)`, ['tenant_456', 'Tenant Two']);
});

module.exports = {
  getTenant: (tenantId, callback) => {
    db.get(`SELECT * FROM tenants WHERE tenant_id = ?`, [tenantId], (err, row) => {
      callback(err, row);
    });
  }
};