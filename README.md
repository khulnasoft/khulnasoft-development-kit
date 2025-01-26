# KhulnaSoft Development Kit (KDK)

[![build status](https://github.com/khulnasoft/khulnasoft-development-kit/badges/main/pipeline.svg)](https://github.com/khulnasoft/khulnasoft-development-kit/pipelines)

The KhulnaSoft Development Kit (KDK) installs KhulnaSoft on your workstation. KDK
manages KhulnaSoft requirements, development tools and databases.

The KDK is used by KhulnaSoft team members and contributors to test changes
locally to speed up the time to make successful contributions.

## Goals

- Provide tools to install, update, and develop against a local KhulnaSoft instance.
- Automate installing [required software](https://docs.khulnasoft.com/ee/install/requirements.html#software-requirements).
- Only manage projects, software, and services that may be needed to run a KhulnaSoft instance.
- Out of the box, only enable the services KhulnaSoft strictly requires to operate.
- Support native operating systems as listed below.

## Installation

You can install KDK using the following methods. Some are:

- Supported and frequently tested.
- Not supported, but we welcome merge requests to improve them.

### Supported methods

The following installation methods are supported, actively maintained, and tested:

#### Local

Requires at least 16 GB RAM and 30 GB disk space.
Available for [supported platforms](#supported-platforms).

- [One-line installation](doc/index.md#one-line-installation).
- [Simple installation](doc/index.md#simple-installation).
- [KDK-in-a-box](doc/kdk_in_a_box.md). Requires at least 30 GB disk space.

#### Remote

- [KhulnaSoft remote development workspaces](doc/howto/khulnasoft-remote-development.md).
- [Gitpod](doc/howto/gitpod.md).

### Supported platforms

| Operating system | Versions                       |
|:-----------------|:-------------------------------|
| macOS            | 15, 14, 13 (1)                 |
| Ubuntu           | 24.04, 22.04                   |
| Fedora           | 40                             |
| Debian           | 13, 12                         |
| Arch             | latest                         |
| Manjaro          | latest                         |

- (1) We follow [Apple's supported versions](https://endoflife.date/macos).<br/>
  MacOS on Intel is supported by KDK but does not enjoy all features like
  skipping compilation of certain services in favor of precompiled
  binaries.

The list of platforms includes operating systems that run in a Windows Subsystem for Linux (WSL) environment.

### Unsupported methods

The following documentation is provided for those who can benefit from it, but aren't
supported installation methods:

- [Advanced installation](doc/advanced.md) on your local system. Requires at least
  8 GB RAM and 12 GB disk space.
- [Vagrant](doc/howto/vagrant.md).
- [minikube](doc/howto/kubernetes/minikube.md).

## Post-installation

- [Use KDK](doc/howto/index.md).
- [Update an existing installation](doc/kdk_commands.md#update-kdk).
- [Login credentials (root login and password)](doc/kdk_commands.md#get-the-login-credentials).

### Using SSH remotes

KDK defaults to HTTPS instead of SSH when cloning the repositories. With HTTPS, you can still use KDK without a KhulnaSoft.com
account or an SSH key. However, if you have a KhulnaSoft.com account and already
[added your SSH key](https://docs.khulnasoft.com/ee/user/ssh.html#add-an-ssh-key-to-your-khulnasoft-account) to your account,
you can configure `git` to rewrite the URLs to use SSH via the following configuration change:

```shell
git config --global url.'git@khulnasoft.com:'.insteadOf 'https://khulnasoft.com/'
```

NOTE:
This command configures `git` to use `SSH` for all KhulnaSoft.com URLs.

## FAQ

### Why don't we Dockerize or containerize KDK, or switch to GCK as the preferred tool?

We have [KDK In A Box](doc/kdk_in_a_box.md),
a preconfigured virtual machine you can download and boot to instantly start developing.

Gitpod and Remote Development use a single container solution,
but we are not yet ready to recommend a Docker solution for your primary development environment.

- The majority of KDK users have macOS as their primary operating system, which is
  supported by Docker and other containerization tools but usually requires a virtual machine (VM).
  Running and managing a VM adds to the overall complexity.
- The performance of Docker or containerization on macOS is still unpredictable.
  It's getting better all the time, but for some users (both KhulnaSoft team members and our community)
  it may prove to be a blocker.
- The ability to debug problems is another issue as getting to the root cause of
  a problem could prove more challenging due to the different execution and operating contexts
  of Docker or other containerization tools.
- For users that run non-Linux operating systems, running Docker or other containerization tools
  have their own set of hardware requirements which could be another blocker.

## Getting help

- We encourage you to [create a new issue](https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/new).
- KhulnaSoft team members can use the `#kdk` channel on the KhulnaSoft Slack workspace.
- Review the [troubleshooting information](doc/troubleshooting).
- Wider community members can use the following:
  - [KhulnaSoft community Discord](https://discord.gg/khulnasoft).
  - [KhulnaSoft Forum](https://forum.khulnasoft.com/c/community/39).

## Contributing to KhulnaSoft Development Kit

Contributions are welcome; see [`CONTRIBUTING.md`](CONTRIBUTING.md)
for more details.

### Install Lefthook locally

Please refer to the [Lefthook page](doc/howto/lefthook.md).

## License

The KhulnaSoft Development Kit is distributed under the MIT license; see the
[LICENSE](LICENSE) file.
