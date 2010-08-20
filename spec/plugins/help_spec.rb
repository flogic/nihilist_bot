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
  
  it 'should not listen indiscriminately' do
    BotPlugin::Help.instance_variable_get('@__cinch_listeners').should be_nil
  end
  
  it "should trigger execution on '!help [some format]' and keep the format name" do
    pattern = BotPlugin::Help.instance_variable_get('@__cinch_patterns').first
    format_name = 'crazy_format'
    pattern.pattern.match("!help #{format_name}")[1].should == format_name
    pattern.method.should == :execute
  end
  
  it "should trigger execution on '!help' and indicate no format name" do
    pattern = BotPlugin::Help.instance_variable_get('@__cinch_patterns').first
    pattern.pattern.match("!help")[1].should be_nil
    pattern.method.should == :execute
  end
  
  describe 'executing a match' do
    before :each do
      @message = Struct.new(:nick, :channel, :text).new('somenick', 'somechannel', 'sometext')
      @message.stubs(:reply)
      
      @formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => "Description for format #{i}") }
      BotParser.stubs(:formats).returns(@formats)
    end
    
    it 'should accept a message and format' do
      lambda { @plugin.execute(@message, 'some_format') }.should_not raise_error(ArgumentError)
    end
    
    it 'should require a message and format' do
      lambda { @plugin.execute(@message) }.should raise_error(ArgumentError)
    end
    
    describe 'when format is nil' do
      before :each do
        @format = nil
      end
      
      it 'should get formats from parser' do
        BotParser.expects(:formats).returns([])
        @plugin.execute(@message, @format)
      end

      it 'should respond with a list of formats' do
        @message.expects(:reply).with("Known formats: #{@formats.collect { |f|  f.name }.join(', ')}")
        @plugin.execute(@message, @format)
      end
    end
    
    describe 'when format is not nil' do
      before :each do
        @format = 'link'
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
end
