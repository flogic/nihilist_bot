require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))

require 'new_bot'

describe NewBot do
  before :each do
    @bot = NewBot.new
  end
  
  it 'should be able to set itself up' do
    @bot.should respond_to(:setup)
  end
  
  describe 'setting itself up' do
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
  end
  
  it 'should be able to load its config' do
    @bot.should respond_to(:load_config)
  end
  
  describe 'when loading its config' do
    before :each do
      @config_data = { 'server' => 'some.irc.server', 'nick' => 'my_nick', 'realname' => 'heyo', 'channels' => %w[#one #two], 'address_required_channels' => [] }
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
      it 'should use the config name as the config realname if no realname is given' do
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
      @config = { 'server' => 'some.server.irc', 'nick' => 'botnick', 'realname' => 'botname', 'channels' => %w[one two] }
      @bot.instance_variable_set('@config', @config)
      @bot.init_bot
      @listener = @bot.bot.listeners[:privmsg].first
      @message = Struct.new(:nick, :channel, :text).new('somenick', 'somechannel', 'sometext')
      
      @parsed = 'some parsed stuff'
      @parser = BotParser.new
      @parser.stubs(:parse).returns(@parsed)
      @bot.stubs(:parser).returns(@parser)
      
      @filtered = 'some filtered stuff'
      @filter = BotFilter.new
      @filter.stubs(:process).returns(@filtered)
      @bot.stubs(:filter).returns(@filter)
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
  end
end
