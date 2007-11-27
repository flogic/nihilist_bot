require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/template'

describe BotFilter::Template do
  before :each do
    @filter = BotFilter::Template.new
  end
  
  should 'accept options on initialization' do
    lambda { BotFilter::Template.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  should 'not require options on initialization' do
    lambda { BotFilter::Template.new }.should_not raise_error(ArgumentError)
  end
  
  should 'store options' do
    options = stub('options')
    filter = BotFilter::Template.new(options)
    filter.options.should == options
  end
  
  should 'default options to empty hash' do
    filter = BotFilter::Template.new
    filter.options.should == {}
  end
  
  should 'require data for processing' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  should 'require a hash for processing' do
    lambda { @filter.process('puppies') }.should raise_error(TypeError)
  end
  
  should 'accept a hash for processing' do
    lambda { @filter.process({ :data => 'puppies' }) }.should_not raise_error
  end
  
  should 'return a hash' do
    @filter.process({ :data => 'puppies' }).should be_kind_of(Hash)
  end
  
  should 'return the input hash' do
    data = { :data => 'puppies' }
    @filter.process(data).should == data
  end
end
