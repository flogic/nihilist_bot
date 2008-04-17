require File.dirname(__FILE__) + '/spec_helper'
require 'bot_parser_format'

describe BotParserFormat, 'when initializing' do
  it 'should require a name' do
    lambda { BotParserFormat.new }.should raise_error(ArgumentError)
  end
  
  it 'should require a format' do
    lambda { BotParserFormat.new(:format_name) }.should raise_error(ArgumentError)
  end
  
  it 'should require a block' do
    lambda { BotParserFormat.new(:format_name, /format/) }.should raise_error(ArgumentError)
  end
  
  it 'should accept a name, format, and block' do
    lambda { BotParserFormat.new(:format_name, /format/) {} }.should_not raise_error(ArgumentError)
  end
  
  it 'should accept a name, format, description, and block' do
    lambda { BotParserFormat.new(:format_name, /format/, 'description') {} }.should_not raise_error(ArgumentError)
  end
  
  it 'should store the name' do
    format = BotParserFormat.new(:format_name, /format/) {}
    format.name.should == :format_name
  end
  
  it 'should store the format' do
    format = BotParserFormat.new(:format_name, /format/) {}
    format.format.should == /format/
  end
  
  it 'should store the block' do
    block = lambda {}
    format = BotParserFormat.new(:format_name, /format/, &block)
    format.block.should == block
  end
  
  it 'should store the description' do
    format = BotParserFormat.new(:format_name, /format/, 'description') {}
    format.description.should == 'description'
  end
  
  it 'should accept multiple descriptions' do
    lambda { BotParserFormat.new(:format_name, /format/, 'desc 1', 'desc 2', 'desc 3') {} }.should_not raise_error(ArgumentError)
  end
  
  it 'should return the descriptions joined with newlines' do
    format = BotParserFormat.new(:format_name, /format/, 'desc 1', 'desc 2', 'desc 3') {}
    format.description.should == "desc 1\ndesc 2\ndesc 3"
  end
  
  it 'should return nil if no description given' do
    format = BotParserFormat.new(:format_name, /format/) {}
    format.description.should be_nil
  end
end

describe BotParserFormat, 'when processing' do
  before :each do
    @re = /format/
    @block = lambda {}
    @format = BotParserFormat.new(:format_name, @re, &@block)
  end
  
  it 'should require text' do
    lambda { @format.process }.should raise_error(ArgumentError)
  end
  
  it 'should accept text' do
    lambda { @format.process('hey hey hey') }.should_not raise_error(ArgumentError)
  end
  
  it 'should return nil if given text does not match format' do
    @format.process('hey hey hey').should be_nil
  end
  
  it 'should call block with match data and text if text matches format' do
    text = 'this should match the format'
    md = stub('match data')
    @re.stubs(:match).returns(md)
    @block.expects(:call).with(md, text).returns({})
    @format.process(text)
  end
  
  it 'should return the (hash) result of the block with :type => name pair added if text matches format' do
    @re.stubs(:match).returns(true)
    @result = { :hi => 'there', :turd => 'nugget', :type => 'greeting' }
    @block.stubs(:call).returns(@result)
    @format.process('hey hey hey').should == @result.merge(:type => :format_name)
  end
end
