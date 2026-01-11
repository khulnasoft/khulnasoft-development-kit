ARG from_image
FROM ${from_image} AS base

ENV MISE_QUIET=true

ARG DEPENDENCY_HASH
RUN echo "Dependency hash: $DEPENDENCY_HASH"

ARG git_checkout_branch
ENV GIT_CHECKOUT_BRANCH $git_checkout_branch

ARG git_remote_origin_url
ENV GIT_REMOTE_ORIGIN_URL $git_remote_origin_url

USER ${WORKSPACE_USER}
WORKDIR $WORKSPACE_DIR_NAME

RUN git clone https://github.com/khulnasoft/khulnasoft-development-kit.git && \
    cd khulnasoft-development-kit && \
    if [ -n "${GIT_REMOTE_ORIGIN_URL:-}" ]; then \
        git remote set-url origin "${GIT_REMOTE_ORIGIN_URL}.git" && \
        git fetch; \
    fi && \
    if [ -n "${GIT_CHECKOUT_BRANCH:-}" ]; then \
        git checkout "${GIT_CHECKOUT_BRANCH}"; \
    fi && \
    cp /tmp/kdk.yml kdk.yml

FROM base AS install

RUN cd khulnasoft-development-kit && \
    kdk install shallow_clone=true && \
    (kdk stop || true) && \
    (KDK_KILL_CONFIRM=true kdk kill || true) && \
    ps -ef && \
    mv khulnasoft/config/secrets.yml . && \
    rm -rf khulnasoft/ tmp/ && \
    git restore tmp && \
    kdk config set khulnasoft.rails.bootsnap true && \
    cd "${WORKSPACE_DIR_NAME}" && \
    ln -s "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/.tool-versions" "${HOME}/.tool-versions"

FROM install AS final

USER root
RUN cp ./khulnasoft-development-kit/support/completions/kdk.bash "/etc/profile.d/90-kdk.sh" && \
    chgrp -R 0 "${WORKSPACE_DIR_NAME}" && \
    chmod -R g=u "${WORKSPACE_DIR_NAME}" && \
    chmod g-w "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/postgresql/data" && \
    rm -rf /tmp/* && \
    rm -rf ${HOME}/.cache/* && \
    rm -rf ${HOME}/go/pkg/mod/* && \
    rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/cache" && \
    rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/deps" && \
    rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/deps/libgit2/source" && \
    rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/intermediate" && \
    echo "=== Final disk usage ===" && \
    (du -ah / 2>/dev/null | sort -rh | head -20 || true)

USER ${WORKSPACE_USER}

COPY entrypoint.sh /tmp
ENTRYPOINT ["/tmp/entrypoint.sh"]
