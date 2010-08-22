require 'rubygems'
require 'cinch'

require 'yaml'

require 'bot_parser'
require 'bot_filter'
require 'bot_sender'
require 'bot_plugin'

class Bot
  attr_reader :config
  attr_reader :bot
  attr_reader :parser, :filter, :sender
  
  def prepare
    load_config
    setup
    init_bot
  end
  
  def start
    bot.start
  end
  
  def load_config
    @config = YAML.load(File.read(File.expand_path(File.join(File.dirname(__FILE__), '/../config/config.yml'))))
    normalize_config
  end
  
  def setup
    @parser = BotParser.new
    @filter = BotFilter.new(config)
    @sender = BotSender.new(sender_configuration)
  end
  
  def init_bot
    options = {
      :server   => config['server'],
      :nick     => config['nick'],
      :realname => config['realname'],
      :username => config['username'],
      :channels => config['channels'],
    }
    
    @bot = Cinch::Bot.new do
      configure do |c|
        c.server   = options[:server]
        c.nick     = options[:nick]
        c.realname = options[:realname]
        c.username = options[:username]
        c.channels = options[:channels]
        
        c.plugins.plugins = [ BotPlugin::Process, BotPlugin::Help ]
      end
    end
    
    # Yeah, that's right
    (class << @bot; self; end).send(:attr_accessor, :container)
    @bot.container = self
  end
  
  def sender_configuration
    raise "bot configuration should include an active_sender option" unless config['active_sender']
    raise "bot configuration should include a list of senders" unless config['senders']
    raise "bot configuration doesn't have a senders entry for active_sender [#{config['active_sender']}]" unless config['senders'][config['active_sender']]
    raise "bot configuration doesn't have a destination type for active_sender [#{config['active_sender']}]" unless config['senders'][config['active_sender']]['destination']
    
    result = {}
    config['senders'][config['active_sender']].each_pair do |k, v|
      new_key = k.to_sym
      new_val = new_key == :destination ? v.to_sym : v
      result[new_key] = new_val
    end
    result
  end
  
  
  private
  
  def normalize_config
    config['realname'] ||= config['nick']
    config['username'] ||= config['nick']
    %w[channels address_required_channels].each do |channels|
      config[channels] = (config[channels] || []).collect { |c| normalized_channel_name(c) }
    end
  end
  
  def normalized_channel_name(name)
    name.sub(/^#?/, '#')
  end
end
