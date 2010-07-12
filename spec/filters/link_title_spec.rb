require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/link_title'

describe BotFilter::LinkTitle do
  before :each do
    @filter = BotFilter::LinkTitle.new
    @url = 'http://www.yahoo.com'
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::LinkTitle.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::LinkTitle.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'link_title' => { :turd => :nugget } } }
    filter = BotFilter::LinkTitle.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::LinkTitle.new
    filter.options.should == {}
  end
  
  it 'should require data for processing' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  it 'should require a hash for processing' do
    lambda { @filter.process('puppies') }.should raise_error(TypeError)
  end
  
  it 'should accept a hash for processing' do
    lambda { @filter.process({ :data => 'puppies' }) }.should_not raise_error
  end
  
  it 'should return a hash' do
    @filter.process({ :data => 'puppies' }).should be_kind_of(Hash)
  end
  
  it 'should use open to fetch URL' do
    @filter.expects(:open).with(@url, anything)
    @filter.process({:url => @url, :type => :link})
  end
  
  it 'should specify a common browser as the user agent when opening' do
    @filter.expects(:open).with(@url, has_entry('User-Agent', 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'))
    @filter.process({:url => @url, :type => :link})
  end
  
  it 'should use the protocol and domain of the link as the HTTP referer when opening' do
    url = 'http://bp1.blogspot.com/foo/bar/baz/dontlinkthisimage.jpg'
    @filter.expects(:open).with(url, has_entry('Referer', 'http://bp1.blogspot.com/'))    
    @filter.process({:url => url, :type => :link})
  end
    
  it 'should do nothing for non-links' do
    @filter.expects(:open).never
    data = {:url => @url}
    @filter.process(data).should == data
  end
  
  it 'should not fail if there is a problem with opening the URL' do
    lambda { @filter.process({:url => 'bad url', :type => :link}) }.should_not raise_error
  end
  
  it 'should not change existing title' do
    title = 'Welcome to my humble adobe'
    result = @filter.process({:url => 'bad url', :type => :link, :name => title})
    result[:name].should == title
  end
  
  it 'should populate title with an empty string if there is a problem with opening the URL' do
    result = @filter.process({:url => 'bad url', :type => :link})
    result[:name].should == ''
  end
  
  it 'should populate title from URL' do
    title = 'Yahoo is the bomb'
    match_data = stub('match data', :[] => title)
    String.any_instance.stubs(:match).returns(match_data)
    result = @filter.process({:url => @url, :type => :link})
    result[:name].should == title
  end
  
  it 'should populate title from HTML title tag' do
    title = 'Yahoo is the bomb'
    html = %Q[<html>
                <head><title>#{title}</title></head>
                <body></body>
              </html>]
    f = stub('fh', :read => html)
    @filter.stubs(:open).yields(f)
    result = @filter.process({:url => @url, :type => :link})
    result[:name].should == title
  end
  
  it 'should populate title from HTML even with extra whitespace in title tag' do
    title = 'Yahoo is the bomb'
    html = %Q[<html>
                <head><title>
                  #{title.gsub(/\s/, "\n")}
                </title></head>
                <body></body>
              </html>]
    f = stub('fh', :read => html)
    @filter.stubs(:open).yields(f)
    result = @filter.process({:url => @url, :type => :link})
    result[:name].should == title
  end
  
  it 'should populate title from uppercased HTML title tag' do
    title = 'Yahoo is the bomb'
    html = %Q[<html>
                <head><TITLE>#{title}</TITLE></head>
                <body></body>
              </html>]
    f = stub('fh', :read => html)
    @filter.stubs(:open).yields(f)
    result = @filter.process({:url => @url, :type => :link})
    result[:name].should == title
  end

  # Uncomment test if you want to test with a network connection
  # it 'should work if there is a network connection' do
  #   result = @filter.process({:url => 'http://ni.hili.st' })
  #   result[:title].should == 'ni.hili.st'
  # end

end
