require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/poster_info'

describe BotFilter::PosterInfo, 'adding poster info' do
  before :each do
    @filter = BotFilter::PosterInfo.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::PosterInfo.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::PosterInfo.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { :filters => { 'poster_info' => { :turd => :nugget } } }
    filter = BotFilter::PosterInfo.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::PosterInfo.new
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
  
  it 'should return a hash' do
    @filter.process({ :data => 'puppies'}).should be_kind_of(Hash)
  end
  
  it 'should add to caption for image' do
    hash = { :type => :image, :poster => 'fred', :caption => 'test one two' }
    result = @filter.process(hash)
    result[:caption].should == 'test one two (posted by fred)'
  end
  
  it 'should handle nil caption for image' do
    hash = { :type => :image, :poster => 'fred' }
    result = @filter.process(hash)
    result[:caption].should == ' (posted by fred)'
  end
    
  it 'should add to caption for video' do
    hash = { :type => :video, :poster => 'fred', :caption => 'test one two' }
    result = @filter.process(hash)
    result[:caption].should == 'test one two (posted by fred)'
  end
  
  it 'should handle nil caption for video' do
    hash = { :type => :video, :poster => 'fred' }
    result = @filter.process(hash)
    result[:caption].should == ' (posted by fred)'
  end
  
  it 'should add to source for quote' do
    hash = { :type => :quote, :poster => 'fred', :source => 'test one two' }
    result = @filter.process(hash)
    result[:source].should == 'test one two (posted by fred)'
  end
  
  it 'should add to description for link' do
    hash = { :type => :link, :poster => 'fred', :description => 'test one two' }
    result = @filter.process(hash)
    result[:description].should == 'test one two (posted by fred)'
  end
  
  it 'should handle nil description for link' do
    hash = { :type => :link, :poster => 'fred' }
    result = @filter.process(hash)
    result[:description].should == ' (posted by fred)'
  end
  
  it 'should set body for fact' do
    hash = { :type => :fact, :poster => 'fred', :body => 'test one two' }
    result = @filter.process(hash)
    result[:body].should == '(posted by fred)'
  end
  
  it 'should set body for true_or_false' do
    hash = { :type => :true_or_false, :poster => 'fred', :body => 'test one two' }
    result = @filter.process(hash)
    result[:body].should == '(posted by fred)'
  end
  
  it 'should set body for definition' do
    hash = { :type => :definition, :poster => 'fred', :body => 'test one two' }
    result = @filter.process(hash)
    result[:body].should == '(posted by fred)'
  end
end
