set -e

echo "Running DB migration..."
mysql -h "$DB_HOST" \
      -u "$DB_USER" \
      -p"$DB_PASSWORD" \
      < /var/app/current/schema.sql
