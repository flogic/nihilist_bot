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
    @mock_result = {}
    BotParser.stubs(:new).returns(@mock_parser)
    BotSender.stubs(:new).returns(@mock_sender)
    @bot = Bot.new
    @bot.stubs(:sender_configuration).returns({})
  end
  
  should "pass channel messages to a parser for identification" do
    @mock_parser.expects(:parse)
    @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
  end
  
  should "pass poster to the parser" do
    @mock_sender.stubs(:deliver)
    @mock_parser.expects(:parse).with('bob', 'foochat', "you winnin', homey?").returns(@mock_result)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")    
  end
  
  should "pass data to sender when parser provides results" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.expects(:deliver)
    @bot.did_receive_channel_message('bob', 'foochat', "you winnin', homey?")
  end
  
  should "not use sender when parser provides no results" do
    @mock_parser.stubs(:parse).returns(nil)
    @bot.did_receive_channel_message('bob', 'foochat', "where my witches be?")    
  end
  
  should "send message back to channel if sender has response" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.stubs(:deliver).returns(@mock_result)
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
  
  should "should not send a message to the channel when responding with an empty message" do
    @bot.expects(:message).never
    @bot.respond(nil, "channel")
  end
  
  should "look up options for sender" do
    @mock_parser.stubs(:parse).returns(@mock_result)
    @mock_sender.stubs(:deliver).returns(@mock_result)
    @bot.stubs(:respond).returns(@mock_result)
    @bot.expects(:sender_configuration)
    @bot.did_receive_channel_message('bob', 'foochat', "what's up, bitches???")
  end
end

describe Bot, "" do
  before(:each) do
    @bot = Bot.new
  end
  
  should "fail unless an active sender is known" do
    @bot.stubs(:options).returns({})
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)
  end
  
  should "fail unless a set of senders is known" do
    @bot.stubs(:options).returns({ 'active_sender' => 'foo' })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)
  end
  
  should "fail unless the specified active sender is known" do
    @bot.stubs(:options).returns({ 'active_sender' => 'foo', 'senders' => { } })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)    
  end
  
  should "fail unless the active sender has a destination type" do
    @bot.stubs(:options).returns({ 'active_sender' => 'foo', 'senders' => { 'foo' => { } } })
    Proc.new { @bot.sender_configuration }.should raise_error(RuntimeError)        
  end
  
  should "succeed when options are fully specified" do
    @bot.stubs(:options).returns({ 'active_sender' => 'foo', 'senders' => { 'foo' => { 'destination' => 'bar' } } })
    Proc.new { @bot.sender_configuration }.should_not raise_error(RuntimeError)            
  end
  
  should "ensure that sender options are in a format usable by the sender" do
    @bot.stubs(:options).returns({ 'active_sender' => 'foo', 'senders' => { 'foo' => { 'destination' => 'bar', 'option' => 'baz' } } })
    result = @bot.sender_configuration
    result[:destination].should == :bar
    result[:option].should == :baz
  end
end


