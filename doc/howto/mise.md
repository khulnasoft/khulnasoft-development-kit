# Migrate to `mise` for dependency management

You can use [`mise`](https://mise.jdx.dev) instead of [`asdf`](https://asdf-vm.com) for KDK dependency management.
You should use one or the other, but not both at the same time.

Most existing KDK installations use `asdf`, which is the default. To migrate from `asdf` to `mise` (replace references
to `$KDK_ROOT` with the directory KDK is located):

1. Opt out of `asdf`:

   ```shell
   kdk config set asdf.opt_out true
   ```

1. Enable `mise` support:

   ```shell
   kdk config set mise.enabled true
   ```

1. Install the new local hooks:

   ```shell
   (cd $KDK_ROOT && lefthook install)
   ```

1. [Install `mise`](https://mise.jdx.dev/getting-started.html#_1-install-mise-cli).
1. Reconfigure your shell (<https://mise.jdx.dev/faq.html#how-do-i-migrate-from-asdf>):

   ```shell
   eval "$(mise activate [bash|zsh|<other_shell>])" # For example, `eval "$(mise activate zsh)"`

   eval "$(mise hook-env)"
   ```

1. Install the current dependencies in the `mise` cache:

   ```shell
   (cd $KDK_ROOT/khulnasoft && mise install)
   ```

1. Re-bootstrap KDK:

   ```shell
   cd $KDK_ROOT
   rm .cache/.kdk_bootstrapped
   make bootstrap
   ```

1. Reconfigure and update KDK. This time, `mise` is used to install the dependencies and `asdf` is not required
   anymore.

   ```shell
   (cd $KDK_ROOT && kdk reconfigure && kdk update)
   ```

1. (Optional) [Uninstall asdf](https://asdf-vm.com/manage/core.html#uninstall).

## Troubleshooting

If you encounter problems with mise, see [the troubleshooting page](../troubleshooting/mise.md).
