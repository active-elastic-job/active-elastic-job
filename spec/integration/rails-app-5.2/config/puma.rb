directory '/var/app/current'
threads 1, 2
workers `grep -c processor /proc/cpuinfo`
bind 'unix:///var/run/puma/my_app.sock'
stdout_redirect '/var/log/puma/puma.log', '/var/log/puma/puma.log', true
