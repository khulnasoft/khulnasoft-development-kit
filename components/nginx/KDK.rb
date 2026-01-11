# frozen_string_literal: true

KDK.component do
  feature_category :delivery

  template name: 'nginx/conf/nginx.conf', template: 'nginx.conf.erb'

  smoke_test 'Has valid configuration' do
    success = KDK::Shellout.new("nginx -p #{KDK.config.kdk_root.join('nginx')} -c conf/nginx.conf -t").execute.success?

    raise 'Invalid nginx configuration' unless success
  end
end
