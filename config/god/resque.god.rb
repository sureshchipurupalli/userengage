rails_env =  "production"
rails_root = "/home/imagapps/webapps/userengage"
rake_root =  "/home/imagapps/webapps/userengage"
ENV['HOME'] = "/home/imagapps/webapps/userengage"
num_workers = rails_env == 'production' ? 2 : 1
 
num_workers.times do |num|
  God.watch do |w|
    w.name          = "resque_userengage_#{num}"
    w.group         = 'resque_userengage'
    w.interval      = 30.seconds
    w.env           = { 'RAILS_ENV' => rails_env, 'QUEUE' => '*' }
    w.dir           = rails_root
    w.start         = "#{rake_root}/rake resque:work"
    w.start_grace   = 10.seconds
    w.log           = File.join(rails_root, 'log', 'resque-worker.log')
 
    # restart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 200.megabytes
        c.times = 2
        # c.restart_file = File.join(rails_root, 'tmp', 'restart.txt')
      end
    end
 
    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end
 
    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end
 
      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end
 
    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end