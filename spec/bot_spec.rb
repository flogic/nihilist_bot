require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))

require 'bot'

class BotSender::Blah < BotSender; end
class BotSender
  @@kinds[:blah] = BotSender::Blah
end

describe Bot do
  before :each do
    @bot = Bot.new
  end
  
  it 'should be able to prepare itself' do
    @bot.should respond_to(:prepare)
  end
  
  describe 'preparing itself' do
    before :each do
      @bot.stubs(:load_config)
      @bot.stubs(:setup)
      @bot.stubs(:init_bot)
    end
    
    it 'should load its config' do
      @bot.expects(:load_config)
      @bot.prepare
    end
    
    it 'should set itself up' do
      @bot.expects(:setup)
      @bot.prepare
    end
    
    it 'should initialize the bot' do
      @bot.expects(:init_bot)
      @bot.prepare
    end
  end
  
  it 'should be able to set itself up' do
    @bot.should respond_to(:setup)
  end
  
  describe 'setting itself up' do
    before :each do
      @sender_configuration = { :destination => :blah }
      @bot.stubs(:sender_configuration).returns(@sender_configuration)
    end
    
    it 'should store a parser' do
      @bot.setup
      @bot.parser.should be_kind_of(BotParser)
    end
    
    it 'should store a filter' do
      @bot.setup
      @bot.filter.should be_kind_of(BotFilter)
    end
    
    it 'should pass the config when creating the filter' do
      @config = { 'server' => 'some.server.irc', 'nick' => 'botnick', 'realname' => 'botname', 'channels' => %w[one two] }
      @bot.instance_variable_set('@config', @config)
      BotFilter.expects(:new).with(@config)
      @bot.setup
    end
    
    it 'should store a sender' do
      @bot.setup
      @bot.sender.should be_kind_of(BotSender)
    end
    
    it 'should use the sender configuration when creating the sender' do
      BotSender.expects(:new).with(@sender_configuration)
      @bot.setup
    end
  end
  
  it 'should get a sender configuration' do
    @bot.should respond_to(:sender_configuration)
  end
  
  describe 'getting sender configuration' do
    it 'should fail unless an active sender is known' do
      @config = {}
      @bot.instance_variable_set('@config', @config)
      lambda { @bot.sender_configuration }.should raise_error
    end

    it 'should fail unless a set of senders is known' do
      @config = { 'active_sender' => 'foo' }
      @bot.instance_variable_set('@config', @config)
      lambda { @bot.sender_configuration }.should raise_error
    end

    it 'should fail unless the specified active sender is known' do
      @config = { 'active_sender' => 'foo', 'senders' => { } }
      @bot.instance_variable_set('@config', @config)
      lambda { @bot.sender_configuration }.should raise_error
    end

    it 'should fail unless the active sender has a destination type' do
      @config = { 'active_sender' => 'foo', 'senders' => { 'foo' => { } } }
      @bot.instance_variable_set('@config', @config)
      lambda { @bot.sender_configuration }.should raise_error
    end

    it 'should succeed when options are fully specified' do
      @config = { 'active_sender' => 'foo', 'senders' => { 'foo' => { 'destination' => 'bar' } }  }
      @bot.instance_variable_set('@config', @config)
      lambda { @bot.sender_configuration }.should_not raise_error
    end

    it 'should ensure that sender options are in a format usable by the sender' do
      @config = { 'active_sender' => 'foo', 'senders' => { 'foo' => { 'destination' => 'bar', 'option' => 'baz', 'turd' => 'nugget' } } }
      @bot.instance_variable_set('@config', @config)
      result = @bot.sender_configuration
      result[:destination].should == :bar
      result[:option].should == 'baz'
      result[:turd].should == 'nugget'
    end
  end
  
  it 'should be able to load its config' do
    @bot.should respond_to(:load_config)
  end
  
  describe 'when loading its config' do
    before :each do
      @config_data = { 'server' => 'some.irc.server', 'nick' => 'my_nick', 'realname' => 'heyo', 'username' => 'user', 'channels' => %w[#one #two], 'address_required_channels' => [] }
      @config_contents = @config_data.to_yaml
      File.stubs(:read).returns(@config_contents)
    end
    
    it 'should read the config file' do
      File.expects(:read).with('./config/config.yml').returns(@config_contents)
      @bot.load_config
    end
    
    it 'should parse the config file as YAML data' do
      YAML.expects(:load).with(@config_contents).returns({})
      @bot.load_config
    end
    
    it 'should store the config for retrieval' do
      @bot.load_config
      @bot.config.should == @config_data
    end
    
    describe 'normalizing the config data' do
      it 'should use the config nick as the config realname if no realname is given' do
        @config_data.delete('realname')
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['realname'].should == @bot.config['nick']
      end
      
      it 'should use the config realname if given' do
        realname = 'some real name'
        @config_data['realname'] = realname
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['realname'].should == realname
      end
      
      it 'should use the config nick as the config username if no username is given' do
        @config_data.delete('username')
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['username'].should == @bot.config['nick']
      end
      
      it 'should use the config username if given' do
        username = 'someuser'
        @config_data['username'] = username
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['username'].should == username
      end
      
      it 'should ensure the channels in the config file are normalized to always start with a #' do
        @config_data['channels'] = ['#blah', 'something withakey', 'somethingelse', '#another alsokeyed']
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['channels'].should == ['#blah', '#something withakey', '#somethingelse', '#another alsokeyed']
      end
      
      it 'should not error if the config file contains no channels' do
        @config_data.delete('channels')
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['channels'].should == []
      end
      
      it 'should ensure the address-required channels in the config file are normalized to always start with a #' do
        @config_data['address_required_channels'] = ['#feh', 'bling withakey', 'blort', '#crap alsokeyed']
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['address_required_channels'].should == ['#feh', '#bling withakey', '#blort', '#crap alsokeyed']
      end
      
      it 'should not error if the config file contains no address-required channels' do
        @config_data.delete('address_required_channels')
        @config_contents = @config_data.to_yaml
        File.stubs(:read).returns(@config_contents)
        
        @bot.load_config
        @bot.config['address_required_channels'].should == []
      end
    end
  end
  
  it 'should be able to initialize the bot' do
    @bot.should respond_to(:init_bot)
  end
  
  describe 'initializing the bot' do
    before :each do
      @config = { 'server' => 'some.server.irc', 'nick' => 'botnick', 'realname' => 'botname', 'channels' => %w[one two] }
      @bot.instance_variable_set('@config', @config)
    end
    
    it 'should store the bot for retrieval' do
      @bot.init_bot
      @bot.bot.should be_kind_of(Cinch::Base)
    end
    
    it 'should set the server from the config' do
      @bot.init_bot
      @bot.bot.options.server.should == @config['server']
    end
    
    it 'should set the nick from the config' do
      @bot.init_bot
      @bot.bot.options.nick.should == @config['nick']
    end
    
    it 'should set the realname from the config' do
      @bot.init_bot
      @bot.bot.options.realname.should == @config['realname']
    end
    
    it 'should set the channels from the config' do
      @bot.init_bot
      @bot.bot.options.channels.should == @config['channels']
    end
    
    it 'should set up a privmsg listener' do
      @bot.init_bot
      @bot.bot.listeners[:privmsg].should_not be_nil
    end
  end
  
  describe 'privmsg listener' do
    before :each do
      @config = { 'server' => 'some.server.irc', 'nick' => 'botnick', 'realname' => 'botname', 'channels' => %w[one two], 'address_required_channels' => [] }
      @bot.instance_variable_set('@config', @config)
      @bot.init_bot
      @listener = @bot.bot.listeners[:privmsg].first
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
    
    it 'should be callable' do
      @listener.should respond_to(:call)
    end
    
    it 'should access the parser' do
      @bot.expects(:parser).returns(@parser)
      @listener.call(@message)
    end
    
    it 'should parse the message, passing the message nick, channel, and text' do
      @parser.expects(:parse).with(@message.nick, @message.channel, @message.text)
      @listener.call(@message)
    end
    
    it 'should access the filter' do
      @bot.expects(:filter).returns(@filter)
      @listener.call(@message)
    end
    
    it 'should pass the result from the parser to the filter for processing' do
      @filter.expects(:process).with(@parsed)
      @listener.call(@message)
    end
    
    it 'should not filter if the parser returns nil' do
      @parser.stubs(:parse).returns(nil)
      @filter.expects(:process).never
      @listener.call(@message)
    end
    
    it 'should access the sender' do
      @bot.expects(:sender).returns(@sender)
      @listener.call(@message)
    end
    
    it 'should deliver the result from the filter' do
      @sender.expects(:deliver).with(@filtered)
      @listener.call(@message)
    end
    
    it 'should reply with the sender delivery message' do
      @message.expects(:reply).with(@delivered)
      @listener.call(@message)
    end
    
    it 'should not deliver if the filter returns nil' do
      @filter.stubs(:process).returns(nil)
      @sender.expects(:deliver).never
      @listener.call(@message)
    end
    
    it 'should not deliver if the parser returns nil' do
      @parser.stubs(:parse).returns(nil)
      @sender.expects(:deliver).never
      @listener.call(@message)
    end
    
    it 'should not reply if the filter returns nil' do
      @filter.stubs(:process).returns(nil)
      @message.expects(:reply).never
      @listener.call(@message)
    end
    
    it 'should not reply if the parser returns nil' do
      @parser.stubs(:parse).returns(nil)
      @message.expects(:reply).never
      @listener.call(@message)
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
        @listener.call(@message)
      end

      it "should parse any message starting with the bot's nick" do
        @parser.expects(:parse)
        @message.text[0,0] = "#{@nick}: "
        @listener.call(@message)
      end

      it "should strip the bot's nick from the message before passing it on to the parser" do
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}: "
        @listener.call(@message)
      end

      it 'should handle extra whitespace when addressing the bot' do
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}    :     "
        @listener.call(@message)
      end

      it 'should handle minimal whitespace when addressing the bot' do
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}:"
        @listener.call(@message)
      end

      it 'should handle a bot nick with special characters' do
        @nick = 'RO^|B07'
        @bot.bot.stubs(:nick).returns(@nick)
        @parser.expects(:parse).with(@message.nick, @message.channel, @message.text.dup)
        @message.text[0,0] = "#{@nick}: "
        @listener.call(@message)
      end
    end
  end

  it 'should be able to start the bot' do
    @bot.should respond_to(:start)
  end
  
  describe 'starting the bot' do
    before :each do
      @actual_bot = Cinch::Base.new
      @actual_bot.stubs(:run)
      @bot.stubs(:bot).returns(@actual_bot)
    end
    
    it 'should tell the stored bot to run' do
      @actual_bot.expects(:run)
      @bot.start
    end
  end
end
