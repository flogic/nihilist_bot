require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))
require 'rake'
require 'bot'

describe 'rake tasks' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), *%w[.. Rakefile]))
  end

  after do
    Rake.application = nil
  end

  describe 'bot:check_restart' do

    it 'should use the Bot support code to check if a restart is needed' do
      Bot.stubs(:restart)
      Bot.expects(:restart?)
      @rake['bot:check_restart'].invoke
    end

    it 'should restart the bot if a restart is indicated' do
      Bot.stubs(:restart?).returns(true)
      Bot.expects(:restart)
      @rake['bot:check_restart'].invoke
    end

    it 'should do nothing if a restart is not indicated' do
      Bot.stubs(:restart?).returns(false)
      Bot.expects(:restart).never
      @rake['bot:check_restart'].invoke
    end
  end

  describe 'Bot support code' do
    it 'should check if restart is needed' do
      Bot.should respond_to(:restart?)
    end

    describe 'checking if restart is needed' do
      it 'should get the status output from the control script' do
        Bot.expects(:`).with("#{File.expand_path(File.join(File.dirname(__FILE__), *%w[.. bin bot_control]))} status").returns('')
        Bot.restart?
      end

      it 'should return false if the bot is running' do
        Bot.stubs(:`).returns("bot: running [pid 27015]\n")
        Bot.restart?.should == false
      end

      it 'should return true if the bot is not running' do
        Bot.stubs(:`).returns("bot: not running\n")
        Bot.restart?.should == true
      end
    end

    it 'should be able to restart' do
      Bot.should respond_to(:restart)
    end

    describe 'restarting' do
      it 'should use the control script to start the bot' do
        Bot.expects(:system).with(File.expand_path(File.join(File.dirname(__FILE__), *%w[.. bin bot_control])), 'start')
        Bot.restart
      end
    end
  end
end
