require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/poster_info'

describe BotFilter::PosterInfo, 'adding poster info' do
  before :each do
    @filter = BotFilter::PosterInfo.new
  end
  
  should 'accept options on initialization' do
    lambda { BotFilter::PosterInfo.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  should 'not require options on initialization' do
    lambda { BotFilter::PosterInfo.new }.should_not raise_error(ArgumentError)
  end
  
  should 'store options' do
    options = stub('options')
    filter = BotFilter::PosterInfo.new(options)
    filter.options.should == options
  end
  
  should 'default options to empty hash' do
    filter = BotFilter::PosterInfo.new
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
  
  should 'return a hash' do
    @filter.process({ :data => 'puppies'}).should be_kind_of(Hash)
  end
  
  should 'add to caption for image' do
    hash = { :type => :image, :poster => 'fred', :caption => 'test one two' }
    result = @filter.process(hash)
    result[:caption].should == 'test one two (posted by fred)'
  end
  
  should 'handle nil caption for image' do
    hash = { :type => :image, :poster => 'fred' }
    result = @filter.process(hash)
    result[:caption].should == ' (posted by fred)'
  end
    
  should 'add to caption for video' do
    hash = { :type => :video, :poster => 'fred', :caption => 'test one two' }
    result = @filter.process(hash)
    result[:caption].should == 'test one two (posted by fred)'
  end
  
  should 'handle nil caption for video' do
    hash = { :type => :video, :poster => 'fred' }
    result = @filter.process(hash)
    result[:caption].should == ' (posted by fred)'
  end
  
  should 'add to source for quote' do
    hash = { :type => :quote, :poster => 'fred', :source => 'test one two' }
    result = @filter.process(hash)
    result[:source].should == 'test one two (posted by fred)'
  end
  
  should 'add to description for link' do
    hash = { :type => :link, :poster => 'fred', :description => 'test one two' }
    result = @filter.process(hash)
    result[:description].should == 'test one two (posted by fred)'
  end
  
  should 'handle nil description for link' do
    hash = { :type => :link, :poster => 'fred' }
    result = @filter.process(hash)
    result[:description].should == ' (posted by fred)'
  end
  
  should 'set body for fact' do
    hash = { :type => :fact, :poster => 'fred', :body => 'test one two' }
    result = @filter.process(hash)
    result[:body].should == '(posted by fred)'
  end
  
  should 'set body for true_or_face' do
    hash = { :type => :true_or_false, :poster => 'fred', :body => 'test one two' }
    result = @filter.process(hash)
    result[:body].should == '(posted by fred)'
  end
end
