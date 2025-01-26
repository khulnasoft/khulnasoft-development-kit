## What does this merge request do and why?

<!-- Briefly describe what this merge request does and why. -->

%{first_multiline_commit}

## How to set up and validate locally

_Numbered steps to set up and validate the change are strongly suggested._

<!--
Example below:

1. Ensure KhulnaSoft Pages is enabled by adding the below configuration in `kdk.yml`:
  ```yml
  ---
  khulnasoft_pages:
    enabled: true
  ```
1. Check out to this merge request's branch.
1. Run `kdk reconfigure` to check if regenerating all configuration is successful.
-->

## Impacted categories

The following categories relate to this merge request:

- [ ] ~"kdk-reliability" - e.g. When a KDK action fails to complete.
- [ ] ~"kdk-usability" - e.g. Improvements or suggestions around how the KDK functions.
- [ ] ~"kdk-performance" - e.g. When a KDK action is slow or times out.

## Merge request checklist

- [ ] This change is backward compatible. If not, please include steps to communicate to our users.
- [ ] Tests added for new functionality. If not, please raise an issue to follow-up.
- [ ] Documentation added/updated, if needed.
- [ ] [Announcement added](doc/howto/announcements.md), if change is notable.
- [ ] `kdk doctor` test added, if needed.

/label ~"Category:KDK" ~"group::developer tooling"
/assign me

<!-- Thanks for contributing to KDK ♥️ -->

<!-- template sourced from https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/.khulnasoft/merge_request_templates/Default.md -->
