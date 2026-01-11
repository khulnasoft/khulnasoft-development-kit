# frozen_string_literal: true

KDK.component do
  feature_category :observability

  smoke_test 'Is enabled' do
    KDK.config.bury!('grafana.enabled', true)
    KDK.config.save_yaml!

    raise 'Reconfigure failed' unless KDK::Shellout.new(%w[kdk reconfigure]).execute.success?
    raise 'Grafana start failed' unless KDK::Shellout.new(%w[kdk start grafana]).execute.success?

    retry_until_true do
      KDK::Shellout.new(%W[curl --fail #{KDK.config.grafana.__uri}]).execute.success?
    end
  end
end
