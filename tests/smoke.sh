#!/bin/sh
# Smoke test for the image: the crontab line entrypoint.sh writes, with TLS verification off and on, and one real
# request on cron's schedule to a listener on a network of its own.
#
#   tests/smoke.sh <image>
#
# DOCKER picks the engine (docker by default; podman works too).
set -eu

image=$1
docker=${DOCKER:-docker}
net=http-docker-cron-smoke-$$
fail() {
  echo "::error::$*"
  exit 1
}
cleanup() {
  $docker rm -f "$net-listener" "$net-cron" >/dev/null 2>&1 || true
  $docker network rm "$net" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# crontab <expected line> [docker run options...]: starts the image, reads the crontab its entrypoint wrote.
crontab() {
  expected=$1
  shift
  cid=$($docker run -d -e CRON_SCHEDULE='*/5 * * * *' -e ENDPOINT='https://example.test/ping' "$@" "$image")
  line=""
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    line=$($docker exec "$cid" cat /etc/crontabs/root 2>/dev/null || true)
    [ -n "$line" ] && break
    sleep 1
  done
  $docker rm -f "$cid" >/dev/null
  [ "$line" = "$expected" ] || fail "crontab is '$line', expected '$expected'"
  echo "ok: $expected"
}

crontab '*/5 * * * * curl -k -L -s https://example.test/ping'
crontab '*/5 * * * * curl -L -s https://example.test/ping' -e HTTP_DOCKER_CRON_VERIFY_TLS=1

# One request, on cron's every-minute schedule, to busybox nc in the same image, which prints what it receives.
$docker network create "$net" >/dev/null
$docker run -d --name "$net-listener" --network "$net" --entrypoint sh "$image" -c \
  'while true; do printf "HTTP/1.1 204 No Content\r\nContent-Length: 0\r\n\r\n" | nc -l -p 8000; done' >/dev/null
$docker run -d --name "$net-cron" --network "$net" \
  -e CRON_SCHEDULE='* * * * *' -e ENDPOINT="http://$net-listener:8000/ping" "$image" >/dev/null
for _ in $(seq 1 15); do
  if $docker logs "$net-listener" 2>&1 | grep -q '^GET /ping '; then
    echo "ok: cron requested the endpoint"
    exit 0
  fi
  sleep 5
done
fail "no request reached the listener within 75 s"
