#!/usr/bin/ruby
#
# Controller for the Autumn Leaves daemon. Starts, stops, and manages the
# daemon.
# 
#  Usage: big-switch.rb <command> <options> -- <application options>
#  
#  * where <command> is one of:
#    start         start an instance of the application
#    stop          stop all instances of the application
#    restart       stop all instances and restart them afterwards
#    run           start the application and stay on top
#    zap           set the application to a stopped state
#  
#  * and where <options> may contain several of the following:
#  
#      -t, --ontop                      Stay on top (does not daemonize)
#      -f, --force                      Force operation
#  
#  Common options:
#      -h, --help                       Show this message
#          --version                    Show version

require 'rubygems'
require 'daemons'

Daemons.run "#{File.dirname(__FILE__)}/genesis.rb", :app_name => 'autumn-leaves', :dir_mod => :script, :multiple => false, :backtrace => true, :monitor => false, :log_output => true
