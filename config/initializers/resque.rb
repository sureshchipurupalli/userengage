# Resque tasks
# require 'resque/tasks'
# require 'resque-scheduler/tasks'

if File.file?("#{Rails.root}/config/redis.yml")
  redis_config = YAML.load_file("#{Rails.root}/config/redis.yml")
else
  redis_config = YAML.load_file("#{Rails.root}/config/local_redis.yml")
end

Resque.redis = Redis.new(redis_config[Rails.env])
#Resque::Plugins::Status::Hash.expire_in = (24 * 60 * 60) # 24hrs in seconds

if Rails.env == 'development'
  Resque.inline = true
end

Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")


Resque::Scheduler.dynamic = true



#
# rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
# rails_env = ENV['RAILS_ENV'] || 'development'
#
# $resque_config = YAML.load_file(rails_root + '/config/resque.yml')
# uri = URI.parse($resque_config[rails_env])
# Resque.redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)