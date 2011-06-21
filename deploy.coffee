control = require 'control'
task    = control.task
perform = control.perform

task 'staging', 'config got my server', ->
  config = user: 'root'
  addresses = ['socketracer.com']
  return control.hosts(config, addresses)
  
task 'deploy', 'deploy the latest version of the app', (host) ->
  host.ssh 'cd apps/socketracer/ && git pull origin master', -> 
    perform 'restart', host
  
task 'update_dependencies', 'upgrade socketstream', (host) ->
  host.ssh 'cd socketstream/ && git pull origin master && sudo npm link', ->

task 'restart', 'restart the application', (host) ->
  host.ssh 'sudo sh /etc/init.d/socketracer restart'  

task 'stop', 'stop the application', (host) ->
  host.ssh 'sudo sh /etc/init.d/socketracer stop'  

task 'start', 'stop the application', (host) ->
  host.ssh 'sudo sh /etc/init.d/socketracer start'

control.begin()