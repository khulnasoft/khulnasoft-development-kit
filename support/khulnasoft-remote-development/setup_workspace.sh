#!/usr/bin/env bash

set -eox pipefail

[[ -z "$KS_WORKSPACE_DOMAIN_TEMPLATE" ]] && { echo "Nothing to do as we're not a KhulnaSoft Workspace."; exit 0; }

eval "$(/home/khulnasoft-workspaces/.local/bin/mise activate bash --shims)" || { echo "mise activation failed."; exit 1; }

KDK_ROOT_DIR="${KDK_ROOT_DIR:-/projects/khulnasoft-development-kit}"
KDK_SETUP_FLAG_FILE="${KDK_ROOT_DIR}/.cache/.kdk_setup_complete"
WORKSPACE_DIR_NAME="${WORKSPACE_DIR_NAME:-~/workspace}"
BOOTSTRAPPED_KDK_DIR="${BOOTSTRAPPED_KDK_DIR:-${WORKSPACE_DIR_NAME}/khulnasoft-development-kit}"
KDK_PORT=$(env | grep SERVICE_PORT_KDK_ | awk -F= '{ print $2 }')
KDK_URL=$(echo "${KS_WORKSPACE_DOMAIN_TEMPLATE}" | sed -r 's/\$\{PORT\}/'"${KDK_PORT}"'/')
MY_IP=$(getent hosts "$(hostname)" | awk '{print $1}')
TIMINGS=()

check_inotify() {
  INOTIFY_WATCHES=$(cat /proc/sys/fs/inotify/max_user_watches)
  INOTIFY_WATCHES_THRESHOLD=524288
  if [[ ${INOTIFY_WATCHES} -lt ${INOTIFY_WATCHES_THRESHOLD} ]]; then
    echo "fs.inotify.max_user_watches is less than ${INOTIFY_WATCHES_THRESHOLD}. Please set this on your node."
    echo "See https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/307 and"
    echo "https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/doc/advanced.md#install-dependencies-for-other-linux-distributions"
    echo "for details."

    exit 1
  fi
}

install_gems() {
  echo "Installing Gems in ${KDK_ROOT_DIR}"
  bundle install
  pushd khulnasoft
  echo "Installing Gems in ${KDK_ROOT_DIR}/khulnasoft"
  bundle install
  popd
}

measure_time() {
  local start=$SECONDS
  "$@"
  local duration=$((SECONDS - start))
  TIMINGS+=("$1: $duration seconds")
}

print_timings() {
  DURATION=$SECONDS
  echo "Total Duration: $((DURATION / 60)) minutes and $((DURATION % 60)) seconds."
  echo "Execution times for each function:"
  printf '%s\n' "${TIMINGS[@]}"
}

clone_khulnasoft() {
  if [ -d "/projects/khulnasoft" ]; then
    echo "Found existing khulnasoft at /projects/khulnasoft, creating symlink."
    ln -snf /projects/khulnasoft khulnasoft
    kdk config set khulnasoft.auto_update false
    kdk config set khulnasoft.default_branch "$(git -C /projects/khulnasoft rev-parse --abbrev-ref HEAD)"
  else
    echo "Cloning khulnasoft-org/khulnasoft"
    make khulnasoft/.git
  fi
  cp "${BOOTSTRAPPED_KDK_DIR}/secrets.yml" khulnasoft/config
}

copy_items_from_bootstrap() {
  interesting_items=(
    "kdk.yml"
    ".cache"
    "clickhouse"
    "consul"
    "kdk-config.mk"
    "gitaly"
    ".khulnasoft-bundle"
    ".khulnasoft-lefthook"
    "khulnasoft-pages"
    "khulnasoft-runner-config.toml"
    "khulnasoft-shell"
    ".khulnasoft-shell-bundle"
    ".khulnasoft-translations"
    ".khulnasoft-yarn"
    "localhost.crt"
    "localhost.key"
    "log"
    "pgbouncers"
    "postgresql"
    "Procfile"
    "redis"
    "registry"
    "registry_host.crt"
    "registry_host.key"
    "repositories"
    "services"
    "sv"
  )

  if [[ "${KDK_ROOT_DIR}" == "${BOOTSTRAPPED_KDK_DIR}" ]]; then
    echo "Skipping moving bootstrapped KDK items to persistent storage."
    return 0
  fi

  for item in "${interesting_items[@]}"; do
    echo "Moving bootstrapped KDK item: ${item}"
    rm -rf "${KDK_ROOT_DIR:?}/${item}" || true
    [ -e "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/${item}" ] && mv "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/${item}" .
  done
}

reconfigure() {
  kdk rake generate_config_files
  kdk reconfigure
}

migrate_db(){
  kdk rake khulnasoft-db-migrate
  kdk stop
}

update_kdk() {
  kdk update
}

restart_kdk() {
  kdk stop
  kdk start
}

configure_license(){
  echo "Configure license"

  if [ -z "$KHULNASOFT_ACTIVATION_CODE" ]; then
    echo "No envvar KHULNASOFT_ACTIVATION_CODE provided. Skipping."
    return 0
  else
    pushd khulnasoft
    echo "Activating Cloud license via envvar KHULNASOFT_ACTIVATION_CODE..."
    bundle exec rake "khulnasoft:license:load[verbose]" || true
    popd
  fi
}

configure_kdk_env() {
  echo "$KDK_CONFIG" | yq eval '.' -P | yq eval-all '. as $item ireduce ({}; . * $item)' -i kdk.yml -
  kdk config set khulnasoft.rails.hostname "${KDK_URL}"
  kdk config set khulnasoft.rails.allowed_hosts "$(hostname)"
  kdk config set listen_address "${MY_IP}"
  if [[ "$(git config user.email)" == *"khulnasoft.com" ]]; then
      kdk config set telemetry.enabled true
      local hmac_secret="${TELEMETRY_HMAC_SECRET:-}"
      if [[ -z "${hmac_secret}" ]]; then
        echo "TELEMETRY_HMAC_SECRET is not set. Telemetry username will be hashed without key."
      fi
      username_hash=$(echo -n "$(git config user.email)" | openssl mac -macopt hexkey:"${hmac_secret}" -digest sha256 HMAC | cut -c1-32 | tr '[:upper:]' '[:lower:]')
      kdk config set telemetry.username "$username_hash"
  else
      echo "Not a KhulnaSoft email, skipping telemetry"
  fi
}

write_flag_file() {
    local exit_code=$?
    mkdir -p "$(dirname "${KDK_SETUP_FLAG_FILE}")"
    echo -e "$exit_code $SECONDS" > "${KDK_SETUP_FLAG_FILE}"
    exit $exit_code
}

setup() {
  measure_time check_inotify
  measure_time clone_khulnasoft
  measure_time copy_items_from_bootstrap
  measure_time configure_kdk_env
  measure_time install_gems
  measure_time reconfigure
  measure_time configure_license
  measure_time migrate_db
  measure_time update_kdk
  measure_time restart_kdk
  print_timings
}

if [[ ! -f "${KDK_SETUP_FLAG_FILE}" ]]; then
  trap write_flag_file EXIT
  pushd "${KDK_ROOT_DIR}"
  setup
  popd
fi
