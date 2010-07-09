require 'rubygems'
require 'cinch'

require 'yaml'

require 'bot_parser'
require 'bot_filter'
require 'bot_sender'

class NewBot
  attr_reader :config
  attr_reader :bot
  attr_reader :parser, :filter, :sender
  
  def setup
    @parser = BotParser.new
    @filter = BotFilter.new(config)
    @sender = BotSender.new(sender_configuration)
  end
  
  def load_config
    @config = YAML.load(File.read('./config/config.yml'))
    normalize_config
  end
  
  def init_bot
    options = {
      :server   => config['server'],
      :nick     => config['nick'],
      :realname => config['realname'],
      :channels => config['channels'],
    }
    @bot = Cinch.setup(options)
    
    bot.on :privmsg do |m|
      result = parser.parse(m.nick, m.channel, m.text)
      result = filter.process(result) if result
      m.reply sender.deliver(result)  if result
    end
  end
  
  def sender_configuration
    raise "bot configuration should include an active_sender option" unless config['active_sender']
    raise "bot configuration should include a list of senders" unless config['senders']
    raise "bot configuration doesn't have a senders entry for active_sender [#{options['active_sender']}]" unless config['senders'][config['active_sender']]
    raise "bot configuration doesn't have a destination type for active_sender [#{options['active_sender']}]" unless config['senders'][config['active_sender']]['destination']
    
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
    %w[channels address_required_channels].each do |channels|
      config[channels] = (config[channels] || []).collect { |c| normalized_channel_name(c) }
    end
  end
  
  def normalized_channel_name(name)
    name.sub(/^#?/, '#')
  end
end
