require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot'
require 'bot_plugin'
require 'plugins/help'

describe BotPlugin::Help do
  it 'should be a cinch plugin' do
    BotPlugin::Help.included_modules.should include(Cinch::Plugin)
  end
end
