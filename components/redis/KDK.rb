# frozen_string_literal: true

KDK.component do
  feature_category :redis

  smoke_test 'Connect via CLI to Redis server' do
    KDK::Shellout.new("kdk start redis").execute

    retry_until_true do
      stdout = KDK::Shellout.new("echo 'ping' | kdk redis-cli").execute.read_stdout
      stdout.include?('PONG')
    end
  end

  template name: 'redis/redis.conf', template: 'redis.conf.erb'
end
