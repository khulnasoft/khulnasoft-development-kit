---
title: KDK in a box Container
---

For more information, check out this [guide to your first contribution with KDK-in-a-box](https://docs.khulnasoft.com/ee/development/contributing/first_contribution/configure-dev-env-kdk-in-a-box.html).

## Prerequisites

- Docker-compatible container runtime
  - Multiple options are available, including [Docker Desktop](https://www.docker.com/products/docker-desktop/), [Docker Engine](https://docs.docker.com/engine/install/), and [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation).
  - Docker Desktop can also be installed through package managers like [Homebrew](https://formulae.brew.sh/formula/docker).
  - On Rancher Desktop, you may want to disable Kubernetes under "Preferences".
  - Other container runtimes that support Docker-compatible commands should also work.

## Usage

You do not need to clone KDK because it is included inside the Docker image.

To run this container, run the following on the command line:

```shell
docker run -d -h kdk.local --name kdk \
  -p 2022:2022 \
  -p 2222:2222 \
  -p 3000:3000 \
  -p 3005:3005 \
  -p 3010:3010 \
  -p 3038:3038 \
  -p 5100:5100 \
  -p 5778:5778 \
  -p 9000:9000 \
  registry.github.com/khulnasoft/khulnasoft-development-kit/khulnasoft-kdk-in-a-box:latest
```

### SSH Host Keys (optional)

You can add an optional volume for SSH host keys, which are generated on first run if they don't exist. (By default, if you don't use this volume, fresh SSH host keys are generated with each new container. In these cases, a mismatch occurs with `~/.ssh/known_hosts`)

```shell
docker volume create kdk-ssh #only required once
docker run -d -h kdk.local --name kdk \
  -v kdk-ssh:/etc/ssh \
  -p 2022:2022 \
  -p 2222:2222 \
  -p 3000:3000 \
  -p 3005:3005 \
  -p 3010:3010 \
  -p 3038:3038 \
  -p 5100:5100 \
  -p 5778:5778 \
  -p 9000:9000 \
  registry.github.com/khulnasoft/khulnasoft-development-kit/khulnasoft-kdk-in-a-box:latest
```

## Connecting to container

After the container is up, you can treat this container as a regular "KDK-in-a-box" VM. To connect, you can SSH to the container ([using the KDK-in-a-box keys](https://docs.khulnasoft.com/ee/development/contributing/first_contribution/configure-dev-env-kdk-in-a-box.html#use-vs-code-to-connect-to-kdk)):

```shell
ssh kdk.local
```

## Troubleshooting

### Host `kdk.local` not found

Starting the container with `-h kdk.local` should resolve this issue.
In some cases, however, you may need to add a hosts entry for `kdk.local`.

Prerequisites:

- You must have local administrator access.

To add a hosts entry:

- **On MacOS or Linux**, run this command:

  ```shell
  echo "127.0.0.1 kdk.local" | sudo tee -a /etc/hosts
  ```

- On **Windows**:

  - You can add an entry from the command line:

    1. Open Command Prompt or PowerShell as Administrator.
    1. Run `echo 127.0.0.1 kdk.local >> C:\Windows\System32\drivers\etc\hosts`.

  - You can also manually edit the hosts file:

    1. Open `C:\Windows\System32\drivers\etc\hosts` in a text editor as Administrator.
    1. Add the line `127.0.0.1 kdk.local`.
    1. Save the file.

## Enabling debugging in VS Code

This section describes how to set up Rails debugging in Visual Studio Code (VS Code) using the KhulnaSoft Development Kit (KDK).

The steps are based on [the documentation page "VS Code debugging"](https://docs.khulnasoft.com/ee/development/vs_code_debugging.html).

### Setup

1. Install the debug gem by running gem install debug inside the `/khulnasoft-kdk/khulnasoft-development-kit/khulnasoft` folder.
1. Install [the VS Code Ruby rdbg Debugger extension](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg) to add support for the rdbg debugger type to VS Code.
1. In case you want to automatically stop and start KhulnaSoft and its associated Ruby Rails/Sidekiq process, you may add the following VS Code task to your configuration under the `.vscode/tasks.json` file:

```json
{
  "version": "2.0.0",
  "tasks": [{
      "label": "start rdbg for rails-web",
      "type": "shell",
      "command": "mise x -- kdk stop rails-web && KHULNASOFT_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true mise x -- rdbg --open -c bin/rails server",
      "isBackground": true,
      "problemMatcher": {
        "owner": "rails",
        "pattern": {
          "regexp": "^.*$",
        },
        "background": {
          "activeOnStart": false,
          "beginsPattern": "^(ok: down:).*$",
          "endsPattern": "^(DEBUGGER: wait for debugger connection\\.\\.\\.)$"
        }
      }
    },
  ]
}
```

1. Add the following configuration to your `.vscode/launch.json` file:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "rdbg",
      "name": "Attach rails-web with rdbg",
      "request": "attach",

      // We need to add the correct rdbg path as additional launch config entry; you can find the correct rdbg path by executing "which rdbg"
      "rdbgPath": "/home/kdk/.local/share/mise/installs/ruby/3.2.4/bin/rdbg",


      // remove the following "preLaunchTask" if you do not wish to stop and start
      // KhulnaSoft via VS Code but manually on a separate terminal.
      "preLaunchTask": "start rdbg for rails-web"
    }
  ]
}
```

NOTE: This assumes the default location for the SSH key.
