# AutoFlow (experimental)

The following sections document how to set up AutoFlow in KDK.

AutoFlow is experimental and may break at any time.

## Enable AutoFlow in KAS

To use AutoFlow with the KDK, you must configure the agent server for Kubernetes (KAS) to turn it on:

```yaml
khulnasoft_k8s_agent:
  autoflow:
    enabled: true
```

AutoFlow requires access to a running
[Temporal](https://temporal.io) server.
You may use the `./support/temporal` script to automatically
install and start a Temporal development server.

## Enable AutoFlow in Rails

To enable AutoFlow in Rails, an administrator can enable the `autoflow_enabled`
feature flag. AutoFlow support is scoped to projects.

## Configure Temporal client

The Temporal client is configured to connect to the
default `host_port` and `namespace` of the Temporal development server
(the development server started by the `./support/temporal` script).

You can reconfigure the Temporal client with the following configuration:

```yaml
khulnasoft_k8s_agent:
  autoflow:
    enabled: true

    # Configure for Temporal Cloud
    temporal:
      host_port: <namespace-name>.<namespace-id>.tmprl.cloud:7233
      namespace: <namespace-name>
      enable_tls: true
      certificate_file: /kdk/dir/temporal-client.pem
      key_file: /kdk/dir/temporal-client.key
```
