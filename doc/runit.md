# runit process supervision

We have replaced
[Foreman](https://github.com/ddollar/foreman) with [runit](http://smarden.org/runit/).

`kdk run` is no longer available. Instead, use `kdk start`, `kdk stop`,
and `kdk tail`.

## Why replace Foreman

Foreman was the tool behind `kdk run`; it was configured via the
`Procfile`. While Foreman is easy to get started with, we find it has a
number of drawbacks in KDK:

- Foreman is attached to a terminal window. If that terminal window
  gets closed abruptly, Foreman is not able to cleanly shut down the
  processes it was supervising, leaving them running in the
  background. This is a problem because the next time you start
  Foreman, most of its services fail to start because they need
  resources (network ports) still being used by the old processes that
  never got cleaned up.
- There is no good way to start / stop / restart individual processes
  in the `Procfile`. This is not so noticeable when you work with Ruby
  or JavaScript because of live code reload features, but for Go
  programs (for example, `gitaly`) this does not work well. There you really
  need to stop an old binary and start a new binary.

## Why runit

runit is a process supervision system that we also use in
Omnibus-KhulnaSoft. Compared to Foreman, it is more of a system
administration tool than a developer tool.

The reason we use runit and not the native OS supervisor (`launchd` on
macOS, `systemd` on Linux) is that:

- runit works the same on macOS and Linux so we don't need to handle
  them separately
- runit does not mind running next to the official OS supervisor
- It is easy to run more than one runit supervision tree (for example, if you
  have multiple KDK installations)

## Solving the closed terminal window problem

runit takes its configuration from a directory tree; in our case this is
`/path/to/kdk/services`. We start a `runsvdir` process
anchored to this directory tree once, and never stop it (until you shut
down your computer).

If you close your terminal window, then `runsvdir` and everything under
it just keeps running. If you want to stop KDK after that, just
create a new terminal, `cd` to your KDK installation, and run
`kdk stop`. The `kdk stop` command talks to `runsvdir` and tells it
to stop your KDK services.

If all goes well you don't have to worry about `runsvdir`; the `kdk`
command manages it for you.

## Solving the individual restart problem

You can start, stop and restart individual services by specifying them
on the command line. For example: `kdk restart postgresql redis`.

Although `rails` really refers to more than one process, we have created
a shortcut that lets you write, for example, `kdk stop rails` if you want to
reclaim some memory while not using `localhost:3000`.

## Logs

Because runit is not attached to a terminal, the logs of the services
you're running must go to files.

There are several ways to view realtime logs in your terminal

- To watch every log at the same time (like the output from Foreman), run `kdk tail`.
  You can press Ctrl-C to exit and the services will keep running.
- To watch a subset of services provide the name of the service as an extra parameter:
  run `kdk tail gitaly postgresql` or `kdk tail rails`.

`runit` relies on a logging service called [svlogd](http://smarden.org/runit/svlogd.8.html).
This service handles log rotation and compaction in the following way:

- Each service is configured to store logs in the `log/<servicename>` folder.
- Logs are written to a file called `current` (uncompressed).
- Periodically, this log is compressed and renamed using the TAI64N format, for
  example: `@400000005f8eaf6f1a80ef5c.s`.
- The filesystem datestamp on the compressed logs will be consistent with the time
  KhulnaSoft last wrote to that file.
- `zmore` and `zgrep` allow viewing and searching through compressed or uncompressed logs.

## Modify service configuration

To modify the used to start services, use the `Procfile`. Every time you run `kdk start`, `kdk stop`, and so on,
KDK updates the runit service configuration from the `Procfile`.

To remove service `foo`:

1. Comment out or delete `foo: exec bar` from `Procfile`.
1. Run `kdk stop foo`.
1. Run `rm services/foo`.

### Using environment variables

For environment variables to persist across sessions, you use a `env.runit` file:

1. Add variables to the `env.runit`, line by lines:

   ```shell

   export <VARIABLE_NAME_1>=<VALUES_1>
   export <VARIABLE_NAME_2>=<VALUES_2>
   ... and so on
   ```

1. Run `kdk restart`. These variables are available every time you start KDK.
