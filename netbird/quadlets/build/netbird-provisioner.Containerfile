FROM alpine:latest

RUN apk add --no-cache bash curl jq ca-certificates

COPY netbird-provisioner.sh /usr/local/bin/netbird-provisioner.sh
RUN chmod +x /usr/local/bin/netbird-provisioner.sh

ENTRYPOINT ["/usr/local/bin/netbird-provisioner.sh"]
