#!/bin/bash
set -e

update_hba_conf() {
  local hba_file="$PGDATA/pg_hba.conf"
  printf '%s\n' "[HBA-UPDATE] Applying fresh runtime configuration to $hba_file..."
  until [ -f "$hba_file" ]; do
    sleep 0.5
  done
  echo "[HBA-UPDATE] Target file found. Overwriting hba_file with secure rules..."
  cat "${POSTGRES_INIT}/pg_hba.conf" > "$hba_file"
  if [ -f "$POSTGRES_PASSWORD_FILE" ]; then
    until pg_isready -h /var/run/postgresql -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
      sleep 1
    done
    printf '%s\n' "[HBA-UPDATE] Database is ready. Applying update..."
    PGPASSWORD="$(cat "$POSTGRES_PASSWORD_FILE")"
    psql -h /var/run/postgresql  -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT pg_reload_conf();"
    printf '%s\n' "[HBA-UPDATE] done"
  else
    printf '%s\n' "File $POSTGRES_PASSWORD_FILE does not exist" >&2
    exit 1
  fi

}

apply_sql_init() {
    printf '%s\n' "[SQL-INIT] Waiting for PostgreSQL to become ready via UNIX socket..."
    until pg_isready -h /var/run/postgresql -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
      sleep 1
    done
    printf '%s\n' "[SQL-INIT] Database is ready. Applying sql init.sql..."

    if [ -f "$POSTGRES_PASSWORD_FILE" ]; then
      PGPASSWORD="$(cat "$POSTGRES_PASSWORD_FILE")"
      export PGPASSWORD
      psql -h /var/run/postgresql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "${POSTGRES_INIT}/init.sql"
      echo "[SQL-INIT] done"
    else
      printf '%s\n' "File $POSTGRES_PASSWORD_FILE does not exist" >&2
      exit 1
    fi
}

main() {
  if [ ! -d "${POSTGRES_INIT}" ]; then
    printf '%s\n' "Directory $POSTGRES_INIT does not exist" >&2
    exit 1
  fi
  update_hba_conf
  apply_sql_init
}

main &
exec /usr/local/bin/docker-entrypoint.sh postgres \
-c ssl=on \
-c ssl_ca_file=/usr/local/etc/postgres/ca.crt \
-c ssl_cert_file=/usr/local/etc/postgres/postgres.crt \
-c ssl_key_file=/usr/local/etc/postgres/postgres.key









