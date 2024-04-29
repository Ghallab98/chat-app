require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}" }
  schedule_file = "config/schedule.yml"
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end

# Sidekiq.configure_client do |config|
#   config.redis = { url: 'redis://localhost:6379' }
# end