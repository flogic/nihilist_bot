require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/ignore_nicks'

describe BotFilter::IgnoreNicks do
  before :each do
    @filter = BotFilter::IgnoreNicks.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::IgnoreNicks.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::IgnoreNicks.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { :filters => { 'ignore_nicks' => { :turd => :nugget } } }
    filter = BotFilter::IgnoreNicks.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::IgnoreNicks.new
    filter.options.should == {}
  end
  
  it 'should require data for processing' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  it 'should require a hash for processing' do
    lambda { @filter.process('puppies') }.should raise_error(TypeError)
  end
  
  it 'should accept a hash for processing' do
    lambda { @filter.process({ :data => 'puppies'}) }.should_not raise_error
  end
  
  it 'should use the stored list of nicks' do
    BotFilter::IgnoreNicks.expects(:nick_list).returns([])
    @filter.process({ :data => 'puppies' })
  end
  
  it 'should return the input hash if no poster given' do
    BotFilter::IgnoreNicks.stubs(:nick_list).returns(%w[fred thomas])
    data = { :data => 'puppies' }
    @filter.process(data).should == data
  end
  
  it 'should return the input hash if poster does not appear in the nick list' do
    BotFilter::IgnoreNicks.stubs(:nick_list).returns(%w[fred thomas])
    data = { :data => 'puppies', :poster => 'george' }
    @filter.process(data).should == data
  end
  
  it 'should return nil if poster appears in the nick list' do
    BotFilter::IgnoreNicks.stubs(:nick_list).returns(%w[fred thomas])
    data = { :data => 'puppies', :poster => 'fred' }
    @filter.process(data).should be_nil
  end
end

describe BotFilter::IgnoreNicks, 'when asked about nicks to ignore' do
  it 'should return a list' do
    BotFilter::IgnoreNicks.nick_list.should respond_to(:include?)
  end
  
  it 'should return the set nick list' do
    list = [1,2,3]
    BotFilter::IgnoreNicks.nick_list = list
    BotFilter::IgnoreNicks.nick_list.should == list
  end
  
  it 'should return an empty list if nick list is not set' do
    BotFilter::IgnoreNicks.nick_list = nil
    BotFilter::IgnoreNicks.nick_list.should == []
  end
end

describe BotFilter::IgnoreNicks, 'when initialized' do
  it 'should set the nick list from the given options' do
    nick_list = stub('nick list')
    options = { :filters => { 'ignore_nicks' => { 'nicks' => nick_list } } }
    BotFilter::IgnoreNicks.expects(:nick_list=).with(nick_list)
    BotFilter::IgnoreNicks.new(options)
  end
  
  it 'should set the nick list to nil if no option exists' do
    options = { :data => 'puppies' }
    BotFilter::IgnoreNicks.expects(:nick_list=).with(nil)
    BotFilter::IgnoreNicks.new(options)
  end
  
  it 'should set the nick list to nil if no options given' do
    BotFilter::IgnoreNicks.expects(:nick_list=).with(nil)
    BotFilter::IgnoreNicks.new
  end
end
