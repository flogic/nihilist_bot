require File.dirname(__FILE__) + '/spec_helper'
require 'bot_helper'

describe Kernel::BotHelper do
  
  it 'should implement get_link_title as a module method' do
    Kernel::BotHelper.should respond_to(:get_link_title)
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
end
