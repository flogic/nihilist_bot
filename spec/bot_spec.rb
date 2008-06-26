require File.dirname(__FILE__) + '/spec_helper'

class AutumnLeaf
  def foo_command(*args)
  end
end

require File.dirname(__FILE__) + '/../leaves/bot'

describe Bot do
  before(:each) do
    @mock_parser = stub('parser')
    @mock_sender = stub('sender')
    @mock_filter = stub('filter')
    @mock_result = {}
    @bot = Bot.new
    @bot.stubs(:address_required_channels).returns([])
    @bot.stubs(:sender_configuration).returns({})
    @bot.stubs(:parser).returns(@mock_parser)
    @bot.stubs(:sender).returns(@mock_sender)
    @bot.stubs(:filter).returns(@mock_filter)
  end
  
  it "should pass channel messages to a parser for identification" do
    @mock_parser.expects(:parse)
    @mock_filter.stubs(:process)
    @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
  end
  
  it "should pass poster to the parser" do
    @mock_sender.stubs(:deliver)
    @mock_filter.stubs(:process)
    @mock_parser.expects(:parse).with('bob', 'foochat', "you winnin', homey?").returns(@mock_result)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")    
  end
  
  describe 'when the channel is set to require addressing' do
    before :each do
      @bot.stubs(:address_required_channels).returns(%w[blahchat barchat foochat bazchat])
      @name = 'RO-BOT'
      @bot.stubs(:name).returns(@name)
    end
    
    it "should ignore any message that does not start with the bot's name" do
      @mock_parser.expects(:parse).never
      @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
    end
    
    it "should parse any message starting with the bot's name" do
      @mock_parser.expects(:parse)
      @bot.did_receive_channel_message('bob', 'foochat', "#{@name}: what's up, bitches???")
    end
    
    it "should strip the bot's name from the message before passing it on to the parser" do
      @mock_parser.expects(:parse).with('bob', 'foochat', "what's up, bitches???")
      @bot.did_receive_channel_message('bob', 'foochat', "#{@name}: what's up, bitches???")
    end
    
    it 'should handle extra whitespace when addressing the bot' do
      @mock_parser.expects(:parse).with('bob', 'foochat', "what's up, bitches???")
      @bot.did_receive_channel_message('bob', 'foochat', "#{@name}    :     what's up, bitches???")
    end
    
    it 'should handle minimal whitespace when addressing the bot' do
      @mock_parser.expects(:parse).with('bob', 'foochat', "what's up, bitches???")
      @bot.did_receive_channel_message('bob', 'foochat', "#{@name}:what's up, bitches???")
    end
  end
  
  it "should pass data to filter when parser provides results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_filter.expects(:process).with(@mock_result)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")
  end
  
  it "should not use filter when parser provides no results" do
    @mock_parser.stubs(:parse).returns(nil)
    @mock_filter.expects(:process).never
    @bot.did_receive_channel_message('bob', 'foochat', "where my witches be?")    
  end

  it "should pass data to sender when filter provides results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_filter.stubs(:process).returns(@mock_result)
    @mock_sender.expects(:deliver)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")
  end
  
  it "should not use sender when filter provides no results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_filter.stubs(:process).returns(nil)
    @mock_sender.expects(:deliver).never
    @bot.did_receive_channel_message('bob', 'foochat', "where my witches be?")    
  end  
  
  it "should send message back to channel if sender has response" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.stubs(:deliver).returns(@mock_result)
    @mock_filter.stubs(:process).returns(@mock_result)
    @bot.expects(:respond)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")        
  end
  
  it "should send a message to the channel when responding with real text" do
    @bot.expects(:message).with("foo", "channel")
    @bot.respond("foo", "channel")
  end
  
  it "should not respond to !foo commands" do
    @bot.should_not respond_to(:foo_command)
  end
  
  it 'should respond to !help' do
    @bot.should respond_to(:help_command)
  end
  
  it "should should not send a message to the channel when responding with an empty message" do
    @bot.expects(:message).never
    @bot.respond(nil, "channel")
  end
  
  it "should look up options for sender" do
    @bot.expects(:sender_configuration)
    BotSender.stubs(:new)
    @bot.did_start_up
  end
  
  it "should pass sender config to sender" do
    config = stub('config')
    @bot.stubs(:sender_configuration).returns(config)
    BotSender.expects(:new).with(config)
    @bot.did_start_up
  end
  
  it 'should pass options to filter' do
    options = stub('options')
    @bot.stubs(:options).returns(options)
    BotFilter.expects(:new).with(options)
    BotSender.stubs(:new)
    @bot.did_start_up
  end
end

describe Bot, 'giving the sender configuration' do
  before(:each) do
    @bot = Bot.new
  end
  
  it "should fail unless an active sender is known" do
    @bot.stubs(:options).returns({})
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)
  end
  
  it "should fail unless a set of senders is known" do
    @bot.stubs(:options).returns({ :active_sender => 'foo' })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)
  end
  
  it "should fail unless the specified active sender is known" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { } })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)    
  end
  
  it "should fail unless the active sender has a destination type" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { 'foo' => { } } })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)        
  end
  
  it "should succeed when options are fully specified" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { 'foo' => { 'destination' => 'bar' } } })
    Proc.new { @bot.sender_configuration }.should_not raise_error(RuntimeError)            
  end
  
  it "should ensure that sender options are in a format usable by the sender" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { 'foo' => { 'destination' => 'bar', 'option' => 'baz', 'turd' => 'nugget' } } })
    result = @bot.sender_configuration
    result[:destination].should == :bar
    result[:option].should == 'baz'
    result[:turd].should == 'nugget'
  end
end

describe Bot, 'getting the address-required channels' do
  before :each do
    @bot = Bot.new
  end
  
  it 'should return the channels marked as requiring addressing in the configuration' do
    @bot.stubs(:options).returns({ :address_required_channels => %w[4chan 2chan redchan bluechan] })
    @bot.address_required_channels.should == %w[4chan 2chan redchan bluechan]
  end
  
  it 'should return an empty array if the configuration has no channels requiring addressing' do
    @bot.stubs(:options).returns({})
    @bot.address_required_channels.should == []
  end
end

describe Bot, '!help command' do
  before :each do
    @bot = Bot.new
  end
  
  it 'should require sender' do
    lambda { @bot.help_command }.should raise_error(ArgumentError)
  end
  
  it 'should require channel' do
    lambda { @bot.help_command('sender') }.should raise_error(ArgumentError)
  end
  
  it 'should require format' do
    lambda { @bot.help_command('sender', 'channel') }.should raise_error(ArgumentError)
  end
  
  it 'should accept sender, channel, and format' do
    lambda { @bot.help_command('sender', 'channel', 'format') }.should_not raise_error(ArgumentError)
  end
  
  it 'should get formats from parser' do
    BotParser.expects(:formats).returns([])
    @bot.stubs(:respond)
    @bot.help_command('sender', 'channel', 'format')
  end
  
  it 'should respond with format list if no format specified' do
    formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym) }
    BotParser.stubs(:formats).returns(formats)
    @bot.expects(:respond).with("Known formats: #{formats.collect { |f|  f.name }.join(', ')}", 'channel')
    @bot.help_command('sender', 'channel', nil)
  end
  
  it 'should respond with format list if empty format specified' do
    formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym) }
    BotParser.stubs(:formats).returns(formats)
    @bot.expects(:respond).with("Known formats: #{formats.collect { |f|  f.name }.join(', ')}", 'channel')
    @bot.help_command('sender', 'channel', '')
  end
  
  it 'should respond with format description if format specified' do
    formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => "Description for format #{i}") }
    BotParser.stubs(:formats).returns(formats)
    wanted_format = formats[1]
    @bot.expects(:respond).with("#{wanted_format.name}: #{wanted_format.description}", 'channel')
    @bot.help_command('sender', 'channel', wanted_format.name.to_s)
  end
  
  it 'should indicate an unspecified format description' do
    formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => nil) }
    BotParser.stubs(:formats).returns(formats)
    wanted_format = formats[1]
    @bot.expects(:respond).with("#{wanted_format.name}: no description available", 'channel')
    @bot.help_command('sender', 'channel', wanted_format.name.to_s)
  end
  
  it 'should indicate an unknown format' do
    formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => "Description for format #{i}") }
    BotParser.stubs(:formats).returns(formats)
    wanted_format = 'turdnugget'
    @bot.expects(:respond).with("Format '#{wanted_format}' unknown", 'channel')
    @bot.help_command('sender', 'channel', wanted_format)
  end
end
