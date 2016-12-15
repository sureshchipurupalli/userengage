rails_root = "/home/imagapps/webapps/userengage"
redis_root = "/usr/bin"
 
# Redis
%w{6379}.each do |port|
  God.watch do |w|
    w.name          = "redis"
    w.interval      = 30.seconds
    w.start         = "#{redis_root}/redis-server /opt/redis/redis.conf"
    w.stop          = "#{redis_root}/redis-cli -p #{port} shutdown"
    w.restart       = "#{w.stop} && #{w.start}"
    w.start_grace   = 10.seconds
    w.restart_grace = 10.seconds
    w.log           = File.join(rails_root, 'log', 'redis.log')
 
    w.start_if do |start|
      start.condition(:process_running) do |c|
          c.interval = 5.seconds
          c.running = false
      end
    end
  end
end


