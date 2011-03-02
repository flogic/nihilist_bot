require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'bot_filter'
require 'filters/tweet_quote'

describe BotFilter::TweetQuote do
  before :each do
    @filter = BotFilter::TweetQuote.new
  end
  
  it 'should accept options on initialization' do
    lambda { BotFilter::TweetQuote.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options on initialization' do
    lambda { BotFilter::TweetQuote.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options for this filter' do
    options = { 'filters' => { 'tweet_quote' => { :turd => :nugget } } }
    filter = BotFilter::TweetQuote.new(options)
    filter.options.should == { :turd => :nugget }
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter::TweetQuote.new
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
  
  describe 'for twitter links' do
    before :each do
      @entry_content = stub('entry content', :text => 'this is the entry')
      @name_content  = stub('name content', :text => 'some name')
      @page = stub('page')
      @page.stubs(:/).with('span.entry-content').returns(@entry_content)
      @page.stubs(:/).with('div.full-name').returns(@name_content)
      @agent = stub('mechanize agent', :get => @page)
      Mechanize.stubs(:new).returns(@agent)
      @data = { :url => 'http://twitter.com/rickbradley/status/3065413804', :type => :link, :poster => 'rickbradley' }
    end
    
    it 'should create a mechanize agent' do
      Mechanize.expects(:new).returns(@agent)
      @filter.process(@data)
    end
    
    it 'should get the twitter link' do
      @agent.expects(:get).with(@data[:url]).returns(@page)
      @filter.process(@data)
    end
    
    it 'should get the normal twitter link when confronted with #! retardation' do
      normal_url  = 'http://twitter.com/rickbradley/status/3065413804'
      @data[:url] = 'http://twitter.com/#!/rickbradley/status/3065413804'
      @agent.expects(:get).with(normal_url).returns(@page)
      @filter.process(@data)
    end
    
    it 'should get the tweet content' do
      @page.expects(:/).with('span.entry-content').returns(@entry_content)
      @filter.process(@data)
    end
    
    it 'should get the author name' do
      @page.expects(:/).with('div.full-name').returns(@name_content)
      @filter.process(@data)
    end
    
    it 'should return a quote' do
      result = @filter.process(@data)
      result[:type].should == :quote
    end
    
    it 'should use the tweet content as the quote text' do
      result = @filter.process(@data)
      result[:quote].should == @entry_content.text
    end
    
    it 'should use the tweet author as the quote source' do
      result = @filter.process(@data)
      result[:source].should == @name_content.text
    end
    
    describe 'when the author name is blank' do
      before :each do
        @name_content.stubs(:text).returns('')
        @username_content = stub('username content', :text => 'some user')
        @page.stubs(:/).with('a.screen-name').returns(@username_content)
      end
      
      it 'should get the username' do
        @page.expects(:/).with('a.screen-name').returns(@username_content)
        @filter.process(@data)
      end
      
      it 'should use the username as the quote source' do
        result = @filter.process(@data)
        result[:source].should == @username_content.text
      end
    end
    
    it 'normally should not get the username' do
      @page.expects(:/).with('a.screen-name').never
      @filter.process(@data)
    end
    
    it 'should leave the twitter link as the quote url' do
      result = @filter.process(@data)
      result[:url].should == @data[:url]
    end
    
    it 'should leave the initial poster intact' do
      result = @filter.process(@data)
      result[:poster].should == @data[:poster]
    end
    
    it "should also work for 'statuses' links" do
      @data[:url].sub!(/status/, 'statuses')
      result = @filter.process(@data)
      result[:quote].should == @entry_content.text
    end
  end
  
  it 'should do nothing for non-twitter links' do
    data = { :url => 'http://www.yahoo.com/', :type => :link }
    result = @filter.process(data)
    Mechanize.expects(:new).never
    result.should == data
  end
  
  it 'should do nothing for non-twitter links even with #! retardation' do
    data     = { :url => 'http://www.facebook.com/example.profile#!/pages/Another-Page/123456789012345', :type => :link }
    expected = { :url => data[:url].dup, :type => :link }
    
    result = @filter.process(data)
    Mechanize.expects(:new).never
    result.should == expected
  end
  
  it 'should do nothing for non-links' do
    data = { :url => 'http://twitter.com/rickbradley/status/3065413804', :type => :blah }
    result = @filter.process(data)
    Mechanize.expects(:new).never
    result.should == data
  end
end
