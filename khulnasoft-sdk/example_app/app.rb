# frozen_string_literal: true

require 'sinatra'
require 'sinatra/namespace'
require 'khulnasoft-sdk'

get '/' do
  'Sinatra server.'
end

namespace '/api/v1' do
  get '/send_event' do
    check_required_env_vars
    client = KhulnasoftSDK::Client.new(app_id: ENV['PA_APPLICATION_ID'], host: ENV['PA_COLLECTOR_URL'])
    client.track('an_event', { id: 123 })
    'Event sent!'
  end
end

def check_required_env_vars
  exception_messsage = 'PA_APPLICATION_ID and PA_COLLECTOR_URL env variables must be set.'
  raise exception_messsage if ENV['PA_APPLICATION_ID'].nil? || ENV['PA_COLLECTOR_URL'].nil?
end
