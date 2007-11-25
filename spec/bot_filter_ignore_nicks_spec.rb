require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/ignore_nicks'

describe BotFilter::IgnoreNicks do
  before :each do
    @filter = BotFilter::IgnoreNicks.new
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
  
  should 'use the stored list of nicks' do
    BotFilter::IgnoreNicks.expects(:nick_list).returns([])
    @filter.process({ :data => 'puppies' })
  end
  
  should 'return the input hash if no poster given' do
    BotFilter::IgnoreNicks.stubs(:nick_list).returns(%w[fred thomas])
    data = { :data => 'puppies' }
    @filter.process(data).should == data
  end
  
  should 'return the input hash if poster does not appear in the nick list' do
    BotFilter::IgnoreNicks.stubs(:nick_list).returns(%w[fred thomas])
    data = { :data => 'puppies', :poster => 'george' }
    @filter.process(data).should == data
  end
  
  should 'return nil if poster appears in the nick list' do
    BotFilter::IgnoreNicks.stubs(:nick_list).returns(%w[fred thomas])
    data = { :data => 'puppies', :poster => 'fred' }
    @filter.process(data).should be_nil
  end
end

describe BotFilter::IgnoreNicks, 'when asked about nicks to ignore' do
  should 'return a list' do
    BotFilter::IgnoreNicks.nick_list.should respond_to(:include?)
  end
  
  should 'return the set nick list' do
    list = [1,2,3]
    BotFilter::IgnoreNicks.nick_list = list
    BotFilter::IgnoreNicks.nick_list.should == list
  end
  
  should 'return an empty list if nick list is not set' do
    BotFilter::IgnoreNicks.nick_list = nil
    BotFilter::IgnoreNicks.nick_list.should == []
  end
end