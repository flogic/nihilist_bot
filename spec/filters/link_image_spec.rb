require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/link_image'

describe BotFilter::LinkImage do
  before :each do
    @filter = BotFilter::LinkImage.new
    @url = 'http://some.domain.com/some_image.jpg'
    @data = { :url => @url, :type => :link, :poster => 'some_dude' }
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::LinkImage.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::LinkImage.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'link_image' => { :turd => :nugget } } }
    filter = BotFilter::LinkImage.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::LinkImage.new
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
  
  it 'should use open to fetch URL' do
    @filter.expects(:open).with(@url, anything)
    @filter.process(@data)
  end
  
  it 'should specify a common browser as the user agent when opening' do
    @filter.expects(:open).with(@url, has_entry('User-Agent', 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'))
    @filter.process(@data)
  end
  
  it 'should use the protocol and domain of the link as the HTTP referer when opening' do
    url = 'http://bp1.blogspot.com/foo/bar/baz/dontlinkthisimage.jpg'
    @filter.expects(:open).with(url, has_entry('Referer', 'http://bp1.blogspot.com/'))    
    @filter.process({:url => url, :type => :link})
  end
  
  it 'should check the content type of the URL' do
    f = stub('fh')
    f.expects(:content_type).returns('')
    @filter.stubs(:open).yields(f)
    @filter.process(@data)
  end
  
  it 'should do nothing if the content is not an image' do
    f = stub('fh', :content_type => 'text/html')
    @filter.stubs(:open).yields(f)
    @filter.process(@data).should == @data
  end
  
  it 'should convert the link to an image if the content is an image' do
    f = stub('fh', :content_type => 'image/jpeg')
    @filter.stubs(:open).yields(f)
    result = @filter.process(@data)
    result[:type].should   == :image
    result[:source].should == @data[:url]
  end
  
  it 'should convert the link to an image if the content is any sort of image' do
    f = stub('fh', :content_type => 'image/made_up_mime')
    @filter.stubs(:open).yields(f)
    result = @filter.process(@data)
    result[:type].should   == :image
    result[:source].should == @data[:url]
  end
  
  it 'should carry over the link name to the image title' do
    name = 'blah blah'
    f = stub('fh', :content_type => 'image/jpeg')
    @filter.stubs(:open).yields(f)
    @data[:name] = name
    result = @filter.process(@data)
    result[:title].should == name
  end
  
  it 'should carry over the link description to the image caption' do
    desc = 'blah blah blah'
    f = stub('fh', :content_type => 'image/jpeg')
    @filter.stubs(:open).yields(f)
    @data[:description] = desc
    result = @filter.process(@data)
    result[:caption].should == desc
  end
  
  it 'should leave the poster intact' do
    f = stub('fh', :content_type => 'image/jpeg')
    @filter.stubs(:open).yields(f)
    result = @filter.process(@data)
    result[:poster].should == @data[:poster]
  end
    
  it 'should do nothing for non-links' do
    @filter.expects(:open).never
    data = {:url => @url}
    @filter.process(data).should == data
  end
  
  it 'should not fail if there is a problem with opening the URL' do
    lambda { @filter.process({:url => 'bad url', :type => :link}) }.should_not raise_error
  end
end
