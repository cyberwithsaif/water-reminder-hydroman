#!/bin/bash
set -e

# Create PostgreSQL user and database
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hydroman_user') THEN
    CREATE USER hydroman_user WITH PASSWORD 'Hydro_Secure_2026!';
  END IF;
END
\$\$;

SELECT 'User ready' AS status;
EOF

sudo -u postgres psql -c "ALTER USER hydroman_user WITH PASSWORD 'Hydro_Secure_2026!';"

# Create database if not exists
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'hydroman'" | grep -q 1 || sudo -u postgres createdb -O hydroman_user hydroman

echo "=== Database setup complete ==="

# Create app directory
mkdir -p /var/www/hydroman

echo "=== Ready for file upload ==="
