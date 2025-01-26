# Migrate from self-managed dependencies to KDK-managed dependencies using `asdf`

If you currently [manage your own KDK dependencies](advanced.md), you can simplify
the process by letting KDK manage dependencies for you using `asdf`.

There are three main types of dependency managers that can be used to manage dependencies required
by KDK:

- A [Ruby](https://www.ruby-lang.org) manager, usually [`rbenv`](https://github.com/rbenv/rbenv) or
  [`rvm`](https://rvm.io).
- A [Node.js](https://nodejs.org) manager, usually [`nvm`](https://github.com/nvm-sh/nvm).
- An operating system's package manager, or a third-party package manager for macOS (for example: [Homebrew](https://brew.sh)
  or [MacPorts](https://www.macports.org)).

Before `asdf` can manage your KDK dependencies, you must:

1. Check the dependencies listed in the project's [.tool-versions](https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/.tool-versions)
   file and remove them from the other dependency managers.
1. If you use macOS, make sure MacPorts is [uninstalled](https://guide.macports.org/chunked/installing.macports.uninstalling.html).
   If you haven't used MacPorts for a long time, you may have to [update](https://guide.macports.org/chunked/using.html#using.port.selfupdate)
   it before you uninstall it.

Before removing the dependencies, note that:

- You can have more than one dependency manager handling the same dependency. For example,
  after removing `node` from `nvm`, you might find another version of `node` managed by `brew`.
  In this case, repeat the process for each dependency manager.
- Your operating system might come with a built-in version of a dependency. For example,
  macOS comes with Ruby by default. Don't try to remove these built-in dependencies because:
  - They are difficult to remove.
  - The dependency managers are designed to override them.

## Uninstall Ruby dependency manager

Uninstall your Ruby dependency manager to let `asdf` manage Ruby dependencies for KDK
and other Ruby projects.

If you're unsure which Ruby dependency manager you are using, run `which ruby` at the command line.
The dependency manager should be indicated in the output:

- If using `rbenv`, see the [`rbenv` uninstall](https://github.com/rbenv/rbenv#uninstalling-rbenv)
  documentation.
- If using `rvm`, see "How do I completely clean out all traces of RVM from my system, including for
  system wide installs?" in the [`rvm` removal](https://rvm.io/support/troubleshooting) documentation.

## Uninstall Node.js dependency manager

Uninstall your Node.js dependency manager to let `asdf` manage Node.js dependencies for KDK
and other Node.js projects.

If you're unsure which Node dependency manager you are using, run `which node` at the command line.
The dependency manager should be indicated in the output:

- If using `nvm`, see the [uninstalling `nvm` documentation](https://github.com/nvm-sh/nvm#uninstalling--removal).
- If not using `nvm`, try running `brew uninstall node`.

## Remove Ruby and Node.js configuration

Uninstalling the dependency managers for Ruby and Node.js doesn't remove the configuration, and this
configuration can clash with `asdf` configuration.

1. Remove configuration from your home directory relating to these dependency managers. For example,
   delete all of the following configuration files if you find them:

   - `~/.rvm`.
   - `~/.rbenv`.
   - `~/.nvm`.

1. Determine which shell you use by running `printenv SHELL` at the command line.
1. Edit the shell's configuration file and remove references to these dependency managers. For
   example, edit:

   - `~/.bashrc` for `bash`.
   - `~/.zshrc` for `zsh`.

## Remove other dependencies

To remove other dependencies so `asdf` can manage them instead:

1. Look at the list of
   [dependencies `asdf` manages for KDK](https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/.tool-versions).
1. Use the package manager for your operating system to uninstall any of those dependencies you have
   installed. For example, to uninstall [Redis](https://redis.io) that was installed
   by using `brew` in macOS:

   ```shell
   brew uninstall redis
   ```

If you uninstall Redis, you should remove the Redis dump file to avoid errors:

```shell
rm <path-to-your-khulnasoft-development-kit>/redis/dump.rdb
```

## Install dependencies with `asdf`

To install KDK dependencies with `asdf`, follow [these instructions](index.md#install-dependencies-using-asdf).
