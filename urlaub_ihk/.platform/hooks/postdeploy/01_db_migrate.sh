set -e

echo "Running DB migration..."
mysql -h "$DB_HOST" \
      -u "$DB_USER" \
      -p"$DB_PASSWORD" \
      "$DB_NAME" < /var/app/current/urlaub_ihk/schema.sql
