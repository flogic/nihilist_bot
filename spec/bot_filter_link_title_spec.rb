require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/link_title'

describe BotFilter::LinkTitle do
  before :each do
    @filter = BotFilter::LinkTitle.new
    @url = 'http://www.yahoo.com'
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
  
  should 'return a hash' do
    @filter.process({ :data => 'puppies'}).should be_kind_of(Hash)
  end
  
  should 'use open to fetch URL' do
    @filter.expects(:open).with(@url)
    @filter.process({:url => @url})
  end
  
  should 'not fail if there is a problem with opening the URL' do
    lambda { @filter.process({:url => 'bad url' }) }.should_not raise_error
  end
  
  should 'not change existing title' do
    title = 'Welcome to my humble adobe'
    result = @filter.process({:url => 'bad url', :name => title})
    result[:name].should == title
  end
  
  should 'populate title with an empty string if there is a problem with opening the URL' do
    result = @filter.process({:url => 'bad url'})
    result[:name].should == ''
  end
  
  should 'populate title from URL' do
    title = 'Yahoo is the bomb'
    match_data = stub('match data', :[] => title)
    String.any_instance.stubs(:match).returns(match_data)
    result = @filter.process({:url => @url})
    result[:name].should == title
  end

  # Uncomment test if you want to test with a network connection
  # should 'work if there is a network connection' do
  #   result = @filter.process({:url => 'http://ni.hili.st' })
  #   result[:title].should == 'ni.hili.st'
  # end
end
