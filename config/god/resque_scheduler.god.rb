rails_env =  "production"
rails_root = "/home/imagapps/webapps/userengage"
rake_root =  "/home/imagapps/webapps/userengage"
ENV['HOME'] = "/home/imagapps/webapps/userengage"
 
God.watch do |w|
  w.name          = "resque_userengage_scheduler"
  w.group         = 'resque_userengage'
  w.interval      = 30.seconds
  w.dir           = rails_root
  w.env           = { 'RAILS_ENV' => rails_env }
  w.start         = "#{rake_root}/rake resque:scheduler"
  w.start_grace   = 10.seconds
  w.log           = File.join(rails_root, 'log', 'resque-scheduler.log')
 
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
end


