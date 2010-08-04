require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/youtube_domain_fix'

describe BotFilter::YoutubeDomainFix do
  before :each do
    @filter = BotFilter::YoutubeDomainFix.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::YoutubeDomainFix.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::YoutubeDomainFix.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'youtube_domain_fix' => { :turd => :nugget } } }
    filter = BotFilter::YoutubeDomainFix.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::YoutubeDomainFix.new
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
  
  it 'should convert a country-code youtube link to the equivalent .com one' do
    result = @filter.process({ :embed => 'http://www.youtube.co.uk/watch?v=IrV1rC8qr44', :type => :video })
    result[:embed].should == 'http://www.youtube.com/watch?v=IrV1rC8qr44'
  end
  
  it 'should leave a .com youtube link as-is' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?v=uwEXywdSpNQ', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ'
  end
  
  it 'should leave other data elements alone' do
    result = @filter.process({ :embed => 'http://www.youtube.co.uk/watch?v=IrV1rC8qr44', :type => :video, :poster => 'rick' })
    result[:type].should == :video
    result[:poster].should == 'rick'
  end
  
  it 'should do nothing for non-videos' do
    result = @filter.process({ :embed => '  hello there : ', :type => :blah })
    result[:type].should == :blah
    result[:embed].should == '  hello there : '
  end
end
