psql := $(postgresql_bin_dir)/psql

.PHONY: postgresql-replica-setup
ifeq ($(postgresql_replica_enabled),true)
postgresql-replica-setup: postgresql-replication/config postgresql-replica/data
else
postgresql-replica-setup:
	@true
endif

.PHONY: postgresql-replica-2-setup
ifeq ($(postgresql_replica_enabled2),true)
postgresql-replica-2-setup: postgresql-replication/config postgresql-replica-2/data
else
postgresql-replica-2-setup:
	@true
endif

postgresql-replica/data:
	pg_basebackup -R -h ${postgresql_dir} -D ${postgresql_replica_data_dir} -P -U khulnasoft_replication --wal-method=fetch

postgresql-replica-2/data:
	pg_basebackup -R -h ${postgresql_dir} -D ${postgresql_replica_data_dir2} -P -U khulnasoft_replication --wal-method=fetch

postgresql-replication-primary-create-slot: postgresql-replication/slot

postgresql-replication/backup:
	$(Q)$(eval postgresql_primary_dir := $(realpath postgresql-primary))
	$(Q)$(eval postgresql_primary_host := $(shell cd ${postgresql_primary_dir}/../ && kdk config get postgresql.host $(QQerr)))
	$(Q)$(eval postgresql_primary_port := $(shell cd ${postgresql_primary_dir}/../ && kdk config get postgresql.port $(QQerr)))

	$(Q)$(psql) -h ${postgresql_primary_host} -p ${postgresql_primary_port} -d postgres -c "select pg_start_backup('base backup for streaming rep')"
	$(Q)rsync -cva --inplace --exclude="*pg_xlog*" --exclude="*.pid" ${postgresql_primary_dir}/data postgresql
	$(Q)$(psql) -h ${postgresql_primary_host} -p ${postgresql_primary_port} -d postgres -c "select pg_stop_backup(), current_timestamp"
	$(Q)./support/postgresql-standby-server ${postgresql_primary_host} ${postgresql_primary_port}
	$(Q)$(MAKE) postgresql/data/khulnasoft.conf ${QQ}

postgresql-replication/slot:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_create_physical_replication_slot('khulnasoft_kdk_replication_slot');"

postgresql-replication/list-slots:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_replication_slots;"

postgresql-replication/drop-slot:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_drop_replication_slot('khulnasoft_kdk_replication_slot');"

postgresql-replication/config:
	$(Q)./support/postgres-replication
