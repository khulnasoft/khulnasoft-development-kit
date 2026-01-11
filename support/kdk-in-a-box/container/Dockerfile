FROM debian:bookworm-slim

ARG git_checkout_branch
ENV GIT_CHECKOUT_BRANCH=$git_checkout_branch

ARG git_remote_origin_url
ENV GIT_REMOTE_ORIGIN_URL=$git_remote_origin_url

WORKDIR /khulnasoft-kdk

COPY additional_packages_*.txt /khulnasoft-kdk/
COPY packages_debian.txt /khulnasoft-kdk/platform_packages.txt

# Prepare the 'raw' container image for KDK
RUN ARCH=$(uname -m) \
    && apt-get update \
    && apt-get install -y \
      chromium-driver \
      locales \
      software-properties-common \
      vim \
      $(sed -e 's/#.*//' "platform_packages.txt") \
      $(sed -e 's/#.*//' "additional_packages_${ARCH}.txt") \
    && rm -rf /var/lib/apt/lists/* \
    && rm additional_packages_*.txt \
    && useradd kdk -u 1000 -m -s /bin/bash \
    && chown -Rv kdk:kdk /khulnasoft-kdk \
    && sed -i "s|# en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|" /etc/locale.gen \
    && sed -i "s|# C.UTF-8 UTF-8|C.UTF-8 UTF-8|" /etc/locale.gen \
    && locale-gen C.UTF-8 en_US.UTF-8

 # Set locale environment variables for the entire container
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

COPY --chmod=600 --chown=root:root ./kdk_sudoers /etc/sudoers.d/kdk_sudoers
COPY --chmod=755 --chown=kdk:kdk ./kdk-container-startup.sh /home/kdk/kdk-container-startup.sh
COPY --chmod=755 --chown=kdk:kdk ./devcontainer-startup.sh /home/kdk/devcontainer-startup.sh

USER kdk

SHELL ["/bin/bash", "-c"]

# See https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/2611
ENV VITE_RUBY_SKIP_PROXY=false

# Prepare Mise
RUN mkdir -p ~/.config/mise \
    && curl https://mise.run | sh \
    && eval "$(~/.local/bin/mise activate bash)" \
    && echo "# Added to support mise for KDK" >> ~/.bashrc \
    && echo "eval \"\$(~/.local/bin/mise activate bash)\"" >> ~/.bashrc

# Prepare KDK and prereqs (bootstrap)
RUN eval "$(~/.local/bin/mise activate bash)" \
    && git clone https://github.com/khulnasoft/khulnasoft-development-kit.git \
    && cd khulnasoft-development-kit \
    && if [ -n "${GIT_REMOTE_ORIGIN_URL:-}" ]; then \
        git remote set-url origin "${GIT_REMOTE_ORIGIN_URL}.git" && \
        git fetch; \
      fi \
    && if [[ -n "${GIT_CHECKOUT_BRANCH:-}" ]]; then git checkout "${GIT_CHECKOUT_BRANCH}"; fi \
    && ln -s /khulnasoft-kdk/khulnasoft-development-kit ~/khulnasoft-development-kit \
    && echo -e "---\ntool_version_manager:\n  enabled: true\n" > kdk.yml \
    && make bootstrap \
    # KDK bootstrap runs _more_ apt actions, lets clean out the cache
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo rm -rf /home/kdk/.bundle/cache/* \
    && sudo rm -rf /home/kdk/.cache/yarn/* \
    && sudo rm -rf /home/kdk/.cache/go-build/* \
    && sudo rm -rf /home/kdk/.npm/_cacache/* \
    && sudo rm -rf /home/kdk/.rustup/toolchains/*/share/doc/* \
    && sudo rm -rf /home/kdk/go/pkg/mod/cache/* \
    && sudo rm -rf /khulnasoft-kdk/khulnasoft-development-kit/khulnasoft/tmp/tests/* \
    && sudo rm -rf /khulnasoft-kdk/khulnasoft-development-kit/tmp/* \
    && sudo rm -rf /tmp/*

# Prepare the container for SSH access
# We do some of these steps down here, because it's _after_ KDK installation
RUN mkdir -p ~/.ssh \
    && cp /khulnasoft-kdk/khulnasoft-development-kit/support/kdk-in-a-box/kdk.local_rsa.pub ~/.ssh/authorized_keys \
    && chmod 600 ~/.ssh/authorized_keys \
    && sudo mkdir -p /run/sshd \
    && sudo mv /etc/ssh /etc/ssh-bootstrap \
    && sudo mkdir /etc/ssh

WORKDIR /khulnasoft-kdk/khulnasoft-development-kit

COPY --chmod=755 --chown=kdk:kdk ./install-config-kdk.sh /khulnasoft-kdk/khulnasoft-development-kit/install-config-kdk.sh

# Install and configure KDK
RUN ./install-config-kdk.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo rm -rf /home/kdk/.bundle/cache/* \
    && sudo rm -rf /home/kdk/.cache/yarn/* \
    && sudo rm -rf /home/kdk/.cache/go-build/* \
    && sudo rm -rf /home/kdk/.npm/_cacache/* \
    && sudo rm -rf /home/kdk/.rustup/toolchains/*/share/doc/* \
    && sudo rm -rf /home/kdk/go/pkg/mod/cache/* \
    && sudo rm -rf /khulnasoft-kdk/khulnasoft-development-kit/khulnasoft/tmp/tests/* \
    && sudo rm -rf /khulnasoft-kdk/khulnasoft-development-kit/tmp/* \
    && sudo rm -rf /tmp/*

VOLUME /etc/ssh

EXPOSE 2022/tcp
EXPOSE 2222/tcp
EXPOSE 3000/tcp
EXPOSE 3005/tcp
EXPOSE 3010/tcp
EXPOSE 3038/tcp
EXPOSE 5100/tcp
EXPOSE 5778/tcp
EXPOSE 9000/tcp

CMD ["/home/kdk/kdk-container-startup.sh"]
