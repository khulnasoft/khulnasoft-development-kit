# Duo Workflow

Prerequisites:

- Install the [`gcloud` CLI](https://cloud.google.com/sdk/docs/install) and configure it with a suitable project:

  ```shell
  gcloud auth application-default login
  ```

- Configure a [loopback interface](local_network.md#create-loopback-interface):

  This interface enables the executor to access services from within Docker.
  When configured, the loopback adapter is automatically set as the host for the Duo Workflow Service.

  - If you are using Colima, configure it to use your loopback IP address:

    ```shell
    colima stop
    colima start --network-address=true --dns-host kdk.test=<LOOPBACK_IP_ADDRESS>
    ```

To configure the Duo Workflow components:

1. In the root of your `<kdk-dir>` enable `duo-workflow-service` and configure your KhulnaSoft instance to use this locally running instance:

   ```shell
   kdk config set duo_workflow.enabled true
   kdk reconfigure
   kdk restart duo-workflow-service rails
   ```

## Optional: Run a different branch of Duo Workflow Service

The
[`duo-workflow-service` repository](https://khulnasoft.com/khulnasoft-org/duo-workflow/duo-workflow-service)
is cloned into `<kdk-dir>/duo-workflow-service`.

To configure KDK to run a specific branch, use either the branch name or SHA:

```shell
kdk config set duo_workflow.service_version <branch-name-or-SHA>
kdk reconfigure
```

## Optional: Run a different branch of Duo Workflow Executor

The [`duo-workflow-executor` repository](https://khulnasoft.com/khulnasoft-org/duo-workflow/duo-workflow-executor) is
cloned into `<kdk-dir>/duo-workflow-executor` and compiled every time you run
`kdk reconfigure`. The binary is placed in `<kdk-dir>/khulnasoft/public/assets` and
served up by your local KhulnaSoft instance.

To change the version used:

1. Edit the `<kdk-dir>/khulnasoft/DUO_WORKFLOW_EXECUTOR_VERSION` with a valid SHA in the repository.
1. Recompile the binary:

   ```shell
   kdk reconfigure
   ```

## Optional: Configure LLM Cache

LLMs are slow and expensive. If you are doing lots of repetitive development
with Duo Workflow you may wish to enable
[LLM caching](https://khulnasoft.com/khulnasoft-org/duo-workflow/duo-workflow-service#llm-caching)
to speed up iteration and save money. To enable the cache:

```shell
kdk config set duo_workflow.llm_cache true
kdk reconfigure
kdk restart duo-workflow-service rails
```
