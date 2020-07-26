FROM gitpod/workspace-postgres
RUN cd /usr/local/bin \
    curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh \
    cd /workspace/wtal-bot
