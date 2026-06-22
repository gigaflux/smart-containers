#!/bin/bash
set -e

# --- 1. Wait for Database Ready ---
if [ -n "$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" ]; then
  # Parse host and port out of the standard connection string
  DB_HOST=$(printf '%s\n' "$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" | sed -n 's,.*@\([^:]*\).*,\1,p')
  DB_PORT=$(printf '%s\n' "$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" | sed -n 's,.*:\([0-9]\+\).*,\1,p')

  print '%s\n' "=== [Entrypoint] Waiting for DB ($DB_HOST:$DB_PORT) to spin up... ==="
  while ! nc -z "$DB_HOST" "$DB_PORT"; do
    sleep 1
  done
  printf '%s\n'  "=== [Entrypoint] database is online and accepting connections! ==="
fi

# --- 2. Wait for Redis Broker Ready ---
if [ -n "$AIRFLOW__CELERY__BROKER_URL" ]; then
  REDIS_HOST=$(printf '%s\n' "$AIRFLOW__CELERY__BROKER_URL" | sed -n 's,.*//\([^@]*@\)\?\([^:]*\).*,\2,p')
  REDIS_PORT=$(printf '%s\n' "$AIRFLOW__CELERY__BROKER_URL" | sed -n 's,.*:[0-9]*@\?[^:]*:\([0-9]\+\).*,\1,p')
  : "${REDIS_PORT:=6379}"

  printf '%s\n' "=== [Entrypoint] Waiting for Redis Broker ($REDIS_HOST:$REDIS_PORT) to spin up... ==="
  while ! nc -z "$REDIS_HOST" "$REDIS_PORT"; do
    sleep 1
  done
  printf '%s\n' "=== [Entrypoint] Redis Broker is online and ready! ==="
fi

# --- 3. Wait for Airflow DB Migration to Complete ---
# 'airflow db check' returns exit code 0 only when tables exist and are reachable.
printf '%s\n' "=== [Entrypoint] Verifying Airflow database schemas... ==="
until airflow db check; do
  printf '%s\n' "=== [Entrypoint] DB is not initialized yet. Waiting for 'airflow-init' to complete migrations... ==="
  sleep 3
done
printf '%s\n' "=== [Entrypoint] Airflow schemas verified successfully! ==="

# --- 4. Execute Handover ---
# Hand over the process execution to the original Docker CMD (e.g., airflow celery worker)
printf '%s\n' "=== [Entrypoint] Running celery worker "
exec airflow celery worker
