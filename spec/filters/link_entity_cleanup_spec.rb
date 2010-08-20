# encoding: utf-8 (for the raquo below)
require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/link_entity_cleanup'

describe BotFilter::LinkEntityCleanup do
  before :each do
    @filter = BotFilter::LinkEntityCleanup.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::LinkEntityCleanup.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::LinkEntityCleanup.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'link_entity_cleanup' => { :turd => :nugget } } }
    filter = BotFilter::LinkEntityCleanup.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::LinkEntityCleanup.new
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
  
  it 'should translate HTML entities in the name' do
    result = @filter.process({ :name => '&gt;&amp;&lt;', :type => :link })
    result[:name].should == '>&<'
  end
  
  it 'should handle non--low-ASCII entities' do
    result = @filter.process({ :name => '&raquo;&mdash;', :type => :link })
    result[:name].should == '»—'
  end
  
  it 'should handle numeric entities' do
    result = @filter.process({ :name => '&#187;', :type => :link })
    result[:name].should == '»'
  end
  
  it 'should not affect non-entity text' do
    result = @filter.process({ :name => 'hello there', :type => :link })
    result[:name].should == 'hello there'
  end
  
  it 'should not handle a combination of entity and non-entity text' do
    result = @filter.process({ :name => 'hello &amp; there', :type => :link })
    result[:name].should == 'hello & there'
  end
  
  it 'should do nothing for non-links' do
    result = @filter.process({ :name => '&gt; &amp; &lt;', :type => :blah })
    result[:name].should == '&gt; &amp; &lt;'
  end
end
