# alpine:3.24 follows the 3.24 branch's point releases, which only respin its packages. A new branch is a new
# snapshot of edge, not a compatible update (Alpine doesn't follow Semantic Versioning), so moving to one is a
# deliberate change, which Dependabot's minor updates propose and a person merges.
FROM alpine:3.24

RUN apk add --no-cache curl dcron

COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Set default values for environment variables
ENV CRON_SCHEDULE="*/5 * * * *"
ENV ENDPOINT="http://example.com/endpoint"

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
