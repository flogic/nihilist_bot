namespace :deploy do
  task :restart_bot do
    system(File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'bot_control')), 'stop')
    system(File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'bot_control')), 'start')
  end

  task :post_deploy => [ :restart_bot ]
end

namespace :bot do
  $:.unshift('lib')
  require 'bot'

  class << Bot
    def restart?
      command = File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'bot_control'))
      status = `#{command} status`
      result = status =~ /^bot: running/
      !result
    end

    def restart
      command = File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'bot_control'))
      system(command, 'start')
    end
  end

  task :check_restart do
    Bot.restart if Bot.restart?
  end
end
