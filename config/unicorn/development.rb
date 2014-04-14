worker_processes 2

pid File.expand_path('tmp/pids/unicorn.pid', ENV['RAILS_ROOT']).to_s
listen 3000

stderr_path File.expand_path('log/error.log', ENV['RAILS_ROOT'])
stdout_path File.expand_path('log/development.log', ENV['RAILS_ROOT'])

preload_app true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{ server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end