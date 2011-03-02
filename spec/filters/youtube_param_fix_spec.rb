require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/youtube_param_fix'

describe BotFilter::YoutubeParamFix do
  before :each do
    @filter = BotFilter::YoutubeParamFix.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::YoutubeParamFix.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::YoutubeParamFix.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'youtube_param_fix' => { :turd => :nugget } } }
    filter = BotFilter::YoutubeParamFix.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::YoutubeParamFix.new
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
  
  it 'should convert a youtube link with extra parameters in an unhelpful order to having the video ID first' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?feature=player_embedded&v=uwEXywdSpNQ', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ&feature=player_embedded'
  end
  
  it 'should convert a youtube link with extra parameters in an unhelpful order and including a fragment marker to having the video ID first' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?feature=player_embedded&v=TzYnlHZeSjw#t=2m37s', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=TzYnlHZeSjw&feature=player_embedded#t=2m37s'
  end
  
  it 'should leave a youtube link with extra parameters alone' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?v=uwEXywdSpNQ&feature=player_embedded', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ&feature=player_embedded'
  end
  
  it 'should leave a youtube link with extra parameters and including a fragment marker alone' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?v=TzYnlHZeSjw&feature=player_embedded#t=2m37s', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=TzYnlHZeSjw&feature=player_embedded#t=2m37s'
  end
  
  it 'should leave a simple youtube link as-is' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?v=uwEXywdSpNQ', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ'
  end
  
  it 'should leave a simple youtube link including a fragment marker as-is' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?v=TzYnlHZeSjw#t=2m37s', :type => :video })
    result[:embed].should == 'http://youtube.com/watch?v=TzYnlHZeSjw#t=2m37s'
  end
  
  it 'should leave other data elements alone' do
    result = @filter.process({ :embed => 'http://youtube.com/watch?v=uwEXywdSpNQ', :type => :video, :poster => 'rick' })
    result[:type].should == :video
    result[:poster].should == 'rick'
  end
  
  it 'should do nothing for non-videos' do
    result = @filter.process({ :embed => '  hello there : ', :type => :blah })
    result[:type].should == :blah
    result[:embed].should == '  hello there : '
  end
end
