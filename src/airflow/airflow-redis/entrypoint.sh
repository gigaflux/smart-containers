#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
	set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' ] && [ "$(id -u)" = '0' ]; then
	find . \! -user redis -exec chown redis: '{}' +
	exec /usr/bin/setpriv --reuid redis --regid redis --clear-groups "$0" "$@"
fi

# set an appropriate umask (if one isn't set already)
# - https://github.com/docker-library/redis/issues/305
# - https://github.com/redis/redis/blob/bb875603fb7ff3f9d19aad906bd45d7db98d9a39/utils/systemd-redis_server.service#L37

conf="/usr/local/etc/redis"

# check secrets
for s in redis.key redis.pwd; do
  if [ ! -f "${conf}/${s}" ]; then
    printf '%s\n' "❌ ERROR: Secret $s is missing!" >&2
    echo "💡 Fix: Create docker compose secret ${s}"
    exit 1
  fi
  perms="$(stat -c "%a" "${conf}/${s}")"
  if [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
    printf '%s\n' "❌ SECURITY ERROR: secret $s has unsafe permissions: $perms!"
    echo "💡 Fix: Update the 'mode' parameter for this secret in docker-compose.yaml to 0400 or 0600."
    exit 1
  fi
done

# check conf and crt
for f in redis.conf ca.crt redis.crt; do
  if [ ! -r "${conf}/${f}" ]; then
    printf '%s\n' "❌ ERROR: file ${conf}/${f} is not readable or does not exist!" >&2
    printf '%s\n'  "💡 Fix: Mount your config folder to ${conf}" >&2
    exit 1
  fi
done

pwd="$(cat "${conf}/redis.pwd")"
current_ip="$(hostname -i)"
set -- "$1" "${conf}/redis.conf" --requirepass "${pwd}" --masterauth "${pwd}"

um="$(umask)"
if [ "$um" = '0022' ]; then
	umask 0077
fi

rm -rf /data/*

exec "$@"
