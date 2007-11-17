require File.dirname(__FILE__) + '/spec_helper'
require 'bot_parser_format'

describe BotParserFormat, 'when initializing' do
  should 'require a name' do
    lambda { BotParserFormat.new }.should raise_error(ArgumentError)
  end
  
  should 'require a format' do
    lambda { BotParserFormat.new(:format_name) }.should raise_error(ArgumentError)
  end
  
  should 'require a block' do
    lambda { BotParserFormat.new(:format_name, /format/) }.should raise_error(ArgumentError)
  end
  
  should 'accept a name, format, and block' do
    lambda { BotParserFormat.new(:format_name, /format/) {} }.should_not raise_error(ArgumentError)
  end
  
  should 'store the name' do
    format = BotParserFormat.new(:format_name, /format/) {}
    format.name.should == :format_name
  end
  
  should 'store the format' do
    format = BotParserFormat.new(:format_name, /format/) {}
    format.format.should == /format/
  end
  
  should 'store the block' do
    block = lambda {}
    format = BotParserFormat.new(:format_name, /format/, &block)
    format.block.should == block
  end
end

describe BotParserFormat, 'when processing' do
  before(:each) do
    @re = /format/
    @block = lambda {}
    @format = BotParserFormat.new(:format_name, @re, &@block)
  end
  
  should 'require text' do
    lambda { @format.process }.should raise_error(ArgumentError)
  end
  
  should 'accept text' do
    lambda { @format.process('hey hey hey') }.should_not raise_error(ArgumentError)
  end
  
  should 'return nil if given text does not match format' do
    @format.process('hey hey hey').should be_nil
  end
  
  should 'call block with text and match data if text matches format' do
    text = 'this should match the format'
    md = stub('match data')
    @re.stubs(:match).returns(md)
    @block.expects(:call).with(text, md).returns({})
    @format.process(text)
  end
  
  should 'return the (hash) result of the block with :type => name pair added if text matches format' do
    @re.stubs(:match).returns(true)
    @result = { :hi => 'there', :turd => 'nugget', :type => 'greeting' }
    @block.stubs(:call).returns(@result)
    @format.process('hey hey hey').should == @result.merge(:type => :format_name)
  end
end
