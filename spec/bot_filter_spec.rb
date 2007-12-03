require File.dirname(__FILE__) + '/spec_helper'
require 'bot_filter'

describe BotFilter, 'as a class' do
  should 'provide a way to register a new filter' do
    BotFilter.register(:filt)
    BotFilter.kinds.should include(:filt)
  end
  
  should 'provide a way to get the list of known filters' do
    BotFilter.kinds.should respond_to(:each)
  end
  
  should 'provide a way to clear the list of known filters' do
    BotFilter.register(:testing)
    BotFilter.kinds.should include(:testing)
    BotFilter.clear_kinds
    BotFilter.kinds.should be_empty
  end
  
  should 'provide the list of known filters in registration order' do
    kinds = [:filt, :test, :blah, :stuff, :hello]
    kinds.each { |kind|  BotFilter.register(kind) }
    BotFilter.kinds.should == kinds
  end
  
  should 'provide a way to retrieve a filter class from a name' do
    filter = stub('turd nugget filter')
    BotFilter.expects(:const_get).with(:TurdNugget).returns(filter)
    BotFilter.get(:turd_nugget).should == filter
  end
end

describe BotFilter, "on initialization" do
  before(:each) do
    BotFilter.clear_kinds
  end
  
  should 'accept options' do
    lambda { BotFilter.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  should 'not require options' do
    lambda { BotFilter.new }.should_not raise_error(ArgumentError)
  end
  
  should 'store options' do
    options = stub('options')
    filter = BotFilter.new(options)
    filter.options.should == options
  end
  
  should 'default options to empty hash' do
    filter = BotFilter.new
    filter.options.should == {}
  end
  
  should "look for filters" do
    BotFilter.expects(:locate_filters)
    BotFilter.new
  end
  
  should "not look for filters more than once" do
    BotFilter.new
    BotFilter.expects(:locate_filters).never
    BotFilter.new
  end
  
  should "register any filters named in the filter options"
  
  should "fail when a filter to be registered cannot be found"
  
  should "register filters in the order they appear in the filter options"
end

describe BotFilter, "when registering a filter" do
  should "load the filter file"
  should "make the filter avilable"
end

def setup_filter_chain
  @options = stub('options')
  @filter.stubs(:options).returns(@options)
  @data = %w[a b c d e]
  @filters = Array.new(@data.size - 1) { |i|  "name_#{@data[i]}".to_sym }
  @objects = []
  @filters.each_index do |i|
    filter = stub('filter')
    name = "name_#{@data[i]}".to_sym
    obj = stub('object #{@data[i]}')
    @objects.push(obj)
    obj.stubs(:process).with(@data[i]).returns(@data[i+1])
    filter.stubs(:new).with(@options).returns(obj)
    BotFilter.stubs(:get).with(name).returns(filter)
    BotFilter.register(name)
  end
end

describe BotFilter, 'when processing' do
  before :each do
    @filter = BotFilter.new
    BotFilter.clear_kinds
  end
  
  should 'require data' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  should 'accept data' do
    lambda { @filter.process('hey hey hey') }.should_not raise_error(ArgumentError)
  end
  
  should 'pass through the filter chain and return the result' do
    setup_filter_chain
    @objects.each_with_index { |o, i|  o.expects(:process).with(@data[i]).returns(@data[i+1]) }
    @filter.process(@data.first).should == @data.last
  end
  
  should 'stop the filter chain and return nil if any filter returns a false value' do
    setup_filter_chain
    target_index = @objects.size / 2
    @objects.each_with_index do |o, i|
      if i < target_index
        o.expects(:process).with(@data[i]).returns(@data[i+1])
      elsif i == target_index
        o.expects(:process).with(@data[i]).returns(false)
      else
        o.expects(:process).never
      end
    end
    @filter.process(@data.first).should be_nil
  end
end
