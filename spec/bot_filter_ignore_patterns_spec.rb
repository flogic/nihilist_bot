require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/ignore_patterns'

describe BotFilter::IgnorePatterns do
  before :each do
    @filter = BotFilter::IgnorePatterns.new
  end
  
  should 'accept options on initialization' do
    lambda { BotFilter::IgnorePatterns.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  should 'not require options on initialization' do
    lambda { BotFilter::IgnorePatterns.new }.should_not raise_error(ArgumentError)
  end
  
  should 'store options' do
    options = stub('options')
    filter = BotFilter::IgnorePatterns.new(options)
    filter.options.should == options
  end
  
  should 'default options to empty hash' do
    filter = BotFilter::IgnorePatterns.new
    filter.options.should == {}
  end
  
  should 'require data for processing' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  should 'require a hash for processing' do
    lambda { @filter.process('puppies') }.should raise_error(TypeError)
  end
  
  should 'accept a hash for processing' do
    lambda { @filter.process({ :data => 'puppies'}) }.should_not raise_error
  end
  
  should 'use the stored list of patterns' do
    BotFilter::IgnorePatterns.expects(:pattern_list).returns([])
    @filter.process({ :data => 'puppies', :type => :link })
  end
  
  should 'return the input hash if no poster given' do
    BotFilter::IgnorePatterns.stubs(:pattern_list).returns([/fred/, /thomas/])
    data = { :data => 'puppies', :type => :link }
    @filter.process(data).should == data
  end
  
  should 'return the input hash if link url does not match any of the patterns in the pattern list' do
    BotFilter::IgnorePatterns.stubs(:pattern_list).returns([/fred/, /thomas/])
    data = { :data => 'puppies', :url => 'http://www.yahoo.com/', :type => :link }
    @filter.process(data).should == data
  end
  
  should 'return the input hash if link url does not match any of the patterns in the pattern list' do
    BotFilter::IgnorePatterns.stubs(:pattern_list).returns([/fred/, /thomas/])
    data = { :data => 'puppies', :url => 'http://www.fred.com/', :type => :link }
    @filter.process(data).should be_nil
  end
  
  should 'do nothing for non-links' do
    BotFilter::IgnorePatterns.expects(:pattern_list).never
    data = {:url => @url }
    @filter.process(data).should == data
  end
end

describe BotFilter::IgnorePatterns, 'when asked about patterns to ignore' do
  should 'return a list' do
    BotFilter::IgnorePatterns.pattern_list.should respond_to(:include?)
  end
  
  should 'return the set patterns list' do
    list = [1,2,3]
    BotFilter::IgnorePatterns.pattern_list = list
    BotFilter::IgnorePatterns.pattern_list.should == list
  end
  
  should 'return an empty list if nick list is not set' do
    BotFilter::IgnorePatterns.pattern_list = nil
    BotFilter::IgnorePatterns.pattern_list.should == []
  end
end

describe BotFilter::IgnorePatterns, 'when initialized' do
  should 'set the pattern list from the given options' do
    pattern_list = stub('pattern list')
    options = { :data => 'puppies', :ignore => { 'patterns' => pattern_list }}
    BotFilter::IgnorePatterns.expects(:pattern_list=).with(pattern_list)
    BotFilter::IgnorePatterns.new(options)
  end
  
  should 'set the pattern list to nil if no option exists' do
    options = { :data => 'puppies' }
    BotFilter::IgnorePatterns.expects(:pattern_list=).with(nil)
    BotFilter::IgnorePatterns.new(options)
  end
  
  should 'set the pattern list to nil if no options given' do
    BotFilter::IgnorePatterns.expects(:pattern_list=).with(nil)
    BotFilter::IgnorePatterns.new
  end
end
