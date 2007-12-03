require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'
require 'filters/link_title'

describe BotFilter::LinkTitle do
  before :each do
    @filter = BotFilter::LinkTitle.new
    @url = 'http://www.yahoo.com'
  end
  
  should 'accept options on initialization' do
    lambda { BotFilter::LinkTitle.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  should 'not require options on initialization' do
    lambda { BotFilter::LinkTitle.new }.should_not raise_error(ArgumentError)
  end
  
  should 'store options for this filter' do
    options = { :filters => { 'link_title' => { :turd => :nugget } } }
    filter = BotFilter::LinkTitle.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  should 'default options to empty hash' do
    filter = BotFilter::LinkTitle.new
    filter.options.should == {}
  end
  
  should 'require data for processing' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  should 'require a hash for processing' do
    lambda { @filter.process('puppies') }.should raise_error(TypeError)
  end
  
  should 'accept a hash for processing' do
    lambda { @filter.process({ :data => 'puppies' }) }.should_not raise_error
  end
  
  should 'return a hash' do
    @filter.process({ :data => 'puppies' }).should be_kind_of(Hash)
  end
  
  should 'use open to fetch URL' do
    @filter.expects(:open).with(@url)
    @filter.process({:url => @url, :type => :link})
  end
  
  should 'do nothing for non-links' do
    @filter.expects(:open).never
    data = {:url => @url}
    @filter.process(data).should == data
  end
  
  should 'not fail if there is a problem with opening the URL' do
    lambda { @filter.process({:url => 'bad url', :type => :link}) }.should_not raise_error
  end
  
  should 'not change existing title' do
    title = 'Welcome to my humble adobe'
    result = @filter.process({:url => 'bad url', :type => :link, :name => title})
    result[:name].should == title
  end
  
  should 'populate title with an empty string if there is a problem with opening the URL' do
    result = @filter.process({:url => 'bad url', :type => :link})
    result[:name].should == ''
  end
  
  should 'populate title from URL' do
    title = 'Yahoo is the bomb'
    match_data = stub('match data', :[] => title)
    String.any_instance.stubs(:match).returns(match_data)
    result = @filter.process({:url => @url, :type => :link})
    result[:name].should == title
  end
  
  should 'populate title from HTML title tag' do
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
  
  should 'populate title from HTML even with extra whitespace in title tag' do
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
  
  should 'populate title from uppercased HTML title tag' do
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
  # should 'work if there is a network connection' do
  #   result = @filter.process({:url => 'http://ni.hili.st' })
  #   result[:title].should == 'ni.hili.st'
  # end

end
