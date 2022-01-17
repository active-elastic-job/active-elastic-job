# Copied from /opt/elasticbeanstalk/config/private/pumaconf.rb
directory '/var/app/current'
threads 8, 32
workers %x(grep -c processor /proc/cpuinfo)
bind 'unix:///var/run/puma/my_app.sock'
stdout_redirect '/var/log/puma/puma.log', '/var/log/puma/puma.log', true
