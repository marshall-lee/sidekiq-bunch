require 'bundler/setup'

require 'sidekiq/testing'
Sidekiq::Testing.disable!

require 'sidekiq/bunch'

Sidekiq::Testing.server_middleware.add(Sidekiq::Bunch::Middleware::Server)

require 'support/sidekiq_helper'

require 'sidekiq/bunch'
require 'sidekiq/api'
require 'sidekiq/redis_connection'

REDIS_URL = ENV['REDIS_URL'] || 'redis://localhost/15'
Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL, namespace: 'sidekiq-bunch-testy' }
end

RSpec.configure do |config|
  config.include SidekiqHelper
  config.after(:each) { clear_sidekiq_workers }
  config.after(:each) do
    Sidekiq.redis { |namespaced| namespaced.redis.flushall }
  end

  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
