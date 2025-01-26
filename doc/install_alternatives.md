# Alternative KDK installation methods

In addition to the [primary installation process](index.md#use-kdk-to-install-khulnasoft), you can install KDK
using alternative methods.

## Install KDK to alternative platforms

Instead of installing KDK locally, you can install KDK to other platforms.

### Vagrant install

You can install KDK under a
[virtualized environment using Vagrant with Virtualbox or Docker](howto/vagrant.md).

### minikube install

You can also install KDK on [minikube](https://github.com/kubernetes/minikube);
see [Kubernetes documentation](howto/kubernetes/minikube.md).

### Gitpod integration

Alternatively, you can use [KDK with Gitpod](howto/gitpod.md) to run a pre-configured KDK instance in the cloud.

## Install KDK using alternative projects

Instead of installing KDK from the default KhulnaSoft project, you can install KDK from other KhulnaSoft
projects.

### Install using KhulnaSoft FOSS project

Learn [how to create a fork](https://docs.khulnasoft.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
of [KhulnaSoft FOSS](https://khulnasoft.com/khulnasoft-org/khulnasoft-foss).

After cloning the `khulnasoft-development-kit` project and running `make bootstrap`, to:

- Clone `khulnasoft-foss` using SSH, run:

  ```shell
  kdk install khulnasoft_repo=git@khulnasoft.com:khulnasoft-org/khulnasoft-foss.git
  ```

- Clone `khulnasoft-foss` using HTTPS, run:

  ```shell
  kdk install khulnasoft_repo=https://khulnasoft.com/khulnasoft-org/khulnasoft-foss.git
  ```

### Install using your own KhulnaSoft fork

Learn [how to create a fork](https://docs.khulnasoft.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
of [KhulnaSoft FOSS](https://khulnasoft.com/khulnasoft-org/khulnasoft-foss).

After cloning the `khulnasoft-development-kit` project and running `make bootstrap`, to:

- Clone `khulnasoft-foss` using SSH, run:

  ```shell
  kdk install khulnasoft_repo=git@khulnasoft.com:khulnasoft-org/khulnasoft-foss.git
  ```

- Clone `khulnasoft-foss` using HTTPS, run:

  ```shell
  kdk install khulnasoft_repo=https://khulnasoft.com/khulnasoft-org/khulnasoft-foss.git
  ```
