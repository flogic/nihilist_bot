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
  
  # triggered on plain !help
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
  
  it "should trigger execution on '!help [some format]' and keep the format name" do
    pattern = BotPlugin::Help.instance_variable_get('@__cinch_patterns').first
    format_name = 'crazy_format'
    pattern.pattern.match("!help #{format_name}")[1].should == format_name
    pattern.method.should == :execute
  end
  
  # triggered on !help [some format]
  describe 'executing a match' do
    before :each do
      @message = Struct.new(:nick, :channel, :text).new('somenick', 'somechannel', 'sometext')
      @message.stubs(:reply)
      @format = 'link'
      
      @formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => "Description for format #{i}") }
      BotParser.stubs(:formats).returns(@formats)
    end
    
    it 'should accept a message and format' do
      lambda { @plugin.execute(@message, @format) }.should_not raise_error(ArgumentError)
    end
    
    it 'should require a message and format' do
      lambda { @plugin.execute(@message) }.should raise_error(ArgumentError)
    end
    
    it 'should get formats from parser' do
      BotParser.expects(:formats).returns([])
      @plugin.execute(@message, @format)
    end
    
    it 'should respond with format description' do
      wanted_format = @formats[1]
      @format = wanted_format.name.to_s
      @message.expects(:reply).with("#{wanted_format.name}: #{wanted_format.description}")
      @plugin.execute(@message, @format)
    end
    
    it 'should respond with multiple lines if the format description is multiple lines' do
      @formats[1].stubs(:description).returns("I have\nmany lines\nin my\ndescription")
      wanted_format = @formats[1]
      @format = wanted_format.name.to_s
      wanted_format.description.split("\n").each do |desc_line|
        @message.expects(:reply).with("#{wanted_format.name}: #{desc_line}")
      end
      @plugin.execute(@message, @format)
    end
    
    it 'should indicate an unspecified format description' do
      @formats.each { |f|  f.stubs(:description).returns(nil) }
      wanted_format = @formats[1]
      @format = wanted_format.name.to_s
      @message.expects(:reply).with("#{wanted_format.name}: no description available")
      @plugin.execute(@message, @format)
    end
    
    it 'should indicate an unknown format' do
      wanted_format = 'turdnugget'
      @format = wanted_format
      @message.expects(:reply).with("Format '#{wanted_format}' unknown")
      @plugin.execute(@message, @format)
    end
  end
end
