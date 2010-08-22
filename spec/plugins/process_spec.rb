require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot'
require 'bot_plugin'
require 'plugins/process'

class BotSender::Blah < BotSender; end
class BotSender
  @@kinds[:blah] = BotSender::Blah
end

describe BotPlugin::Process do
  before :each do
    @bot = Bot.new
    @config = { 'server' => 'some.server.irc', 'nick' => 'botnick', 'realname' => 'botname', 'channels' => %w[one two], 'address_required_channels' => [] }
    @bot.instance_variable_set('@config', @config)
    @bot.init_bot
    @bot.bot.logger = Cinch::Logger::NullLogger.new
    @plugin = BotPlugin::Process.new(@bot.bot)
  end
  
  it 'should be a cinch plugin' do
    BotPlugin::Process.included_modules.should include(Cinch::Plugin)
  end
  
  it 'should listen to channel messages' do
    listener = BotPlugin::Process.instance_variable_get('@__cinch_listeners').first
    listener.event.should == :channel
    listener.method.should == :listen
  end
  
  it 'should have no patterns to match' do
    pending "There's really no way to turn this off, but the default execute does nothing."
    BotPlugin::Process.instance_variable_get('@__cinch_patterns').should be_nil
  end
  
  describe 'listening to a channel message' do
    before :each do
      @message = Struct.new(:nick, :channel, :text).new('somenick', 'somechannel', 'sometext')
      @message.stubs(:reply)
      
      @parsed = 'some parsed stuff'
      @parser = BotParser.new
      @parser.stubs(:parse).returns(@parsed)
      @bot.stubs(:parser).returns(@parser)
      
      @filtered = 'some filtered stuff'
      @filter = BotFilter.new
      @filter.stubs(:process).returns(@filtered)
      @bot.stubs(:filter).returns(@filter)
      
      @delivered = 'some delivered stuff'
      @sender = BotSender.new({ :destination => :blah })
      @sender.stubs(:deliver).returns(@delivered)
      @bot.stubs(:sender).returns(@sender)
    end
    
    it 'should accept a message' do
      lambda { @plugin.listen(@message) }.should_not raise_error(ArgumentError)
    end
    
    it 'should require a message' do
      lambda { @plugin.listen }.should raise_error(ArgumentError)
    end
    
    it 'should access the parser' do
      @bot.expects(:parser).returns(@parser)
      @plugin.listen(@message)
    end
    
    it 'should parse the message, passing the message nick, channel, and text' do
      @parser.expects(:parse).with(@message.nick, @message.channel, @message.text)
      @plugin.listen(@message)
    end
    
    it 'should access the filter' do
      @bot.expects(:filter).returns(@filter)
      @plugin.listen(@message)
    end
    
    it 'should pass the result from the parser to the filter for processing' do
      @filter.expects(:process).with(@parsed)
      @plugin.listen(@message)
    end
    
    it 'should not filter if the parser returns nil' do
      @parser.stubs(:parse).returns(nil)
      @filter.expects(:process).never
      @plugin.listen(@message)
    end
    
    it 'should access the sender' do
      @bot.expects(:sender).returns(@sender)
      @plugin.listen(@message)
    end
    
    it 'should deliver the result from the filter' do
      @sender.expects(:deliver).with(@filtered)
      @plugin.listen(@message)
    end
    
    it 'should reply with the sender delivery message' do
      @message.expects(:reply).with(@delivered)
      @plugin.listen(@message)
    end
    
    it 'should not deliver if the filter returns nil' do
      @filter.stubs(:process).returns(nil)
      @sender.expects(:deliver).never
      @plugin.listen(@message)
    end
    
    it 'should not deliver if the parser returns nil' do
      @parser.stubs(:parse).returns(nil)
      @sender.expects(:deliver).never
      @plugin.listen(@message)
    end
    
    it 'should not reply if the filter returns nil' do
      @filter.stubs(:process).returns(nil)
      @message.expects(:reply).never
      @plugin.listen(@message)
    end
    
    it 'should not reply if the parser returns nil' do
      @parser.stubs(:parse).returns(nil)
      @message.expects(:reply).never
      @plugin.listen(@message)
    end
    
    describe 'when the channel is set to require addressing' do
      before :each do
        @config['address_required_channels'] = %w[#blahchat #barchat #foochat #bazchat]
        @message.channel = '#foochat'
        
        @nick = 'RO-BOT'
        @bot.bot.stubs(:nick).returns(@nick)
      end

      it "should ignore any message that does not start with the bot's nick" do
        @parser.expects(:parse).never
        @plugin.listen(@message)
      end

      it "should parse any message starting with the bot's nick" do
        @parser.expects(:parse)
        @message.text[0,0] = "#{@nick}: "
        @plugin.listen(@message)
      end

      it "should strip the bot's nick from the message before passing it on to the parser" do
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}: "
        @plugin.listen(@message)
      end

      it 'should handle extra whitespace when addressing the bot' do
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}    :     "
        @plugin.listen(@message)
      end

      it 'should handle minimal whitespace when addressing the bot' do
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}:"
        @plugin.listen(@message)
      end

      it 'should handle a bot nick with special characters' do
        @nick = 'RO^|B07'
        @bot.bot.stubs(:nick).returns(@nick)
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}: "
        @plugin.listen(@message)
      end
    end
  end
end
