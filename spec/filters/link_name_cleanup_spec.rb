require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/link_name_cleanup'

describe BotFilter::LinkNameCleanup do
  before :each do
    @filter = BotFilter::LinkNameCleanup.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::LinkNameCleanup.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::LinkNameCleanup.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'link_name_cleanup' => { :turd => :nugget } } }
    filter = BotFilter::LinkNameCleanup.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::LinkNameCleanup.new
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
  
  it 'should remove whitespace from the front of the name' do
    result = @filter.process({ :name => '  hello there', :type => :link })
    result[:name].should == 'hello there'
  end
  
  it 'should remove whitespace from the end of the name' do
    result = @filter.process({ :name => 'hello there   ', :type => :link })
    result[:name].should == 'hello there'
  end
  
  it 'should remove a trailing colon from the name' do
    result = @filter.process({ :name => 'hello there:', :type => :link })
    result[:name].should == 'hello there'
  end
  
  it 'should remove trailing dashes from the name' do
    result = @filter.process({ :name => 'hello there-', :type => :link })
    result[:name].should == 'hello there'
    
    result = @filter.process({ :name => 'hello there--', :type => :link })
    result[:name].should == 'hello there'
    
    result = @filter.process({ :name => 'hello there---', :type => :link })
    result[:name].should == 'hello there'
  end
  
  it 'should handle a combination of the above removals' do
    result = @filter.process({ :name => '  hello there : ', :type => :link })
    result[:name].should == 'hello there'
  end  
  
  it 'should do nothing for non-links' do
    result = @filter.process({ :name => '  hello there : ', :type => :blah })
    result[:name].should == '  hello there : '
  end
end
