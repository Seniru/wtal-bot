FROM gitpod/workspace-postgres
COPY ./install.sh /
RUN chmod +x /install.sh
ENTRYPOINT ["/install.sh"]
