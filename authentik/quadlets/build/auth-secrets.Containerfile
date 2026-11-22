FROM docker.io/library/alpine:latest 

COPY --chmod=755 ./secret-sync.sh /usr/local/bin/secret-sync.sh

CMD [ "/usr/local/bin/secret-sync.sh" ]
