FROM codeberg.org/forgejo/forgejo:17-rootless


COPY --chmod 755 ./forgejo-oauth.sh /usr/local/bin/forgejo-oauth.sh


CMD [ "/usr/local/bin/forgejo-oauth.sh" ]
