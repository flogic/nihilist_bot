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
    BotParser.stubs(:new).returns(@mock_parser)
    BotSender.stubs(:new).returns(@mock_sender)
    BotFilter.stubs(:new).returns(@mock_filter)
    @bot = Bot.new
    @bot.stubs(:sender_configuration).returns({})
  end
  
  should "pass channel messages to a parser for identification" do
    @mock_parser.expects(:parse)
    @mock_filter.stubs(:process)
    @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
  end
  
  should "pass poster to the parser" do
    @mock_sender.stubs(:deliver)
    @mock_filter.stubs(:process)
    @mock_parser.expects(:parse).with('bob', 'foochat', "you winnin', homey?").returns(@mock_result)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")    
  end
  
  should "pass data to filter when parser provides results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_filter.expects(:process).with(@mock_result)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")
  end
  
  should "not use filter when parser provides no results" do
    @mock_parser.stubs(:parse).returns(nil)
    @mock_filter.expects(:process).never
    @bot.did_receive_channel_message('bob', 'foochat', "where my witches be?")    
  end

  should "pass data to sender when filter provides results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_filter.stubs(:process).returns(@mock_result)
    @mock_sender.expects(:deliver)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")
  end
  
  should "not use sender when filter provides no results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_filter.stubs(:process).returns(nil)
    @mock_sender.expects(:deliver).never
    @bot.did_receive_channel_message('bob', 'foochat', "where my witches be?")    
  end  
  
  should "send message back to channel if sender has response" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.stubs(:deliver).returns(@mock_result)
    @mock_filter.stubs(:process).returns(@mock_result)
    @bot.expects(:respond)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")        
  end
  
  should "send a message to the channel when responding with real text" do
    @bot.expects(:message).with("foo", "channel")
    @bot.respond("foo", "channel")
  end
  
  should "not respond to !foo commands" do
    @bot.should_not respond_to(:foo_command)
  end
  
  should 'respond to !help' do
    @bot.should respond_to(:help_command)
  end
  
  should "should not send a message to the channel when responding with an empty message" do
    @bot.expects(:message).never
    @bot.respond(nil, "channel")
  end
  
  should "look up options for sender" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.stubs(:deliver).returns(@mock_result)
    @mock_filter.stubs(:process).returns(@mock_result)
    @bot.stubs(:respond).returns(@mock_result)
    @bot.expects(:sender_configuration)
    @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
  end
  
  should 'pass options to filter' do
    options = stub('options')
    @bot.stubs(:options).returns(options)
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.stubs(:deliver).returns(@mock_result)
    BotFilter.expects(:new).with(options).returns(@mock_filter)
    @mock_filter.stubs(:process).returns(@mock_result)
    @bot.stubs(:respond).returns(@mock_result)
    @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
  end
end

describe Bot, 'giving the sender configuration' do
  before(:each) do
    @bot = Bot.new
  end
  
  should "fail unless an active sender is known" do
    @bot.stubs(:options).returns({})
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)
  end
  
  should "fail unless a set of senders is known" do
    @bot.stubs(:options).returns({ :active_sender => 'foo' })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)
  end
  
  should "fail unless the specified active sender is known" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { } })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)    
  end
  
  should "fail unless the active sender has a destination type" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { 'foo' => { } } })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)        
  end
  
  should "succeed when options are fully specified" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { 'foo' => { 'destination' => 'bar' } } })
    Proc.new { @bot.sender_configuration }.should_not raise_error(RuntimeError)            
  end
  
  should "ensure that sender options are in a format usable by the sender" do
    @bot.stubs(:options).returns({ :active_sender => 'foo', :senders => { 'foo' => { 'destination' => 'bar', 'option' => 'baz', 'turd' => 'nugget' } } })
    result = @bot.sender_configuration
    result[:destination].should == :bar
    result[:option].should == 'baz'
    result[:turd].should == 'nugget'
  end
end

describe Bot, '!help command' do
  before :each do
    @bot = Bot.new
  end
  
  should 'require sender' do
    lambda { @bot.help_command }.should raise_error(ArgumentError)
  end
  
  should 'require channel' do
    lambda { @bot.help_command('sender') }.should raise_error(ArgumentError)
  end
  
  should 'require text' do
    lambda { @bot.help_command('sender', 'channel') }.should raise_error(ArgumentError)
  end
  
  should 'accept sender, channel, and text' do
    lambda { @bot.help_command('sender', 'channel', 'text') }.should_not raise_error(ArgumentError)
  end
  
  should 'get formats from parser' do
    BotParser.expects(:formats).returns([])
    @bot.help_command('sender', 'channel', 'text')
  end
  
  should 'respond with format descriptions' do
    formats = Array.new(3) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => "This explains format #{i}") }
    BotParser.stubs(:formats).returns(formats)
    formats.each { |f|  @bot.expects(:respond).with("#{f.name}: #{f.description}", 'channel') }
    @bot.help_command('sender', 'channel', 'text')
  end
  
  should 'indicate missing descriptions' do
    formats = Array.new(1) { |i|  stub("format #{i}", :name => "format_#{i}".to_sym, :description => nil) }
    BotParser.stubs(:formats).returns(formats)
    formats.each { |f|  @bot.expects(:respond).with("#{f.name}: no description available", 'channel') }
    @bot.help_command('sender', 'channel', 'text')
  end
end
