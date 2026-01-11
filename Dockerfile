FROM ubuntu:22.04
LABEL authors.maintainer="KDK contributors"

## The CI script that build this file can be found under: support/docker

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV KDK_DEBUG=true

ARG mise_http_timeout=60s
ENV MISE_HTTP_TIMEOUT $mise_http_timeout
ARG mise_fetch_remote_versions_timeout=60s
ENV MISE_FETCH_REMOTE_VERSIONS_TIMEOUT $mise_fetch_remote_versions_timeout

RUN apt-get update && \
    apt-get install -y \
      curl \
      gpg \
      libssl-dev \
      locales \
      locales-all \
      pkg-config \
      software-properties-common \
      sudo && \
    add-apt-repository ppa:git-core/ppa -y

RUN useradd --user-group --create-home --groups sudo kdk && \
    echo "kdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kdk_no_password

WORKDIR /home/kdk/tmp
RUN chown -R kdk:kdk /home/kdk

USER kdk
COPY --chown=kdk . .

ENV PATH="/home/kdk/.local/bin:/home/kdk/.local/share/mise/bin:/home/kdk/.local/share/mise/shims:${PATH}"

SHELL ["/bin/bash", "-c"]
RUN echo "tool_version_manager:" > kdk.yml && \
    echo "  enabled: true" >> kdk.yml && \
    # (Temporarily) import Node.js GPG key to fix GPG signature verification error.
    # See https://github.com/jdx/mise/discussions/7237 for more details.
    gpg --keyserver hkps://keys.openpgp.org --recv-keys 8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 && \
    bash ./support/bootstrap && \
    echo 'Verify tools and cleanup...' && \
    eval "$(mise activate --shims)" && \
    bash -eclx "mise version; yarn --version; node --version; ruby --version" && \
    sudo apt-get purge software-properties-common -y && \
    sudo apt-get clean -y && \
    sudo apt-get autoremove -y && \
    sudo rm -rf \
      "$HOME/.cache/" \
      "$HOME/tmp" \
      /tmp/* \
      /var/cache/apt/* \
      /var/lib/apt/lists/* \
      $(ls -d "$HOME/kdk/gitaly/_build/"* | grep -v /bin) \
      $HOME/.rustup/toolchains/*/share/doc/rust/html && \
    sudo find $HOME/.local/share/mise/installs/ruby/*/lib/ruby/gems/*/gems/lefthook*/libexec/ -type f -and -not -path '*-linux-*' -delete

WORKDIR /home/kdk
