#!/bin/bash
set -e

# Validity period for the certificates (in days)
DAYS=3650

# Reusable function to generate and sign node certificates using SAN (DNS/IP)
generate_cert() {
    local vault="$1"
    local service="$2"
    local name="$3"
    local subj="$4"
    local dns_alt_names="$5"

    local prefix="$service/$name"
    printf '%s\n' "=== Generating certificate for: $prefix ==="

    mkdir -p "${vault}/${service}"

    # 1. Generate private key
    openssl genrsa -out "${vault}/$prefix.key" 2048

    # 2. Build configuration extension file for SAN mapping
    local ext_file="${vault}/$prefix.ext"
    printf '%s\n' "subjectAltName = $dns_alt_names" > "$ext_file"

    # 3. Create Certificate Signing Request (CSR)
    openssl req -new -key "${vault}/$prefix.key" -subj "$subj" -out "${vault}/$prefix.csr"

    # 4. Sign the certificate using the established Root CA
    openssl x509 -req -in "${vault}/$prefix.csr" \
      -CA "${vault}/ca/ca.crt" -CAkey "${vault}/ca/ca.key" -CAcreateserial \
      -out "${vault}/$prefix.crt" -days $DAYS -sha256 -extfile "$ext_file"

    chmod 600 "${vault}/$prefix.key"

    # Clean up temporary configuration items
    rm "${vault}/$service/$name.csr" "$ext_file"
}

generate_certs()  {
  local vault="$1"
  # Create organized directories for targeted Docker Compose mounting
  mkdir -p "${vault}/ca"

  printf '%s\n' "Creating Custom Certificate Authority (Root CA) ==="
  openssl genrsa -out "${vault}/ca/ca.key" 4096
  openssl req -x509 -new -nodes -key "${vault}/ca/ca.key" -sha256 -days $DAYS \
  -subj "/CN=Airflow-Internal-CA" -out "${vault}/ca/ca.crt"
  chmod 600 "${vault}/ca/ca.key"
  printf '\n%s\n' "Generating Infrastructure Component Certificates ==="

  # REDIS: Bound to all cluster container endpoints in the overlay network
  generate_cert "${vault}" "airflow-redis" "redis" "/CN=airflow-redis" \
  "DNS:airflow-redis-1,DNS:airflow-redis-2,DNS:airflow-redis-3"

  # POSTGRESQL: Core metadata and task outcomes store
  generate_cert "${vault}" "airflow-db" "postgres" "/CN=airflow-db" \
  "DNS:airflow-db,DNS:localhost,IP:127.0.0.1"

  # AIRFLOW API SERVER: Airflow 3.x core worker communications nexus
  generate_cert "${vault}" "airflow-api" "airflow-api" "/CN=airflow-api" \
  "DNS:airflow-api,DNS:localhost,IP:127.0.0.1"

  # AIRFLOW WEBSERVER: Secured user login UI
  generate_cert "${vault}" "airflow-web" "airflow-web" "/CN=airflow-web" \
  "DNS:airflow-web,DNS:localhost,IP:127.0.0.1"
}

generate_password() {
  openssl rand -hex 16
}

generate_passwords() {
  local vault="$1"
  for p in 'airflow-redis/redis' 'airflow-db/postgres' 'airflow-api/airflow-api'; do
    generate_password > "${vault}/$p.pwd"
    chmod 600 "${vault}/$p.pwd"
  done
}

create_docker_network() {
  docker network inspect airflow-net >/dev/null 2>&1 || \
  { \
    printf '\n%s\n' "Creating network airflow-net ===" \
    && docker network create airflow-net;
  }
}

create_docker_volumes() {
  for v in airflow-db_data airflow-redis-1_data \
  airflow-redis-2_data airflow-redis-3_data airflow-redis-init_data; do
    if ! docker volume inspect "${v}" >/dev/null 2>&1; then
      docker volume create "${v}"
    fi
  done
}

generate_api_token() {
  local vault="$1"
  openssl rand -hex 32 > "${vault}/airflow-api/airflow-api.jwt"
}

main() {
  local root
  root="$(dirname "$(dirname "$(dirname "$(readlink -f "$1")")")")"
  shift
  local vault="${root}/var/.vault"
  if [ ! -d "${vault}" ]; then
    mkdir -p "${vault}"
  fi
  generate_certs "${vault}"
  generate_passwords "${vault}"
  generate_api_token "${vault}"
  create_docker_network
  create_docker_volumes
  mkdir -p "${root}/var/dags" "${root}/var/plugins"
}

main "$0" "$@"
