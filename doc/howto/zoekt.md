# Zoekt

KhulnaSoft Enterprise Edition has a [Zoekt](https://github.com/sourcegraph/zoekt)
integration, which you can enable in your development environment.

## Installation

### Enable Zoekt in the KDK

The default version of Zoekt is automatically downloaded into your KDK root under `/zoekt`.
The default version of KhulnaSoft Zoekt Indexer is automatically downloaded into your KDK root under `/khulnasoft-zoekt-indexer`.

To enable the service and run it as part of `kdk start`:

1. Run `kdk config set zoekt.enabled true`.
1. Run `kdk reconfigure`.
1. Run `kdk start` which now starts 6 Zoekt servers:
   - `khulnasoft-zoekt-indexer` for test.
   - `khulnasoft-zoekt-indexer-1` for development.
   - `khulnasoft-zoekt-indexer-2` for development.
   - `zoekt-webserver` for test.
   - `zoekt-webserver-1` for development.
   - `zoekt-webserver-2` for development.

### Configure Zoekt in development

Zoekt must be enabled for each namespace you wish to index. Launch the Rails
console with `kdk rails c`. Given the default ports for Zoekt in KDK and
assuming your local instance has a namespace called `flightjs` (which is a KDK
seed by default), run the following from the Rails console:

```ruby
ApplicationSetting.current.update!(zoekt_settings: { zoekt_indexing_enabled: true, zoekt_indexing_paused: false, zoekt_search_enabled: true, zoekt_cpu_to_tasks_ratio: 1.0 })
zoekt_node = ::Search::Zoekt::Node.online.last
namespace = Namespace.find_by_full_path("flightjs") # Some namespace you want to enable
enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
zoekt_node.indices.find_or_create_by!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, zoekt_replica_id: Search::Zoekt::Replica.for_enabled_namespace!(enabled_namespace).id)
```

Now, if you create a new public project in the `flightjs` namespace or update
any existing public project in this namespace, it is indexed in Zoekt. Code
searches within this project are served by Zoekt.

Group-level searches in `flightjs` are also served by Zoekt.

### Switch to a different version of Zoekt

The default Zoekt version is defined in [`lib/kdk/config.rb`](../../lib/kdk/config.rb).

You can change this by setting `repo` and/or `version`:

```shell
   kdk config set zoekt.repo https://github.com/MyFork/zoekt.git
   kdk config set zoekt.version v1.2.3
```

Here, `repo` is any valid repository URL that can be cloned, and
`version` is any valid ref that can be checked out.

### Switch to a different version of KhulnaSoft Zoekt Indexer

The default KhulnaSoft Zoekt Indexer version is defined in [`lib/kdk/config.rb`](../../lib/kdk/config.rb).

To change this, set `indexer_version`:

```shell
   kdk config set zoekt.indexer_version v1.2.3
```

`indexer_version` is any valid ref that can be checked out.

## Troubleshooting

### No preset version installed for command go

If you get this error during installation, execute the provided command
to install the correct version of Go:

```plaintext
No preset version installed for command go
Please install a version by running one of the following:
```

We cannot use the same Go version we use for other tools because the supported
version is controlled by Zoekt.
