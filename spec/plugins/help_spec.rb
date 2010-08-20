require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot'
require 'bot_plugin'
require 'plugins/help'

describe BotPlugin::Help do
  before :each do
    @bot = Bot.new
    @bot.prepare
    @bot.bot.logger = Cinch::Logger::NullLogger.new
    @plugin = BotPlugin::Help.new(@bot.bot)
  end
  
  it 'should be a cinch plugin' do
    BotPlugin::Help.included_modules.should include(Cinch::Plugin)
  end
  
  it 'should listen to messages' do
    listener = BotPlugin::Help.instance_variable_get('@__cinch_listeners').first
    listener.event.should  == :message
    listener.method.should == :listen
  end
  
  describe 'listening to a message' do
    before :each do
      @message = Struct.new(:nick, :channel, :text).new('somenick', 'somechannel', 'sometext')
      @message.stubs(:reply)
    end
    
    it 'should accept a message' do
      lambda { @plugin.listen(@message) }.should_not raise_error(ArgumentError)
    end
    
    it 'should require a message' do
      lambda { @plugin.listen }.should raise_error(ArgumentError)
    end
    
    it 'should get formats from parser' do
      BotParser.expects(:formats).returns([])
      @plugin.listen(@message)
    end
    
    it 'should respond with a list of formats' do
      formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym) }
      BotParser.stubs(:formats).returns(formats)
      @message.expects(:reply).with("Known formats: #{formats.collect { |f|  f.name }.join(', ')}")
      @plugin.listen(@message)
    end
  end
end
