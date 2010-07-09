require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))
require 'bot'

def run_command(*args)
  Object.const_set(:ARGV, args)
  begin
    eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin bot]))
  rescue SystemExit
  end
end


describe 'bot command' do
  before :each do
    [:ARGV].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
    
    @bot = Bot.new
    @bot.stubs(:prepare)
    @bot.stubs(:start)
    Bot.stubs(:new).returns(@bot)
  end
  
  it 'should exist' do
    lambda { run_command }.should_not raise_error(Errno::ENOENT)
  end
  
  it 'should make a new bot instance' do
    Bot.expects(:new).returns(@bot)
    run_command
  end
  
  it 'should prepare the bot instance' do
    @bot.expects(:prepare)
    run_command
  end
  
  it 'should start the bot instance' do
    @bot.expects(:start)
    run_command
  end
end
