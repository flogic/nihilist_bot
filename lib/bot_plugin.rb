class BotPlugin
  include Cinch::Plugin
  
  def main_bot
    bot.container
  end
end

require 'plugins/help'
require 'plugins/process'
