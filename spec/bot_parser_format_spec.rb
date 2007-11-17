require File.dirname(__FILE__) + '/spec_helper'
require 'bot_parser_format'

describe BotParserFormat, 'when initializing' do
  should 'require a name' do
    lambda { BotParserFormat.new }.should raise_error(ArgumentError)
  end
  
  should 'require a block' do
    lambda { BotParserFormat.new(:format_name) }.should raise_error(ArgumentError)
  end
  
  should 'accept a name and block' do
    lambda { BotParserFormat.new(:format_name) {} }.should_not raise_error
  end
  
  should 'store the name' do
    format = BotParserFormat.new(:format_name) {}
    format.name.should == :format_name
  end
  
  should 'store the block' do
    block = lambda {}
    format = BotParserFormat.new(:format_name, &block)
    format.block.should == block
  end
end
