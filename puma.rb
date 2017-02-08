root = "#{Dir.getwd}"

activate_control_app "tcp://0.0.0.0:9293"
bind "unix:///tmp/puma.keepion.sock"
# bind 'tcp://0.0.0.0:4567'

pidfile "#{root}/tmp/pids/puma.pid"
rackup "#{root}/config.ru"
state_path "#{root}/tmp/pids/puma.state"
