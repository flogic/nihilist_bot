require File.dirname(__FILE__) + '/spec_helper'
require 'bot_helper'

describe Kernel::BotHelper do
  it 'should implement get_link_title as a module method' do
    Kernel::BotHelper.should respond_to(:get_link_title)
  end
  
  should 'implement add_poster_info as a module method' do
    Kernel::BotHelper.should respond_to(:add_poster_info)
  end
end

describe 'get_link_title', 'without a URL' do
  it 'should fail' do
    lambda { Kernel::BotHelper.get_link_title }.should raise_error(ArgumentError)
  end
end

describe 'get_link_title', 'with a URL' do
  before :each do
    @url = 'http://www.yahoo.com'
  end
  
  it 'should not fail if there is a problem with opening the URL' do
    lambda { Kernel::BotHelper.get_link_title('bad url') }.should_not raise_error
  end
  
  it 'should return an empty_string if there is a problem with opening the URL' do
    Kernel::BotHelper.get_link_title('bad url').should == ''
  end
  
  it 'should return the title' do
    title = 'Yahoo is the bomb'
    match_data = stub('match data', :[] => title)
    String.any_instance.stubs(:match).returns(match_data)
    Kernel::BotHelper.get_link_title(@url).should == title
  end
  
  it 'should use open to fetch title' do
    Kernel::BotHelper.expects(:open).once
    Kernel::BotHelper.get_link_title(@url)
  end

  # Uncomment test if you want to test with a network connection
  # it 'should work if there is a network connection' do
  #   Kernel::BotHelper.get_link_title('http://ni.hili.st').should == 'ni.hili.st'
  # end
end

describe 'adding poster info' do
  should 'require a hash' do
    lambda { Kernel::BotHelper.add_poster_info }.should raise_error(ArgumentError)
  end
  
  should 'accept a hash' do
    lambda { Kernel::BotHelper.add_poster_info({}) }.should_not raise_error(ArgumentError)
  end
  
  should 'add to caption for image' do
    hash = { :type => :image, :poster => 'fred', :caption => 'test one two' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:caption].should == 'test one two (posted by fred)'
  end
  
  should 'handle nil caption for image' do
    hash = { :type => :image, :poster => 'fred' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:caption].should == ' (posted by fred)'
  end
    
  should 'add to caption for video' do
    hash = { :type => :video, :poster => 'fred', :caption => 'test one two' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:caption].should == 'test one two (posted by fred)'
  end
  
  should 'handle nil caption for video' do
    hash = { :type => :video, :poster => 'fred' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:caption].should == ' (posted by fred)'
  end
  
  should 'add to source for quote' do
    hash = { :type => :quote, :poster => 'fred', :source => 'test one two' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:source].should == 'test one two (posted by fred)'
  end
  
  should 'add to description for link' do
    hash = { :type => :link, :poster => 'fred', :description => 'test one two' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:description].should == 'test one two (posted by fred)'
  end
  
  should 'handle nil description for link' do
    hash = { :type => :link, :poster => 'fred' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:description].should == ' (posted by fred)'
  end
  
  should 'set body for fact' do
    hash = { :type => :fact, :poster => 'fred', :body => 'test one two' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:body].should == '(posted by fred)'
  end
  
  should 'set body for true_or_face' do
    hash = { :type => :true_or_false, :poster => 'fred', :body => 'test one two' }
    result = Kernel::BotHelper.add_poster_info(hash)
    result[:body].should == '(posted by fred)'
  end
end
