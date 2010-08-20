require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))
require 'bot'
require 'bot_plugin'

describe BotPlugin do
  it 'should exist' do
    lambda { BotPlugin }.should_not raise_error
  end
end
