#!/bin/bash
set -e

if command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y mariadb105
else
  sudo yum install -y mariadb
fi

mysql -h "$DB_HOST" \
      -u "$DB_USER" \
      -p"$DB_PASSWORD" \
      "$DB_NAME" < /var/app/current/schema.sql

