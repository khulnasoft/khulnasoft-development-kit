<!-- Replace `<RUBY_VERSION>` with the new Ruby version. -->

## Overview

The goal of this issue is to upgrade the Ruby version to `<RUBY_VERSION>`.

### Prior to Starting to Upgrade Ruby Version

- [ ] Confirm the new Ruby version is available in [asdf-ruby](https://github.com/asdf-vm/asdf-ruby).

### Checklist

- [ ] Update the version of Ruby in the `.tool-versions` file for the following projects:
  - [ ] gitaly
  - [ ] khulnasoft
  - [ ] khulnasoft-docs
  - [ ] khulnasoft-shell
  - [ ] khulnasoft-development-kit
    - [ ] Update [`MISC_RUBY_PATCHES`](https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/910b6f294341910a7427bd381052f520aa3fc8b5/support/bootstrap#L57-63) so that the Ruby version gets installed with patches.
    - [ ] Create an announcement in the [`data/announcements`](https://github.com/khulnasoft/khulnasoft-development-kit/-/tree/main/data/announcements) directory.
- [ ] Test the KDK using the new Ruby version by running `verify-*` jobs in CI pipelines ensure the compatibility.
- [ ] Test the the Remote Development KDK docker image by creating a workspace from the KDK repository.
- [ ] Test the Gitpod KDK docker image using the new Ruby version by running `verify-gitpod-workspace-image` job in CI pipelines.

### Announcement

Once the upgrade is ready to take place, an announcement should be made in the `#kdk` Slack channel with a message using the following message as an example:

```
Hey team! Please be advised that an upgrade of the Ruby version to ________ is scheduled to take place on ________. If you experience any issues or have any concerns, please contact to us in this issue: ________. Thank you for your understanding.
```

/label ~"Category:KDK" ~"kdk-reliability" ~"group::developer tooling" ~"type::maintenance" ~"maintenance::dependency"

<!-- template sourced from https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/.khulnasoft/issue_templates/Ruby Version Upgrade.md -->
