# Troubleshooting mise

The following are possible solutions to problems you might encounter with
[mise](https://mise.jdx.dev/) and KDK.

If your issue is not listed here:

- For generic mise problems, raise an issue or pull request in the [mise project](https://github.com/jdx/mise).
- For KDK-specific issues, raise an issue or merge request in the [KDK project](https://github.com/khulnasoft/khulnasoft-development-kit/-/issues).

If you are a KhulnaSoft team member, you can also ask for help with troubleshooting in
the `#mise` Slack channel. If your problem is KDK-specific, use the
`#kdk` channel so more people can see it.

## Error: `No such file or directory` when installing

You might have `mise install` fail with a cache error like the following.

```shell
$ mise install
mise ruby build tool update error: failed to update ruby-build: No such file or directory (os error 2)
mise failed to execute command: ~/Library/Caches/mise/ruby/ruby-build/bin/ruby-build 3.2.5 /Users/kdk/.local/share/mise/installs/ruby/3.2.5
mise No such file or directory (os error 2)
```

You can usually fix this by cleaning the mise cache: `mise cache clear`
