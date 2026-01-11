# frozen_string_literal: true

KDK.component do
  feature_category :database

  smoke_test 'Is enabled' do
    KDK.config.bury!('clickhouse.enabled', true)
    KDK.config.save_yaml!

    enabled_services = KDK::Services.enabled.map(&:name)
    raise "ClickHouse is not enabled" unless enabled_services.include?('clickhouse')
  end
end
