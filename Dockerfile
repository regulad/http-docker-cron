FROM alpine:3.14

RUN apk add --no-cache curl dcron

# Create an entrypoint script
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'echo "${CRON_SCHEDULE} curl -k -L -s ${ENDPOINT}" > /etc/crontabs/root' >> /entrypoint.sh && \
    echo 'crond -f' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set default values for environment variables
ENV CRON_SCHEDULE="*/5 * * * *"
ENV ENDPOINT="http://example.com/endpoint"

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
