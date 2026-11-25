#!/bin/sh
# Writes root's crontab to call ENDPOINT on CRON_SCHEDULE, then runs crond in the foreground.
#
# curl skips TLS verification (-k) unless HTTP_DOCKER_CRON_VERIFY_TLS is set to anything non-empty, so endpoints with
# self-signed certificates keep working by default.
set -eu

insecure="-k "
if [ -n "${HTTP_DOCKER_CRON_VERIFY_TLS:-}" ]; then
  insecure=""
fi

echo "${CRON_SCHEDULE} curl ${insecure}-L -s ${ENDPOINT}" > /etc/crontabs/root
# Not exec: as PID 1, crond would lead its session, and dcron's setpgid fails for a session leader ("setpgid:
# Operation not permitted").
crond -f
