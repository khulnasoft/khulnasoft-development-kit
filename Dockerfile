FROM ubuntu:22.04
LABEL authors.maintainer "KDK contributors: https://github.com/khulnasoft/khulnasoft-development-kit/-/graphs/main"

## The CI script that build this file can be found under: support/docker

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN apt-get update && apt-get install -y sudo locales locales-all software-properties-common \
  && add-apt-repository ppa:git-core/ppa -y

RUN useradd --user-group --create-home --groups sudo kdk
RUN echo "kdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kdk_no_password

WORKDIR /home/kdk/tmp
RUN chown -R kdk:kdk /home/kdk

USER kdk
COPY --chown=kdk . .

ENV PATH="/home/kdk/.asdf/shims:/home/kdk/.asdf/bin:${PATH}"

RUN bash ./support/bootstrap \
  # simple tests that tools work
  && bash -lec "asdf version; yarn --version; node --version; ruby --version" \
  # Remove unneeded packages
  && sudo apt-get purge software-properties-common -y \
  && sudo apt-get clean -y \
  && sudo apt-get autoremove -y \
  # clear tmp caches e.g. from postgres compilation
  && sudo rm -rf /tmp/* ~/.asdf/tmp/* \
  # Remove files we copied in
  && sudo rm -rf /home/kdk/tmp \
  # Remove build caches
  # Unfortunately we cannot remove all of "$HOME/kdk/gitaly/_build/*" because we need to keep the compiled binaries in "$HOME/kdk/gitaly/_build/bin"
  && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/* "$HOME/kdk/gitaly/_build/deps/git/source" "$HOME/kdk/gitaly/_build/deps/libgit2/source" "$HOME/kdk/gitaly/_build/cache" "$HOME/kdk/gitaly/_build/deps" "$HOME/kdk/gitaly/_build/intermediate" "$HOME/.cache/" /tmp/*

WORKDIR /home/kdk
