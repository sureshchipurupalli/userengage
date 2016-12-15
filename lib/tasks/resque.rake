require 'resque/tasks'
require 'resque/scheduler/tasks'

task "resque:setup" => :environment
task :scheduler => :setup_schedule
