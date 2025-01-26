# KhulnaSoft Docs in KDK

You can use the KDK to contribute KhulnaSoft documentation. The KDK can:

- Maintain a clone of the [`khulnasoft-docs`](https://khulnasoft.com/khulnasoft-org/khulnasoft-docs) repository
  for work on changes to that project.
- Preview changes made in the KDK-managed `khulnasoft/doc` directory.
- Run linting tasks that require `khulnasoft-docs`, including internal link and anchor checks.

If you want to contribute to KhulnaSoft documentation without using KDK, see
[Set up, preview, and update KhulnaSoft Docs site](https://khulnasoft.com/khulnasoft-org/khulnasoft-docs/-/blob/main/doc/setup.md).

## Enable KhulnaSoft Docs

To enable KDK to manage `khulnasoft-docs`:

1. Add the following to your [`kdk.yml` file](../configuration.md#khulnasoft-docs-settings):

   ```yaml
   khulnasoft_docs:
     enabled: true
   ```

   The default port is `3005` but this can be customized. For example:

   ```yaml
   khulnasoft_docs:
     enabled: true
     port: 4005
   ```

   By default, `khulnasoft-docs` is updated from the default project branch every time `kdk update` is
   run. This can be disabled:

   ```yaml
   khulnasoft_docs:
     enabled: true
     auto_update: false
   ```

1. Run `kdk update` to:
   - Clone `khulnasoft-docs` for the first time, or update an existing local copy.
   - Compile a published version of the contents of the `khulnasoft/doc` directory.
1. Start the `khulnasoft-docs` service:

   ```shell
   kdk start khulnasoft-docs
   ```

   Or all KDK services (including `khulnasoft-docs`):

   ```shell
   kdk start
   ```

1. Go to the local documentation URL to ensure the site loads correctly. Either:
   - The URL shown in the terminal, if you ran `kdk start`.
   - The URL given by the `hostname` and `port` of the following commands:

   ```shell
   kdk config get hostname
   kdk config get khulnasoft_docs
   ```

   If the site doesn't load correctly, `tail` the `khulnasoft-docs` logs:

   ```shell
   kdk tail khulnasoft-docs
   ```

## Run KhulnaSoft Docs under HTTPS

You can run the Docs site under HTTPS. Read more in the [NGINX howto](nginx.md).

## Make documentation changes

You can preview documentation changes as they would appear when published on
[KhulnaSoft Docs](https://docs.khulnasoft.com).

To make changes to KhulnaSoft documentation and preview them:

1. Start the `khulnasoft-docs` service and ensure you can preview the documentation site:

   ```shell
   kdk start khulnasoft-docs
   ```

1. Make the necessary changes to the files in `<path_to_kdk>/khulnasoft/doc`.
1. View the preview. You must restart the `khulnasoft-docs` service to recompile the published version of the documentation
   with the new changes:

   ```shell
   kdk restart khulnasoft-docs
   ```

   You can `tail` the `khulnasoft-docs` logs to see progress on rebuilding the documentation:

   ```shell
   kdk tail khulnasoft-docs
   ```

### Include more documentation

The full published documentation suite [includes additional documentation](https://docs.khulnasoft.com/ee/development/documentation/site_architecture/index.html)
from outside the [`khulnasoft` project](https://khulnasoft.com/khulnasoft-org/khulnasoft).

To be able to make and preview changes to the additional documentation:

1. Add the following to your [`kdk.yml`](../configuration.md#additional-projects-settings) as required:

   ```yaml
   khulnasoft_docs:
     enabled: true
   khulnasoft_runner:
     enabled: true
   omnibus_khulnasoft:
     enabled: true
   charts_khulnasoft:
     enabled: true
   khulnasoft_operator:
     enabled: true
   ```

1. Run `kdk update` to:
   - Clone the additional projects for the first time, or update existing local copies.
   - Compile a published version of the additional documentation.
1. Start the `khulnasoft-docs` service if not already running:

   ```shell
   kdk start khulnasoft-docs
   ```

NOTE:
`khulnasoft_runner` should not be confused with [`runner`](runner.md).

By default, the cloned repositories of the `khulnasoft_runner`, `omnibus_khulnasoft`, `charts_khulnasoft`, and `khulnasoft_operator`
components are:

- Updated automatically when you run `kdk update`. To disable this, set `auto_update: false` against
  whichever project to disable.
- Cloned using HTTPS. If you originally [cloned `khulnasoft` using SSH](../index.md#use-kdk-to-install-khulnasoft), you
  might want to set these cloned repositories to SSH also. To set these repositories to SSH:

  1. Go into each cloned repository and run `git remote -v` to review the current settings.
  1. To switch to SSH, run `git remote set-url <remote name> git@khulnasoft.com:khulnasoft-org/<project path>.git`.
     For example, to update your HTTPS-cloned `khulnasoft-runner` repository (with a `remote` called
     `origin`), run:

     ```shell
     cd <KDK root path>/khulnasoft-runner
     git remote set-url origin git@khulnasoft.com:khulnasoft-org/khulnasoft-runner.git
     ```

  1. Run `git remote -v` in each cloned repository to verify that you have successfully made the change from
     HTTPS to SSH.

### Check links

If you move or rename any sections within the documentation, you can verify your changes
don't break any links by running:

```shell
make khulnasoft-docs-check
```

This check requires:

- `khulnasoft_docs.enabled` is true.
- `enabled` is true for [all other projects](#include-more-documentation) that provide
  documentation.

### Troubleshooting

#### Stale published documentation

Sometimes the local published version of the documentation can fall out-of-date with the source
content. In these cases, you can remove the data structure `nanoc` uses to keep track of changes
with the following command:

```shell
make khulnasoft-docs-clean
```

This causes `nanoc` to rebuild all documentation on the next run.

#### Documentation from disabled projects appears in preview

Disabling [additional documentation projects](#include-more-documentation) doesn't remove them
from your file system and `nanoc` continues to use them as a source of documentation. When disabled,
the projects aren't updated so `nanoc` is using old commits to preview the data from those projects.

To ensure only enabled projects appear in the preview:

1. Disable any projects you don't want previewed.
1. Remove the cloned project directory from within KDK.

#### `No preset version installed` error for `markdownlint`

Sometimes the `./scripts/lint-doc.sh` script fails with an error similar to:

```shell
No preset version installed for command markdownlint
Please install a version by running one of the following:

asdf install nodejs 14.16.1
```

The cause is unknown but you can try reinstalling `markdownlint` and reshiming:

```shell
$ rm -f ~/.asdf/shims/markdownlint
$ make markdownlint-install

INFO: Installing markdownlint..
$ asdf reshim nodejs
```

## Preview documentation by using the `khulnasoft-docs-hugo` project

KDK supports locally previewing the KhulnaSoft documentation by using the
[`khulnasoft-docs-hugo` project](https://khulnasoft.com/khulnasoft-org/technical-writing-group/khulnasoft-docs-hugo) instead of the
`khulnasoft-docs` project.

### Enable and disable the `khulnasoft-docs-hugo` project in KDK

To enable previewing KhulnaSoft documentation by using the `khulnasoft-docs-hugo` project:

1. Enable the `khulnasoft-docs-hugo` integration:

   ```shell
   kdk config set khulnasoft_docs_hugo.enabled true
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

To disable previewing KhulnaSoft documentation by using the `khulnasoft-docs-hugo` project:

1. Disable the `khulnasoft-docs-hugo` integration:

   ```shell
   kdk config set khulnasoft_docs_hugo.enabled false
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

### Disable automatic updates

To avoid automatically updating the `khulnasoft-docs-hugo` checkout, run:

```shell
kdk config set khulnasoft_docs_hugo.auto_update false
```

### Configure a custom port

The default port is `1313` but this can be customized:

```shell
kdk config set khulnasoft_docs_hugo.port 1314
```

### Run migration scripts

While the `khulnasoft-docs-hugo` project is under initial development, you can't preview the KhulnaSoft documentation
without running migration scripts. These migration scripts make many changes to the documentation source files that
leave checkouts of the documentation with a lot of changes.

Therefore, by default, the `khulnasoft-docs-hugo` project in KDK doesn't include all the documentation. Instead, the KhulnaSoft
documentation site landing page is shown but links to other documentation don't work. However, KDK can run these
migration scripts so that you can fully preview the KhulnaSoft documentation by using the `khulnasoft-docs-hugo` project.

You should only run these migration scripts if you understand what changes they make. For more information, see
[Documentation post-processing](https://khulnasoft.com/khulnasoft-org/technical-writing-group/khulnasoft-docs-hugo/-/blob/main/doc/post-processing.md).

To allow KDK to run these migration scripts, run:

```shell
kdk config set khulnasoft_docs_hugo.run_migration_scripts true
```

To stop KDK from running these migrations scripts, run:

```shell
kdk config set khulnasoft_docs_hugo.run_migration_scripts false
```

To observe the progress of the migrations scripts as they progress, run:

```shell
kdk tail khulnasoft-docs-hugo
```
