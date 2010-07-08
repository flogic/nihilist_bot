require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))
require 'bot_filter'

describe BotFilter, 'as a class' do
  it 'should provide a way to register a new filter' do
    BotFilter.register(:filt)
    BotFilter.kinds.should include(:filt)
  end
  
  it 'should provide a way to get the list of known filters' do
    BotFilter.kinds.should respond_to(:each)
  end
  
  it 'should provide a way to clear the list of known filters' do
    BotFilter.register(:testing)
    BotFilter.kinds.should include(:testing)
    BotFilter.clear_kinds
    BotFilter.kinds.should be_empty
  end
  
  it 'should provide the list of known filters in registration order' do
    kinds = [:filt, :test, :blah, :stuff, :hello]
    kinds.each { |kind|  BotFilter.register(kind) }
    BotFilter.kinds.should == kinds
  end
  
  it 'should provide a way to retrieve a filter class from a name' do
    filter = stub('turd nugget filter')
    BotFilter.expects(:const_get).with(:TurdNugget).returns(filter)
    BotFilter.get(:turd_nugget).should == filter
  end
end

describe BotFilter, "on initialization" do
  before(:each) do
    BotFilter.clear_kinds
  end
  
  it 'should accept options' do
    lambda { BotFilter.new(stub('options')) }.should_not raise_error(ArgumentError)
  end
  
  it 'should not require options' do
    lambda { BotFilter.new }.should_not raise_error(ArgumentError)
  end
  
  it 'should store options' do
    options = { :foo => :bar }
    filter = BotFilter.new(options)
    filter.options.should == options
  end
  
  it 'should default options to empty hash' do
    filter = BotFilter.new
    filter.options.should == {}
  end
  
  it "should look for filters" do
    BotFilter.expects(:locate_filters)
    BotFilter.new
  end
  
  it "should not look for filters more than once" do
    BotFilter.new
    BotFilter.expects(:locate_filters).never
    BotFilter.new
  end
  
  it "should register any active filters named in the filter options" do
    options = { 'active_filters' => [ 'foo', 'bar' ] }
    BotFilter.expects(:locate_filters).with(options)
    BotFilter.new(options)
  end
end

describe BotFilter, "when locating filters" do
  it "should not fail when no active filters are specified" do
    lambda { BotFilter.locate_filters({}) }.should_not raise_error
  end
  
  it "should register an individual filter" do
    options = { :active_filters => [ 'foo', 'bar' ] }
    BotFilter.expects(:register_filter).with('foo')
    BotFilter.expects(:register_filter).with('bar')
    BotFilter.locate_filters options
  end
end

describe BotFilter, "when registering a filter" do
  it "should fail when a filter to be registered cannot be found" do
    BotFilter.stubs(:filter_path).returns('gobbeldygook')
    lambda { BotFilter.register_filter 'foo' }.should raise_error
  end
  
  it "should load the filter file" do
    BotFilter.stubs(:filter_path).returns(__FILE__)
    BotFilter.expects(:load).with(__FILE__)
    BotFilter.register_filter 'foo'
  end
  
  it "should register the filter" do
    BotFilter.stubs(:filter_path).returns(__FILE__)
    BotFilter.stubs(:load)
    BotFilter.expects(:register).with('foo')
    BotFilter.register_filter 'foo'
  end
end

describe BotFilter, "when computing a filter path" do
  it "should look in the filters directory" do
    filter_path = File.expand_path(File.dirname(__FILE__) + '/../lib/filters/')
    File.expand_path(BotFilter.filter_path('foo')).should match(Regexp.new('^' + Regexp.escape(filter_path)))
  end
  
  it "should look for a ruby file with the same name as the filter" do
    BotFilter.filter_path('foo_bar').should match(%r{/foo_bar\.rb$})
  end
end

def setup_filter_chain
  @options = { :foo => :bar }
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
  
  it 'should require data' do
    lambda { @filter.process }.should raise_error(ArgumentError)
  end
  
  it 'should accept data' do
    lambda { @filter.process('hey hey hey') }.should_not raise_error(ArgumentError)
  end
  
  it 'should pass through the filter chain and return the result' do
    setup_filter_chain
    @objects.each_with_index { |o, i|  o.expects(:process).with(@data[i]).returns(@data[i+1]) }
    @filter.process(@data.first).should == @data.last
  end
  
  it 'should stop the filter chain and return nil if any filter returns a false value' do
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
