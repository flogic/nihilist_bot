require File.dirname(__FILE__) + '/spec_helper'
require 'bot_sender'

describe BotSender, "as a class" do
  it "should provide a way to get the list of known destination types" do
    BotSender.kinds.should respond_to(:first)
  end
  
  it "should provide a way to register a new sender type" do
    mock_class = mock('BotSender subclass')
    BotSender.register(:good => mock_class)
    BotSender.kinds.should include(:good)
  end
end

describe BotSender, "when initializing" do
  it "should require specifying destination configuration options" do
    Proc.new { BotSender.new }.should raise_error(ArgumentError)
  end
  
  it "should fail if the destination type is unknown" do
    Proc.new { BotSender.new(:destination => :bullshit) }.should raise_error(ArgumentError)
  end
  
  it "should provide a Sender which can contact the specified destination" do
    BotSender.register(:good => Class.new(BotSender))
    BotSender.expects(:kinds).returns([:good])
    BotSender.new(:destination => :good).should respond_to(:deliver)
  end
end

describe BotSender, "in general" do
  it "should provide a means of determining what type of sender it is" do
    BotSender.expects(:kinds).returns([:good])
    @sender = BotSender.new(:destination => :good)
    @sender.kind.should == :good
  end
end

describe BotSender, "when delivering a message" do
  before(:each) do
    BotSender.register(:good => Class.new(BotSender))
    @sender = BotSender.new(:destination => :good)
  end
  
  it "should fail when attempting to send an empty message" do
    @sender.deliver(nil).should be_nil
  end
  
  it "should create a new message on the destination site when given a valid message" do
    @sender.expects(:do_quote)
    @sender.deliver(:type => :quote)
  end
  
  it "should fail when trying to send an unknown message type" do
    Proc.new {@sender.deliver(:type => :unknown)}.should raise_error(ArgumentError)
  end
  
  it "should respond gracefully when destination post fails" do
    @sender.stubs(:do_quote).raises(RuntimeError, "blew up horrendously")
    Proc.new { @sender.deliver(:type => :quote) }.should_not raise_error
  end

  it "should include a reason for failure in response when destination post fails" do
    @sender.stubs(:do_quote).raises(RuntimeError, "blew up horrendously")
    @sender.deliver(:type => :quote).should match(/blew up horrendously/)
  end
  
  it "should respond with a success response when destination post succeeds" do
    @sender.stubs(:do_quote).returns("good show")
    @sender.deliver(:type => :quote).should match(/good show/)
  end
end