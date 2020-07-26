FROM gitpod/workspace-postgres
COPY ./install.sh /
ENTRYPOINT ["/install.sh"]
