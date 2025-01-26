# OpenBao

OpenBao is backward compatible with Vault and can replace Vault without changing the existing setup. To avoid conflicts, disable Vault when enabling OpenBao.

You can configure the [OpenBao](https://openbao.org) to run locally in KDK.

To configure:

1. Set the `BAO_ADDR` variable in your environment

```shell
   export BAO_ADDR='http://kdk.test:8200'
```

1. Run `kdk config set openbao.enabled true`.
1. Run `kdk reconfigure`.
1. Run `rake openbao/config.hcl` to create a configuration file
1. Run `rake openbao/proxy_config.hcl` to create a proxy configuration file
1. Run `kdk start openbao`.
1. Run `kdk start openbao-proxy`.
1. Run `kdk bao configure` to unseal the vault

```shell
=> "✅ OpenBao has been unsealed successfully"
=> "The root token is: s.xxxxxxxxxxxxxxx"
```

1. Run `bao login` with root token from above (`kdk config get openbao.root_token`)
1. Run `bao auth enable approle`
1. Run `bao write auth/approle/role/project_secret_engines_manager token_policies=manage_projects_secret_engines`
1. Run `bao read -field=role_id auth/approle/role/project_secret_engines_manager/role-id > openbao/roleid`
1. Run `bao write -field=wrapping_token -f -wrap-ttl=1h auth/approle/role/project_secret_engines_manager/secret-id > openbao/secretid`
1. Run OpenBaoProxy with `kdk start openbao-proxy`
